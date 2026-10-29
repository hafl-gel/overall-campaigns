# August 2026: Rohwerte, Kalibration, Hintergrund und Nullsetzung

Stand: 28.10.2026. Separate Diagnose der am 24.07.2026 begonnenen Offsetkampagne. Quellen und bisherige Jahresauswertung wurden nicht verändert.

## Ergebnis

Die frühen Stall-2-Spitzen sind bereits in den unkalibrierten Abluftkonzentrationen vorhanden. Sie stammen nicht erst aus der linearen Kalibration oder der Nullsetzung. Alle vier Abluftsensoren an den relevanten Ventilatoren zeigen ein sehr ähnliches zeitliches Muster. Der Luftstrom bestimmt massgeblich, wann dieses Konzentrationssignal als Emissionsfracht sichtbar wird. Besonders die späteren Tagespulse werden zusätzlich durch die sinkende berechnete Zuluftkonzentration verstärkt.

Eine ausschliesslich biologische Erklärung ist dennoch nicht bewiesen. Die frühe Konzentrationsbilanz liegt häufig unter dem Bereich der späteren Vergleichskalibration. Hintergrundsensoren und ungewichtete Zuluftmittelung verursachen dort eine erhebliche Empfindlichkeit der berechneten Nettoemission. Gemeinsame Sensoreinflüsse, räumliche Hintergrundunterschiede und echte NH3-Signale sind aus diesen Daten allein nicht vollständig trennbar.

## 1. Geprüfte Verarbeitungskette

- Rohmesswerte: `mettmenstetten-aug2026/rsaves/xnodes-raw-nh3-list.rds`, etwa minütliche Sensorwerte. Die gespeicherten mg/m3 werden aus ppm, Temperatur und Druck berechnet; sie sind noch nicht durch die nachträgliche Vergleichskalibration korrigiert.
- Korrigierte Minute: `xnodes-nh3-list.rds`.
- Stundenmittel und Enddatensatz: `xnode-data.qd` bzw. `final-dataset.qd`.
- Sensorpositionen: `data/instruments.csv`.
- Vergleichskalibration: `xnode-intercomparisons/rsaves/xnode-nh3-ic-aug26-coefficients.rds`, Auflösung 1 Minute; für Sensoren 11 und 15 Ersatz aus `xnode-nh3-ic-all-ics-coefficients.rds`.

Für jeden der 20 NH3-Sensoren wurde die tatsächlich gespeicherte Transformation `C_korr = a + b * C_roh` aus Roh- und korrigierten Werten rekonstruiert. Die maximale Abweichung beträgt weniger als 5 × 10^-12 mg/m3. Die rekonstruierten Faktoren stimmen mit den aktuellen Koeffizientdateien überein. Die anschliessende Stundenmittelung wurde mit identischen Intervallgrenzen nachvollzogen und stimmt mit den finalen Sensor-Konzentrationen auf besser als 10^-8 mg/m3 überein. Die Summe der kanalweisen Abluft- minus Zuluftfrachten rekonstruiert die gespeicherten Nettoemissionen nach Nullsetzung ebenfalls auf besser als 10^-8 mg/s.

Das ist ein Nachweis der numerischen Verarbeitung, kein Nachweis der absoluten Richtigkeit der Sensoren.

## 2. Erste Spitze: mehrere Sensoren, schon im Rohsignal

Die Roh-Stundenwerte der vier relevanten Stall-2-Abluftsensoren 16–19 korrelieren in der ersten Woche paarweise mit r = 0,972 bis 0,997. Die hohe Korrelation wird auch durch die gemeinsame anfängliche Abklingphase geprägt. Sie spricht gegen einen isolierten Ausreisser eines einzelnen Sensors, schliesst aber gemeinsame Störeinflüsse nicht aus.

