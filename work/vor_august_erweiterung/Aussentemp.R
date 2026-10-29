library(data.table)
library(qs)
library(ggplot2)
library(lubridate)

# Pfade zu den finalen Datensätzen pro Kampagne
path_datasets <- list(
  feb = '~/git/mettmenstetten-feb2024/rsaves/final-dataset.qs',
  apr = '~/git/mettmenstetten-apr2024/rsaves/final-dataset.qs',
  jul = '~/git/mettmenstetten-jul2024/rsaves/final-dataset.qs',
  dec = '~/git/mettmenstetten-dec2024/rsaves/final-dataset.qs'
)

# Funktion zur Extraktion und Aufbereitung der Daten
load_temp_data <- function(campaign_name, file_path) {
  dat <- qread(file_path)
  
  # Nur Sensor 'außentemp'
  temp_data <- dat[sensor == "außentemp"]
  
  if (nrow(temp_data) == 0) return(NULL)
  
  # berechne Masttag aus Startzeit pro Stall
  einstallung <- temp_data[, min(st), by = housing]
  setnames(einstallung, "V1", "start_time")
  
  # Join zur Berechnung Masttag
  temp_data <- merge(temp_data, einstallung, by = "housing")
  temp_data[, masttag := as.numeric(difftime(st, start_time, units = "days"))]
  
  # Kampagnen-Label
  temp_data[, campaign := campaign_name]
  
  return(temp_data[, .(masttag, value, housing, campaign)])
}

# Daten aus allen Kampagnen einlesen und zusammenführen
all_temp <- rbindlist(lapply(names(path_datasets), function(camp) {
  load_temp_data(camp, path_datasets[[camp]])
}), use.names = TRUE, fill = TRUE)

# Faktor-Labels für Plot
all_temp[, campaign := as.character(campaign)]

all_temp[, housing := factor(housing, labels = c("Barn 1", "Barn 2"))]
all_temp[, campaign := factor(campaign,
                              levels = c("feb", "apr", "jul", "dec"),
                              labels = c("Feb-24", "Apr-24", "Jul-24", "Dec-24"))]

# Plot: jeder einzelne Wert als Punkt
ggplot(all_temp, aes(x = masttag, y = value, color = housing, group = housing)) +
  geom_line(size = 0.75, alpha = 0.85) +
  # geom_point(size = 0.5, alpha = 0.9) +
  facet_wrap(~ campaign, ncol = 2, scales = "free_x") +
  labs(
    title = "Outdoor Temperature Profiles During Fattening Cycles",
    x = "Day of age",
    y = "Temperature [°C]",
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


# Temperaturstatistiken nur nach Kampagne (unabhängig vom Stall)
temp_summary_campaign <- all_temp[, .(
  mean_temp = round(mean(value, na.rm = TRUE), 1),
  min_temp = round(min(value, na.rm = TRUE), 1),
  max_temp = round(max(value, na.rm = TRUE), 1)
), by = campaign][order(campaign)]

# Ausgabe
print(temp_summary_campaign)




