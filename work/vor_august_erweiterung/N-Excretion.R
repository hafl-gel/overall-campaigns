# Pakete laden
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)
library(ggbreak)
library(car)

# Datei einlesen – Pfad ggf. anpassen
# Beispiel: "daten_broiler_emissionen.xlsx", Blattname ggf. anpassen
df <- read_excel("/Users/stefan/Documents/0 - MSc HAFL/MA/analysen/IMPEX_Gfeller_nach MA.xlsx", sheet = "R")

# Überblick über die Struktur
str(df)

# Spaltennamen säubern (falls nötig)
names(df) <- gsub(" ", "_", names(df))

df$Umtrieb <- factor(df$Umtrieb, levels = unique(df$Umtrieb))
df$Stall <- factor(df$Stall)
df$Season <- factor(df$Season, levels = c("Winter", "Übergang", "Sommer"))

# Wichtige Spalten für die Analyse prüfen
# z. B.: Stall, Season, Umtrieb, N_ausgeschieden_kg, N_ausgeschieden_pro_Tier_g



# === 1. Wilcoxon-Test (Dec-24 ausschließen) ===
df_paired <- df %>%
  filter(Umtrieb != "Dec-24") %>%
  select(Stall, Umtrieb, N_Ausscheidung_pro_Tier_und_Jahr_g) %>%
  pivot_wider(names_from = Stall, values_from = N_Ausscheidung_pro_Tier_und_Jahr_g,
              names_prefix = "Stall_") %>%
  mutate(diff = Stall_1 - Stall_2) %>%
  filter(!is.na(diff))

wilcox_result <- wilcox.test(df_paired$Stall_1, df_paired$Stall_2, paired = TRUE, exact = TRUE)
print("Wilcoxon-Test (ohne Dec-24):")
print(wilcox_result)

# === 2. Nicht gewichteter Mittelwert über alle Umtriebe ===
mean_raw <- mean(df$N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE)
sd_raw <- sd(df$N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE)
cat("Nicht gewichteter Mittelwert (n=8):", round(mean_raw, 1), "g N/Jahr\n")
cat("Standardabweichung:", round(sd_raw, 1), "g\n")

# === 3. Benutzerdefinierte Gewichtung pro Kampagne und Stall ===

# Gewichtungs-Vektor: Werte müssen zu den 8 Kampagnen passen (in Reihenfolge von df)
# Summe sollte 1 ergeben, falls du absolute Jahresanteile willst
kampagnen_gewichte <- c(
  0.125,  # Stall 1, Feb-24
  0.125,   # Stall 2, Feb-24
  0.5,  # Stall 1, Apr-24
  0.5,  # Stall 2, Apr-24
  0.25,  # Stall 1, Jul-24
  0.25,  # Stall 2, Jul-24
  0.125,  # Stall 1, Dec-24 
  0.125  # Stall 2, Dec-24
)

# Gewichtete Mittelwertberechnung
df$gewicht <- kampagnen_gewichte
df$Stall <- factor(df$Stall)

# === 1. Prüfung der Voraussetzungen für gepaarten Vergleich ===
df_paired <- df %>%
  filter(Umtrieb != "Dec-24") %>%
  select(Stall, Umtrieb, N_Ausscheidung_pro_Tier_und_Jahr_g) %>%
  pivot_wider(names_from = Stall, values_from = N_Ausscheidung_pro_Tier_und_Jahr_g,
              names_prefix = "Stall_") %>%
  mutate(diff = Stall_1 - Stall_2) %>%
  filter(!is.na(diff))

# Differenzen anzeigen
print("Differenzen (Stall 1 – Stall 2):")
print(df_paired$diff)

# Shapiro-Wilk-Test
shapiro_test <- shapiro.test(df_paired$diff)
print("Shapiro-Wilk-Test auf Normalverteilung der Differenzen:")
print(shapiro_test)

# Histogramm
ggplot(df_paired, aes(x = diff)) +
  geom_histogram(bins = 10, fill = "steelblue", color = "black") +
  labs(title = "Histogramm der Differenzen (Stall 1 – Stall 2)",
       x = "Differenz in N-Ausscheidung [g/Jahr]",
       y = "Häufigkeit") +
  theme_minimal()

# QQ-Plot
ggplot(df_paired, aes(sample = diff)) +
  stat_qq() +
  stat_qq_line(color = "red") +
  labs(title = "QQ-Plot der Differenzen",
       x = "Theoretische Quantile", y = "Beobachtete Quantile") +
  theme_minimal()

# === 4. Ungewichteter Mittelwert pro Stall ===
unweighted_summary <- df %>%
  group_by(Stall) %>%
  summarise(
    mean_unweighted = mean(N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE),
    sd_unweighted = sd(N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE),
    n = n(),
    se_unweighted = sd_unweighted / sqrt(n),
    .groups = "drop"
  )

print("Ungewichteter Mittelwert pro Stall:")
print(unweighted_summary)

# === 5. Gewichteter Mittelwert pro Stall ===
weighted_summary <- df %>%
  group_by(Stall) %>%
  summarise(
    mean_weighted = sum(N_Ausscheidung_pro_Tier_und_Jahr_g * gewicht) / sum(gewicht),
    .groups = "drop"
  )

print("Gewichteter Mittelwert pro Stall:")
print(weighted_summary)

# === 6. Zusammenfassen beider Mittelwerte (optional) ===
summary_table <- left_join(unweighted_summary, weighted_summary, by = "Stall")
print("Summary of weighted and unweighted nitrogen excretion per barn:")
print(summary_table)




