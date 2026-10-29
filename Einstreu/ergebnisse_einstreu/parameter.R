list(input = "/Users/stefan/git/overall-campaigns/Einstreu/litter_data_all.xlsx", 
    sheet = "Sheet 1", out = "/Users/stefan/git/overall-campaigns/Einstreu/ergebnisse_einstreu", 
    campaigns = c("FEB", "APR", "JUL", "DEC", "AUG26"), historical_comparison = TRUE, 
    sampling_caution_metrics = "moisture_pct", sampling_caution = "Feuchtigkeit, August 2026, Stall 2, Masttag 34: Der Mittelwert aus fuenf Proben ist moeglicherweise durch eine nicht repraesentative Probenahme beeinflusst. Werte sind enthalten.", 
    comparison_day = 34, test_method = "anova_tukey", alpha = 0.05, 
    dunn_adjust = "holm", spread = "sd", decimal_mark = ",", 
    colours = c(`1` = "#E41A1C", `2` = "#377EB8"), facet_columns = 2, 
    base_size = 14, dpi = 300, export_pdf = TRUE)
