## Korrigierte Basisdefinition

Stall 1 als Realität und unkorrigierter Vergleich: ausschliesslich Stall 1 aller berücksichtigten Kampagnen liefert die Basis. Nur die mittlere Stallbasis verwendet zusätzlich den korrigierten Stall 2 der Offsetkampagnen, zunächst als Mittel innerhalb der jeweiligen Kampagne. Die Jahresreduktionen sind deshalb nicht mehr identisch. Einzelkampagnenvergleiche beider korrigierter Varianten bleiben dagegen gleich.

# NH3-Auswertung: aktueller Berechnungsstand

Stand: 28.10.2026. Massgebend ist `emissionen_mettmenstetten.R`; aktuelle Ausgaben liegen in `ergebnisse_bericht`. Frühere Ordner `ergebnisse_emissionen` und `ergebnisse_ohne_offset2026` sind historische Szenarien mit anderen Vorgaben und nicht die aktuellen Berichtstabellen.

## Einstellungen und Quellen

Arbeitsverzeichnis: `~/git/overall-campaigns`. `anzahl_umtriebe <- 8.5` ist die änderbare Anzahl Umtriebe pro Jahr. Das Modell setzt ein Tier je Tierplatz und Umtrieb voraus. Winter wird mit 25 %, Frühling/Herbst zusammen mit 50 % und Sommer mit 25 % gewichtet.

Importiert werden ausschliesslich die finalen QD-Datensätze der Kampagnen Februar, April, Juli und Dezember 2024 sowie August 2026. Juli 2025 ist vollständig ausgeschlossen. Dezember 2024 und August 2026 sind Offsetkampagnen: beide Ställe ohne WRG. Die übrigen Kampagnen liefern Stall 1 ohne und Stall 2 mit WRG. Rohdaten und vorgängige Kalibrationsberechnungen werden nicht verändert.

## Bezugsvarianten

Offsetverhältnisse aus ungerundeten kumulierten g/Tier am jeweiligen Kampagnenende:

| Kampagne | Stall 1 [g/Tier] | Stall 2 [g/Tier] | Stall 2 / Stall 1 |
|---|---:|---:|---:|
| Dezember 2024 | 2,3103396176 | 1,7659068842 | 0,7643494795 |
| August 2026 | 0,5634243209 | 0,5836129676 | 1,0358320468 |

Das arithmetische Mittel der Verhältnisse ist `r = 0,900090763168022`. Es wird nicht das Mittel der inversen Korrekturfaktoren gebildet. Diese Definition gilt für beide Varianten:

1. **Stall 1 als Realität:** Stall 1 bleibt unverändert; Stall 2 wird mit `1/r = 1,11099906911646` multipliziert.
2. **Realität im Mittel beider Ställe:** Stall 1 wird mit `f = (1+r)/2 = 0,950045381584011` multipliziert; Stall 2 mit `f/r = 1,05549953455823`.

Bei einzelnen WRG-Kampagnen skaliert die gemeinsame Bezugsbasis beide Mengen mit demselben zusätzlichen Faktor. Dort bleibt die prozentuale Reduktion gleich. Im Jahresmittel unterscheiden sich zusätzlich die für die Basis verwendeten Stallmessungen; die Jahresreduktion kann sich deshalb ändern. Die Verhältnisfaktoren aus g/Tier werden konsistent auch auf die in Tabelle 4 ausgewiesenen kg-Mengen angewandt. Die beiden separaten kg-Gesamtmengenverhältnisse werden dafür nicht zusätzlich verwendet.

## Quadratische Extrapolation

Die Tagesstützpunkte werden aus den ungerundeten Quelldaten berechnet: letzter kumulierter kg-Wert pro Masttag / mittlere Tierzahl dieses Tages × 1000. Die x-Koordinate ist das tatsächliche Intervallende seit Einstallung. Das entspricht dem bisher erstellten R-Modell; es ist nicht die gerundete Tagesstützpunkt-Tabelle des Excel.

Je Kampagne und Stall werden die letzten acht Tagesstützpunkte einschliesslich des unvollständigen letzten Masttags verwendet. Der Fit ist

`E(d) = c + b * (d - x0) + a * (d - x0)^2`,

