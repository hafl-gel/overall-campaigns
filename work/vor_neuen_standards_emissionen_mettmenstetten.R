# NH3-Auswertung Mettmenstetten. Quelldateien werden ausschliesslich gelesen.
# Ausführen: source("emissionen_mettmenstetten.R") oder Rscript emissionen_mettmenstetten.R
# Pakete bei Bedarf selbst installieren: install.packages(c("data.table", "qs2"))
working_directory <- path.expand("~/git/overall-campaigns")
if (!dir.exists(working_directory)) stop("Arbeitsordner fehlt: ", working_directory)
setwd(working_directory)
required <- c("data.table", "qs2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Fehlende Pakete: ", paste(missing, collapse = ", "))
suppressPackageStartupMessages(library(data.table))

# EINSTELLUNGEN ---------------------------------------------------------------
anzahl_umtriebe <- 8.5  # Umtriebe pro Jahr: hier frei einstellen
cfg <- list(
  root = path.expand("~/git"),
  out = "ergebnisse_bericht",
  cycles = anzahl_umtriebe,
  # Relative Messfehler fuer alle Emissionstabellen: 0.055 = 5.5 %, 0.15 = 15 %.
  # Einzelmenge: u = sqrt(uncertainty_fan^2 + uncertainty_xnode^2).
  uncertainty_fan = 0.055,
  uncertainty_xnode = 0.15,
  # Tabelle-5-Stallunterschied d = 100 * (Stall2/Stall1 - 1), in Prozent.
  # excel_legacy: +/- abs(d) * sqrt(2) * u (bisherige Excelkonvention).
  # ratio_independent: +/- 100 * (Stall2/Stall1) * sqrt(2) * u.
  # Zweite Formel setzt unabhaengige Stallfehler voraus; keine Konfidenzintervalle.
  offset_difference_error = "excel_legacy", # Tabelle-5-Text; alternativ "ratio_independent"
  reduction_error = "excel_legacy", # alle Reduktionen; alternativ "ratio_independent"
  # Multiplikativer Messfehler je Kampagne/Stall, zeitlich voll korreliert.
  # Kampagnen und Staelle voreingestellt voneinander unabhaengig (Annahme).
  # 0 = unabhaengig, 1 = voll korreliert; Zwischenwerte erlaubt.
  measurement_campaign_correlation = 0,
  measurement_barn_correlation = 0,
  # Aktive Jahresrechnung: bisheriger Fit bleibt voreingestellt.
  extrapolation_method = "quadratic_free", # alternativ "linear_rate"
  rate_fit_points = 5, # letzte fuenf Tagesraten, nur bei linear_rate
  # Modellannahme: ein Tier pro Tierplatz und Umtrieb. Keine Kapazitäten geliefert.
  # Bei abweichender Belegung hier Tiere je Platz einsetzen.
  animals_per_place = 1,
  offset_method = "cumulative_endpoint", # kumulierte Endwerte pro Tier wie im PDF
  fit_points = 8,        # quadratischer Fit, wie Excel letzte 8 kumulierte Tageswerte
  max_extrapolation_days = 4,
  season_weights = c(winter = .25, transition = .50, summer = .25)
)
campaigns <- data.table(
  # Juli 2025 ist ausdrücklich ausgeschlossen und wird nicht importiert.
  campaign = c("feb2024", "apr2024", "jul2024", "dec2024", "aug2026"),
  season = c("winter", "transition", "summer", "winter", "summer"),
  role = c("wrg", "wrg", "wrg", "offset", "offset"),
  include_annual = rep(TRUE, 5)
)
# Szenario-Ueberschreibung ausschliesslich fuer den separaten Szenariostarter.
if (exists("scenario_settings", inherits=FALSE)) {
  cfg <- utils::modifyList(cfg,scenario_settings$cfg)
  campaigns <- campaigns[!campaign %in% scenario_settings$exclude_campaigns]
}
stopifnot(cfg$reduction_error %in% c("excel_legacy","ratio_independent"))
# Endtag ist verstrichene Mastdauer. Excel unterscheidet Endtag und Schlachttag.
slaughter <- data.table(end_day = c(29,30,31,32,33.5,34.25,35.25,36.25),
                        slaughter_day = 30:37,
                        share = c(18,2,6,6,4,2,51,11)/100)
stopifnot(abs(sum(slaughter$share)-1) < 1e-12,
          abs(sum(cfg$season_weights)-1) < 1e-12,
          all(slaughter$share >= 0), cfg$cycles > 0, cfg$animals_per_place > 0)
stopifnot(length(cfg$cycles)==1L, is.finite(cfg$cycles),
 all(is.finite(cfg$season_weights)),all(cfg$season_weights>=0),
 all(is.finite(slaughter$share)), all(is.finite(slaughter$end_day)),
 cfg$fit_points>=3, cfg$fit_points==as.integer(cfg$fit_points))
dir.create(cfg$out, recursive = TRUE, showWarnings = FALSE)
run_started <- Sys.time()
writeLines(paste("GESTARTET:",format(run_started),"- erst Status ERFOLGREICH bestaetigt einen vollstaendigen Lauf."),
 file.path(cfg$out,"laufstatus.txt"))
season_note <- paste0("Winter ",formatC(100*cfg$season_weights['winter'],format='fg',digits=6),
 " %, Übergangszeit ",formatC(100*cfg$season_weights['transition'],format='fg',digits=6),
 " %, Sommer ",formatC(100*cfg$season_weights['summer'],format='fg',digits=6)," %")
