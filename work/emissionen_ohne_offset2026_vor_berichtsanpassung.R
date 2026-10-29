# NH3-Auswertung Mettmenstetten. Quelldateien werden ausschliesslich gelesen.
# Ausführen: source("emissionen_mettmenstetten.R") oder Rscript emissionen_mettmenstetten.R
# Pakete bei Bedarf selbst installieren: install.packages(c("data.table", "qs2", "readxl"))
working_directory <- path.expand("~/git/overall-campaigns")
if (!dir.exists(working_directory)) stop("Arbeitsordner fehlt: ", working_directory)
setwd(working_directory)
required <- c("data.table", "qs2", "readxl")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Fehlende Pakete: ", paste(missing, collapse = ", "))
suppressPackageStartupMessages(library(data.table))

# EINSTELLUNGEN ---------------------------------------------------------------
anzahl_umtriebe <- 8.5  # Umtriebe pro Jahr: hier frei einstellen
cfg <- list(
  root = path.expand("~/git"),
  excel = path.expand("~/Documents/0 - MSc HAFL/MA/documents/Korrektur_Emissionen_Mettmenstetten_neue-Kalibration.xlsx"),
  out = "ergebnisse_ohne_offset2026",
  cycles = anzahl_umtriebe,
  # Modellannahme: ein Tier pro Tierplatz und Umtrieb. Keine Kapazitäten geliefert.
  # Bei abweichender Belegung hier Tiere je Platz einsetzen.
  animals_per_place = 1,
  offset_method = "cumulative_endpoint", # kumulierte Endwerte pro Tier wie im PDF
  fit_points = 8,        # quadratischer Fit, wie Excel letzte 8 kumulierte Tageswerte
  max_extrapolation_days = 4,
  season_weights = c(winter = 1/3, transition = 1/3, summer = 1/3)
)
campaigns <- data.table(
  # Juli 2025 ist ausdrücklich ausgeschlossen und wird nicht importiert.
  campaign = c("feb2024", "apr2024", "jul2024", "dec2024", "aug2026"),
  season = c("winter", "transition", "summer", "winter", "summer"),
  role = c("wrg", "wrg", "wrg", "offset", "offset"),
  include_annual = rep(TRUE, 5)
)
# Separates Szenario: August 2026 vollständig ausschliessen.
campaigns <- campaigns[campaign != "aug2026"]
# Endtag ist verstrichene Mastdauer. Excel unterscheidet Endtag und Schlachttag.
slaughter <- data.table(end_day = c(29,30,31,32,33.5,34.25,35.25,36.25),
                        slaughter_day = 30:37,
                        share = c(18,2,6,6,4,2,51,11)/100)
stopifnot(abs(sum(slaughter$share)-1) < 1e-12,
          abs(sum(cfg$season_weights)-1) < 1e-12,
          all(slaughter$share >= 0), cfg$cycles > 0, cfg$animals_per_place > 0)
dir.create(cfg$out, recursive = TRUE, showWarnings = FALSE)
save_csv <- function(x, name) fwrite(x, file.path(cfg$out, paste0(name, ".csv")), sep = ";", dec = ",", bom = TRUE, na = "NA")
folders <- list.dirs(cfg$root,recursive=FALSE,full.names=FALSE)
ids <- sub("^mettmenstetten-","",folders[grepl("^mettmenstetten-",folders)])
inventory <- data.table(campaign=ids)
inventory[, status := fifelse(campaign %in% campaigns$campaign,"importiert",
  "nicht_in_Excel_und_anderes_Datenschema_separat_pruefen")]
inventory[campaign == "aug2026", status := "Szenario_ohne_Offsetkampagne2026_ausgeschlossen"]
inventory[campaign == "jul2025", status := "auf_Nutzerwunsch_vollstaendig_ausgeschlossen"]
save_csv(inventory,"kampagneninventar")

