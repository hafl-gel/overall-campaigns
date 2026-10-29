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

## Extrapolation: neue Standardmethode und bisherige Alternative

Standard ist `extrapolation_method = "linear_rate"` mit `rate_fit_points = 5`. Die Tagesstützpunkte entstehen aus dem letzten kumulierten kg-Wert je Masttag geteilt durch die mittlere Tierzahl dieses Tages, mal 1000. Die x-Koordinate ist das tatsächliche Intervallende seit Einstallung. Aus den letzten sechs Stützpunkten werden fünf Raten als Mengendifferenz geteilt durch den tatsächlichen Zeitabstand berechnet. An deren Intervallmitten wird ein linearer Trend geschätzt und ab dem letzten gemessenen kumulierten Wert integriert. Prognostizierte negative Raten werden auf null begrenzt. Der Anschluss an den letzten Messwert ist exakt stetig.

Die bisherige Alternative bleibt `extrapolation_method = "quadratic_free"` mit `fit_points = 8`. Diese freie quadratische OLS-Regression wird an die letzten acht kumulierten Tageswerte angepasst und kann am letzten Messwert einen kleinen Sprung aufweisen. Beide Methoden verwenden innerhalb der Messdauer die interpolierten Tageswerte; nur nach dem Messende wird extrapoliert.

`extrapolation_alle.png` und die Einzelgrafiken zeigen die tatsächlich aktive Methode vor der Stalloffset-Korrektur. Offene Punkte sind Tageswerte, ausgefüllte Punkte die für den Fit benötigten Tagesstützpunkte, die gestrichelte Linie ist die Extrapolation und Kreuze sind die tatsächlich verwendeten Schlachttagwerte. `quadratische_extrapolation_alle.png` bleibt als kompatibler Dateiname erhalten und zeigt ebenfalls die aktive Methode.

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

`Berichtstabellen.html` enthält Tabelle 5 und für beide Varianten die Tabellen 4 und 6 in der Struktur der hochgeladenen Berichtsausschnitte. Jede Tabelle liegt zusätzlich als PNG und CSV vor.

- Tabelle 4: gemessene kumulierte Mast-Endmengen in kg und g/Tier, korrigiert auf die jeweilige Bezugsbasis, dazu Reduktion auf Basis der ungerundeten g/Tier.
- Tabelle 6: Schlachttag-gewichtete und saisongewichtete Jahresmengen; die Einheit ist ausdrücklich g NH3/Tierplatz/Jahr. Die Umtriebszahl wird einmal angewandt.

| Variante | Basis [g/Platz/Jahr] | WRG [g/Platz/Jahr] | Einsparung [g/Platz/Jahr] | Reduktion |
|---|---:|---:|---:|---:|
| Stall 1 als Realität | 20,16 ± 1,76 | 9,16 ± 1,71 | 11,00 ± 2,30 | 54,57 ± 8,90 % |
| Gemeinsame mittlere Basis | 18,97 ± 2,03 | 8,70 ± 1,10 | 10,27 ± 2,67 | 54,13 ± 8,97 % |

Massgebend für volle Präzision ist `tabelle6_ungerundet.csv`, nicht die dargestellte Rundung dieser Anleitung. Im Skript wird nur in den Berichtszellen gerundet.

**Messfehler:** Alle Berichtstabellen (4, 5 und 6), Kampagnenvergleiche und Jahresmittel enthalten ±-Angaben. Die relativen Eingangsmessfehler werden durch die vollständige Stallkorrektur, Mittelung und Saisonrechnung fortgepflanzt. Gemeinsam genutzte Offsetfaktoren erzeugen abhängige Fehler und werden entsprechend berücksichtigt. Die ausgegebenen Fehler sind keine Konfidenzintervalle und enthalten keine zusätzliche Unsicherheit aus der Extrapolation oder saisonaler Repräsentativität. Die Annahmen und die auswählbare Excelkonvention für prozentuale Reduktionen stehen unten.

## Validierung

Die Rechenkontrolle berücksichtigt beide auswählbaren Extrapolationsmethoden. Für den Ratenstandard werden die verwendeten Prognosen unabhängig über die geschlossene Stammfunktion der nichtnegativen linearen Rate rekonstruiert.

`work/Pruefung_Bericht.R` führt die vollständige Auswertung aus und prüft: direkte Rekonstruktion der Extrapolationswerte aus den exportierten Koeffizienten, korrekte Einzel- und Saisongewichte, Mittelung beider Offsetställe innerhalb der Kampagne, Endmengen in Tabelle 4 und Invarianz der relativen Reduktion bei gemeinsamer Skalierung. Zeitbasis und Kontinuität der gespeicherten Kumulierung werden separat geprüft; das ist kein Nachweis vollständiger unabhängiger Messabdeckung. Coverage steht in `datenqualitaet.csv`.

