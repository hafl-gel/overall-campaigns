# Klima- und N-Auswertungen mit August 2026

Stand: 29.10.2026. Alle Skripte und Ergebnisse liegen direkt in diesem Projektordner.

## Angepasste Skripte

| Skript | Inhalt | Ergebnisordner |
|---|---|---|
| Aussentemp.R | Aussentemperatur, fünf Kampagnen, beide Ställe; Kampagnen- und Stallstatistik | ergebnisse_klima/aussentemperatur |
| RH-Graph.R | Abluftfeuchte, Aggregation und deskriptives GAM über alle fünf Kampagnen | ergebnisse_klima/rh |
| gam_rh_analysis.R | Einzel-GAM je Kampagne, WRG-Sammelmodell und separates Offset-Sammelmodell | ergebnisse_klima/gam_rh |
| N-Excretion.R | Vorhandene N-Bilanzen, dynamische Saisongewichte, vorbereiteter August-Import und Datenverfügbarkeit | ergebnisse_n_ausscheidung |

Start jeweils im Projektordner, beispielsweise:

    Rscript Aussentemp.R
    Rscript RH-Graph.R
    Rscript gam_rh_analysis.R
    Rscript N-Excretion.R

PNG, PDF, numerische CSV und Modellzusammenfassungen werden bei jedem Skriptlauf im jeweiligen Ergebnisordner neu geschrieben. Grafiken erscheinen zusätzlich beim interaktiven Aufruf in RStudio. Die Quelldateien werden ausschliesslich gelesen.

Die ursprünglichen vier Skripte sind unter work/vor_august_erweiterung gesichert.

## Gemeinsame Kampagnen und Datenschema

kampagnen_daten.R enthält die gemeinsame Kampagnenliste und Importfunktionen. FEB/APR/JUL/DEC 2024 sowie AUG 2026 sind registriert. Juli 2025 wird nicht geladen.

Die Klimaskripte verwenden qs2::qd_read mit den tatsächlich vorhandenen final-dataset.qd-Dateien. Die bisherigen .qs-Dateien existieren hier nicht mehr. Die Zeitachse wird aus local-times.rds relativ zur Einstallung berechnet und als Days after placement beschriftet. Das Einlesen beruht nicht auf einem zufällig späteren ersten Sensorwert.

Die Einstellungen stehen in jedem Skript am Anfang. campaigns steuert die Auswahl. Der bisherige Ausschluss von Positionen mit turbo bleibt als einstellbarer Sensorfilter erhalten. Das ist eine Datenfilterregel, keine Behauptung zur Ursache früherer Lüftungsschwankungen.

## RH und GAM

Die RH-Mittel sind arithmetische Mittel der ausgewählten NH3-Xnode-Feuchtesensoren pro Stall und Zeitintervall. Sie sind nicht nach Luftvolumenstrom gewichtet. Das Aggregationsintervall ist tatsächlich wirksam; der einzelne Mastzeitpunkt ist kein zusätzliches Gruppierungsmerkmal, das die Aggregation verhindern würde.

RH-Graph.R behält standardmässig das bisherige deskriptive Sammelmodell ohne Kampagneneffekt bei. include_campaign_effect = TRUE ergänzt einen Kampagneneffekt. Das Sammelmodell ist kein isolierter WRG-Vergleich.

gam_rh_analysis.R berechnet Einzelmodelle für alle fünf Kampagnen. gam_main verwendet nur Februar/April/Juli 2024 mit aktiver WRG in Stall 2. gam_offsets verwendet Dezember 2024 und August 2026, als beide Ställe ohne WRG liefen. gam_dec und gam_aug stehen zusätzlich als Einzelmodelle zur Verfügung.

Bei August liegen bereits in den finalen Sensordaten RH-Werte über 100 %. Sie werden weder gekappt noch als neue Skriptfehler kaschiert, sondern in rh_qualitaetskontrolle.csv protokolliert. Bei der Modellierung werden nur endliche RH-Mittel verwendet; fehlende Werte werden nicht imputiert.

Die GAM-Diagnostik ist als PDF und Text gespeichert. Es bestehen Hinweise auf nicht vollständig erfasste zeitliche Struktur. Die bisherigen Glättungsmodelle wurden nicht zu einem vollständigen Zeitreihenmodell mit Autokorrelation umgebaut. Modellkonvergenz und ausgeführte Tests belegen keine validierte kausale WRG-Wirkung; die Bänder sind punktweise modellbedingte Bänder.

## N-Ausscheidung: August 2026 ergänzt, vorläufige Futtergehalte

N-Excretion.R liest jetzt daten/IMPEX_Gfeller_nach MA.xlsx im Projekt. Diese Arbeitsdatei enthält zehn Stall-Kampagnen-Zeilen. Die ursprüngliche Datei im Ordner analysen bleibt unverändert.

Tier-/Futtermengen für August stammen aus den beiden PDFs im Ordner digital_Annex/1-raw-data/Mastauswertungen/August 26. Halle 9500989 ist Stall 1, Halle 9500960 ist Stall 2. Die N-Bilanzen verwenden auf ausdrücklichen Nutzerwunsch vorläufig die Labor-Futtergehalte von 2024. Bestandsfutter wird wie bisher dem Endmastfutter zugerechnet; diese Phase ist im PDF nicht genannt. Bilanzstatus und n_provisional machen die Vorläufigkeit in den Ergebnissen sichtbar.

Saisongewichte: Winter 25 %, Übergang 50 %, Sommer 25 %. Innerhalb der Saison werden Kampagnen gleich gewichtet. Juli und August erhalten je 12,5 %, Februar und Dezember ebenfalls je 12,5 %, April 50 %.

Die Umtriebszahl ist cfg_n$cycles (Standard 8,5). source_cycles beschreibt den Jahresfaktor im Excel und muss bei Änderung von Variante_Proben D23 entsprechend angepasst werden. N pro Umtrieb wird primär aus der entsprechenden Spalte übernommen und genau einmal annualisiert.

Die vollständigen gewichteten Mittelwerte betragen vorläufig 276,106477868759 bzw. 296,469298518499 g N/Tierplatz/Jahr. Je Stall fliessen fünf Kampagnen ein, davon eine vorläufige August-Bilanz.

Dezember und August bleiben beim Stallvergleich mit aktiver WRG ausgeschlossen. Die August-NH3-Menge ist der unkorrigierte kumulierte Messendwert an Tag 33,42. Die N-Bilanz umfasst hingegen die ganze Mast von 35/36 Tagen. Die daraus folgende NH3-N/TAN-Quote hat deshalb keine identische Zeitabdeckung.

daten/N_Bilanz_August2026.csv bleibt als optionale Zusatzdatei leer. August nicht gleichzeitig in Excel und CSV eintragen. Einzelheiten zu Quellen, Mengen, Formeln und Annahmen stehen in daten/README_N_Bilanz_August2026.md.

## Prüfung

work/Pruefung_August_Kampagnen.R prüft fünf geladene Kampagnen, beide August-Ställe, direkte RH-Sensormittel, die Trennung der Modellgruppen und die vorläufigen August-N-Bilanzen. Der spätere August-Import und die Sommergewichtung wurden mit ausdrücklich synthetischen Eingaben in einem separaten Testordner geprüft. Diese Testwerte stehen weder in der echten Eingabevorlage noch in den produktiven Ergebnissen.

work/Pruefung_IMPEX_August2026.py prüft den PDF-/Excel-Import, Formelergebnisse, unveränderte historische Eingaben und den Abgleich der gewichteten Jahresmittel zwischen Excel und R.