# 1. IMPORT UND DATENPRÜFUNG --------------------------------------------------
read_campaign <- function(id) {
  path <- file.path(cfg$root, paste0("mettmenstetten-", id), "rsaves", "final-dataset.qd")
  if (!file.exists(path)) stop("Fehlende Kampagnendatei: ", path)
  x <- as.data.table(qs2::qd_read(path))
  times <- readRDS(file.path(dirname(path), "local-times.rds"))
  needed <- c("housing","tracer","type","flow_direction","location","sensor","units","value","days","st","et","coverage")
  if (!all(needed %in% names(x))) stop("Unbekanntes Datenschema: ", id)
  cc <- x[tracer == "nh3" & type == "cum_flow" & flow_direction == "net" & location == "total"]
  aa <- x[location == "bfn" & sensor == "tiere"]
  ff <- x[tracer == "nh3" & type == "flow" & flow_direction == "net" & location == "total"]
  if (anyDuplicated(cc[, .(housing, st, et)]) || anyDuplicated(aa[, .(housing, st, et)]))
    stop("Mehrdeutige kumulierte Reihe/Tierzahl: ", id)
  stopifnot(setequal(unique(cc$housing), c("housing_1","housing_2")), all(cc$units == "kg"))
  setorder(cc, housing, st); setorder(aa, housing, st)
  z <- merge(cc, aa[, .(housing, st, et, animals = value)], by = c("housing","st","et"), all.x = TRUE)
  if (any(!is.finite(z$value)) || any(!is.finite(z$animals) | z$animals <= 0))
    stop("Fehlende kumulierte Emissionen/Tierzahlen: ", id)
  # Zeitbasis aus expliziten Einstallungsdaten, nicht blind aus der Spalte days.
  z[, age_end := as.numeric(difftime(et, times[[.BY$housing]][["from"]], units = "days")), by = housing]
  z[, age_start := as.numeric(difftime(st, times[[.BY$housing]][["from"]], units = "days")), by = housing]
  z[, ef := value / animals * 1000] # kumulierte g NH3/Tier, wie Kampagnenberichte
  z[, campaign := id]
  quality <- z[, .(
    cumulative_start_day = min(age_start), measured_end_day = max(age_end),
    days_axis_shift = median(age_end - as.numeric(et-st, units="days")/2 - days),
    cumulative_kg = tail(value,1), animals_end = tail(animals,1),
    ef_end_g_animal = tail(ef,1), coverage_cumulative_end = tail(coverage,1),
    negative_cumulative_steps = sum(diff(value) < -1e-8),
    max_interval_hours = max(as.numeric(et-st, units="hours")),
    max_gap_hours = if (.N > 1) max(c(0, as.numeric(st[-1]-et[-.N], units="hours"))) else 0
  ), by = .(campaign,housing)]
  fq <- ff[, .(flow_missing_n = sum(!is.finite(value)), flow_coverage_mean = mean(coverage,na.rm=TRUE)), by=housing]
  quality <- merge(quality, fq, by="housing")
  quality[, valid_full_cycle := cumulative_start_day < 1/24 + 1e-6 &
            abs(days_axis_shift) < 1/24 & negative_cumulative_steps == 0 & max_gap_hours < 1e-6]
  # Tägliche kumulierte Werte: letzter Messwert im Masttag / mittlere Tierzahl.
  # Der letzte unvollständige Masttag bleibt ein eigener Stützpunkt.
  z[, bin := floor(age_start + 1e-8)]
  daily <- z[, .(day = tail(age_end,1), ef = tail(value,1)/mean(animals)*1000), by=.(campaign,housing,bin)]
  list(raw=z, daily=daily, quality=quality, path=path)
}
data <- setNames(lapply(campaigns$campaign, read_campaign), campaigns$campaign)
quality <- rbindlist(lapply(data, `[[`, "quality"))
save_csv(quality, "datenqualitaet")
save_csv(rbindlist(lapply(data, `[[`, "daily")), "tageswerte_kumuliert")
valid_ids <- quality[, .(valid = all(valid_full_cycle)), by=campaign][valid == TRUE, campaign]
bad_requested <- setdiff(campaigns[include_annual == TRUE,campaign], valid_ids)
if (length(bad_requested)) stop("Ungültige Zeitbasis/Kumulierung im Jahresmittel: ",paste(bad_requested,collapse=", "), ". Siehe datenqualitaet.csv")

