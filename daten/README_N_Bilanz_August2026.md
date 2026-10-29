# August 2026: spätere N-Bilanzdaten

N_Bilanz_August2026.csv enthält vorbereitete Zeilen für Stall 1 und Stall 2. Beide stehen unter Umtrieb = Aug-26.

- N_ausgeschieden_pro_Tier_g: N-Ausscheidung in Gramm pro Tier und Mastumtrieb, in derselben Bezugsdefinition wie die bisherige IMPEX-Spalte. Dies wird für die N-Jahresauswertung benötigt.
- TAN_pro_Tier_g: TAN in Gramm N pro Tier und Mastumtrieb, falls verfügbar.
- NH3_N_gemessen_pro_Tier_g: gemessene NH3-N-Menge in Gramm N pro Tier und Mastumtrieb, falls verfügbar. Dies ist nicht die NH3-Masse.

Leere Werte bleiben leer. Semikolon ist das Spaltentrennzeichen; Dezimalkomma wird unterstützt. Die Jahreswerte und Umtriebszahl werden im Skript berechnet und gehören nicht in diese pro-Umtrieb-Spalten.

Falls eine vollständige aktualisierte IMPEX-Exceldatei vorliegt, kann stattdessen cfg_n$input in N-Excretion.R geändert werden. Dieselbe August-Bilanz sollte nicht doppelt in der Hauptdatei und Zusatzdatei eingetragen werden.
