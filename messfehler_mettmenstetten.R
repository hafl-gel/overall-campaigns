# Messfehlerfortpflanzung fuer die Berichtstabellen. Keine Zusatzpakete.
# Je Kampagne/Stall wirkt ein multiplikativer Messfehler auf die ganze Kurve.
# Deshalb bleiben Tageswerte, Messendwert und Extrapolation desselben Stalls
# abhaengig. Offsetverhaeltnisse werden bei jeder Stoerung neu berechnet.
measurement_uncertainties <- function(ends, weighted, campaigns, cfg) {
  src <- data.table::copy(ends[, .(campaign, housing)])
  data.table::setorder(src, campaign, housing)
  src[, source := paste(campaign, housing, sep = ":")]
  n <- nrow(src)
  u <- sqrt(cfg$uncertainty_fan^2 + cfg$uncertainty_xnode^2)
  rc <- cfg$measurement_campaign_correlation
  rb <- cfg$measurement_barn_correlation
  stopifnot(is.finite(rc), rc >= 0, rc <= 1,
            is.finite(rb), rb >= 0, rb <= 1)
  # Produkt zweier Korrelationsmatrizen; fuer 0..1 positiv semidefinit.
  corr <- outer(src$campaign, src$campaign, "==") * (1 - rc) + rc
  corr <- corr * (outer(src$housing, src$housing, "==") * (1 - rb) + rb)
  covariance <- u^2 * corr
  evaluate <- function(multiplier) {
    scale <- setNames(multiplier, src$source)
    e <- data.table::copy(ends)
    w <- data.table::copy(weighted)
    e[, scale := scale[paste(campaign, housing, sep = ":")]]
    w[, scale := scale[paste(campaign, housing, sep = ":")]]
    e[, `:=`(kg = kg * scale, g_animal = g_animal * scale)]
    w[, g_animal := g_animal * scale]
    ids <- campaigns[role == "offset", campaign]
    ratios <- vapply(ids, function(id) {
      a <- e[campaign == id]
      a[housing == "housing_2", g_animal] / a[housing == "housing_1", g_animal]
    }, numeric(1))
    r <- mean(ratios)
    rows <- list(); k <- 0L
    add <- function(group, variant, campaign, values) {
      k <<- k + 1L
      rows[[k]] <<- data.table::data.table(group = group, variant = variant,
        campaign = campaign, metric = names(values), value = unname(values))
    }
    for (v in c("unkorrigiert", "stall1_realitaet", "mittel_beider_staelle")) {
      f1 <- if (v == "mittel_beider_staelle") (1 + r) / 2 else 1
      f2 <- if (v == "unkorrigiert") 1 else f1 / r
      weighted_rows <- list()
      for (id in campaigns$campaign) {
        a <- e[campaign == id]; b <- w[campaign == id]
        e1 <- a[housing == "housing_1", g_animal] * f1
        e2 <- a[housing == "housing_2", g_animal] * f2
        k1 <- a[housing == "housing_1", kg] * f1
        k2 <- a[housing == "housing_2", kg] * f2
        w1 <- b[housing == "housing_1", g_animal] * f1
        w2 <- b[housing == "housing_2", g_animal] * f2
        add("end", v, id, c(barn1=e1, barn2=e2, difference=e1-e2,
          barn1_total_kg=k1, barn2_total_kg=k2, difference_total_kg=k1-k2,
          ratio=e2/e1, stall_difference_pct=100*(1-e2/e1)))
        add("weighted", v, id, c(barn1=w1, barn2=w2, difference=w1-w2,
          barn1_g_place_year=w1*cfg$cycles*cfg$animals_per_place,
          barn2_g_place_year=w2*cfg$cycles*cfg$animals_per_place,
          difference_g_place_year=(w1-w2)*cfg$cycles*cfg$animals_per_place,
          ratio=w2/w1, stall_difference_pct=100*(1-w2/w1)))
        weighted_rows[[id]] <- data.table::data.table(campaign=id, barn1=w1, barn2=w2)
      }
      z <- merge(data.table::rbindlist(weighted_rows), campaigns, by="campaign")
      z <- z[include_annual == TRUE]
      z[, basis := ifelse(v=="mittel_beider_staelle" & role=="offset",
                         (barn1+barn2)/2, barn1)]
      bs <- z[, .(basis=mean(basis)), by=season]
      ws <- z[role=="wrg", .(wrg=mean(barn2)), by=season]
      b <- sum(bs$basis*cfg$season_weights[bs$season])*cfg$cycles*cfg$animals_per_place
      wv <- sum(ws$wrg*cfg$season_weights[ws$season])*cfg$cycles*cfg$animals_per_place
      add("annual", v, "annual", c(basis_g_place_year=b, wrg_g_place_year=wv,
        saved_g_place_year=b-wv, ratio=wv/b, reduction_pct=100*(1-wv/b)))
    }
    data.table::rbindlist(rows)
  }
  center <- evaluate(rep(1,n))
  jacobian <- function(step) {
    vapply(seq_len(n), function(j) {
      a <- b <- rep(1,n); a[j] <- 1+step; b[j] <- 1-step
      (evaluate(a)$value-evaluate(b)$value)/(2*step)
    }, numeric(nrow(center)))
  }
  j <- jacobian(1e-5)
  # Zweite Schrittweite kontrolliert die numerische Ableitung.
  j2 <- jacobian(5e-6)
  stopifnot(max(abs(j-j2)/pmax(1,abs(j))) < 1e-6)
  center[, propagated_error := sqrt(pmax(0,rowSums((j %*% covariance)*j)))]
  center[, `:=`(measurement_error=propagated_error, convention="propagated")]
  # Excelkonvention fuer prozentuale Reduktion: relativer Quotientenfehler
  # mal Reduktion. Die regulaere Fortpflanzung steht zusaetzlich im CSV.
  ix <- which(center$metric %in% c("stall_difference_pct","reduction_pct"))
  for (i in ix) {
    rr <- center[group==center$group[i] & variant==center$variant[i] &
                   campaign==center$campaign[i] & metric=="ratio"]
    legacy <- abs(center$value[i])*rr$propagated_error/abs(rr$value)
    center[i, `:=`(excel_legacy_error=legacy,
      measurement_error=if(cfg$reduction_error=="excel_legacy") legacy else propagated_error,
      convention=cfg$reduction_error)]
  }
  wide <- lapply(c("end","weighted","annual"), function(g) {
    a <- data.table::copy(center[group==g])
    a[, metric := paste0(metric,"_error")]
    data.table::dcast(a,variant+campaign~metric,value.var="measurement_error")
  })
  names(wide) <- c("end","weighted","annual")
  wide$detail <- center
  cov_export <- data.table::as.data.table(covariance)
  data.table::setnames(cov_export,src$source)
  cov_export[, source := src$source]
  data.table::setcolorder(cov_export,c("source",src$source))
  wide$covariance <- cov_export
  wide
}