# 2. OFFSET: VERHÄLTNIS DER KUMULIERTEN ENDWERTE WIE IM KAMPAGNEN-PDF ----------
# Ungerundete Endmenge kg / letzte Tierzahl * 1000; keine Tagesinterpolation,
# keine Extrapolation und keine Quotienten aus den gerundeten PDF-Anzeigen.
offsets <- rbindlist(lapply(campaigns[role == "offset", campaign], function(id) {
  if (!id %in% valid_ids) stop("Ungültige Offset-Kampagne: ",id)
  z <- data[[id]]$raw
  e1 <- tail(z[housing=="housing_1"][order(et)],1)
  e2 <- tail(z[housing=="housing_2"][order(et)],1)
  a <- e1$ef; b <- e2$ef
  data.table(campaign=id, method=cfg$offset_method,
    barn1_end=as.character(e1$et), barn2_end=as.character(e2$et),
    barn1_end_day=e1$age_end, barn2_end_day=e2$age_end,
    barn1_cumulative_kg=e1$value, barn2_cumulative_kg=e2$value,
    barn1_animals=e1$animals, barn2_animals=e2$animals,
    barn1_g_animal=a, barn2_g_animal=b, ratio_2_over_1=b/a)
}))
if (any(!is.finite(offsets$ratio_2_over_1) | offsets$ratio_2_over_1 <= 0)) stop("Ungültiges Offsetverhältnis")
r_winter <- offsets[campaign=="dec2024",ratio_2_over_1]
variants <- data.table(
  variant=c("winter_stall1", "winter_gemeinsame_basis"),
  ratio=rep(r_winter,2),
  factor_barn1=c(1,(1+r_winter)/2))
variants[, factor_barn2 := factor_barn1 / ratio]
save_csv(offsets,"offsets"); save_csv(variants,"varianten")

# 3. MASTTAGVERTEILUNG UND QUADRATISCHE EXTRAPOLATION -------------------------
predict_curve <- function(d, targets) {
  setorder(d,day)
  if (anyDuplicated(d$day)) stop("Doppelte Masttage")
  fit <- tail(d,cfg$fit_points)
  if (nrow(fit) < cfg$fit_points) stop("Zu wenig Fit-Stützpunkte")
  x0 <- max(fit$day); fit[, t := day-x0]
  model <- lm(ef ~ t + I(t^2), data=fit)
  if (model$rank != 3) stop("Quadratischer Fit nicht bestimmbar")
  if (max(targets)-max(d$day) > cfg$max_extrapolation_days) stop("Extrapolationsgrenze überschritten")
  y <- approx(d$day,d$ef,xout=targets,rule=1)$y
  extra <- targets > max(d$day)
  y[extra] <- predict(model,newdata=data.frame(t=targets[extra]-x0))
  if (any(!is.finite(y)) || any(y < 0)) stop("Ungültige Prognose")
  # Keine stillschweigende Nullsetzung oder Monotoniekorrektur.
  if (any(diff(y) < -1e-6)) stop("Kumulative Prognose sinkt; Fit prüfen")
  data.table(end_day=targets, ef_g_animal=y, extrapolated=extra,
             measured_end_day=max(d$day), fit_rmse=sqrt(mean(resid(model)^2)))
}
curves <- rbindlist(lapply(valid_ids, function(id) rbindlist(lapply(c("housing_1","housing_2"), function(h) {
  d <- data[[id]]$daily[housing==h]
  out <- predict_curve(d,slaughter$end_day)
  out[, `:=`(campaign=id,housing=h)]; out
}))))
curves <- merge(curves,slaughter,by="end_day")
save_csv(curves,"masttag_prognosen")
per_housing <- curves[, .(ef_g_animal=sum(share*ef_g_animal),
                         extrapolated_share=sum(share[extrapolated])),by=.(campaign,housing)]