wobei x0 die letzte gemessene Tagesstützstelle ist. Es handelt sich um eine freie quadratische OLS-Regression mit Achsenabschnitt. Sie wird nicht am letzten Messwert verankert. Deshalb kann der Fitwert am Übergang leicht vom letzten Messwert abweichen; z.B. August Stall 1: Fit 0,54555 statt Tagesendwert 0,56337 g/Tier. Diese Differenz wird nicht verdeckt oder korrigiert. Innerhalb des Messbereichs werden die beobachteten Tageswerte linear interpoliert; ausschliesslich danach wird der Fit verwendet.

`quadratische_extrapolation_alle.png` zeigt die fünf Kampagnen vor der Offsetskalierung. Offene Punkte: Tageswerte. Ausgefüllte Punkte: acht Fitstützpunkte. Durchgezogene Kurve: quadratischer Fit im beobachteten Bereich. Gestrichelte Kurve: Extrapolation. Kreuze: tatsächlich für die Schlachttagverteilung verwendete Werte. Senkrechte Linie: Messende. Die letzten beiden Augustkurven kreuzen sich in der Extrapolation; dies ist ein Modellergebnis, keine zusätzliche Messung.

Die Grafik reicht bis Tag 37, die Rechnung verwendet maximal Endtag 36,25. Die acht Schlachttaganteile 18/2/6/6/4/2/51/11 % werden den Endtagen 29/30/31/32/33,5/34,25/35,25/36,25 zugeordnet. Der Fit liefert keine Konfidenzintervalle. Ein erheblicher Teil der Verteilung liegt nach dem Messende; die Jahreswerte sind entsprechend modellabhängig.

Die vollständigen Stützpunkte, Koeffizienten, Fit-RMSE und tatsächlich verwendeten Prognosen werden separat als ungerundete CSV-Dateien ausgegeben. Die Bezugsvarianten multiplizieren die gesamte jeweilige Kurve mit ihrem konstanten Stallfaktor; eine neue Regression nach Skalierung ist mathematisch nicht notwendig.

## Basisgewichtung: beide Ställe der Offsetkampagnen

Für Stall 1 als Realität und den unkorrigierten Vergleich wird ausschliesslich Stall 1 zur Basis verwendet. Nur für die Mittelwert-Variante gilt die folgende Mittelung beider Ställe: Zuerst werden beide Ställe auf die gewünschte Bezugsbasis korrigiert. Bei den beiden Offsetkampagnen wird dann je Kampagne der Mittelwert beider Ställe verwendet. In den WRG-Kampagnen kann nur Stall 1 zur Basis beitragen. Anschliessend werden die Kampagnen innerhalb der jeweiligen Saison gleich gewichtet, zuletzt die Saisonanteile angewandt.

| Basisbeitrag der Mittelwert-Variante | Anteil am Jahresmittel |
|---|---:|
| Februar 2024 Stall 1 | 12,5 % |
| Dezember 2024 Stall 1 | 6,25 % |
| Dezember 2024 Stall 2, korrigiert | 6,25 % |
| April 2024 Stall 1 | 50 % |
| Juli 2024 Stall 1 | 12,5 % |
| August 2026 Stall 1 | 6,25 % |
| August 2026 Stall 2, korrigiert | 6,25 % |

Die beiden Stallmessungen einer Offsetkampagne zählen damit nicht als zwei selbständige Kampagnen. Winter und Sommer bleiben bei jeweils 25 %. Für die WRG-Menge gelten Februar 25 %, April 50 %, Juli 25 %. Offsetkampagnen liefern keine WRG-Menge und keine gemessene WRG-Reduktion. Die unterschiedlichen Kampagnensätze können Jahres-/Herdeneffekte enthalten.

## Berichtstabellen und Ergebnisse

`Berichtstabellen.html` enthält für beide Varianten die Tabellen 4 und 6 in der Struktur der hochgeladenen Berichtsausschnitte. Jede Tabelle liegt zusätzlich als PNG und CSV vor.

- Tabelle 4: gemessene kumulierte Mast-Endmengen in kg und g/Tier, korrigiert auf die jeweilige Bezugsbasis, dazu Reduktion auf Basis der ungerundeten g/Tier.
- Tabelle 6: Schlachttag-gewichtete und saisongewichtete Jahresmengen; die Einheit ist ausdrücklich g NH3/Tierplatz/Jahr. Die Umtriebszahl wird einmal angewandt.