ggplot(df, aes(x = factor(Stall), y = N_Ausscheidung_pro_Tier_und_Jahr_g, fill = factor(Stall))) +
  geom_boxplot(outlier.shape = NA) +
  coord_cartesian(ylim = c(200, 310)) +  # Untere Achsengrenze auf 250 setzen
  labs(
    title = "Annual nitrogen excretion per animal place",
    x = "Barn",
    y = "N excretion [g/year]",
    fill = "Barn"
  ) +
  scale_fill_brewer(palette = "Set1", name = "Barn") +
  theme_minimal(base_size = 14) +  # Basisschriftgrösse z. B. 14 pt
  theme(
    plot.title = element_text(size = 22, face = "bold"),
    axis.title.x = element_text(size = 18),
    axis.title.y = element_text(size = 18),
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 18)
)

# === 8. Anteil NH3-Emission – Stall 2 (ohne Dec-24), Stall 1 (mit Dec-24) ===

# === Voraussetzungen prüfen ===


# Nur relevante Daten selektieren
df_s1 <- df %>% filter(Stall == 1, Umtrieb != "Dec-24")
df_s2 <- df %>% filter(Stall == 2, Umtrieb != "Dec-24")
df_test <- bind_rows(df_s1, df_s2)

# Sicherstellen, dass Faktorstruktur passt
df_test$Stall <- factor(df_test$Stall)

# Shapiro-Wilk-Test auf Normalverteilung
cat("Shapiro-Wilk-Test für Stall 1:\n")
print(shapiro.test(df_s1$`Anteil_NH3-Emission`))

cat("\nShapiro-Wilk-Test für Stall 2:\n")
print(shapiro.test(df_s2$`Anteil_NH3-Emission`))

# Levene-Test auf Varianzhomogenität
cat("\nLevene-Test auf Varianzhomogenität:\n")
print(leveneTest(`Anteil_NH3-Emission` ~ Stall, data = df_test))

# Wilcoxon-Test
cat("\nWilcoxon-Rank-Sum-Test (unabhängig, exact = TRUE):\n")
print(wilcox.test(`Anteil_NH3-Emission` ~ Stall, data = df_test, exact = TRUE))

# Optional: t-Test nur, falls Voraussetzungen erfüllt wären (nur zu Vergleichszwecken)
cat("\nWelch t-Test (nur informativ):\n")
print(t.test(`Anteil_NH3-Emission` ~ Stall, data = df_test))

# Boxplot
ggplot(df_test, aes(x = Stall, y = `Anteil_NH3-Emission`, fill = Stall)) +
  geom_boxplot(outlier.shape = NA) +
  labs(
    title = "Share of NH3-N Emissions Relative to Total Ammoniacal Nitrogen (TAN)",
    x = "Barn",
    y = "NH3 Emission Share [%]",
    fill = "Barn"
  ) +
  scale_fill_brewer(palette = "Set1", name = "Barn") +
  theme_minimal(base_size = 14) +  # Basisschriftgrösse z. B. 14 pt
  theme(
    plot.title = element_text(size = 22, face = "bold"),
    axis.title.x = element_text(size = 18),
    axis.title.y = element_text(size = 18),
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 18)
  )


#####################################################################



# --- Clean Column Names ---
names(df) <- gsub(" ", "_", names(df))

# --- Recode Season Labels to English ---
df <- df %>%
  mutate(
    Season_en = recode_factor(
      Season,
      "Winter" = "Winter",
      "Übergang" = "Transition",
      "Sommer" = "Summer"
    )
  )

# Optional: Set ordered factor levels
df$Season_en <- factor(df$Season_en, levels = c("Winter", "Transition", "Summer"))

# === Summary: Group Sizes ===
df %>%
  count(Season_en)

# === Descriptive Statistics ===
df %>%
  group_by(Season_en) %>%
  summarise(
    n = sum(!is.na(N_Ausscheidung_pro_Tier_und_Jahr_g)),
    mean = round(mean(N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE), 1),
    sd = round(sd(N_Ausscheidung_pro_Tier_und_Jahr_g, na.rm = TRUE), 1)
  )

# === Check Variance Homogeneity ===
levene_result <- leveneTest(N_Ausscheidung_pro_Tier_und_Jahr_g ~ Season_en, data = df)
print(levene_result)

# === Kruskal-Wallis Test (non-parametric) ===
kw_result <- kruskal.test(N_Ausscheidung_pro_Tier_und_Jahr_g ~ Season_en, data = df)
cat("Kruskal-Wallis Test Result:\n")
print(kw_result)

# === Dunn Post-hoc Test (only if Kruskal-Wallis is significant) ===
if (kw_result$p.value < 0.05) {
  cat("\nDunn Post-hoc Test (Benjamini-Hochberg corrected):\n")
  dunn_result <- dunnTest(N_Ausscheidung_pro_Tier_und_Jahr_g ~ Season_en, data = df, method = "bh")
  print(dunn_result)
} else {
  cat("\nNo post-hoc test required (Kruskal-Wallis not significant).\n")
}

# === Boxplot (English Labels) ===
ggplot(df, aes(x = Season_en, y = N_Ausscheidung_pro_Tier_und_Jahr_g, fill = Season_en)) +
  geom_boxplot(outlier.shape = NA) +
  labs(
    title = "Annual Nitrogen Excretion per Animal Place",
    x = "Season",
    y = "Nitrogen Excretion [g/year]",
    fill = "Season"
  ) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 22, face = "bold"),
    axis.title.x = element_text(size = 18),
    axis.title.y = element_text(size = 18),
    axis.text.x = element_text(size = 18),
    axis.text.y = element_text(size = 18),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 18)
  )