wide <- dcast(per_housing,campaign~housing,value.var="ef_g_animal")
wide <- merge(campaigns,wide,by="campaign",all.x=TRUE)
campaign_result <- rbindlist(lapply(seq_len(nrow(variants)),function(i) {
  v <- variants[i]; z <- copy(wide)
  z[, `:=`(variant=v$variant, basis_g_animal=housing_1*v$factor_barn1,
    wrg_g_animal=ifelse(role=="wrg",housing_2*v$factor_barn2,NA_real_))]
  z[, difference_g_animal := basis_g_animal-wrg_g_animal]
  z[, reduction_pct := 100*difference_g_animal/basis_g_animal]
  z[, `:=`(basis_g_place_year=basis_g_animal*cfg$cycles*cfg$animals_per_place,
    wrg_g_place_year=wrg_g_animal*cfg$cycles*cfg$animals_per_place,
    saved_g_place_year=difference_g_animal*cfg$cycles*cfg$animals_per_place)]
  z[, status := fifelse(campaign %in% valid_ids,"modelliert",
                       "unvollstaendige_Kumulierung_keine_Hochrechnung")]
  z
}))
save_csv(campaign_result,"ergebnisse_kampagnen")

# Auch vorhandene Endwerte ungültiger Kampagnen sichtbar ausgeben.
observed <- dcast(quality,campaign~housing,value.var="ef_end_g_animal")
observed <- merge(observed,campaigns,by="campaign")
observed[, valid_full_cycle := campaign %in% valid_ids]
save_csv(observed,"gemessene_endwerte")

# 4. JAHRESMITTEL: SAISONEN GETRENNT FÜR BASIS UND WRG -------------------------
# Offset-Kampagnen liefern Basiswerte, aber KEINE WRG-Reduktionsmessung.
annual <- rbindlist(lapply(variants$variant,function(v) {
  z <- campaign_result[variant==v & include_annual==TRUE]
  base_season <- z[,.(basis=mean(basis_g_place_year)),by=season]
  wrg_season <- z[role=="wrg",.(wrg=mean(wrg_g_place_year)),by=season]
  s <- merge(base_season,wrg_season,by="season",all=TRUE)
  if (!setequal(s$season,names(cfg$season_weights)) || any(!is.finite(s$basis)) || any(!is.finite(s$wrg)))
    stop("Fehlende Saison; keine stille Umgewichtung")
  s[, weight := cfg$season_weights[season]]
  b <- sum(s$basis*s$weight); w <- sum(s$wrg*s$weight)
  data.table(variant=v,basis_g_place_year=b,wrg_g_place_year=w,
    saved_g_place_year=b-w,reduction_pct=100*(1-w/b),
    cycles=cfg$cycles,animals_per_place=cfg$animals_per_place)
}))
save_csv(annual,"ergebnisse_jahr")
# Ergänzender WRG-Vergleich mit identischen Kampagnen auf beiden Seiten.
# Unterschiedliche Basis-/WRG-Kampagnensätze können Jahreseffekte enthalten.
paired_annual <- rbindlist(lapply(variants$variant,function(v) {
  z <- campaign_result[variant==v & include_annual==TRUE & role=="wrg"]
  s <- z[,.(basis=mean(basis_g_place_year),wrg=mean(wrg_g_place_year)),by=season]
  if (!setequal(s$season,names(cfg$season_weights))) stop("Fehlende Vergleichssaison")
  b <- sum(s$basis*cfg$season_weights[s$season]); w <- sum(s$wrg*cfg$season_weights[s$season])
  data.table(variant=v,basis_g_place_year=b,wrg_g_place_year=w,
    saved_g_place_year=b-w,reduction_pct=100*(1-w/b))
}))
save_csv(paired_annual,"ergebnisse_jahr_vergleichspaare")
weights <- campaigns[include_annual==TRUE]
weights[, baseline_weight := cfg$season_weights[season]/.N,by=season]
weights[, wrg_weight := 0]
weights[role=="wrg",wrg_weight := cfg$season_weights[season]/.N,by=season]
save_csv(weights,"jahresgewichte"); save_csv(slaughter,"schlachttagverteilung")