save_csv <- function(x, name) fwrite(x, file.path(cfg$out, paste0(name, ".csv")), sep = ";", dec = ",", bom = TRUE, na = "NA")
folders <- list.dirs(cfg$root,recursive=FALSE,full.names=FALSE)
ids <- sub("^mettmenstetten-","",folders[grepl("^mettmenstetten-",folders)])
inventory <- data.table(campaign=ids)
inventory[, status := fifelse(campaign %in% campaigns$campaign,"importiert",
  "nicht_in_Excel_und_anderes_Datenschema_separat_pruefen")]
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
r_summer <- offsets[campaign=="aug2026",ratio_2_over_1]
r_mean <- mean(c(r_winter,r_summer)) # gleiches Gewicht je Kampagne
# Zwei Bezugsvarianten, beide mit dem Mittel der beiden Endwert-Verhältnisse.
variants <- data.table(variant=c("stall1_realitaet","mittel_beider_staelle"),
  ratio=r_mean, factor_barn1=c(1,(1+r_mean)/2))
variants[, factor_barn2 := factor_barn1/ratio]
save_csv(offsets,"offsets");save_csv(variants,"varianten")
labels <- c(feb2024="Februar 2024",apr2024="April 2024",jul2024="Juli 2024",
            dec2024="Dezember 2024",aug2026="August 2026")

offset_note <- paste(labels[campaigns[role=="offset",campaign]],collapse=" und ")
# Auswaehlbare Extrapolation; innerhalb der Messung stets Interpolation.
stopifnot(cfg$extrapolation_method %in% c("quadratic_free","linear_rate"),
 cfg$offset_difference_error %in% c("excel_legacy","ratio_independent"),
 cfg$rate_fit_points>=2, cfg$rate_fit_points==as.integer(cfg$rate_fit_points),
 cfg$uncertainty_fan>=0,cfg$uncertainty_xnode>=0)
method_title <- if(cfg$extrapolation_method=="quadratic_free") "Freier quadratischer Fit" else "Linearer Trend der letzten Tagesraten"
fit_predict <- function(f,day) {
 t<-day-f$x0
 if(f$method=="quadratic_free")return(as.numeric(predict(f$model,newdata=data.frame(t=t))))
 vapply(t,function(h) f$y0+integrate(function(u)pmax(f$r0+f$rate_slope*u,0),0,h)$value,numeric(1))
}
fits <- list(); fit_details <- list(); fit_points <- list(); predictions <- list(); rate_points<-list()
for(id in campaigns$campaign) for(h in c("housing_1","housing_2")) {
 d <- copy(data[[id]]$daily[housing==h]);setorder(d,day)
 x0<-max(d$day);y0<-tail(d$ef,1);key<-paste(id,h,sep="_")
 stopifnot(max(slaughter$end_day)-x0<=cfg$max_extrapolation_days)
 if(cfg$extrapolation_method=="quadratic_free") {
  f<-tail(d,cfg$fit_points);f[,t:=day-x0]
  m<-lm(ef~t+I(t^2),data=f);stopifnot(m$rank==3,nrow(f)==cfg$fit_points)
  b<-unname(coef(m));rmse<-sqrt(mean(resid(m)^2));rmse_units<-"g_animal"
  obj<-list(model=m,x0=x0,y0=y0,daily=d,fit=f,method="quadratic_free")
 }else{
  rates<-data.table(day=(head(d$day,-1)+tail(d$day,-1))/2,
    rate=diff(d$ef)/diff(d$day))
  r<-tail(rates,cfg$rate_fit_points);r[,t:=day-x0]
  m<-lm(rate~t,data=r);stopifnot(m$rank==2,nrow(r)==cfg$rate_fit_points)
  cc<-unname(coef(m));b<-c(y0,cc[1],cc[2]/2)
  rmse<-sqrt(mean(resid(m)^2));rmse_units<-"g_animal_day"
  f<-tail(d,cfg$rate_fit_points+1);f[,t:=day-x0]
  obj<-list(model=m,x0=x0,y0=y0,daily=d,fit=f,method="linear_rate",r0=cc[1],rate_slope=cc[2])
  r[,`:=`(campaign=id,housing=h)];rate_points[[key]]<-r
 }
 fits[[key]]<-obj;fit_points[[key]]<-f
 fit_details[[key]]<-data.table(campaign=id,housing=h,method=cfg$extrapolation_method,x0=x0,
  intercept=b[1],linear=b[2],quadratic=b[3],rmse=rmse,rmse_units=rmse_units,
  last_measured_ef=y0,fit_at_end=fit_predict(obj,x0))
 target<-copy(slaughter);target[,ef:=approx(d$day,d$ef,xout=end_day,rule=1)$y]
 target[,extrapolated:=end_day>x0]
 target[extrapolated==TRUE,ef:=fit_predict(obj,end_day)]
 stopifnot(all(is.finite(target$ef)),all(target$ef>=0),all(diff(target$ef)>=-1e-6))
 target[,`:=`(campaign=id,housing=h,method=cfg$extrapolation_method)]
 predictions[[key]]<-target
}
csv_rates <- if(length(rate_points)) rbindlist(rate_points) else data.table(day=numeric(),rate=numeric(),t=numeric(),campaign=character(),housing=character())
save_csv(csv_rates,"fit_tagesraten")
curves <- rbindlist(predictions)
save_csv(curves,"masttag_prognosen");save_csv(rbindlist(fit_points),"fit_stuetzpunkte")
save_csv(rbindlist(fit_details),"fit_koeffizienten")

