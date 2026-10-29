library(data.table)
library(lubridate)
library(qs)

# ================== Parameter definieren =====================
# Pfade zu den Kampagnendaten
path_datasets <- list(
  feb = '~/git/mettmenstetten-feb2024/rsaves/final-dataset.qs',
  apr = '~/git/mettmenstetten-apr2024/rsaves/final-dataset.qs',
  jul = '~/git/mettmenstetten-jul2024/rsaves/final-dataset.qs',
  dec = '~/git/mettmenstetten-dec2024/rsaves/final-dataset.qs'
)

# Aggregationsintervall definieren: "hour", "6hours", "day"
agg_interval <- "1minute"

# ================== Funktion zur Datenverarbeitung =====================
load_rh_data <- function(campaign_name, file_path, interval) {
  dat <- qread(file_path)
  
  # RH-Daten filtern: gültige Sensoren, outflow, kein "turbo"
  rh <- dat[
    tracer == "humidity" &
      flow_direction == "outflow" &
      grepl("^nh3_", sensor) &
      !grepl("turbo", location, ignore.case = TRUE)
  ]
  
  if (nrow(rh) == 0) return(NULL)
  
  # Berechnung Masttage je Stall
  placement <- rh[, .(start_time = min(st)), by = housing]
  rh <- merge(rh, placement, by = "housing")
  rh[, masttag := as.numeric(difftime(st, start_time, units = "days"))]
  rh[, campaign := campaign_name]
  
  # Aggregationszeitpunkt definieren
  rh[, agg_time := floor_date(st, unit = interval)]
  
  # Mittelwert über Sensoren pro Zeitintervall und Stall
  rh_summary <- rh[, .(
    rh_mean = mean(value, na.rm = TRUE),
    rh_sd = sd(value, na.rm = TRUE),
    n = .N
  ), by = .(housing, campaign, masttag, agg_time)]
  
  return(rh_summary)
}

# ================== Ausführung über alle Kampagnen =====================
all_rh <- rbindlist(lapply(names(path_datasets), function(camp) {
  load_rh_data(camp, path_datasets[[camp]], agg_interval)
}), use.names = TRUE, fill = TRUE)

# ================== Labeling & Ausgabe =====================
# Faktoren für Sortierung und Plot-Label
all_rh[, housing := factor(housing, labels = c("Barn 1", "Barn 2"))]
all_rh[, campaign := factor(campaign,
                            levels = c("feb", "apr", "jul", "dec"),
                            labels = c("Feb-24", "Apr-24", "Jul-24", "Dec-24"))]

# Beispielplot
library(ggplot2)

ggplot(all_rh, aes(x = masttag, y = rh_mean, color = housing, group = housing)) +
  geom_line(size = 0.75, alpha = 0.85) +
  # geom_point(size = 1.2, alpha = 0.9) +
  facet_wrap(~ campaign, ncol = 2, scales = "free_x") +
  labs(
    title = sprintf("Relative Humidity in Exhaust Air"),
    x = "Day of age",
    y = "RH [%]",
    color = "Barn"
  ) +
  theme_minimal(base_size = 13) +
  scale_color_manual(
    values = c("Barn 1" = "red",  
               "Barn 2" = "blue") )  +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
      plot.title = element_text(size = 22, face = "bold"),
      axis.title.x = element_text(size = 18),
      axis.title.y = element_text(size = 18),
      axis.text.x = element_text(size = 18),
      axis.text.y = element_text(size = 18),
      legend.title = element_text(size = 18),
      legend.text = element_text(size = 18)
  ) 


  library(mgcv)
library(ggplot2)

# Nur vollständige Werte verwenden
gam_data <- na.omit(all_rh[, .(masttag, rh_mean, housing, campaign)])

# Optional: Nur eine Kampagne betrachten (z. B. Juli)
# gam_data <- gam_data[campaign == "Jul-24"]

# Fit GAM-Modell: additiver Effekt Masttag + Interaktion mit Stall
gam_model <- gam(rh_mean ~ s(masttag, by = housing) + housing,
                 data = gam_data,
                 method = "REML")

# Zusammenfassung
summary(gam_model)

# Visualisierung der glatten Verläufe
plot(gam_model, pages = 1, shade = TRUE)

# Alternativ: ggplot + predict()
library(dplyr)
pred_df <- gam_data %>%
  group_by(housing) %>%
  do({
    pred <- predict(gam_model, newdata = ., se.fit = TRUE)
    mutate(., fit = pred$fit, se = pred$se.fit)
  })

ggplot(pred_df, aes(x = masttag, y = rh_mean, color = housing)) +
  geom_point(alpha = 0.5, size = 1) +
  geom_line(aes(y = fit), size = 1.1) +
  geom_ribbon(aes(ymin = fit - 2 * se, ymax = fit + 2 * se, fill = housing),
              alpha = 0.2, color = NA) +
  facet_wrap(~ campaign) +
  scale_color_manual(values = c("red", "blue")) +
  scale_fill_manual(values = c("red", "blue")) +
  labs(
    title = "GAM-Modelled RH Trajectories in Exhaust Air",
    x = "Day of age",
    y = "RH [%]",
    color = "Barn", fill = "Barn"
  ) +
  theme_minimal()

