# August 2026: Import der Mastauswertungen

Stand: 29.10.2026. Arbeitsdatei: `daten/IMPEX_Gfeller_nach MA.xlsx` im Projekt `/Users/stefan/git/overall-campaigns`.
Die bisherige Datei unter `/Users/stefan/Documents/0 - MSc HAFL/MA/analysen` wurde nicht verändert.
`N-Excretion.R` verwendet jetzt die Arbeitsdatei im Projekt. Die Zusatz-CSV bleibt leer, um doppelte Datensätze zu vermeiden.

## Quellen und Stallzuordnung

Quellordner: `/Users/stefan/Documents/0 - MSc HAFL/MA/digital_Annex/1-raw-data/Mastauswertungen/August 26`.
Die Hallenzuordnung ist anhand der gleich benannten Stall-PDFs der Dezemberkampagne bestätigt.

| Merkmal | Stall 1, Halle 9500989 | Stall 2, Halle 9500960 |
|---|---:|---:|
| PDF | 9500989_27082026.pdf | 9500960_28082026.pdf |
| Einstallung | 24.07.2026 | 24.07.2026 |
| Schlachtung | 27.08.2026 | 28.08.2026 |
| Mastdauer gemäss PDF [Tage] | 35 | 36 |
| Eingestallte Tiere | 8 730 | 8 730 |
| Ausgestallte Tiere, Geschl. Stk | 8 600 | 8 384 |
| Abgänge im Stall, Differenz | 130 | 346 |
| Netto ausgestallt [kg] | 18 120,24 | 18 459,24 |
| Starter [kg] | 1 960 | 1 980 |
| Mastfutter [kg] | 12 040 | 12 940 |
| Endmastfutter inklusive Bestandsänderung [kg] | 10 920 | 11 300 |
| Futter total [kg] | 24 920 | 26 220 |
| N-Ausscheidung total, vorläufig [kg] | 253,687056 | 283,726876 |
| N-Ausscheidung pro ausgestalltem Tier, vorläufig [g] | 29,4984948837 | 33,8414689885 |
| Auf 8,5 Umtriebe annualisiert, vorläufig [g/Tierplatz/Jahr] | 250,7372065116 | 287,6524864027 |

PDF-Seite 1 enthält die Mastübersicht. Seiten 4–8 enthalten Küken-, Futter- und Bestandsbelege.
Für die Tier-/Gewichtsbilanz werden wie bisher die geschlachteten Stück und Netto-kg verwendet, nicht nur die bezahlten Stück oder bezahlten kg.

Bestandsrechnung:
- Stall 1: 7 000 Anfangsbestand + 17 920 Lieferung vom 23.07. + 6 000 Lieferung vom 24.08. − 6 000 Restbestand = 24 920 kg.
- Stall 2: 4 000 Anfangsbestand + 17 920 Lieferung vom 23.07. + 11 800 Lieferung vom 24.08. − 7 500 Restbestand = 26 220 kg.

## Vorläufige Annahmen

Die PDFs enthalten keine Futter-N-/Rohproteingehalte für 2026. Der Nutzer hat am 29.10.2026 ausdrücklich zugestimmt, vorläufig die Laborgehalte von 2024 zu verwenden:
Starter 203,5, Mast 191,81, Endmast 189,1 g Rohprotein/kg; N = Rohprotein / 6,25.
Anfangs- und Restbestand werden nach dem bisherigen Rechenschema dem Endmastfutter zugerechnet. Die PDFs nennen dafür keine Phase. Diese Zuordnung ist eine Annahme, kein belegter Futterinhalt.

Die übrige vorhandene Bilanzkonvention bleibt erhalten: 0,04 kg Einstallgewicht/Tier, 28,7 g N/kg Tiergewicht, N-Produktion = N ausgestallt − N eingestallt.
Abgangsgewicht wird als Hilfsgrösse ausgewiesen, in der vorhandenen Formel für die N-Produktion aber nicht abgezogen.
N pro Tier bezieht sich wie die bisherigen R-Zeilen auf ausgestallte Tiere. Die alternative Variante_Spring behält ihren anderen Nenner, ihre Herstellergehalte 2024 und ihren Jahresfaktor 9 bei; sie speist nicht die produktive N-Auswertung.

## Excel und R

Variante_Proben und Variante_Spring enthalten August in Zeilen 13–14; R und Tabelle MT in Zeilen 10–11.
Die R-Zeilen sind Formellinks zur Variante_Proben. Dort geänderte Eingaben müssen in Excel berechnet und gespeichert werden, bevor readxl die neuen Ergebnisse lesen kann.
Quellen und Annahmen stehen rechts in Variante_Proben; R enthält die Spalten Bilanzstatus und Quelle.
Die vorhandenen Pivot-Tabellen wurden in Microsoft Excel aktualisiert. Detail1/Detail2 bleiben historische Drilldown-Auszüge.

August-NH3-Werte stammen aus den ungerundeten, unkorrigierten kumulierten Endwerten in `ergebnisse_bericht/tabelle5_offsetkampagnen_ungerundet.csv`:
0,563424320917825 bzw. 0,583612967569813 g NH3/Tier. Umrechnung zu NH3-N mit dem bisherigen Faktor 0,822.
Diese NH3-Messwerte decken Tag 33,42 ab, die Futter-/Tierbilanz hingegen die ganze Mast über 35/36 Tage.
Die August-NH3-N/TAN-Quote ist deshalb keine über die gesamte Mast vollständig gemessene Quote und fliesst nicht in den Vergleich mit aktiver WRG ein.

Die Jahresgewichtung lautet je Stall: Februar 12,5 %, Dezember 12,5 %, April 50 %, Juli 12,5 %, August 12,5 %.
Das ergibt bei 8,5 Umtrieben vorläufig 276,106477868759 bzw. 296,469298518499 g N/Tierplatz/Jahr.
Die Umtriebszahl wird in R weiterhin über cfg_n$cycles gesteuert. cfg_n$source_cycles beschreibt den Annualisierungsfaktor im Excel (Variante_Proben D23), damit TAN aus der Jahresspalte korrekt zurückgerechnet wird. Bei Änderung dieses Excel-Faktors auch source_cycles anpassen.

Die fünf Kampagnen sind jetzt vollständig belegt, aber die beiden August-Stallbilanzen sind vorläufig. `n_provisional`, `Bilanzstatus` und die Laufstatusdatei halten dies ausdrücklich fest.
Neu ausführen: `Rscript N-Excretion.R`. Alle N-Ergebnisse werden unter `ergebnisse_n_ausscheidung` neu erstellt.

## Prüfung

`work/Pruefung_IMPEX_August2026.py` gleicht Futtergesamtsummen, N-Rechnung, Gewichte, Excel- und R-Jahresmittel unabhängig ab.
Originaldatei und historische Eingabezellen/Formeln sind erhalten. Alle neuen Berechnungen sind in Excel berechnet und gespeichert, native Pivots enthalten zehn Stall-Kampagnenzeilen, keine Excel-Fehler gefunden.
`work/Pruefung_August_Kampagnen.R` prüft zusätzlich Kampagnengruppen, Sensoraggregation und den weiterhin unterstützten separaten CSV-Import in einem isolierten Testordner.