## Ausgaben mit geänderten Parametern aktualisieren

Die Parameter stehen am Anfang von emissionen_mettmenstetten.R. Nach Änderungen das vollständige Skript ausführen, nicht nur ausgewählte Abschnitte. Bei erfolgreichem Lauf werden alle 52 vom Skript erzeugten Dateien in ergebnisse_bericht neu geschrieben: Tabellen, CSV, Fitgrafiken, Parameter und Kontrolldateien. Erläuterungstexte zu Saisongewichten, Offsetfaktoren, Umtriebszahl, Belegung und Anzahl Fitpunkte werden aus den tatsächlichen Parametern erzeugt.

In laufstatus.txt muss ERFOLGREICH stehen; GESTARTET ohne Abschluss kennzeichnet einen nicht vollständig beendeten Lauf. ausgabedateien.csv listet die neu geschriebenen Dateien, laufparameter.rds speichert zusätzlich Kampagnenauswahl und Schlachttagverteilung. include_annual steuert den Einbezug in Jahresmittel; die Offsetbestimmung verwendet weiterhin die als Offsetkampagnen definierten Datensätze.

Die Einlesequelle bleibt final-dataset.qd der jeweiligen Kampagne. Eine Änderung von Sensor-Kalibrationsparametern muss zuerst in deren Kampagnenauswertung zu einer aktualisierten QD-Datei verarbeitet werden. Rohdatenkalibration, Rmd/PDF-Reports, Szenario ohne August, Lüftungsvergleich und Rohwertdiagnose sind eigene Skripte und werden nicht durch das Hauptskript neu berechnet.

Geprüft wurden ein vollständiger Lauf mit 8,5 Umtrieben und 25/50/25 sowie ein separater Testlauf mit 9,5 Umtrieben und 30/40/30; alle erzeugten Dateien, dynamische Berichtstexte und unabhängig aggregierte Jahreswerte wurden abgeglichen. Die produktiven Einstellungen bleiben bei 8,5 und 25/50/25.

## Tabelle 5 und Methodenvergleich

Tabelle 5 für Dezember 2024 und Juli/August 2026 wird im Hauptlauf neu erstellt (PNG, CSV und HTML). Die Messfehler-Konvention aus Excel ist über uncertainty_fan und uncertainty_xnode einstellbar; keine neuen Konfidenzintervalle. Die Hauptrechnung verwendet standardmässig den linearen Trend der letzten fünf Tagesraten. Der freie quadratische Fit bleibt als Alternative auswählbar. Der separate Rücktest alternativer Extrapolationen wird mit extrapolation_vergleich.R gestartet; Ergebnisse und Grenzen stehen in vergleich_extrapolation/Extrapolationsvergleich.md.


## Messfehler und Extrapolation im Einstellungsteil

`uncertainty_fan = 0.055` und `uncertainty_xnode = 0.15` sind relative Fehler (5,5 % und 15 %). Für die Rohmengen in Tabelle 5 gilt `u = sqrt(uncertainty_fan^2 + uncertainty_xnode^2)`, aktuell 15,9765 %. Die angezeigte absolute Unsicherheit ist Menge mal u.

Für die ergänzten prozentualen Stallunterschiede steuert `offset_difference_error` die Konvention. Mit r = Stall 2 / Stall 1 und d = 100 × (r − 1) gilt:

- `"excel_legacy"` (bisherige Alternative): ± |d| × sqrt(2) × u. Dies reproduziert die bisherige Excelkonvention, ist aber keine reguläre Fehlerfortpflanzung des Quotienten.
- `"ratio_independent"` (neuer Standard): ± 100 × r × sqrt(2) × u bei unabhängigen Stallfehlern. Für den Rohvergleich in Tabelle 5 wird bei anderer Stallkorrelation der Faktor sqrt(2) durch sqrt(2 × (1 − Stallkorrelation)) ersetzt. Für korrigierte Kampagnen und Jahreswerte werden gemeinsame Offsets und eingestellte Korrelationen vollständig fortgepflanzt.

Die ±-Beträge zu den prozentualen Unterschieden sind Prozentpunkte und keine Konfidenzintervalle. Beide berechneten Varianten stehen ungerundet in `tabelle5_stallunterschiede.csv`; die Einstellung bestimmt den Begleittext in `tabelle5_begleittext.txt` und im HTML-Bericht. Die Fehlerparameter beeinflussen keine Punktschätzer oder Offsetfaktoren; sie bestimmen die ±-Angaben der Kampagnen- und Jahreswerte. Die Messfehler in Tabellen 4 und 6 werden nun mit demselben Eingangsmessfehler berechnet und durch die Offset- und Mittelungsrechnung fortgepflanzt. Extrapolationsfehler sind darin nicht enthalten.

