# Vergleich der Extrapolationsmethoden

Stand 28.10.2026. Diagnose aus den ungerundeten kumulierten Tageswerten aller fünf Kampagnen, je zwei Ställe. Die produktive Jahresauswertung verwendet weiterhin den freien quadratischen Fit. Dieser Vergleich ändert keine Messwerte, Offsets oder Jahresergebnisse.

## Prüfverfahren

Die bekannte Kurve wird an Masttag 26, 27, 28, 29 und 30 abgeschnitten. Mit ausschliesslich den bis dahin bekannten Daten werden jeweils die nächsten ein, zwei und drei Tage vorhergesagt und mit den tatsächlich vorhandenen Tageswerten verglichen. Das ergibt 150 Vorhersagefehler je Methode. Die Testfenster überlappen sich; sie sind keine 150 unabhängigen Versuche. Die Skalierung zur Vergleichbarkeit zwischen Reihen erfolgt mit dem mittleren absoluten Zuwachs der letzten acht Trainingsstützpunkte, nicht mit zukünftigen Werten.

Dies ist eine zeitlich geordnete Rückprüfung mit gleitenden Prognoseursprüngen. Methodische Quelle: Hyndman und Athanasopoulos, *Forecasting: Principles and Practice*, Abschnitt Time series cross-validation, https://otexts.com/fpp3/tscv.html .

## Verglichene Methoden

1. **Freier quadratischer Fit, letzte acht kumulierte Tageswerte:** bisherige Methode. Der Fit darf am letzten Messpunkt einen kleinen Sprung aufweisen.
2. **Am letzten Messpunkt verankerter quadratischer Fit, acht Tageswerte:** exakt stetiger Anschluss; die Abweichungen zum letzten Messwert werden ohne freien Achsenabschnitt regressiert.
3. **Konstante Rate aus drei letzten Tageszuwächsen:** Fortschreibung ab dem letzten Messwert mit konstantem mittlerem Zuwachs. Einfach, bildet weitere Beschleunigung aber nicht ab.
4. **Linearer Trend der letzten fünf Tagesraten:** Zunächst Differenzen kumulierter g/Tier durch die tatsächliche Dauer zwischen den Tagesstützpunkten teilen. Einen linearen Trend auf diese Raten fitten und ab dem letzten gemessenen kumulierten Wert integrieren. Zukünftige negative Raten werden in diesem Vergleich auf null begrenzt, entsprechend der hier untersuchten nichtnegativen kumulierten Produktionskurve.
5. **Gedämpfter Trend derselben fünf Tagesraten:** wie 4, mit abklingendem Trendzuwachs `(1-exp(-0.5*h))/0.5`. Der Dämpfungsparameter ist eine feste Sensitivitätsannahme und wurde nicht auf Testdaten optimiert.

## Ergebnis über alle Reihen und Horizonte

| Methode | Mittlerer absoluter Fehler [g/Tier] | RMSE [g/Tier] | Mittlerer Fehler [g/Tier] |
|---|---:|---:|---:|
| Linearer Trend der Tagesrate | 0,0843 | 0,1582 | -0,0766 |
| Gedämpfter Trend der Tagesrate | 0,0898 | 0,1681 | -0,0860 |
| Verankerter quadratischer Fit | 0,0981 | 0,1762 | -0,0899 |
| Bisheriger freier quadratischer Fit | 0,1120 | 0,1935 | -0,1021 |
| Konstante Tagesrate | 0,1460 | 0,2365 | -0,1459 |

Die lineare Ratenfortschreibung reduziert den mittleren absoluten Fehler gegenüber dem bisherigen Fit um rund 24,7 %. Bei drei Tagen Vorhersage beträgt der Fehler 0,1574 statt 0,1990 g/Tier, also ca. 20,9 % weniger. Sie hat in neun der zehn Reihen den kleinsten mittleren skalierten absoluten Fehler; in der verbleibenden Reihe ist der gedämpfte Ratentrend am besten. Alle fünf Methoden unterschätzen die in diesem Rücktest später tatsächlich beobachteten kumulierten Werte im Mittel. Die Rücktestgüte ist deshalb kein Nachweis einer unverzerrten Prognose.

## Einordnung und Empfehlung

Eine Fortschreibung über nur rund drei Tage anhand der jüngsten Tagesraten ist eine gut begründete Alternative zum freien Fit der kumulierten Werte. Sie startet exakt beim letzten Messwert und modelliert die lokale Emissionsentwicklung direkt. Für einen künftigen Methodenwechsel wäre sie aufgrund dieses Rücktests mein erster Kandidat.

Mathematisch wichtig: Ein linearer Trend der Tagesrate ergibt nach Integration wiederum einen quadratischen Verlauf der kumulierten Emission. Das ist also keine pauschale Ablehnung quadratischer Kurven. Die Verbesserung liegt in der Verankerung am letzten Messwert und der anderen, lokalen Schätzung des Zuwachses. Der einfache lineare Verlauf der kumulierten Menge, also konstante Tagesrate, schneidet in diesen Daten schlechter ab.

Die reale Fortsetzung nach Tag 33 ist nicht gemessen. Insbesondere das Mastende, Tierzahländerungen, Temperatur, Lüftung und Einstreuzustand können sich anders entwickeln als bei früheren Abschnitten. Die beobachteten Unterschiede zwischen den Methoden sind deshalb als Sensitivität auszuweisen, nicht als Konfidenzband. Ein höheres Polynom würde diese fehlende Information nicht ersetzen und ist durch den vorliegenden Rücktest nicht begründet.

Beispiel Juli/August 2026, verstrichener Endtag 36,25, vor Stalloffset-Korrektur:

| Stall | Bisheriger Fit [g/Tier] | Linearer Ratentrend [g/Tier] |
|---|---:|---:|
| Stall 1 | 1,0386 | 1,2312 |
| Stall 2 | 0,9051 | 0,9936 |

Diese Unterschiede zeigen, dass ein Methodenwechsel auch die Jahreswerte verändern kann. Es wurden hier bewusst keine neuen Jahreswerte aus einer ungeprüft ausgetauschten Produktionsmethode ausgegeben.

## Dateien

`extrapolation_vergleich.R` erzeugt `ruecktests_einzelwerte.csv`, Gesamtmetriken, Kennzahlen je Prognosehorizont und Reihe sowie `prognosen_nach_messende.csv`. `methodenvergleich_kurven.png` zeigt alle fünf tatsächlichen Prognosekurven mit Legende. Die aktuellen 8-/5-/3-Punkte-Fenster sind im separaten Vergleichsskript definiert. Bei Änderungen der produktiven Fitparameter dieses Vergleichsskript separat passend aktualisieren und ausführen.

## Tabelle 5 im Bericht

Das Hauptskript erstellt nun Tabelle 5 für Dezember 2024 und Juli/August 2026, jeweils als CSV und PNG und im HTML-Bericht. Es handelt sich um dieselben gemessenen Endwerte für beide Bezugsvarianten, ohne Stalloffset-Korrektur. Die ±-Werte übernehmen ausschliesslich die Messfehler-Konvention aus Excel: `sqrt(0.055^2 + 0.15^2)`. Die beiden relativen Fehler sind am Skriptanfang einstellbar. Diese Angaben sind keine neu ermittelten Konfidenzintervalle und werden nicht auf die korrigierten oder extrapolierten Jahreswerte übertragen.
