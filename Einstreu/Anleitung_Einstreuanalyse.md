# Einstreuanalysen Mettmenstetten

Start im Projektordner:

    Rscript einstreu_mettmenstetten.R

Alternativ das Skript in RStudio öffnen und vollständig ausführen. Die Einstellungen stehen am Anfang des Skripts. Eingabe ist Einstreu/litter_data_all.xlsx, Blatt Sheet 1. Die Excel-Datei wird ausschliesslich gelesen.

## Ausgabe

Einstreu/ergebnisse_einstreu/Einstreuanalysen.html enthält für Feuchtigkeit, pH, Gesamt-N und Ammoniumstickstoff:

- Boxplots über die Masttage, getrennt nach Kampagne und Stall, im Stil der Screenshots.
- Boxplots an Masttag 34 mit automatisch berechneten Signifikanzbuchstaben.
- Tabellen 8–11: Mittelwert +/- Standardabweichung, hochgestellte Buchstaben und Probenzahlen.

Grafiken und Tabellen liegen als PNG mit hoher Auflösung und als PDF vor. Tabellen und ungerundete Deskriptivstatistik, adjustierte p-Werte und Modelldiagnosen werden zusätzlich als CSV geschrieben. Tabellen haben deutsche, Grafiken die englischen Beschriftungen der Vorlagen. NH4-N ist ausdrücklich Ammoniumstickstoff; die irreführende Prozentangabe der ursprünglichen NH4-Achse wurde nicht übernommen.

Standardmässig werden FEB, APR, JUL, DEC und AUG26 ausgewertet. Die vorhandenen AKB-Proben gehören nicht zu Stall 1/2 und werden mit Begründung protokolliert. Es werden keine auffälligen Messwerte automatisch gelöscht oder korrigiert, auch nicht der historische pH-Wert 0,52.

Mit historical_comparison = TRUE wird zusätzlich die ursprüngliche Auswahl FEB/APR/JUL/DEC im Unterordner ohne_august2026 erstellt. Dort stimmen die acht gerundeten Feuchte-Mittelwerte, Standardabweichungen und Buchstaben mit Tabelle 8 der Vorlage überein. Über alle vier Merkmale sind alle 112 paarweisen Signifikanzentscheidungen der gezeigten Buchstaben rekonstruiert. Das ist ein Nachbau aus den Daten, keine Wiederherstellung des verlorenen Originalcodes.

## Einstellungen

- campaigns: einbezogene Kampagnen in gewünschter Reihenfolge.
- historical_comparison: zusätzliche ursprüngliche Vier-Kampagnen-Ansicht.
- comparison_day = 34: genau dieser Masttag, nicht automatisch der letzte Tag jeder Kampagne.
- test_method = "anova_tukey": einfaktorielle ANOVA mit Kampagne-Stall als gemeinsamer Gruppierungsvariable und anschliessend Tukey-HSD, wie anhand der Vorlagen rekonstruiert.
- test_method = "welch_games_howell": Alternative für ungleiche Varianzen. Kleine Gruppengrössen bleiben eine Einschränkung; keine pauschal überlegene Methode.
- test_method = "kruskal_dunn": Kruskal-Wallis mit zweiseitigem Dunn-Test und einstellbarer Korrektur dunn_adjust, standardmässig Holm. Diese Variante vergleicht Rangverteilungen; die daneben angegebenen Mittelwerte ändern sich dadurch nicht.
- alpha = 0.05: Schwelle für die Buchstaben.
- spread = "sd": Standardabweichung der Einzelproben, alternativ "se" für Standardfehler. Dies ist keine Übernahme der pauschalen Messfehler aus dem NH3-Skript.
- decimal_mark: Komma als Standard, Punkt für Zahlenschreibweise wie im Screenshot.
- colours, dpi, base_size, facet_columns und export_pdf: Darstellung.

Einstellungen einzeln ändern und das ganze Skript ausführen. Pro Ausgabeordner bestätigt laufstatus.txt mit ERFOLGREICH den vollständigen Datensatzlauf. ausgabedateien.csv nennt die in diesem Lauf erzeugten Dateien; parameter.R und laufparameter.rds dokumentieren die Einstellungen.