# Übersichtsgrafik (keine Konfidenzintervalle aus nur zwei Offsetkampagnen).
png(file.path(cfg$out,"jahresvergleich.png"),width=1500,height=850,res=150)
par(mar=c(8,5,3,1))
vals <- t(as.matrix(annual[,.(basis_g_place_year,wrg_g_place_year)]))
barplot(vals,beside=TRUE,names.arg=c("Winteroffset, Stall 1","Winteroffset, gemeinsame Basis"),
  col=c("#9C4A45","#327CAF"),ylab="g NH3 / Tierplatz / Jahr (Modell)",
  main="Jahresmittel ohne August 2026",ylim=c(0,max(vals)*1.25),las=1)
legend("topright",legend=c("Basis ohne WRG","Mit WRG"),fill=c("#9C4A45","#327CAF"),bty="n")
dev.off()

# 5. EXAKTE REPRODUKTION DER EXCEL-METHODE ALS SEPARATER VERGLEICH ------------
# Nur Excel-Eingabewerte, inklusive Rundungen und ursprünglicher Tagesachse.
# So werden Datenrevisionen nicht mit Methodenänderungen vermischt.
excel <- as.data.frame(readxl::read_excel(cfg$excel,sheet=2,range="A3:O20",col_names=FALSE,.name_repair="minimal"))
numeric_col <- function(j) suppressWarnings(as.numeric(excel[[j]]))
ex_day <- numeric_col(1); ex_share <- replace(numeric_col(3),is.na(numeric_col(3)),0)/100
ex_values <- sapply(c(4,5,7,8,10,11,13,14),numeric_col)
for (j in seq_len(ncol(ex_values))) {
  t <- ex_day[7:14]-ex_day[14]
  fit <- lm(ex_values[7:14,j] ~ t + I(t^2))
  ex_values[15:18,j] <- predict(fit,newdata=data.frame(t=ex_day[15:18]-ex_day[14]))
}
ex_ratio <- ex_values[14,8]/ex_values[14,7]
ex_b <- drop(ex_values[,c(1,3,5,7)] %*% c(.125,.5,.25,.125))
ex_w <- drop(ex_values[,c(2,4,6)] %*% c(.25,.5,.25))/ex_ratio
excel_result <- data.table(basis_g_place_year=sum(ex_b*ex_share)*cfg$cycles,
  wrg_g_place_year=sum(ex_w*ex_share)*cfg$cycles)
excel_result[, reduction_pct := 100*(1-wrg_g_place_year/basis_g_place_year)]
save_csv(excel_result,"excel_reproduktion")
# Bei unveränderter Originaldatei und 8.5 Umtrieben müssen diese Werte stimmen.
if (abs(cfg$cycles-8.5)<1e-12) stopifnot(
  abs(excel_result$basis_g_place_year-23.90392596469495)<1e-8,
  abs(excel_result$wrg_g_place_year-10.532767655992572)<1e-8)

# Reproduzierbarkeit: Pfade, Prüfsummen, Parameter und R-Versionen sichern.
paths <- c(vapply(data,`[[`,character(1),"path"), cfg$excel)
save_csv(data.table(path=paths,md5=unname(tools::md5sum(paths))),"quellen")
dput(cfg,file=file.path(cfg$out,"parameter.R"))
capture.output(sessionInfo(),file=file.path(cfg$out,"sessionInfo.txt"))
message("Fertig. Ergebnisse: ",normalizePath(cfg$out))
print(annual)
