# Pakete laden
library(data.table)
library(qs)
library(mgcv)
library(ggplot2)
library(gratia)   # für Diagnoseplots

# Pfade zu den final-datasets
path_datasets <- list(
  feb = '~/git/mettmenstetten-feb2024/rsaves/final-dataset.qs',
  apr = '~/git/mettmenstetten-apr2024/rsaves/final-dataset.qs',
  jul = '~/git/mettmenstetten-jul2024/rsaves/final-dataset.qs',
  dec = '~/git/mettmenstetten-dec2024/rsaves/final-dataset.qs'
)

# Funktion zur Extraktion und Aufbereitung der rel. Feuchte
load_rh_data <- function(campaign_name, file_path) {
  dat <- qread(file_path)
  
  # Filterung nach relevanten Kriterien
  rh_filtered <- dat[
    tracer == "humidity" &
      flow_direction == "outflow" &
      grepl("^nh3_", sensor) &
      !grepl("turbo", location, ignore.case = TRUE)
  ]
  
  if (nrow(rh_filtered) == 0) return(NULL)
  
  # Einsetzzeitpunkt je Stall ermitteln
  einstallung <- rh_filtered[, min(st), by = housing]
  setnames(einstallung, "V1", "start_time")
  
  # Masttag berechnen
  rh_filtered <- merge(rh_filtered, einstallung, by = "housing")
  rh_filtered[, masttag := as.numeric(difftime(st, start_time, units = "days"))]
  
  # Kampagne zuweisen
  rh_filtered[, campaign := campaign_name]
  
  # Sensorübergreifender Mittelwert pro Zeitpunkt und Stall
  rh_avg <- rh_filtered[, .(
    rh_mean = mean(value, na.rm = TRUE)
  ), by = .(st, masttag, housing, campaign)]
  
  return(rh_avg)
}

# Daten laden und zusammenführen
all_rh <- rbindlist(lapply(names(path_datasets), function(camp) {
  load_rh_data(camp, path_datasets[[camp]])
}), use.names = TRUE, fill = TRUE)

# Kategorien für schöne Darstellung
all_rh[, housing := factor(housing, labels = c("Barn 1", "Barn 2"))]
all_rh[, campaign := factor(campaign, levels = c("feb", "apr", "jul", "dec"),
                            labels = c("Feb-24", "Apr-24", "Jul-24", "Dec-24"))]

# Aufteilung der Daten
rh_main <- all_rh[campaign %in% c("Feb-24", "Apr-24", "Jul-24")]
rh_dec  <- all_rh[campaign == "Dec-24"]


library(mgcv)
library(data.table)

# Annahme: rh_main ist bereits vorbereitet, enthält:
# - masttag
# - rh_mean
# - housing (factor mit "Barn 1", "Barn 2")
# - campaign (factor mit "Feb-24", "Apr-24", ...)

# Liste zur Speicherung der Modelle
gam_models <- list()

# Iteration über alle Kampagnen
for (camp in unique(rh_main$campaign)) {
  
  # Teilmenge der Daten für die aktuelle Kampagne
  dat <- rh_main[campaign == camp]
  
  # Modellformulierung
  model <- gam(
    rh_mean ~ s(masttag, by = housing) + housing,
    data = dat,
    method = "REML"
  )
  
  # Modell speichern
  gam_models[[as.character(camp)]] <- model
  
  # Zusammenfassung ausgeben
  cat("### GAM Summary for", camp, "###\n")
  print(summary(model))
  cat("\n\n")
}


#########################################################################

# GAM-Modell für Feb–Jul
gam_main <- gam(
  rh_mean ~ s(masttag, by = housing) + housing + campaign,
  data = rh_main,
  method = "REML"
)

# GAM-Modell für Dezember separat
gam_dec <- gam(
  rh_mean ~ s(masttag, by = housing) + housing,
  data = rh_dec,
  method = "REML"
)

# Modellzusammenfassungen
summary(gam_main)
summary(gam_dec)

# Diagnoseplots (z. B. für gam_main)
par(mfrow = c(2,2))
gam.check(gam_main)
par(mfrow = c(1,1))

# Plotten der Kurven
ggplot(rh_main, aes(x = masttag, y = rh_mean, color = housing, group = housing)) +
  # geom_point(alpha = 0.5, size = 1) +        # einzelne Punkte
  geom_line(size = 0.7, alpha = 0.8) +       # verbundene Linie zwischen Punkten
  facet_wrap(~ campaign, ncol = 2, scales = "free_x") +
  labs(
    title = "Relative Humidity in Exhaust Air During Fattening Cycles",
    x = "Days after placement",
    y = "Relative Humidity (%)",
    color = "Barn"
  ) +
  theme_minimal(base_size = 12) +
  scale_color_manual(values = c("blue", "gold")) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold"),
    axis.text = element_text(color = "black")
  )