# Grafiken zeigen exakt die zur Prognose verwendeten Modelle, vor Skalierung.
plot_campaign <- function(id) {
  cols <- c("#A7443F","#2479AD");hs<-c("housing_1","housing_2")
  ymax <- max(curves[campaign==id,ef],unlist(lapply(hs,function(h) tail(fits[[paste(id,h,sep="_")]]$daily$ef,8))))*1.15
  plot_end<-max(37,slaughter$end_day)
  plot(NA,xlim=c(25,plot_end),ylim=c(0,ymax),xlab="Verstrichene Mastdauer [Tage]",
       ylab="Kumulierte NH3-Emission [g/Tier]",main=labels[[id]],las=1)
  grid(col="#E5E5E5")
  for(j in seq_along(hs)) {
    f<-fits[[paste(id,hs[j],sep="_")]];d<-f$daily
    rect(f$x0,0,plot_end,ymax,col=adjustcolor("#D8DCE4",alpha.f=.12),border=NA)
    lines(d$day,d$ef,col=adjustcolor(cols[j],alpha.f=.45),lwd=1)
    points(d$day,d$ef,col=cols[j],pch=1,cex=.7)
    points(f$fit$day,f$fit$ef,col=cols[j],pch=16,cex=.85)
    xx<-seq(min(f$fit$day),f$x0,length.out=150)
    lines(xx,fit_predict(f,xx),col=cols[j],lwd=2)
    xx<-seq(f$x0,plot_end,length.out=100)
    lines(xx,fit_predict(f,xx),col=cols[j],lwd=2,lty=2)
    abline(v=f$x0,col=adjustcolor(cols[j],.6),lty=3)
    p<-curves[campaign==id & housing==hs[j]]
    points(p$end_day,p$ef,col=cols[j],pch=4,cex=.8,lwd=1.3)
  }
  legend("topleft",legend=c("Stall 1","Stall 2"),col=cols,lty=1,lwd=2,bty="n",cex=.85)
}
png(file.path(cfg$out,"quadratische_extrapolation_alle.png"),width=1900,height=2100,res=160)
par(mfrow=c(3,2),mar=c(4,4,3,1),oma=c(2,0,2,0))
for(id in campaigns$campaign) plot_campaign(id)
plot.new();legend("center",legend=c(paste0("Punkte: Tageswerte; ausgefüllt: ",if(cfg$extrapolation_method=="quadratic_free") cfg$fit_points else cfg$rate_fit_points+1," Tagesstützpunkte"),
 paste0("Durchgezogen: ",method_title),"Gestrichelt: ausgewählte Extrapolation",
 "Kreuze: tatsächlich verwendete Schlachttagwerte","Senkrechte Linie: letztes Messende",
 "Keine Konfidenzbänder; Werte vor Offsetkorrektur"),bty="n",cex=.95)
mtext(paste0(method_title,": kumulierte Emissionen"),outer=TRUE,side=3,line=.5,font=2)
dev.off()
file.copy(file.path(cfg$out,"quadratische_extrapolation_alle.png"),file.path(cfg$out,"extrapolation_alle.png"),overwrite=TRUE)
for(id in campaigns$campaign) {
 png(file.path(cfg$out,paste0("extrapolation_",id,".png")),width=1500,height=950,res=160)
 par(mar=c(5,5,3,1));plot_campaign(id);dev.off()
}

# Tabelle 4: gemessene kumulierte Endwerte, keine Masttag-Hochrechnung.
ends <- rbindlist(lapply(campaigns$campaign,function(id) {
 z<-data[[id]]$raw
 z[, .(kg=tail(value,1),g_animal=tail(ef,1)),by=.(campaign,housing)]
}))
ends<-merge(ends,campaigns,by="campaign")
report4 <- rbindlist(lapply(seq_len(nrow(variants)),function(i) {
 v<-variants[i];z<-copy(ends[role=="wrg"])
 z[,factor:=ifelse(housing=="housing_1",v$factor_barn1,v$factor_barn2)]
 z[,`:=`(total_kg=kg*factor,emission_g_animal=g_animal*factor,variant=v$variant)]
 z[,reduction_pct:=ifelse(housing=="housing_2",
   100*(1-emission_g_animal/emission_g_animal[housing=="housing_1"]),NA_real_),by=campaign]
 z
}))
# Speicherung erfolgt nach Ergaenzung der Messfehler.

