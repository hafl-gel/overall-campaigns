# Plausibilitätsprüfung Einstreudaten August 2026

Stand: 29.10.2026. Prüfung ohne Änderung der Gesamtdatei oder Laborwerte.

**Ergebnis:** Die 31 August-Proben sind korrekt zugeordnet und quellengleich übertragen. Die Messwerte zeigen keine groben physikalischen Widersprüche. Vor einer Nährstoffauswertung müssen aber bestehende Einheiten- und Phosphorbezeichnungen bereinigt werden. Einzelne Laborwerte sind innerhalb ihrer Probenahmegruppe auffällig und sollten geprüft werden.

## Quellen und Umfang

- Gesamtdatei: [litter_data_all.xlsx](</Users/stefan/git/overall-campaigns/Einstreu/litter_data_all.xlsx>), Blatt Sheet 1, Zeilen 154–184, Kampagne AUG26.
- Probenahme: [Einstreuproben_Mettmenstetten.xlsx](</Users/stefan/git/mettmenstetten-aug2026/data/Einstreuproben_Mettmenstetten.xlsx>), Blatt Sheet1, A2:E32.
- Labor: [HD_115914_HAFL  Gfeller Stefan_20260927.xlsx](</Users/stefan/git/mettmenstetten-aug2026/data/HD_115914_HAFL  Gfeller Stefan_20260927.xlsx>), Blatt 125956_BFH_Gfeller_20260917, G5:AG35; Parameter und Einheiten in Zeilen 1–3.
- Mastbeginn aus local-times.rds: beide Ställe am 24.07.2026.
- 806 Zuordnungs- und Messwertzellen mit den Quellen abgeglichen; keine Abweichung. Feuchte und N in Frischsubstanz zusätzlich nachgerechnet.
- Alle 31 Probennummern besitzen Laborbefund und Probenahmezuordnung. Keine doppelten Kombinationen aus Kampagne, Stall, Masttag und Wiederholung.
- 13.08., 18.08. und 26.08.2026 entsprechen den Masttagen 21, 26 und 34.
- Stall 1 hat 16, Stall 2 hat 15 Proben. Die zusätzliche Probe 620 ist als Wiederholung 6, Stall 1, Masttag 34 dokumentiert.

## Augustwerte je Stall und Masttag

Arithmetische Mittel der Proben. Die Proben sind keine 31 unabhängigen Ställe oder Kampagnen. Beide Ställe liefen ohne WRG; aus dem Vergleich wird kein WRG-Effekt abgeleitet.

| Stall | Masttag | n | pH | Feuchte [%] | N gesamt [g/kg TS] | NH4-N [g/kg TS] | C/N |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 21 | 5 | 5,81 | 20,02 | 36,70 | 2,20 | 14,36 |
| 1 | 26 | 5 | 6,11 | 27,56 | 41,10 | 2,17 | 12,75 |
| 1 | 34 | 6 | 6,44 | 36,38 | 47,18 | 4,62 | 10,91 |
| 2 | 21 | 5 | 5,96 | 21,10 | 35,76 | 2,04 | 14,57 |
| 2 | 26 | 5 | 6,33 | 31,00 | 40,08 | 2,17 | 12,94 |
| 2 | 34 | 5 | 6,82 | 26,02 | 44,92 | 3,39 | 11,52 |

NH4-N folgt dem Laborparameter «Ammoniumstickstoff». Die Kurzbezeichnung NH4_gkg_TS sollte nicht als Masse des gesamten NH4-Ions interpretiert werden.

Stall 1: Feuchte und N steigen mit dem Mastalter, das C/N-Verhältnis sinkt. Stall 2: Am Tag 34 ist die Einstreu mit 26,02 % mittlerer Feuchte trockener als am Tag 26 (31,00 %) und als Stall 1 am Tag 34 (36,38 %). Der Stallunterschied beträgt am Tag 34 10,36 Prozentpunkte. Alle fünf Tag-34-Proben aus Stall 2 liegen zwischen 25,3 und 27,2 % Feuchte; die Beobachtung hängt nicht an einem Einzelwert. Eine Ursache lässt sich daraus ohne Probenpositionen und weitere Prozessdaten nicht bestimmen.