| Variante | Basis [g/Platz/Jahr] | WRG [g/Platz/Jahr] | Einsparung [g/Platz/Jahr] | Reduktion |
|---|---:|---:|---:|---:|
| Stall 1 als Realität | 20,19095229 | 9,07665173 | 11,11430056 | 55,04594533 % |
| Gemeinsame mittlere Basis | 18,99131731 | 8,62323106 | 10,36808625 | 54,59382349 % |

Massgebend für volle Präzision ist `tabelle6_ungerundet.csv`, nicht die dargestellte Rundung dieser Anleitung. Im Skript wird nur in den Berichtszellen gerundet.

**Unsicherheiten:** Die ±-Angaben aus den Screenshots werden nicht auf die neue Rechnung übertragen. Die Excel-Formeln kombinieren pauschale relative Fehler (Fan 5,5 %, Xnode 15 %) und behandeln u.a. die Reduktionsunsicherheit proportional zur Reduktion. Damit ist keine validierte Unsicherheit für gemittelte Offsets, gemeinsam korrigierte Ställe, saisonale Mittel und quadratische Extrapolation bestimmt. Die neuen Tabellen enthalten deshalb überprüfte Punktschätzer ohne ±. Für wissenschaftlich interpretierbare Unsicherheitsintervalle braucht es eine festgelegte Behandlung gemeinsamer Kalibrationsfehler, Kovarianzen und zeitlicher Abhängigkeit. Es werden keine scheinpräzisen Fehlergrenzen ergänzt.

## Validierung

`work/Pruefung_Bericht.R` führt die vollständige Auswertung aus und prüft: direkte Rekonstruktion der Extrapolationswerte aus den exportierten Koeffizienten, korrekte Einzel- und Saisongewichte, Mittelung beider Offsetställe innerhalb der Kampagne, Endmengen in Tabelle 4 und Invarianz der relativen Reduktion bei gemeinsamer Skalierung. Zeitbasis und Kontinuität der gespeicherten Kumulierung werden separat geprüft; das ist kein Nachweis vollständiger unabhängiger Messabdeckung. Coverage steht in `datenqualitaet.csv`.

## Ausgaben mit geänderten Parametern aktualisieren

Die Parameter stehen am Anfang von emissionen_mettmenstetten.R. Nach Änderungen das vollständige Skript ausführen, nicht nur ausgewählte Abschnitte. Bei erfolgreichem Lauf werden alle 48 vom Skript erzeugten Dateien in ergebnisse_bericht neu geschrieben: Tabellen, CSV, Fitgrafiken, Parameter und Kontrolldateien. Erläuterungstexte zu Saisongewichten, Offsetfaktoren, Umtriebszahl, Belegung und Anzahl Fitpunkte werden aus den tatsächlichen Parametern erzeugt.

In laufstatus.txt muss ERFOLGREICH stehen; GESTARTET ohne Abschluss kennzeichnet einen nicht vollständig beendeten Lauf. ausgabedateien.csv listet die neu geschriebenen Dateien, laufparameter.rds speichert zusätzlich Kampagnenauswahl und Schlachttagverteilung. include_annual steuert den Einbezug in Jahresmittel; die Offsetbestimmung verwendet weiterhin die als Offsetkampagnen definierten Datensätze.

Die Einlesequelle bleibt final-dataset.qd der jeweiligen Kampagne. Eine Änderung von Sensor-Kalibrationsparametern muss zuerst in deren Kampagnenauswertung zu einer aktualisierten QD-Datei verarbeitet werden. Rohdatenkalibration, Rmd/PDF-Reports, Szenario ohne August, Lüftungsvergleich und Rohwertdiagnose sind eigene Skripte und werden nicht durch das Hauptskript neu berechnet.

Geprüft wurden ein vollständiger Lauf mit 8,5 Umtrieben und 25/50/25 sowie ein separater Testlauf mit 9,5 Umtrieben und 30/40/30; alle erzeugten Dateien, dynamische Berichtstexte und unabhängig aggregierte Jahreswerte wurden abgeglichen. Die produktiven Einstellungen bleiben bei 8,5 und 25/50/25.