# Basis: zuerst beide Ställe einer Offsetkampagne auf dieselbe Bezugsbasis
# bringen und mitteln; dann Kampagnenmittel je Saison; zuletzt 25/50/25.
weighted <- curves[,.(g_animal=sum(share*ef)),by=.(campaign,housing)]
weighted<-merge(weighted,campaigns,by="campaign")
contributions<-list(); seasons<-list();annual<-list()
for(i in seq_len(nrow(variants))) {
 v<-variants[i];z<-copy(weighted[include_annual==TRUE])
 z[,factor:=ifelse(housing=="housing_1",v$factor_barn1,v$factor_barn2)]
 z[,corrected:=g_animal*factor]
 base<-if(v$variant=="mittel_beider_staelle") z[role=="offset" | housing=="housing_1"] else z[housing=="housing_1"]
 # Jede Kampagne hat zunächst das gleiche Gewicht innerhalb ihrer Saison.
 base[,barn_share:=1/.N,by=campaign]
 base[,n_campaigns_season:=uniqueN(campaign),by=season]
 base[,weight:=cfg$season_weights[season]/n_campaigns_season*barn_share]
 base[,`:=`(variant=v$variant,component="basis")]
 wrg<-z[role=="wrg" & housing=="housing_2"]
 wrg[,weight:=cfg$season_weights[season]/.N,by=season]
 wrg[,`:=`(variant=v$variant,component="wrg",barn_share=1,n_campaigns_season=.N),by=season]
 stopifnot(abs(sum(base$weight)-1)<1e-12,abs(sum(wrg$weight)-1)<1e-12)
 c<-rbindlist(list(base,wrg),fill=TRUE)
 contributions[[i]]<-c
 seasons[[i]]<-c[,.(g_animal=sum(weight*corrected)/sum(weight),weight=sum(weight)),by=.(variant,component,season)]
 b<-sum(base$corrected*base$weight)*cfg$cycles*cfg$animals_per_place
 w<-sum(wrg$corrected*wrg$weight)*cfg$cycles*cfg$animals_per_place
 annual[[i]]<-data.table(variant=v$variant,basis_g_place_year=b,wrg_g_place_year=w,
  saved_g_place_year=b-w,reduction_pct=100*(1-w/b),cycles=cfg$cycles)
}
annual<-rbindlist(annual); contributions<-rbindlist(contributions);seasons<-rbindlist(seasons)
save_csv(contributions,"basis_und_wrg_einzelgewichte");save_csv(seasons,"saisonmittel")
# Messfehler durch genau dieselbe Offset-, Kampagnen- und Saisonrechnung.
source(file.path(working_directory,"messfehler_mettmenstetten.R"),local=TRUE)
unc <- measurement_uncertainties(ends,weighted,campaigns,cfg)
save_csv(unc$detail,"messfehler_fortpflanzung")
save_csv(unc$covariance,"messfehler_kovarianz")
annual <- merge(annual,unc$annual[,campaign:=NULL],by="variant",sort=FALSE)
report4 <- merge(report4,unc$end,by=c("variant","campaign"))
report4[, `:=`(total_kg_error=ifelse(housing=="housing_1",barn1_total_kg_error,barn2_total_kg_error),
 emission_g_animal_error=ifelse(housing=="housing_1",barn1_error,barn2_error),
 reduction_pct_error=ifelse(housing=="housing_2",stall_difference_pct_error,NA_real_))]
save_csv(report4,"tabelle4_ungerundet")
save_csv(annual,"tabelle6_ungerundet");save_csv(slaughter,"schlachttagverteilung")
u_measure <- sqrt(cfg$uncertainty_fan^2+cfg$uncertainty_xnode^2)
error_note <- paste0("±: fortgepflanzte Messfehler (Lüftung ",100*cfg$uncertainty_fan,
 " %, NH3-Sensor ",100*cfg$uncertainty_xnode," %). Multiplikativer Fehler innerhalb jeder Kampagne/Stall über die Zeit vollständig korreliert; Korrelation zwischen Kampagnen = ",
 cfg$measurement_campaign_correlation,", zwischen Ställen = ",cfg$measurement_barn_correlation,
 ". Gemeinsam verwendete Offsets und die gemeinsame Stallskalierung werden abhängig fortgepflanzt. Prozentuale Reduktionen: ",
 if(cfg$reduction_error=="excel_legacy")"bisherige Excelkonvention (relativer Quotientenfehler × Reduktion)" else "Fehlerfortpflanzung des Quotienten",
 "; ± bei Prozentangaben in Prozentpunkten. Keine Konfidenzintervalle; zusätzliche Extrapolationsunsicherheit und Streuung zwischen Kampagnen sind nicht enthalten.")
writeLines(error_note,file.path(cfg$out,"messfehler_konvention.txt"))

# Berichtstabellen: Rundung ausschliesslich in der Darstellung.
fmt<-function(x,d=2) ifelse(is.na(x),"–",formatC(x,digits=d,format="f",decimal.mark=","))
fmt_pm<-function(x,e,d=2) ifelse(is.na(x)|is.na(e),"–",paste0(fmt(x,d)," ± ",fmt(e,d)))
tables<-list()
for(v in variants$variant) {
 z<-report4[variant==v];z[,idx:=match(campaign,campaigns$campaign)];setorder(z,idx,housing)
 t4<-data.frame(Stall=ifelse(z$housing=="housing_1","Stall 1 (Referenz)","Stall 2 (WRG)"),
  Messkampagne=unname(labels[z$campaign]),
  `NH3-Emissionen total [kg]`=fmt_pm(z$total_kg,z$total_kg_error),
  `NH3-Emissionen pro Tier [g]`=fmt_pm(z$emission_g_animal,z$emission_g_animal_error),
  `Reduktion durch WRG [%]`=fmt_pm(z$reduction_pct,z$reduction_pct_error,1),check.names=FALSE)
 a<-annual[variant==v]
 t6<-data.frame(Stall=c("Stall 1 (Referenz)","Stall 2 (WRG)"),
  Messkampagne="Gewichtetes Jahresmittel",
  `NH3-Emissionen [g/Tierplatz/Jahr]`=fmt_pm(c(a$basis_g_place_year,a$wrg_g_place_year),c(a$basis_g_place_year_error,a$wrg_g_place_year_error),1),
  `Reduktion durch WRG [%]`=c("–",fmt_pm(a$reduction_pct,a$reduction_pct_error,1)),check.names=FALSE)
 tables[[paste0(v,"_tabelle4")]]<-t4;tables[[paste0(v,"_tabelle6")]]<-t6
 fwrite(t4,file.path(cfg$out,paste0(v,"_tabelle4.csv")),sep=";",bom=TRUE)
 fwrite(t6,file.path(cfg$out,paste0(v,"_tabelle6.csv")),sep=";",bom=TRUE)
}
# Tabelle 5: gemessene, nicht stalloffset-korrigierte Offsetkampagnen.
# Messfehler-Konvention aus Excel; kein statistisches Konfidenzintervall.
u_measure <- sqrt(cfg$uncertainty_fan^2+cfg$uncertainty_xnode^2)
table5_raw <- copy(ends[role=="offset"])
table5_raw[, `:=`(uncertainty_total_kg=kg*u_measure,
 uncertainty_g_animal=g_animal*u_measure,relative_measurement_error=u_measure)]
