# Szenario ohne August 2026. Alle Einstellungen und Berechnungen stammen aus
# emissionen_mettmenstetten.R; August ist auch aus der Offsetbestimmung entfernt.
local({
  scenario_settings <- list(
    cfg=list(out="ergebnisse_bericht_ohne_august2026"),
    exclude_campaigns="aug2026"
  )
  source(path.expand("~/git/overall-campaigns/emissionen_mettmenstetten.R"),local=environment())
})