Mit dem neuen Standard `extrapolation_method = "linear_rate"` ist die Ratenmethode für alle Prognosen, Schlachttagwerte, Jahresmittel und Fitgrafiken aktiv. `rate_fit_points = 5` bestimmt die Zahl der letzten Tagesraten. Jede Rate entsteht aus der Differenz zweier kumulierter Tageswerte geteilt durch den tatsächlichen Zeitabstand. Ein linearer Trend wird an den Intervallmitten angepasst und ab dem letzten gemessenen kumulierten Wert integriert. Negative prognostizierte Raten werden auf null begrenzt; gemessene kumulierte Werte werden dadurch nicht verändert. Innerhalb des Messbereichs bleibt die lineare Interpolation bestehen.

Als bisherige Alternative steht `extrapolation_method = "quadratic_free"` mit `fit_points = 8` bereit. `extrapolation_alle.png` zeigt die tatsächlich gewählte Methode. `quadratische_extrapolation_alle.png` bleibt als kompatibler Dateiname bestehen und enthält ebenfalls die gewählte Methode. Bei der Ratenmethode enthält `fit_tagesraten.csv` die tatsächlichen Ratenstützpunkte. Der Fit-RMSE hat dort die Einheit g/Tier/Tag; beim kumulierten quadratischen Fit g/Tier.

Beide Methoden wurden vollständig ausgeführt. Für die neue Methode stimmen alle 30 mit dem separaten Methodenvergleich gemeinsamen Prognosen bis auf weniger als 1e-10 g/Tier überein; alle zehn Reihen schliessen exakt an ihrem gemessenen Endwert an. Die produktiven Berichte mit und ohne August 2026 werden mit dem neuen Standard der Ratenmethode und regulärer Fehlerfortpflanzung berechnet.


## Messfehler in sämtlichen Berichtstabellen

Die zentrale Datei `messfehler_mettmenstetten.R` wird vom Hauptskript automatisch eingelesen. Sie verwendet dieselben Rohendmengen, Schlachttagwerte, Offsetverhältnisse, Stallfaktoren und saisonalen Gewichte wie die Punktrechnung. Die Endmengen beider Offsetkampagnen und die gesamte jeweilige Kurve erhalten je Kampagne/Stall denselben multiplikativen Messfehler. Dadurch werden innerhalb einer Kampagne weder Tageswerte noch Schlachttagwerte als unabhängige Wiederholungen gezählt. Die Umtriebszahl wird als fest vorgegeben behandelt.

Im Einstellungsteil gelten:

- `uncertainty_fan = 0.055`, `uncertainty_xnode = 0.15`: quadratische Kombination zum relativen Eingangsmessfehler, Fan und Xnode voneinander unabhängig angenommen.
- `measurement_campaign_correlation = 0`: Messfehler verschiedener Kampagnen zunächst unabhängig angenommen. Ein Wert von 1 beschreibt einen über Kampagnen gemeinsamen Fehler desselben Stalls. Bei 0 reduziert die Mittelung unabhängiger Kampagnen einen Teil des Messfehlers; die gemeinsame Offsetunsicherheit reduziert sich nicht nochmals durch mehrere WRG-Kampagnen.
- `measurement_barn_correlation = 0`: Messfehler beider Ställe zunächst unabhängig angenommen. 1 bedeutet einen gemeinsamen Fehler beider Ställe. Zwischenwerte sind erlaubt. Die gesamte Korrelationsmatrix ist das Produkt aus Kampagnen- und Stallkorrelation.
- `reduction_error = "ratio_independent"` (neuer Standard): 100 mal absoluter Quotientenfehler. `"excel_legacy"` bleibt als bisherige Alternative erhalten und verwendet den relativen Quotientenfehler mal Betrag der Reduktion. Trotz dieses kompatiblen Optionsnamens berücksichtigt die neue Fortpflanzung die eingestellten Korrelationen und gemeinsam genutzten Offsets.
- `offset_difference_error = "ratio_independent"` (neuer Standard): dieselbe Wahl für den beschreibenden Roh-Stallunterschied in Tabelle 5, getrennt von den WRG-Reduktionen einstellbar.

Die neuen Annahmen sind ausdrücklich Modellvorgaben; aus den gelieferten Daten ist die Korrelation gemeinsamer Kalibrationsfehler nicht bestimmt. Ein unabhängiger Eingangsmessfehler je Kampagne ist daher keine nachgewiesene Eigenschaft der Sensoren. Wer persistierende Kalibrationsfehler annimmt, kann die Kampagnenkorrelation entsprechend erhöhen. Alle Ergebnistabellen nennen die tatsächlich verwendeten Einstellungen.