table5_raw <- merge(table5_raw,quality[,.(campaign,housing,measured_end_day)],by=c("campaign","housing"))
save_csv(table5_raw,"tabelle5_offsetkampagnen_ungerundet")
table5s <- list()
for(id in campaigns[role=="offset",campaign]) {
 z<-table5_raw[campaign==id][order(housing)]
 t5<-data.frame(Stall=ifelse(z$housing=="housing_1","Stall 1 (Referenz)","Stall 2 (WRG inaktiv)"),
  `NH3-Emissionen total [kg]`=paste0(fmt(z$kg,2)," ± ",fmt(z$uncertainty_total_kg,2)),
  `NH3-Emissionen pro Tier [g]`=paste0(fmt(z$g_animal,3)," ± ",fmt(z$uncertainty_g_animal,3)),check.names=FALSE)
 table5s[[id]]<-t5
 fwrite(t5,file.path(cfg$out,paste0("tabelle5_",id,".csv")),sep=";",bom=TRUE)
}
# Beschreibender Stallunterschied fuer Tabelle 5: vorzeichenrichtig und ungerundet.
table5_differences<-rbindlist(lapply(campaigns[role=="offset",campaign],function(id){
 z<-table5_raw[campaign==id];a<-z[housing=="housing_1"];b<-z[housing=="housing_2"]
 rbindlist(lapply(c("kg","g_animal"),function(metric){
  ratio<-b[[metric]]/a[[metric]];difference_pct<-100*(ratio-1)
  u_ratio_relative<-sqrt(2*(1-cfg$measurement_barn_correlation))*u_measure
  legacy_pp<-abs(difference_pct)*u_ratio_relative
  propagated_pp<-100*ratio*u_ratio_relative
  data.table(campaign=id,metric=metric,ratio=ratio,difference_pct=difference_pct,
   uncertainty_excel_pp=legacy_pp,uncertainty_independent_ratio_pp=propagated_pp,
   displayed_uncertainty_pp=if(cfg$offset_difference_error=="excel_legacy")legacy_pp else propagated_pp,
   convention=cfg$offset_difference_error)
 }))
}))
save_csv(table5_differences,"tabelle5_stallunterschiede")
table5_text<-function(id){
 z<-table5_differences[campaign==id];kg<-z[metric=="kg"];g<-z[metric=="g_animal"]
 term<-function(a)paste0("rund ",fmt(abs(a$difference_pct),1)," ± ",fmt(a$displayed_uncertainty_pp,1),
  " % ",if(a$difference_pct>=0)"höher" else "tiefer")
 paste0("Damit liegen die gemessenen kumulierten Emissionen in Stall 2 gegenüber Stall 1 bei der Gesamtemission ",
  term(kg)," und pro Tier ",term(g),". Die ±-Angaben folgen der eingestellten Konvention (",cfg$offset_difference_error,
  "); keine Konfidenzintervalle und kein Nachweis eines zeitlich konstanten Stallunterschieds.")
}
writeLines(vapply(campaigns[role=="offset",campaign],function(id)
 paste0(if(id=="aug2026")"Juli/August 2026" else labels[[id]],": ",table5_text(id)),character(1)),
 file.path(cfg$out,"tabelle5_begleittext.txt"))
html_table<-function(t) paste0("<table><thead><tr>",paste0("<th>",names(t),"</th>",collapse=""),
 "</tr></thead><tbody>",paste(vapply(seq_len(nrow(t)),function(i)
 paste0("<tr>",paste0("<td>",as.character(t[i,]),"</td>",collapse=""),"</tr>"),character(1)),collapse=""),"</tbody></table>")
html<-c("<!doctype html><html lang='de'><meta charset='utf-8'><title>NH3-Berichtstabellen</title>",
 "<style>body{font:16px Georgia,serif;max-width:1150px;margin:40px auto;color:#111}table{width:100%;border-collapse:collapse;margin:18px 0 26px}th,td{padding:12px 8px;text-align:center;border-bottom:1px solid #aaa}thead{border-top:2px solid #111;border-bottom:2px solid #111}h1{font-size:25px}h2{font-size:21px;margin-top:35px}.note{font:14px Arial;line-height:1.5}.variant{break-before:page}@media print{body{margin:12mm;font-size:11pt}table{break-inside:avoid}}</style>",
 "<h1>NH3-Emissionen und Reduktion durch die WRG</h1>")
# Gemeinsame Rohmessungen der Offsetkampagnen, unabhaengig von Bezugsvariante.
for(id in names(table5s)) {
 z<-table5_raw[campaign==id]
 name<-if(id=="aug2026") "Juli/August 2026" else labels[[id]]
 html<-c(html,paste0("<h2>Tabelle 5: Offsetkampagne ",name,"</h2><p>Messdauer: ",
 fmt(min(z$measured_end_day),1)," Tage; beide Ställe ohne WRG. Gemessene Endwerte ohne Stalloffset-Korrektur.</p>"),
 html_table(table5s[[id]]),paste0("<p>",table5_text(id),"</p>"))
}
html<-c(html,paste0("<p class='note'>Stallunterschied: excel_legacy multipliziert den Unterschied mit dem relativen Quotientenfehler (alte Excelkonvention). ratio_independent propagiert dagegen den Quotienten mit der eingestellten Stallkorrelation; die Fehler sind dann meist deutlich groesser. Die ±-Beträge beim prozentualen Stallunterschied sind Prozentpunkte. ± in Tabelle 5: übernommene Excel-Messfehlerkonvention sqrt(",
 cfg$uncertainty_fan,"² + ",cfg$uncertainty_xnode,"²); keine Konfidenzintervalle. Diese Rohwerte sind für beide Bezugsvarianten identisch.</p>"))
