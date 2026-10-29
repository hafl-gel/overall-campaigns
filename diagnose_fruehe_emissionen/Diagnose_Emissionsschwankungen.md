# Frühe Emissionsschwankungen Juli/August 2026

Untersucht ist die als August 2026 bezeichnete Mastkampagne ab 24.07.2026. Die Diagnose verändert weder Sensor-, Kalibrations- noch Jahresauswertungen.

## Befund

Die Auffälligkeit ist eine Kombination aus engerer Grafikskalierung, unterschiedlichen gespeicherten Nettoemissionen und der vorgängigen Nullsetzung negativer Nettoemissionen. Dass die berechnete Emissionsrate schwankt, ist nachgewiesen. Ob die Schwankungen vollständig echte NH3-Freisetzung oder teilweise Mess-/Bilanzierungseffekte sind, lässt sich aus dem finalen Datensatz allein nicht entscheiden.

Die Reportquellen `reports/1-nh3-emission.Rmd` verwenden pro Kampagne den Wertebereich beider Ställe als y-Limit; zwischen Kampagnen wird keine gemeinsame Skala festgelegt. Die PDF-Seite 2 des August-Reports hat Achsenticks 0, 10, 20 mg/s, die Seite 2 des archivierten Juli-2024-Reports 0, 50, 100 mg/s. Derselbe Ausschlag von 3 mg/s wirkt im August-Plot daher wesentlich grösser. Die aktuellen Datensätze haben folgende maximale Nettoemissionen (jeweils Maximum beider Ställe): Februar 53,78; April 55,11; Juli 97,87; Dezember 46,38; August 26,81 mg/s. Bezogen auf diese Wertebereiche erscheint dieselbe Amplitude im August gegenüber Juli rund 3,65-mal höher. Die Achsen sind linear, nicht logarithmisch.

## Gleicher Zeitraum und identische Skala

Kennzahlen aus den ersten sieben verstrichenen Masttagen (0 <= days < 7), je 168 gespeicherte Stundenwerte und keine fehlenden Netto-Stundenwerte:

| Kampagne | Mittel Stall 1 [mg/s] | Mittel Stall 2 [mg/s] | Maximum Stall 1 [mg/s] | Maximum Stall 2 [mg/s] |
|---|---:|---:|---:|---:|
| Februar 2024 | 0,00245 | 0 | 0,060 | 0 |
| April 2024 | 0,00419 | 0 | 0,050 | 0 |
| Juli 2024 | 0,18161 | 0,01725 | 3,532 | 2,477 |
| Dezember 2024 | 0,04165 | 0 | 0,151 | 0 |
| Juli/August 2026 | 0,28022 | 0,67786 | 3,741 | 5,367 |

Somit ist Stall 1 im Juli 2024 keineswegs völlig ruhig; die frühen Spitzen sind ähnlich hoch wie 2026. Besonders Stall 2 zeigt 2026 aber deutlich häufigere und höhere frühe Ausschläge. Der Standardabweichungsvergleich der Stundenwerte ergibt für Stall 2 0,962 mg/s (2026) gegenüber 0,193 mg/s (Juli 2024). Bei Stall 1 ist die Standardabweichung der aufeinanderfolgenden Stundendifferenzen 2026 sogar kleiner als Juli 2024 (0,316 gegenüber 0,406 mg/s). Eine pauschale Aussage, beide Ställe seien 2026 nach jeder Schwankungskennzahl stärker schwankend, wäre daher falsch.

## Luftmenge und Konzentrationsbilanz

Die Produktionsskripte bilden NH3-Nettoemission = Summe der Abluft-Massenströme minus Zuluft-Massenstrom. Der Massenstrom entsteht aus Konzentration mal Luftvolumenstrom. In der ersten Augustwoche schwankt die Luftmenge stark und tagesperiodisch; ihr Zusammenhang mit der ausgewiesenen Nettorate beträgt deskriptiv Pearson r = 0,65 (Stall 1) und 0,86 (Stall 2). Das ist ein beobachteter Zusammenhang und zum Teil schon durch die Multiplikation bedingt, kein unabhängiger Nachweis einer biologischen Ursache.

