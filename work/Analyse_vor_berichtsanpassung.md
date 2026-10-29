# NH₃-Emissionen Mettmenstetten – Analyse und R-Auswertung

Stand: 28. Oktober 2026. Die Originaldateien wurden nicht verändert.

## Ergebnis unter den eingestellten Annahmen

Alle Mengen in **g NH₃ pro Tierplatz und Jahr**. Modellannahme: 8,5 Umtriebe und ein Tier je Tierplatz und Umtrieb. Die Umrechnung übernimmt damit die Logik des Excel; tatsächliche Stallkapazität, Auslastung, Verluste und Leerstand sind damit nicht separat nachgewiesen.

| Offset-Variante | Basis ohne WRG | Mit WRG | Einsparung | Reduktion |
|---|---:|---:|---:|---:|
| Winteroffset, Bezug Stall 1 | 20,74 | 11,25 | 9,49 | 45,77 % |
| Sommeroffset, Bezug Stall 1 | 20,74 | 8,30 | 12,44 | 59,98 % |
| Mittel beider Offsets, Bezug Stall 1 | 20,74 | 9,55 | 11,19 | 53,95 % |
| Mittel beider Offsets, gemeinsame Basis | 19,71 | 9,08 | 10,63 | 53,95 % |

Dies sind Modellwerte, keine statistisch abgesicherten Wirkungsschätzer. Beide gewünschten Varianten werden berechnet: Bezug auf den unveränderten Stall 1 und Bezug auf die gemeinsame mittlere Stallbasis. Alle Annahmen sind im Skript änderbar.

### Ergebnisse je Kampagne: mittlerer Offset, gemeinsame Basis

Die Jahreswerte je Kampagne sind Hochrechnungen auf 8,5 vergleichbare Umtriebe. Sie sind keine gemessenen Jahresbilanzen und auch keine bereits saisongewichteten Beiträge.

| Kampagne | Basis | Mit WRG | Einsparung | Reduktion |
|---|---:|---:|---:|---:|
| Februar 2024 | 20,81 | 9,33 | 11,48 | 55,17 % |
| April 2024 | 17,61 | 7,27 | 10,34 | 58,73 % |
| Juli 2024 | 35,83 | 10,63 | 25,20 | 70,33 % |
| Dezember 2024 | 21,10 | – | – | Offsetkampagne |
| August 2026 | 5,29 | – | – | Offsetkampagne |

Bei Offsetkampagnen waren beide Ställe ohne WRG. Ihre Unterschiede sind deshalb keine gemessene WRG-Wirkung. Die vorhandenen Endwerte beider Ställe der fünf berücksichtigten Kampagnen stehen zusätzlich in `gemessene_endwerte.csv`.

## Was die Excel-Datei berechnet

Quelle: `Korrektur_Emissionen_Mettmenstetten_neue-Kalibration.xlsx` im vom Nutzer angegebenen Dokumentenordner.

1. **Erstes Blatt:** Gesamtverluste in kg und kumulierte Verluste in g/Tier. Der Dezemberoffset ist proportional: Stall 2 wird mit `2,31 / 1,77 = 1,3051` korrigiert (I8:I9, J3/J5/J7). Der Offset der kg-Gesamtmengen ist ein anderer Faktor und darf nicht mit dem g/Tier-Faktor vermischt werden.
2. **Saisongewichtung:** Basis: Februar 12,5 %, April 50 %, Juli 25 %, Dezember 12,5 %. WRG: Februar 25 %, April 50 %, Juli 25 %. Jahreswerte entstehen durch Multiplikation mit 8,5 Umtrieben (B20).
3. **Zweites Blatt:** Die Werte sind **kumulierte g NH₃/Tier bis zum jeweiligen Masttag**. Der tägliche Zuwachs wäre die Differenz aufeinanderfolgender Werte. Spalte A enthält verstrichene Mastdauer, Spalte B den Schlachttag. Beide sind nicht identisch.
4. **Extrapolation:** Ab Zeile 17 wird eine quadratische Regression auf die letzten acht kumulierten Messwerte A9:A16 angewendet. Das entspricht in R `lm(ef ~ t + I(t^2))`, mit Zentrierung am letzten Stützpunkt. Es handelt sich nicht um eine exponentielle Kurve.
5. **Masttagverteilung:** 18/2/6/6/4/2/51/11 % an Schlachttagen 30–37. Zugehörige Endtage sind 29/30/31/32/33,5/34,25/35,25/36,25. Summe 100 %. Die gewichteten kumulierten Mengen werden anschliessend annualisiert.