for(v in variants$variant) {
 title<-if(v=="stall1_realitaet")"Variante 1: Stall 1 als Realität" else "Variante 2: Realität in der Mitte beider Ställe"
 html<-c(html,paste0("<section class='variant'><h2>",title,"</h2>"),
 "<p><i>Tabelle 4: Emissionen der gemessenen Mastumtriebe total, pro Tier und Reduktion durch die WRG.</i></p>",
 html_table(tables[[paste0(v,"_tabelle4")]]),
 "<p><i>Tabelle 6: Schlachttag-gewichtete NH3-Emissionen und Reduktionsleistung der WRG, basierend auf der Schweizer Schlachtalter-Verteilung.</i></p>",
 html_table(tables[[paste0(v,"_tabelle6")]]),"</section>")
}
html<-c(html,paste0("<p class='note'>",error_note,"</p>"))
html<-c(html,paste0("<p class='note'>",cfg$cycles," Umtriebe/Jahr; ",cfg$animals_per_place," Tiere je Tierplatz/Umtrieb. Saisongewichte: ",season_note,". ",offset_note,": beide Ställe ohne WRG. Stall 2 trägt nur in der Mittelwert-Variante zur Basis bei; die Offsetbestimmung verwendet in beiden Varianten beide Ställe. Juli 2025 ausgeschlossen. Alle Emissionstabellen enthalten die fortgepflanzten Messfehler unter den im Bericht genannten Annahmen.</p>"),"</html>")
writeLines(html,file.path(cfg$out,"Berichtstabellen.html"))

# PNG-Tabellen zum Einfügen in den Bericht.
draw_table<-function(t,title,path) {
 png(path,width=2200,height=if(nrow(t)>2)900 else 600,res=180)
 grid::grid.newpage();n<-nrow(t);nc<-ncol(t)
 grid::grid.text(title,x=.03,y=.94,just="left",gp=grid::gpar(fontsize=15,fontface="italic"))
 widths<-if(nc==5)c(.20,.19,.20,.20,.21) else if(nc==3)c(.30,.35,.35) else c(.23,.25,.30,.22)
 xx<-.03+.94*(cumsum(widths)-widths/2);yy<-seq(.79,.15,length.out=n+2)
 for(j in seq_len(nc)) grid::grid.text(paste(strwrap(names(t)[j],width=24),collapse="\n"),x=xx[j],y=yy[1],gp=grid::gpar(fontsize=12,fontface="bold"))
 for(i in seq_len(n))for(j in seq_len(nc))grid::grid.text(t[i,j],x=xx[j],y=yy[i+1],gp=grid::gpar(fontsize=11))
 for(y in c(.87,(yy[-length(yy)]+yy[-1])/2))grid::grid.lines(x=c(.03,.97),y=c(y,y),gp=grid::gpar(col="#666666"))
 dev.off()
}
for(id in names(table5s))draw_table(table5s[[id]],
 paste0("Tabelle 5: ",if(id=="aug2026") "Juli/August 2026" else labels[[id]]," - beide Staelle ohne WRG"),
 file.path(cfg$out,paste0("tabelle5_",id,".png")))
for(n in names(tables))draw_table(tables[[n]],if(grepl("tabelle4",n))"Tabelle 4: Emissionen der gemessenen Mastumtriebe" else "Tabelle 6: Schlachttag-gewichtetes Jahresmittel",file.path(cfg$out,paste0(n,".png")))

# Plausibilitäts- und Reproduzierbarkeitskontrollen.
stopifnot(!"jul2025" %in% campaigns$campaign,
 all(contributions[variant=="stall1_realitaet" & component=="basis",housing]=="housing_1"),
 all(contributions[variant=="mittel_beider_staelle" & component=="basis" & role=="offset",barn_share]==.5))
for(v in variants$variant) for(comp in c("basis","wrg")) {
 ss<-contributions[variant==v & component==comp,.(weight=sum(weight)),by=season]
 stopifnot(max(abs(ss$weight-cfg$season_weights[ss$season]))<1e-12)
}
paths<-vapply(data,`[[`,character(1),"path")
save_csv(data.table(path=paths,md5=unname(tools::md5sum(paths))),"quellen")
dput(cfg,file=file.path(cfg$out,"parameter.R"))
capture.output(sessionInfo(),file=file.path(cfg$out,"sessionInfo.txt"))
print(annual)
message("Berichtstabellen und Fitgrafiken erstellt: ",normalizePath(cfg$out))


# DIREKTER KAMPAGNENVERGLEICH: roh und beide Korrekturvarianten ----------------
comparison_variants<-rbindlist(list(
 data.table(variant="unkorrigiert",ratio=NA_real_,factor_barn1=1,factor_barn2=1),
 variants),use.names=TRUE)