Mittlere Luftmengen der ersten Woche: August 4,79 bzw. 5,28 m3/s; Juli 2024 3,12 bzw. 4,68 m3/s; Februar 0,71 bzw. 0,29 m3/s. Hohe und stark wechselnde Lüftung kann auch kleine Konzentrationsunterschiede als sichtbare mg/s-Schwankungen abbilden. Temperatur, Steuerung, tatsächliche NH3-Produktion und Sensorabweichungen sind dabei nicht separat kausal identifiziert.

Beispiel einer frühen Spitze: 24.07.2026, 14 Uhr (Zeit wie im Datensatz), Stall 2: 5,367 mg/s bei 7,574 m3/s; aus den Massenströmen abgeleitete effektive Konzentrationen 1,010 mg/m3 Abluft und 0,302 mg/m3 Zuluft. Das ist kein ausschliessliches Darstellungsartefakt. Vor allem der erste Peak hat auch eine grössere Konzentrationsdifferenz. Für die über den Gesamtluftstrom abgeleiteten effektiven Konzentrationen gilt: bei sehr kleiner oder verschwindender Luftmenge ist der Quotient instabil bzw. nicht definiert; nicht als unabhängige Sensormessung interpretieren.

## Nullsetzung erklärt einen Teil der ruhigen früheren Kurven

Alle fünf `scripts/3-b-estimate-emissions.r` enthalten eine Anweisung der Form:

`total[tracer=='nh3' & flow_direction == 'net' & value<0, value := 0]`

Im Februar, April und Dezember sind in Stall 2 sämtliche ersten 168 Nettostundenwerte null; Juli 2024 rund 96 %, August 2026 nur rund 18 %. Vor der Nullsetzung können Zu- und Abluftbilanzen schwanken und rechnerisch negative Nettoemissionen ergeben. Die flache Null-Linie beweist deshalb keine stabile Konzentrationsmessung. In August sind ausserdem einzelne kalibrierte Zuluftkonzentrationen negativ, und die Netto-Konzentrationsdifferenz von Stall 1 bewegt sich früh häufig um null. Das zeigt die Bedeutung von Hintergrundsubtraktion und Kalibration bei kleinen Netto-Signalen. Es ist kein alleiniger Beweis eines defekten Sensors.

## Schlussfolgerung und praktische Einordnung

1. Die y-Skala verstärkt die visuelle Auffälligkeit eindeutig.
2. Zusätzlich sind die berechneten frühen Nettoemissionen 2026, besonders in Stall 2, tatsächlich höher und wechselhafter als in den kühlen Kampagnen. Ähnliche einzelne frühe Spitzen gibt es auch im Juli 2024.
3. Der tagesperiodische Luftstrom erklärt einen wichtigen Teil des zeitlichen Musters; Konzentrationsdifferenzen und Nullsetzung wirken zusätzlich.
4. Eine eindeutige Trennung zwischen realem Prozesssignal und Mess-/Bilanzierungsartefakt braucht eine gezielte Sensor- und Kalibrationsprüfung. Die Diagnose rechtfertigt weder automatisches Glätten noch das Löschen der ersten Tage.

Die ersten sieben Tage liefern im August ungefähr 0,169 kg (Stall 1) und 0,410 kg (Stall 2), ca. 3,5 % bzw. 8,2 % der aus endlichen gespeicherten Flusswerten integrierten Gesamtmenge. Diese Kontrollintegration lässt fehlende Stunden aus und ist deshalb geringfügig kleiner als die bereitgestellte, vorgängig interpolierte Kumulierung. Sie ersetzt nicht die Jahresauswertung.

## Datenstände und Dateien

Die aktuelle August-PDF ist auf 28.10.2026 datiert. Die verfügbaren Juli-/Februar-2024-PDFs liegen unter `reports_old`, sind auf 27.11.2025 datiert und weisen teilweise andere Endmengen als die aktuellen QD-Dateien aus. Deshalb wurden sämtliche Kennzahlen und Vergleichsgrafiken aus den aktuellen `rsaves/final-dataset.qd` berechnet. Die PDF-Achsen wurden direkt geprüft.

Reproduzierbare Diagnose: `diagnose_fruehe_emissionen.R`. Ausgaben: `diagnose_fruehe_emissionen/kennzahlen_ersten_7_tage.csv`, `massenbilanz_ersten_7_tage.csv`, `vergleich_ersten_7_tage_gleiche_achse.png`, `vergleich_gesamte_mast_gleiche_achse.png`, `aug2026_bilanz_und_luftmenge.png`.