Das Skript reproduziert die gespeicherten Excel-Endergebnisse separat aus den ursprünglichen Eingabewerten und Formeln: **23,90392596 g Basis**, **10,53276766 g WRG**, **55,93708050 % Reduktion**. Numerische Abweichung der Mengen unter 10⁻⁸ g. Diese Kontrollrechnung steht in `excel_reproduktion.csv` und wird nicht als aktualisierte Auswertung ausgegeben.

Einzelne Hilfsformeln im ersten Blatt sind auffällig: AH9 verweist auf die leere Zelle AF9 statt AG9; W10:W11 und AH10:AH11 verwenden leere Bezugszellen. Diese Fehlerbereiche gehören nicht zur nachgerechneten Hauptsumme des zweiten Blatts. Die Originaldatei wurde nicht korrigiert.

## Aktuelle Berechnung

### Datenquelle und Zeitachse

Importiert werden ausschliesslich die fünf `rsaves/final-dataset.qd` aus `~/git/mettmenstetten-{feb2024,apr2024,jul2024,dec2024,aug2026}`. Verwendet werden NH₃, `net`, `total`, `cum_flow`, Einheit kg, sowie Tierzahlen aus `bfn/tiere`. Es wird keine Rohsensor-Neukalibration durchgeführt. Die Auswertung übernimmt die bereits berechneten kumulierten Emissionen samt vorgängiger Interpolation und Extrapolation.

Die echte Mastdauer wird aus `local-times.rds` und den Intervallzeiten berechnet. Pro Masttag wird die letzte kumulierte kg-Menge durch die mittlere Tierzahl des Tages geteilt und in g umgerechnet, entsprechend der Tagesauswertung der Kampagnenberichte. Innerhalb des Messbereichs wird linear interpoliert, danach quadratisch extrapoliert. Die letzten acht Tagesstützpunkte einschliesslich des unvollständigen letzten Masttags gehen in den Fit ein. Sinkende oder negative Prognosen und eine Überschreitung von vier Extrapolationstagen führen zu einem Fehler. Es findet keine stille Korrektur solcher Prognosen statt.

### Offsetdefinition und Absenkung der Basis

Für beide Offsetkampagnen werden die **kumulierten Endwerte pro Tier wie im jeweiligen Kampagnen-PDF** verwendet. Berechnet wird mit den ungerundeten Quelldaten: letzte kumulierte kg-Menge geteilt durch die letzte Tierzahl, multipliziert mit 1000. Die PDF-Anzeigen werden erst für die Darstellung gerundet. Die Endwerte beider Ställe liegen in diesen Dateien jeweils bei Masttag 33,4167; es erfolgt keine Interpolation auf Tag 33.

```
r_Winter = 1,7659068842 / 2,3103396176 = 0,7643494795
r_Sommer = 0,5836129676 / 0,5634243209 = 1,0358320468
r_Mittel = (r_Winter + r_Sommer) / 2     = 0,9000907632
```

Es ist das arithmetische Mittel der beiden Verhältnisse. Das Mittel der inversen Korrekturfaktoren wäre eine andere Methode.

Für den Bezug auf Stall 1 gilt `Basis = E1` und `WRG = E2 / r`. Für die gemeinsame Basis gilt:

```
f = (1 + r_Mittel) / 2 = 0,9500453816
Basis = E1 × f
WRG   = E2 × f / r_Mittel
```