## Tabelle 5 und Methodenvergleich

Tabelle 5 für Dezember 2024 und Juli/August 2026 wird im Hauptlauf neu erstellt (PNG, CSV und HTML). Die Messfehler-Konvention aus Excel ist über uncertainty_fan und uncertainty_xnode einstellbar; keine neuen Konfidenzintervalle. Die Hauptrechnung verwendet voreingestellt den freien quadratischen Fit; der lineare Trend der letzten fünf Tagesraten ist jetzt ebenfalls im Hauptskript auswählbar. Der separate Rücktest alternativer Extrapolationen wird mit extrapolation_vergleich.R gestartet; Ergebnisse und Grenzen stehen in vergleich_extrapolation/Extrapolationsvergleich.md.


## Messfehler und Extrapolation im Einstellungsteil

`uncertainty_fan = 0.055` und `uncertainty_xnode = 0.15` sind relative Fehler (5,5 % und 15 %). Für die Rohmengen in Tabelle 5 gilt `u = sqrt(uncertainty_fan^2 + uncertainty_xnode^2)`, aktuell 15,9765 %. Die angezeigte absolute Unsicherheit ist Menge mal u.

Für die ergänzten prozentualen Stallunterschiede steuert `offset_difference_error` die Konvention. Mit r = Stall 2 / Stall 1 und d = 100 × (r − 1) gilt:

- `"excel_legacy"` (Voreinstellung): ± |d| × sqrt(2) × u. Dies reproduziert die bisherige Excelkonvention, ist aber keine reguläre Fehlerfortpflanzung des Quotienten.
- `"ratio_independent"`: ± 100 × r × sqrt(2) × u. Dies ist die lineare Fehlerfortpflanzung unter der Annahme unabhängiger Stallfehler. Gemeinsame Kalibrationsfehler und Kovarianzen sind darin nicht berücksichtigt.

Die ±-Beträge zu den prozentualen Unterschieden sind Prozentpunkte und keine Konfidenzintervalle. Beide berechneten Varianten stehen ungerundet in `tabelle5_stallunterschiede.csv`; die Einstellung bestimmt den Begleittext in `tabelle5_begleittext.txt` und im HTML-Bericht. Die Fehlerparameter beeinflussen keine Punktschätzer, Offsetfaktoren oder Jahresmittel. Für Tabellen 4 und 6 werden weiterhin keine neuen Unsicherheiten ohne ein Modell für Offset-, Mittelungs- und Extrapolationsfehler behauptet.

Mit `extrapolation_method = "linear_rate"` wird die neue Methode für alle Prognosen, Schlachttagwerte, Jahresmittel und Fitgrafiken aktiv. `rate_fit_points = 5` bestimmt die Zahl der letzten Tagesraten. Jede Rate entsteht aus der Differenz zweier kumulierter Tageswerte geteilt durch den tatsächlichen Zeitabstand. Ein linearer Trend wird an den Intervallmitten angepasst und ab dem letzten gemessenen kumulierten Wert integriert. Negative prognostizierte Raten werden auf null begrenzt; gemessene kumulierte Werte werden dadurch nicht verändert. Innerhalb des Messbereichs bleibt die lineare Interpolation bestehen.

Voreingestellt bleibt `extrapolation_method = "quadratic_free"` mit `fit_points = 8`. `extrapolation_alle.png` zeigt die tatsächlich gewählte Methode. `quadratische_extrapolation_alle.png` bleibt als kompatibler Dateiname bestehen und enthält ebenfalls die gewählte Methode. Bei der Ratenmethode enthält `fit_tagesraten.csv` die tatsächlichen Ratenstützpunkte. Der Fit-RMSE hat dort die Einheit g/Tier/Tag; beim kumulierten quadratischen Fit g/Tier.

Beide Methoden wurden vollständig ausgeführt. Für die neue Methode stimmen alle 30 mit dem separaten Methodenvergleich gemeinsamen Prognosen bis auf weniger als 1e-10 g/Tier überein; alle zehn Reihen schliessen exakt an ihrem gemessenen Endwert an. Der produktive Bericht bleibt mit der voreingestellten quadratischen Methode berechnet.