## Vergleich mit früheren Kampagnen

| Parameter | August 2026: Minimum–Maximum | Frühere Kampagnen: Minimum–Maximum |
|---|---:|---:|
| pH | 5,63–6,89 | 0,52–7,62 |
| moisture_pct | 18,00–39,00 | 15,80–44,70 |
| N_total_gkg_TS | 33,00–49,20 | 7,69–48,00 |
| NH4_gkg_TS | 1,88–5,02 | 0,02–7,02 |
| C/N-Verhältnis | 10,44–15,86 | 9,59–66,89 |
| TS_pct | 61,00–82,00 | 55,30–84,20 |

Historische Spannweiten dienen als interne Orientierung, nicht als validierte Grenzwerte. Kampagnen besitzen unterschiedliche Masttage und Probenzahlen. Im Juli 2024 steht bereits pH 0,52 für Probe 321 (Gesamtdatei F102). Dieser auffällige Wert steht auch in der ursprünglichen Juli-Labordatei P26 und in deren editierter Fassung P22. Er ist kein August-Importfehler und sollte nicht als plausibles Referenzminimum verwendet werden.
- Historische Originalquelle: [HD_116922_HAFL Gfeller Stefan_20241106.xlsx](</Users/stefan/git/mettmenstetten-jul2024/data/HD_116922_HAFL Gfeller Stefan_20241106.xlsx>).

## Rechenkontrollen

- Feuchte = 100 − TS und N_FS = N_TS × TS/100: jeweils alle 31 Werte korrekt.
- N_FS laut Labor weicht maximal 0,0508 g/kg FS vom Ergebnis aus angezeigten gerundeten Eingangswerten ab; alle Abweichungen passen zur angegebenen Stellenzahl.
- C/N = Corg/N_TS: maximale Abweichung 0,016; alle Werte mit der Rundung vereinbar.
- Glühverlust + Asche = 100,0 bis 100,1 %. Kleine Rundungsdifferenz, kein Übertragungsfehler.
- P2O5/P ≈ 2,291 und K2O/K ≈ 1,205: alle Werte innerhalb der Rundungstoleranzen der Eingangswerte.
- NH4-N liegt bei jeder Probe zwischen 0 und Gesamt-N. Keine negativen Gehalte, keine TS- oder Feuchtewerte ausserhalb 0–100 %.
- Corg liegt unter der Trockenmasse; die Summe der Mineralstoffelemente liegt unter dem Aschegehalt, wenn die Laboreinheiten kg/t TS bzw. g/kg TS verwendet werden.
- Corg entspricht weitgehend einer Berechnung aus organischem Anteil mit Faktor 0,58 und ist damit keine unabhängige Bestätigung des Glühverlustes. Probe 618: 87,6 % Glühverlust plus 12,5 % Asche; Corg 507,5 g/kg entspricht (100 − 12,5) × 5,8. Diese kleine Uneinheitlichkeit ist bereits im Laborbefund enthalten.

## Wichtige Bezeichnungsprobleme

**Mineralstoffe N:T: kg/t TS statt g/t TS.** Die Überschriften nennen g/t TS, das Labor weist kg/t TS aus. Die Zahlen folgen unverändert der bisherigen Skala. Eine Interpretation als g/t wäre um Faktor 1000 falsch. Sinnvolle Bereinigung: Überschriften auf kg/t TS oder g/kg TS korrigieren, nicht die Zahlen mit 1000 multiplizieren.

**Spalte V enthält offenbar P2O5_FS statt elementarem P_FS.** Beispiel Probe 431, Zeile 154: 4,77 kg P/t TS × 78,6 % TS = 3,74922 g P/kg FS. V154 enthält 8,59 g/kg, nahe bei 10,94 × 0,786 = 8,59884 g P2O5/kg FS. Diese Bezeichnung stammt schon aus dem Laborfeld AC und tritt auch in den älteren Kampagnen auf. Spalte W ist als Phosphorpentoxid g/kg FS beschriftet, aber leer.

