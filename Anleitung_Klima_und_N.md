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

## N-Ausscheidung: August noch ohne Bilanzdaten

Die verfügbaren IMPEX-Dateien enthalten nur acht Stall-Kampagnen-Zeilen aus 2024. Die Augustwerte fehlen für beide Ställe. Die leere Eingabevorlage liegt unter daten/N_Bilanz_August2026.csv. Alternativ kann cfg_n$input auf eine später ergänzte vollständige IMPEX-Datei umgestellt werden.

Das N-Skript erstellt zehn erwartete Zeilen und zeigt August ausdrücklich mit fehlenden Werten. Es ersetzt fehlende Werte nicht durch null oder einen geschätzten Sommerwert. Der vollständige gewichtete Mittelwert über fünf Kampagnen bleibt leer, solange August fehlt. mean_weighted_available beschreibt separat die vorläufige Rechnung mit den vorhandenen Kampagnen.

Saisongewichte sind Winter 25 %, Übergang 50 % und Sommer 25 %. Innerhalb einer Saison werden die Kampagnen je Stall gleich gewichtet. Sobald August verfügbar ist, teilen sich Juli und August das Sommergewicht. Die Gewichte hängen nicht mehr von einer fest codierten Zeilenreihenfolge ab.

Die Umtriebszahl ist cfg_n$cycles, standardmässig 8,5. source_cycles = 8,5 beschreibt den Faktor des bisherigen jährlichen IMPEX-Exports und dient nur zur Rückrechnung bereits annualisierter Eingabespalten. Primär verwendet das Skript die N-Ausscheidung pro Tier und Mastumtrieb und annualisiert sie einmal.

Dezember und August bleiben bei den Stallvergleichen mit aktiver WRG ausgeschlossen. Die NH3-N/TAN-Quoten beruhen weiterhin auf IMPEX, nicht automatisch auf den neu korrigierten Mengen aus emissionen_mettmenstetten.R. Die Prozentgrafik zeigt jetzt korrekt 100 mal den dimensionslosen Anteil.

Die Statusmeldung UNVOLLSTAENDIGE DATEN ist bis zur Ergänzung der August-N-Bilanzen beabsichtigt. Die vorhandenen Ergebnisse und ihre Verfügbarkeit werden trotzdem ausgegeben.

## Prüfung

work/Pruefung_August_Kampagnen.R prüft fünf geladene Kampagnen, beide August-Ställe, direkte RH-Sensormittel, die Trennung der Modellgruppen und den Umgang mit fehlenden N-Bilanzen. Der spätere August-Import und die Sommergewichtung wurden mit ausdrücklich synthetischen Eingaben in einem separaten Testordner geprüft. Diese Testwerte stehen weder in der echten Eingabevorlage noch in den produktiven Ergebnissen.
