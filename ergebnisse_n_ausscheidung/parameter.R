list(input = "/Users/stefan/git/overall-campaigns/daten/IMPEX_Gfeller_nach MA.xlsx",
    sheet = "R", supplement = "/Users/stefan/git/overall-campaigns/daten/N_Bilanz_August2026.csv",
    out = "/Users/stefan/git/overall-campaigns/ergebnisse_n_ausscheidung",
    campaigns = c("feb", "apr", "jul", "dec", "aug"), cycles = 8.5,
    source_cycles = 8.5, season_weights = c(Winter = 0.25, Transition = 0.5,
    Summer = 0.25))