Mögliche spätere Bereinigung: bisherige V-Werte als Labor-P2O5_FS in W erhalten und elementaren P_FS in V aus Q × G/100 berechnen. Die Umrechnung P → P2O5 mit Faktor 2,291 ist in [BAFU/Agroscope: Le phosphore dans les sols, Seite 113](https://www.bafu.admin.ch/dam/fr/sd-web/aAP0-NeynzHD/phosphor_in_boedenstandortbestimmungschweizphosphorinboedendueng.pdf#page=114) dokumentiert.

## Auffällige Einzelproben

Screening innerhalb gleicher Ställe und Masttage: |modifizierter z-Wert| > 3,5 sowie Mindestabweichung vom Median: pH 0,3; TS 4 Prozentpunkte; N 4 g/kg TS; NH4-N 0,8 g/kg TS. Die Schwellen dienen der Priorisierung. Kleine Gruppen und kleine MAD können grosse z-Werte erzeugen; kein Hinweis beweist einen Messfehler. Alle aufgeführten Werte sind im Laborbefund identisch enthalten.

| Probe | Excelzeile | Stall/Tag | Merkmal | Wert | Andere Proben der Gruppe |
|---|---:|---|---|---:|---:|
| 603 | 167 | 1/26 | TS_pct | 69,10 | 72,10–74,00 |
| 603 | 167 | 1/26 | N_total_gkg_TS | 45,00 | 39,40–40,40 |
| 438 | 161 | 2/21 | pH | 6,57 | 5,63–5,91 |
| 606 | 170 | 2/26 | pH | 6,01 | 6,36–6,46 |
| 610 | 174 | 2/34 | NH4_gkg_TS | 2,10 | 3,61–3,90 |

Besonders prüfenswert: Probe 438 mit pH 6,57 gegenüber 5,63–5,91 in den anderen Tag-21-Proben aus Stall 2, Probe 606 mit pH 6,01 gegenüber 6,36–6,46 an Tag 26 sowie Probe 610 mit NH4-N 2,10 gegenüber 3,61–3,90 g/kg TS an Tag 34. Probe 603 ist relativ feucht und hat zugleich höheres N pro TS; diese Kombination kann durch die andere Bezugsmasse verstärkt werden.

Sensitivität: Ohne Probe 610 wäre der NH4-N-Mittelwert von Stall 2 an Tag 34 3,7075 statt 3,386 g/kg TS (+9,5 %). Ohne Probe 438 wäre der pH-Mittelwert von Stall 2 an Tag 21 5,8075 statt 5,96. Die pH-Mittel sind nur deskriptiv, keine Berechnung der Aktivität einer Mischprobe. Es wurden keine Werte entfernt oder geändert.

## Dateien

- Plausibilitaet_August2026_Gruppen.csv: Gruppengrössen, Mittel, Streuung und Spannweiten.
- Plausibilitaet_August2026_Rechenkontrollen.csv: Einzelprüfungen, Residuen und Rundungstoleranzen.
- Plausibilitaet_August2026_Prueffaelle.csv: priorisierte Auffälligkeiten.
- Plausibilitaet_August2026_Kampagnenvergleich.csv: deskriptive Kampagnenkennzahlen.

Die Prüfung bestätigt Zuordnung und Rechenkonsistenz, nicht die analytische Richtigkeit der Laborbestimmungen. Für auffällige Einzelproben wären Labor-Rohprotokolle oder Wiederholungsbestimmungen erforderlich.

## Präzisierung zum Probenahmeverdacht

Der Hinweis bezieht sich auf den Mittelwert der Feuchtigkeit aller fünf Proben aus Stall 2 am Masttag 34 (26,02 %), nicht auf den NH4-N-Einzelwert der Probe 610. Vermutet wird eine für die Einstreu im Stall nicht repräsentative Probenahme. Die Messwerte bleiben unverändert; der Verdacht wurde nicht durch eine Wiederholungsbeprobung bestätigt.
