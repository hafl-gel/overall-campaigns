list(input = "/Users/stefan/Documents/0 - MSc HAFL/MA/analysen/IMPEX_Gfeller_nach MA.xlsx",
    sheet = "R", supplement = "/Users/stefan/git/overall-campaigns/work/test_august_n_bilanz/synthetische_eingabe.csv",
    out = "/Users/stefan/git/overall-campaigns/work/test_august_n_bilanz/ergebnisse",
    campaigns = c("feb", "apr", "jul", "dec", "aug"), cycles = 8.5,
    source_cycles = 8.5, season_weights = c(Winter = 0.25, Transition = 0.5,
    Summer = 0.25))