Zum Beginn zeigen die Roh-Minutenwerte aller vier Sensoren deutliche Konzentrationen. Beispielsweise erreicht Sensor 16 etwa 14,31 ppm bzw. 9,48 mg/m3. Dieser Verlauf ist schon vor der linearen Kalibration vorhanden. In den ersten zwei Tagen lagen die Roh-Feuchten dieser vier Sensoren zwischen etwa 41,5 und 84,5 %, nicht bei Sättigung; die Versorgungsspannungen sind je Sensor weitgehend stabil. Damit ist kein offensichtlicher gemeinsamer Feuchtesättigungs- oder Spannungsausfall an diesen vier Sensoren belegt. Temperatur-/Feuchtequerempfindlichkeit oder gemeinsame Drift sind damit nicht ausgeschlossen.

Bei der Emissionsspitze am 24.07.2026 um 14 Uhr Schweizer Sommerzeit ergibt sich:

| Abluftsensor | Netto-Beitrag [mg/s] |
|---|---:|
| 19, links | 1,2593 |
| 18, mitte links | 1,3857 |
| 17, mitte rechts | 1,2567 |
| 16, rechts | 1,4633 |
| 15, WRG-Kanal | 0,0020 |
| Summe | 5,3670 |

Sensor 15 verwendet zwar Ersatz-Kalibrationsfaktoren; sein Beitrag beträgt bei dieser Spitze aber nur rund 0,04 %. Über die erste Woche beträgt sein vorzeichenbehafteter Nettobeitrag ca. 0,000066 kg von insgesamt 0,409868 kg. Er erklärt die auffälligen frühen Spitzen somit nicht.

Die Kalibration vergrössert die erste Spitze nicht: Mit unveränderten unkalibrierten Konzentrationen gerechnet wäre die diagnostische Fracht 6,1693 mg/s, nach Kalibration 5,3670 mg/s. Die Rohwert-Fracht ist keine gültige alternative Emissionsschätzung, da die Sensoren unterschiedliche Nullpunkte haben; sie zeigt lediglich, dass der Ausschlag bereits vorher existiert.

## 3. Luftvolumenstrom und Hintergrund wirken zusammen

Die verwendete Bilanz lautet kanalweise:

`F = Summe_i Q_i * (C_Abluft_i - Mittelwert(C_Zuluft_1 ... C_Zuluft_6))`.

Die sechs Zuluftsensoren werden arithmetisch, nicht nach dem tatsächlichen Luftanteil an den verschiedenen Einlässen gewichtet. Die Repräsentativität dieses Mittels hängt deshalb von der Verteilung der Zuluft ab. Diese Luftanteile sind hier nicht unabhängig bestimmt.

Die Luftmengen der ersten Woche beruhen in Stall 2 fast vollständig auf den vorhandenen Messventilator-/Frequenzdaten: Gesamtabdeckung ca. 99,98 %, mittlerer BigFarmNet-Ersatzanteil ca. 0,008 %. Die Tagespulse sind deshalb nicht bloss das Ergebnis einer grossflächigen BigFarmNet-Lückenfüllung. Die vorhandene Umrechnung von Frequenz auf Luftmenge und der Anteil niedriger Frequenzen bleiben eigene Messunsicherheiten.

Die frühe vorzeichenbehaftete Emissionsrate und die Luftmenge korrelieren in Stall 2 mit r = 0,864. Wegen der rechnerischen Multiplikation ist das kein unabhängiger Kausalitätsnachweis und keine erklärte biologische Varianz.

Zwei Ereignisse verdeutlichen die gemeinsame Wirkung:

| Zeitpunkt, Schweizer Sommerzeit | Q [m3/s] | Effektive Abluftkonzentration [mg/m3] | Zuluftmittel [mg/m3] | Netto [mg/s] |
|---|---:|---:|---:|---:|
| 24.07.2026, 14 Uhr | 7,574 | 1,0102 | 0,3016 | 5,3670 |
| 30.07.2026, 16 Uhr | 21,370 | 0,1804 | 0,0349 | 3,1091 |

Die erste Spitze verbindet erhöhte Rohkonzentrationen mit einsetzender Lüftung. Die spätere Spitze entsteht bei wesentlich grösserem Luftstrom und kleiner Konzentrationsdifferenz. Ein rechnerisch konstanter Zuluftmittelwert der ersten Woche würde die spätere Spitze sogar in eine negative Bilanz von etwa -4,10 mg/s verwandeln. Dieser künstliche Versuch ist keine zulässige Korrekturmethode; er zeigt, dass die Zuordnung nur zur Lüftung zu kurz greift.