Stall 1 wird damit um **5,00 % abgesenkt**, Stall 2 um **5,55 % angehoben**. Beide liegen auf derselben gedachten mittleren Stallbasis. Der Wechsel von Stall-1-Bezug auf diese gemeinsame Basis verändert die absoluten Mengen, aber nicht die prozentuale WRG-Reduktion. Würde nur die Basis abgesenkt, ohne die WRG-Menge auf dieselbe Bezugsbasis zu bringen, wären die Mengen nicht mehr direkt vergleichbar.

Die Offsets beziehen sich auf die kumulierten Kampagnen-Endwerte und werden als konstanter proportionaler Faktor über die Mastkurve verwendet. Der saisonale Unterschied ist gross und das Verhältnis hängt auch vom gewählten Masttag ab. Eine konstante Übertragbarkeit auf alle Masttage und Kampagnen bleibt eine Modellannahme.

### Jahresgewichtung und Vergleichbarkeit

Winter, Übergangszeit und Sommer werden jeweils mit einem Drittel gewichtet. Innerhalb einer Saison werden die eingeschlossenen Kampagnen gleich gewichtet. Aktuell ergeben sich:

- Basis: Februar 1/6, Dezember 1/6, April 1/3, Juli 2024 1/6, August 2026 1/6.
- WRG: Februar, April und Juli 2024 jeweils 1/3.

August 2026 liefert ohne WRG auch eine Basismessung. Seine niedrigen Emissionen senken die Sommerbasis deutlich. Die Hauptauswertung nutzt damit unterschiedliche Kampagnensätze für Basis und WRG, wie bereits die ursprüngliche Excel-Logik im Winter. Jahres-, Herden- oder sonstige Kampagneneffekte können die Differenz mitprägen.

Deshalb gibt es zusätzlich `ergebnisse_jahr_vergleichspaare.csv`: nur Februar, April und Juli 2024 auf **beiden** Seiten, jeweils mit einem Drittel. Für die gemeinsame Basis ergibt dieser Vergleich **24,75 g Basis**, **9,08 g WRG**, **15,67 g Einsparung**, **63,33 % Reduktion**. Dieser Wert und die 53,95 % der Hauptauswertung beantworten unterschiedliche Vergleichsfragen; sie dürfen nicht als austauschbare Wirkungsschätzer behandelt werden.

Die Gesamtreduktion ist stets `1 − gewichtete WRG-Menge / gewichtete Basismenge`. Prozentwerte einzelner Kampagnen werden nicht einfach gemittelt.

## Datenlücken und Grenzen

- **Juli 2025 ist auf ausdrücklichen Nutzerwunsch vollständig ausgeschlossen.** Diese Kampagne wird weder importiert noch in Kampagnenergebnissen, Tageswerten oder Jahresmitteln berücksichtigt. August 2026 ist die zusätzliche Sommer-Offsetkampagne neben Dezember 2024.
- **November 2023:** im Ordner vorhanden, aber nicht in der gelieferten Excel-Auswertung. Anderes RDS-Datenschema mit `mg_s_net`, keine vergleichbare aktuelle QD-Kumulierung. Im Inventar sichtbar und nicht automatisch dem gleichen Kalibrationsstand zugeordnet. Vor Einbezug separat harmonisieren und Betriebszustand klären.
- **Messabdeckung:** auch verwendete Kampagnen enthalten zeitweise geringe Coverage. Beispielsweise beträgt sie am kumulierten Ende für Juli 2024 Stall 1 etwa 59 %, für Dezember Stall 1 etwa 64 %. `valid_full_cycle` prüft Zeitbasis und Kontinuität der gespeicherten Reihe, nicht die Vollständigkeit unabhängiger Messungen. Die Coverage-Werte und fehlenden Flusswerte werden ausgegeben, nicht durch eine grüne Gesamtfreigabe ersetzt.
- **Tierzahl:** g/Tier mit zeitlich veränderlicher Tierzahl ist nicht automatisch g/Tierplatz. Die Jahresergebnisse gelten unter der expliziten Belegungsannahme `animals_per_place = 1`. Für tatsächliche Tierplatzbilanzen sind Stallkapazität und ein konsistenter Tierzahlnenner festzulegen. Die Tagesnormierung entspricht der vorhandenen Excel-/Berichtslogik.
- **Extrapolation:** 68 % der Schlachttagverteilung liegen bei Endtagen 33,5 und später, hinter den Messenden von etwa 33,42–33,54 Tagen. Je nach Kampagne werden 64 % oder 68 % der Verteilung zumindest teilweise extrapoliert. Die Form der späten Kurve beeinflusst das Ergebnis wesentlich.
- **Unsicherheit:** Es werden keine neuen ±-Werte oder Konfidenzintervalle behauptet. Sensorfehler, gemeinsame Kalibrationsfehler, Offsetstreuung, zeitliche Abhängigkeit und Extrapolationsunsicherheit sind nicht durch zwei Kampagnenverhältnisse ausreichend bestimmt. Die Winter-/Sommervarianten sind Sensitivitätsvarianten, keine Konfidenzgrenzen.