compare_campaigns<-function(source,metric) {
 rbindlist(lapply(seq_len(nrow(comparison_variants)),function(i) {
  v<-comparison_variants[i];z<-copy(source)
  z[,value:=get(metric)*ifelse(housing=="housing_1",v$factor_barn1,v$factor_barn2)]
  out<-dcast(z,campaign+season+role~housing,value.var="value")
  setnames(out,c("housing_1","housing_2"),c("barn1","barn2"))
  out[,`:=`(variant=v$variant,difference=barn1-barn2,
    stall_difference_pct=100*(1-barn2/barn1))]
  errs<-if(metric=="kg")copy(unc$end) else if(identical(source,ends))copy(unc$end) else copy(unc$weighted)
  # Kg-Vergleich braucht nur die kg-Fehler, alle anderen Mengen bleiben g/Tier.
  if(metric=="kg") errs[, `:=`(barn1_error=barn1_total_kg_error,barn2_error=barn2_total_kg_error,
                              difference_error=difference_total_kg_error)]
  out<-merge(out,errs,by=c("variant","campaign"))
  out[,`:=`(reduction_pct=ifelse(role=="wrg",stall_difference_pct,NA_real_),
             reduction_pct_error=ifelse(role=="wrg",stall_difference_pct_error,NA_real_))]
  out
 }))
}
cmp_end<-compare_campaigns(ends,"g_animal")
cmp_kg<-compare_campaigns(ends,"kg")
setnames(cmp_kg,c("barn1","barn2","difference"),c("barn1_total_kg","barn2_total_kg","difference_total_kg"))
cmp_end<-merge(cmp_end,cmp_kg[,.(campaign,variant,barn1_total_kg,barn2_total_kg,difference_total_kg)],by=c("campaign","variant"))
cmp_cycle<-compare_campaigns(weighted,"g_animal")
cmp_cycle[,`:=`(barn1_g_place_year=barn1*cfg$cycles*cfg$animals_per_place,
 barn2_g_place_year=barn2*cfg$cycles*cfg$animals_per_place,
 difference_g_place_year=difference*cfg$cycles*cfg$animals_per_place)]
for(zname in c("cmp_end","cmp_cycle")) {
 z<-get(zname);z[,`:=`(campaign_order=match(campaign,campaigns$campaign),
  variant_order=match(variant,comparison_variants$variant))]
 setorder(z,campaign_order,variant_order);z[,c("campaign_order","variant_order"):=NULL]
}
save_csv(cmp_end,"kampagnenvergleich_gemessene_endwerte")
save_csv(cmp_cycle,"kampagnenvergleich_schlachttaggewichtet")
variant_labels<-c(unkorrigiert="Unkorrigiert",stall1_realitaet="Stall 1 als Realität",
 mittel_beider_staelle="Mittlere Stallbasis")
pretty_compare<-function(z) data.frame(
 Kampagne=unname(labels[z$campaign]),Variante=unname(variant_labels[z$variant]),
 `Stall 1 [g/Tier]`=fmt_pm(z$barn1,z$barn1_error,3),`Stall 2 [g/Tier]`=fmt_pm(z$barn2,z$barn2_error,3),
 `Differenz [g/Tier]`=fmt_pm(z$difference,z$difference_error,3),
 `WRG-Reduktion [%]`=fmt_pm(z$reduction_pct,z$reduction_pct_error,2),check.names=FALSE)
cmp_html<-c("<!doctype html><html lang='de'><meta charset='utf-8'><title>Kampagnenvergleich</title>",
 "<style>body{font:16px Arial;max-width:1200px;margin:35px auto;color:#111}table{border-collapse:collapse;width:100%;margin:24px 0}td,th{padding:10px;text-align:right;border-bottom:1px solid #ccc}td:first-child,td:nth-child(2){text-align:left}th{background:#eef2f5}p{line-height:1.5}@media print{table{font-size:10pt}}</style>",
 "<h1>Kampagnenvergleich: unkorrigiert und beide Bezugsvarianten</h1>",
 "<h2>Gemessene kumulierte Mast-Endwerte</h2>",html_table(pretty_compare(cmp_end)),
 paste0("<p>",offset_note," – Offsetkampagnen: beide Ställe ohne WRG. Die Differenz ist dort ein Stallunterschied, keine WRG-Einsparung. Der unkorrigierte Unterschied bei WRG-Kampagnen enthält den Stallunterschied und ist daher keine isolierte WRG-Wirkung.</p>"),
 "<h2>Nach Schlachttagverteilung gewichtete Emissionen pro Tier und Umtrieb</h2>",
 html_table(pretty_compare(cmp_cycle)),
 "<p>Diese zweite Tabelle enthält Extrapolationen. Annualisierte Kampagnenwerte bei eingestellter Umtriebszahl stehen zusätzlich in der zugehörigen ungerundeten CSV. Keine Saisongewichtung in diesen Einzelkampagnenwerten.</p>",
 paste0("<p>Die Variante Stall 1 verwendet E1 und E2/r. Die mittlere Stallbasis verwendet f·E1 und f·E2/r. Dabei gilt r=",format(r_mean,digits=15)," und f=(1+r)/2=",format((1+r_mean)/2,digits=15),". Bei einzelnen WRG-Kampagnen sind die prozentualen Reduktionen identisch. Im Jahresmittel unterscheiden sie sich, weil nur die Mittelwert-Variante Stall 2 der Offsetkampagnen in die Basis einbezieht. Rundung nur für die Darstellung; die ±-Angaben beschreiben die eingestellte Messfehlerkonvention.</p></html>"))
cmp_html<-c(gsub("</html>","",cmp_html,fixed=TRUE),paste0("<p>",error_note,"</p></html>"))
writeLines(cmp_html,file.path(cfg$out,"Kampagnenvergleich.html"))
stopifnot(nrow(cmp_end)==nrow(campaigns)*nrow(comparison_variants),nrow(cmp_cycle)==nrow(campaigns)*nrow(comparison_variants),
 all(is.na(cmp_end[role=="offset",reduction_pct])))