Sensitivitäten der ersten Stall-2-Woche, jeweils ohne Netto-Nullsetzung:

- Aktuelle arithmetische Zuluftmittelung: mittlere Fracht 0,67769 mg/s.
- Median statt Mittelwert der sechs Zuluftsensoren: 0,60986 mg/s, ca. 10 % niedriger.
- Sensor 14 aus dem Mittel weglassen: ca. 0,42962 mg/s, ca. 36,6 % niedriger.
- Sensor 04 weglassen: ca. 0,88028 mg/s, ca. 29,9 % höher.

Diese Fälle sind Sensitivitätstests, keine Auswahlregel und kein Beleg, Sensor 14 oder 04 sei falsch. Sie zeigen, wie stark die absolute Bilanz vom repräsentativen Hintergrund abhängt. Auch mit Median-Hintergrund bleibt die erste Spitze bei rund 5,415 mg/s bestehen.

## 4. Kritischer Punkt: Niedrigkonzentrationen ausserhalb des Vergleichsbereichs

Die August-Vergleichsmessung wurde vom 26.08. bis 12.10.2026, also nach der Mastkampagne, ausgewertet. Im gespeicherten Vergleichsdatensatz entspricht die Referenz `avg` exakt `cal-s12`: dem laborkalibrierten Sensor 12. Es ist hier kein unabhängiger Nullgas-Standard für jeden Sensor verfügbar.

Die Referenz liegt bei ca. 0,524 bis 5,883 mg/m3. Für viele frühe Messwerte wird die lineare Korrektur unterhalb des tatsächlich beobachteten Rohwertbereichs des jeweiligen Vergleichssensors angewendet:

| Stall-2-Zuluftsensor | Anteil erster Woche unter dem minimalen Rohwert seines Vergleichsbereichs |
|---|---:|
| 03 | 91,7 % |
| 04 | 60,7 % |
| 10 | 92,3 % |
| 14 | 98,8 % |
| 21 | 85,7 % |
| 22 | 73,2 % |

Auch die vier relevanten Abluftsensoren liegen zu ca. 36–59 % ihrer frühen Stunden unter ihrem jeweiligen Rohwert-Vergleichsbereich. Der spätere Peak mit nur 0,1455 mg/m3 effektiver Zu-/Abluftdifferenz ist daher empfindlich gegenüber kleinen Nullpunktfehlern. Die Residuen der relativen Vergleichskalibration bei Referenz <1 mg/m3 haben sensorabhängig RMSE-Werte von ca. 0,035 bis 0,171 mg/m3. Das ist keine formale Unsicherheit der stündlichen Nettoemission; zeitliche und gemeinsame Referenzfehler sind darin nicht getrennt. Die Grössenordnung rechtfertigt aber eine vorsichtige Interpretation solcher kleinen Differenzen.

Die Kalibration ist technisch korrekt angewendet. Eine ausreichend abgesicherte absolute Nullpunktkorrektur im niedrigen Kampagnenbereich lässt sich daraus nicht ableiten. Das ist der wichtigste noch offene Sensor-/Kalibrationspunkt.

## 5. Gegenrechnung ohne Nullsetzung

Aufgehoben wurde ausschliesslich das Abschneiden negativer NH3-Nettoemissionen. Reale Null-Luftmengen bei abgeschalteten Ventilatoren bleiben bestehen. Die vorhandenen negativen Sensor-Konzentrationen wurden bereits vorher nicht allgemein genullt. Fehlende Stunden werden in beiden Varianten wie im Produktionsskript linear interpoliert.

Die bisherige Kumulierung mit Nullsetzung wurde in allen fünf Kampagnen auf besser als 10^-8 kg reproduziert. Erst danach wurde der Schritt `negative Nettoemission = 0` entfernt.

Für August 2026:

| Stall | Bisher [kg] | Ohne Nullsetzung [kg] | Veränderung | Bisher [g/Tier] | Ohne Nullsetzung [g/Tier] |
|---|---:|---:|---:|---:|---:|
| 1 | 4,85019 | 4,64883 | -4,15 % | 0,56342 | 0,54003 |
| 2 | 5,02050 | 4,99649 | -0,48 % | 0,58361 | 0,58082 |

Die frühen positiven Stall-2-Spitzen bleiben bestehen. In der ersten Woche ändert sich dessen kumulierte Menge nur von 0,409969 auf 0,409868 kg. Bei Stall 1 sinkt sie deutlicher von 0,169479 auf 0,113494 kg. Über die gesamte Kampagne gibt es 262 negative beobachtete Stunden in Stall 1 und 91 in Stall 2; fehlende Stunden sind dabei separat gezählt.

Das Verhältnis der August-Endwerte Stall 2/Stall 1 steigt ohne Nullsetzung von 1,035832 auf 1,075531. Die Folge ist also nicht nur eine geringere Gesamtmenge, sondern auch ein anderer Offset.

Gegenrechnung aller Kampagnen, kg NH3 am Messende:

| Kampagne | Stall 1 bisher | Stall 1 ohne Nullsetzung | Stall 2 bisher | Stall 2 ohne Nullsetzung |
|---|---:|---:|---:|---:|
| Februar 2024 | 20,71494 | 19,67877 | 8,06384 | 6,92798 |
| April 2024 | 15,73333 | 15,39105 | 5,48975 | 4,53744 |
| Juli 2024 | 30,91356 | 30,79955 | 7,44507 | 4,66509 |
| Dezember 2024 | 19,17829 | 19,17829 | 14,79377 | 14,62840 |
| August 2026 | 4,85019 | 4,64883 | 5,02050 | 4,99649 |

Besonders Juli 2024 Stall 2 reagiert stark: -37,34 %. Die früher flachen Null-Linien sind daher nicht gleichbedeutend mit einer ausgeglichenen oder rauschfreien Konzentrationsbilanz. Ein Methodenwechsel müsste für alle Kampagnen, Offsetbestimmungen und Extrapolationen konsistent erfolgen.

Negative Nettofrachten beweisen nicht automatisch eine reale NH3-Aufnahme. Sie können aus einer echten Bilanz, einem unrepräsentativen Hintergrund oder Sensor-Nullpunktfehlern stammen. Die vorzeichenbehaftete Rechnung ist hier eine Sensitivitätsanalyse, keine neu freigegebene Emissionsfaktorenrechnung.

## 6. Dateien und überprüfbare Grenzen

`diagnose_rohwerte_aug2026.R` erzeugt alle Tabellen und Grafiken reproduzierbar. `angewendete_kalibrationsfaktoren.csv`, `pruefung_rohwert_bis_finale_konzentration.csv` und `quellen_pruefsummen.csv` dokumentieren die geprüfte Verarbeitung. `kalibrationsbereich_und_residuen.csv` enthält die Vergleichsbereiche, `kanalzerlegung_erste_woche.csv` und `stall2_spitzen_nach_sensor.csv` die Kanalbilanz. Die Rohminuten der ersten zwei Tage stehen separat bereit.

Die CSV-Zeiten `st`/`et` werden in UTC ausgegeben; `time_local` in der Hintergrundsensitivität bezeichnet ausdrücklich Europe/Zurich. Die Uhrzeiten in diesem Bericht sind Schweizer Sommerzeit.

Für eine eindeutige Aufteilung in tatsächliche Freisetzung und gemeinsame Sensoreinflüsse fehlen hier unabhängige gleichzeitige Referenzkonzentrationen im niedrigen Kampagnenbereich bzw. eine gesicherte Nullgasprüfung, Angaben zur Sensor-Einschwinghistorie und eine nach Einlass-Luftanteilen geprüfte Hintergrundkonzentration. Die vorliegenden Daten sprechen gegen eine einzelne fehlerhafte Abluftsonde oder eine erst durch Software geschaffene Anfangsspitze; sie beweisen nicht, dass alle frühen Flüsse biologisch korrekt quantifiziert sind.