Die Fortpflanzung verwendet die Ableitungen aller Ergebnisgrössen nach den multiplikativen Eingangsmessungen und die Kovarianzmatrix: `Fehler = sqrt(J * Kovarianz * J')`. Die Ableitungen werden mit zwei Schrittweiten geprüft. Der Offset wird bei jeder Störung neu aus den ungerundeten Endwerten berechnet. So werden z.B. die gemeinsame mittlere Stallskalierung und deren Aufhebung in einem Quotienten korrekt berücksichtigt. Die lineare Fortpflanzung ist eine Näherung, keine Simulation einer Wahrscheinlichkeitsverteilung.

`messfehler_fortpflanzung.csv` enthält alle Punktschätzer, regulär fortgepflanzte Fehler und die jeweils verwendete Fehlerkonvention; bei prozentualen Reduktionen zusätzlich die Excelkonvention. `messfehler_kovarianz.csv` dokumentiert die angenommene Eingangskovarianz. `messfehler_konvention.txt` enthält die Erläuterung für den Bericht. In den übrigen ungerundeten Ergebnis-CSV stehen Werte und Fehler in getrennten numerischen Spalten mit der Endung `_error`; im HTML, den Berichtstabellen-CSV und PNG stehen sie als `Wert ± Fehler`.

Auch `emissionen_ohne_offset2026.R` verwendet jetzt dieselbe aktuelle Rechnung und dieselben Einstellungen wie das Hauptskript. Es lässt August 2026 vollständig aus der Basis und der Offsetbestimmung weg und erzeugt die Tabellen mit Messfehlern im separaten Ordner `ergebnisse_bericht_ohne_august2026`. Es wird separat gestartet; der normale Hauptlauf verändert dieses Szenario nicht.


## Aktuelle Standardwerte und Rückkehr zu früheren Methoden

```r
extrapolation_method = "linear_rate"
rate_fit_points = 5
offset_difference_error = "ratio_independent"
reduction_error = "ratio_independent"
```

Für die bisherige Methode die drei Auswahlen auf `"quadratic_free"`, `"excel_legacy"` und `"excel_legacy"` setzen; der dafür nötige Wert `fit_points = 8` bleibt definiert. Die Punktrechnung und die Fehlerkonvention können auch einzeln umgestellt werden. Die Annahmen zu Messfehlerkorrelationen bleiben explizite Einstellungen; aus den verfügbaren Daten lässt sich kein neuer Korrelationswert ableiten.


## Welche Kampagnen stehen hinter den Jahreswerten?

Die Berichte nennen direkt unter Tabelle 6 je Variante die verwendeten Kampagnen, Ställe und deren Anteile am Jahresmittel. Die Kampagnenzahlen stehen auch in Tabelle 6. `herkunft_jahreswerte.csv` enthält diese Zuordnung mit den ungerundeten Gewichten.

- **Offsetkorrektur mit August 2026 (2 Kampagnen):** Dezember 2024 und August 2026, jeweils Stall 1 und Stall 2 ohne WRG. Je Kampagne wird aus den kumulierten Endemissionen pro Tier das Verhältnis Stall 2 / Stall 1 berechnet; beide Verhältnisse werden gleich gewichtet gemittelt. Dieser Offset wird in beiden korrigierten Varianten verwendet.
- **Basis, Stall 1 als Realität (5 Kampagnen):** ausschliesslich Stall 1 aus Februar, April, Juli und Dezember 2024 sowie August 2026.
- **Basis, mittlere Stallbasis (5 Kampagnen):** korrigierter Stall 1 aus Februar, April und Juli 2024; für Dezember 2024 und August 2026 jeweils das Mittel beider auf die mittlere Bezugsbasis korrigierten Ställe. Die beiden Stallmessungen erhöhen die Kampagnenzahl nicht.
- **Mit WRG (3 Kampagnen):** Stall 2 aus Februar, April und Juli 2024, korrigiert auf die jeweilige Bezugsbasis. Der unkorrigierte Vergleich verwendet dieselben Kampagnen mit rohen Stall-2-Werten.

Ohne August 2026 werden nur Dezember 2024 für den Offset (1 Kampagne) und Februar, April, Juli und Dezember 2024 für die Basis (4 Kampagnen) verwendet. Die WRG-Menge beruht weiterhin auf Februar, April und Juli 2024 (3 Kampagnen). Die Erklärungstexte werden aus der tatsächlich aktiven Kampagnenauswahl und den berechneten Einzelgewichten erzeugt.