for(id in campaigns$campaign) {
 vals<-cmp_end[campaign==id & variant!="unkorrigiert",stall_difference_pct]
 stopifnot(abs(diff(vals))<1e-10)
}
print(cmp_end[,.(campaign,variant,barn1,barn2,reduction_pct)])


# Saisongewichtetes Jahresmittel auch für die unkorrigierte Vergleichsvariante.
annual_compare<-rbindlist(lapply(comparison_variants$variant,function(v) {
 z<-copy(cmp_cycle[variant==v & campaign %in% campaigns[include_annual==TRUE,campaign]])
 # Nur Mittelwert-Variante: je Offsetkampagne Mittel beider Ställe; sonst ausschliesslich Stall 1 als Basis.
 z[,basis:=ifelse(v=="mittel_beider_staelle" & role=="offset",(barn1+barn2)/2,barn1)]
 bs<-z[,.(basis=mean(basis)),by=season]
 ws<-z[role=="wrg",.(wrg=mean(barn2)),by=season]
 stopifnot(setequal(bs$season,names(cfg$season_weights)),setequal(ws$season,names(cfg$season_weights)))
 b<-sum(bs$basis*cfg$season_weights[bs$season])*cfg$cycles*cfg$animals_per_place
 w<-sum(ws$wrg*cfg$season_weights[ws$season])*cfg$cycles*cfg$animals_per_place
 data.table(variant=v,basis_g_place_year=b,wrg_g_place_year=w,
  saved_g_place_year=b-w,reduction_pct=100*(1-w/b),cycles=cfg$cycles)
}))
annual_compare<-merge(annual_compare,unc$annual,by="variant",sort=FALSE)
save_csv(annual_compare,"jahresvergleich_alle_drei_varianten")
for(v in variants$variant) {
 stopifnot(abs(annual_compare[variant==v,basis_g_place_year]-annual[variant==v,basis_g_place_year])<1e-10,
           abs(annual_compare[variant==v,wrg_g_place_year]-annual[variant==v,wrg_g_place_year])<1e-10)
}
annual_pretty<-data.frame(Variante=unname(variant_labels[annual_compare$variant]),
 `Basis [g/Tierplatz/Jahr]`=fmt_pm(annual_compare$basis_g_place_year,annual_compare$basis_g_place_year_error,2),
 `Mit WRG [g/Tierplatz/Jahr]`=fmt_pm(annual_compare$wrg_g_place_year,annual_compare$wrg_g_place_year_error,2),
 `Differenz [g/Tierplatz/Jahr]`=fmt_pm(annual_compare$saved_g_place_year,annual_compare$saved_g_place_year_error,2),
 `Reduktion [%]`=fmt_pm(annual_compare$reduction_pct,annual_compare$reduction_pct_error,2),check.names=FALSE)
full_html<-gsub("</html>","",cmp_html,fixed=TRUE)
full_html<-c(full_html,"<h2>Schlachttag- und saisongewichtetes Jahresmittel – alle drei Varianten</h2>",
 html_table(annual_pretty),paste0("<p>",cfg$cycles," Umtriebe; ",season_note,". Innerhalb der Saison werden zuerst die Kampagnen gemittelt; nur in der Mittelwert-Variante innerhalb jeder Offsetkampagne zuvor beide Stallwerte. Für Stall 1 als Realität und den unkorrigierten Vergleich stammt die Basis ausschliesslich aus Stall 1. Unkorrigierte Reduktionen enthalten Stallunterschiede und sind keine isolierte WRG-Wirkung. Die Werte sind Modellwerte bei ",cfg$animals_per_place," Tieren je Tierplatz und Umtrieb.</p></html>"))
writeLines(full_html,file.path(cfg$out,"Kampagnenvergleich_mit_Jahresmittel.html"))
for(g in c("end","weighted","annual")) {
 z<-if(g=="end")cmp_end else if(g=="weighted")cmp_cycle else annual_compare
 for(i in seq_len(nrow(z))) {
  d<-unc$detail[group==g & variant==z$variant[i] &
    campaign==if(g=="annual")"annual" else z$campaign[i]]
  for(m in intersect(d$metric,names(z))) stopifnot(abs(z[[m]][i]-d[metric==m,value])<1e-9)
 }
}
print(annual_compare)


# Ein erfolgreicher Gesamtlauf aktualisiert alle erzeugten Dateien und zeigt
# die tatsaechlich verwendeten Parameter. Diagnose-/andere Szenarioordner separat.
saveRDS(list(cfg=cfg,campaigns=campaigns,slaughter=slaughter,variants=variants),
 file.path(cfg$out,"laufparameter.rds"))
run_finished <- Sys.time()
writeLines(c("ERFOLGREICH",paste("Beginn:",format(run_started)),
 paste("Ende:",format(run_finished)),paste("Umtriebe:",cfg$cycles),season_note,
 paste("Ausgabeordner:",normalizePath(cfg$out))),file.path(cfg$out,"laufstatus.txt"))
generated <- list.files(cfg$out,full.names=TRUE)
generated <- generated[file.info(generated)$mtime >= run_started & !dir.exists(generated)]
fwrite(data.table(file=basename(generated),modified=as.character(file.info(generated)$mtime),
 bytes=file.info(generated)$size),file.path(cfg$out,"ausgabedateien.csv"),sep=";",bom=TRUE)
message("ERFOLGREICH: ",length(generated)+1," Ausgabedateien aktualisiert in ",normalizePath(cfg$out))