## Ausführen und Outputs

`emissionen_mettmenstetten.R` in RStudio öffnen und vollständig ausführen. Benötigt werden `data.table`, `qs2` und `readxl`, auf diesem Rechner vorhanden. Pfade und Parameter stehen am Skriptanfang. Die Anzahl Umtriebe ist ausdrücklich als Variable `anzahl_umtriebe <- 8.5` definiert; sie steuert alle aktuellen Jahreshochrechnungen. Die Saisongewichte sind unabhängig davon jeweils `1/3`. Das Skript setzt das Arbeitsverzeichnis ausdrücklich auf `~/git/overall-campaigns`. Der Ergebnisordner ist `~/git/overall-campaigns/ergebnisse_emissionen`. Der Arbeitsordner lässt sich über `working_directory` am Skriptanfang ändern. Die Ausführung installiert keine Pakete und verändert keine Quellen.

Die CSV-Dateien verwenden Semikolon und Dezimalkomma. `NA` bedeutet nicht verfügbar und wird nicht als null behandelt.

| Datei | Inhalt |
|---|---|
| `ergebnisse_kampagnen.csv` | Alle Kampagnen und Varianten, g/Tier, modellierte g/Platz/Jahr, Einsparung und Prozent |
| `ergebnisse_jahr.csv` | Jahreswerte mit allen eingeschlossenen Basiskampagnen |
| `ergebnisse_jahr_vergleichspaare.csv` | Jahresvergleich aus identischen WRG-Kampagnen |
| `offsets.csv`, `varianten.csv` | Kampagnenverhältnisse und angewendete Faktoren |
| `tageswerte_kumuliert.csv`, `masttag_prognosen.csv` | Tageswerte, Prognosen, Extrapolationskennzeichnung und Fit-RMSE |
| `datenqualitaet.csv`, `gemessene_endwerte.csv` | Zeitbasis, Coverage, vorhandene Endwerte, Einschlussfähigkeit |
| `jahresgewichte.csv`, `schlachttagverteilung.csv` | Tatsächlich angewendete Gewichte |
| `excel_reproduktion.csv` | Numerischer Kontrollabgleich mit dem zweiten Excel-Blatt |
| `kampagneninventar.csv`, `quellen.csv` | Ordnerinventar, importierte Pfade und MD5-Prüfsummen |
| `parameter.R`, `sessionInfo.txt` | Eingestellte Parameter und verwendete R-/Paketversionen |
| `jahresvergleich.png` | Übersicht der vier Jahresvarianten |

Geprüft wurden die vollständige Ausführung mit den vorhandenen Dateien, der Excel-Abgleich, die quadratische Prognose gegen eine bekannte Funktion, Fehler bei ungenügenden Fitdaten und zu weiter Extrapolation, die unveränderte relative Reduktion bei gemeinsamer Skalierung, die Jahresaggregation anhand expliziter Einzelgewichte und der Ausschluss ungültiger bzw. WRG-loser Vergleichswerte. Diese Kontrollen bestätigen die Umsetzung der beschriebenen Methode; sie ersetzen keine Prüfung des vorgängigen Mess- und Kalibrationsprozesses.