## Interpretation der Buchstaben

Gruppen mit mindestens einem gemeinsamen Buchstaben zeigen im gewählten Paarvergleich keinen nachgewiesenen Unterschied. Gruppen ohne gemeinsamen Buchstaben unterscheiden sich mit adjustiertem p < alpha. Beispielsweise teilen ab und ac den Buchstaben a; ihre vollständigen Zeichenfolgen müssen nicht identisch sein. Nicht signifikant bedeutet nicht, dass Gleichheit nachgewiesen wäre.

Die Buchstaben werden pro Merkmal über alle Kampagne-Stall-Gruppen des jeweiligen Datensatzes ermittelt. August 2026 vergrössert die Vergleichsfamilie und verändert gegebenenfalls die Residualvarianz; daher können sich auch Buchstaben der früheren Kampagnen ändern. Buchstabenbezeichnungen selbst sind austauschbar, entscheidend sind die gemeinsamen Buchstaben und p-Werte. Eine zusätzliche Korrektur über verschiedene Merkmale erfolgt nicht.

## Datenbasis und Grenzen

Mit August werden 181 Proben aus Stall 1/2 ausgewertet, davon 51 an Tag 34 in zehn Gruppen. Ohne August sind es 150 Proben, davon 40 an Tag 34 in acht Gruppen. August-Stall 1 hat an Tag 34 sechs Proben, alle übrigen Tag-34-Gruppen fünf.

Die Proben sind keine unabhängigen Ställe oder Kampagnen. Die Tests sind explorative Vergleiche innerhalb der beprobten Situation und kein kausaler Nachweis einer WRG-Wirkung. In Dezember 2024 und August 2026 lief die WRG in beiden Ställen nicht. Das wird in den Tabellen ausgewiesen.

Shapiro-Wilk an den ANOVA-Residuen und der Levene-Test mit Medianzentrum werden ausgegeben. Die jetzigen Daten zeigen Abweichungen von Modellannahmen. Das Skript dokumentiert dies und wechselt die Testmethode nicht automatisch anhand von p-Werten. Für wissenschaftliche Schlussfolgerungen sind die tatsächliche Stichprobenanlage, mögliche Abhängigkeiten und die geprüften Laborauffälligkeiten zu berücksichtigen.

Die plausibilisierten Feuchte-, pH-, N- und NH4-N-Spalten können für diese Darstellungen verwendet werden. Die zusätzlich festgestellten Einheiten- und Phosphor-Beschriftungsprobleme sind in Plausibilitaet_August2026.md beschrieben. Sie wurden durch das Grafikskript nicht verändert.

## Dokumentation

- [R: TukeyHSD](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/TukeyHSD.html)
- [multcompView](https://cran.r-project.org/web/packages/multcompView/refman/multcompView.html)
- [rstatix: Games-Howell](https://rpkgs.datanovia.com/rstatix/reference/games_howell_test.html)
- [rstatix: Dunn](https://rpkgs.datanovia.com/rstatix/reference/dunn_test.html)

## Probenahmeverdacht August 2026

Der Hinweis bezieht sich ausdrücklich auf den Mittelwert der Feuchtigkeit aller fünf Proben aus Stall 2 am Masttag 34, nicht auf den NH4-N-Einzelwert der Probe 610. Der Feuchtemittelwert beträgt 26,02 %; die fünf Werte liegen zwischen 25,3 und 27,2 %. Es besteht der Verdacht, dass die Probenahme die Einstreu dieses Stalls am Mastende nicht repräsentativ erfasst hat.

sampling_caution_metrics = "moisture_pct" begrenzt die Kennzeichnung auf Feuchtegrafiken und die Feuchtetabelle. sampling_caution enthält die Erläuterung. Grafiken und Tabellen für pH, Gesamt-N und NH4-N übernehmen diesen Hinweis nicht pauschal. Die Feuchtewerte bleiben vorerst in Mittelwerten, Tests und Buchstaben enthalten. Die Kennzeichnung ist weder eine bestätigte Fehlerdiagnose noch eine automatische Ausschlussregel.
