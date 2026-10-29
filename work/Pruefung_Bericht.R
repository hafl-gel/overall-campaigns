setwd(path.expand('~/git/overall-campaigns'))
source('emissionen_mettmenstetten.R')
# Tatsächlich verwendete Prognosen unabhängig aus gespeicherten Koeffizienten.
cf<-fread(file.path(cfg$out,'fit_koeffizienten.csv'),dec=',')
pr<-merge(curves,cf,by=c('campaign','housing'))
pr[,independent:=intercept+linear*(end_day-x0)+quadratic*(end_day-x0)^2]
if(cfg$extrapolation_method=='linear_rate') {
 # Geschlossene Stammfunktion der nichtnegativen linearen Rate, unabhaengig
 # von der numerischen Integration im Hauptskript.
 pr[, independent := mapply(function(y0,r0,q,h) {
  slope<-2*q
  y0+if(abs(slope)<1e-12) max(r0,0)*h else
   (max(r0+slope*h,0)^2-max(r0,0)^2)/(2*slope)
 },intercept,linear,quadratic,pmax(end_day-x0,0))]
 stopifnot(max(abs(cf$fit_at_end-cf$last_measured_ef))<1e-12)
}
stopifnot(max(abs(pr[extrapolated==TRUE,ef-independent]))<1e-10)
# Beide Ställe beider Offsets werden je Kampagne gleich gewichtet.
bc<-contributions[component=='basis']
stopifnot(nrow(bc[variant=='mittel_beider_staelle' & role=='offset'])==4,all(bc[variant=='mittel_beider_staelle' & role=='offset',weight]==.0625), all(bc[variant=='stall1_realitaet',housing]=='housing_1'),
 all(bc[campaign=='apr2024',weight]==.5),
 all(bc[campaign %in% c('feb2024','jul2024'),weight]==.125))
# Aus vier bzw. sieben expliziten Beiträgen direkt nachvollziehbare Hauptsumme.
for(v in variants$variant) {
 b<-bc[variant==v,sum(corrected*weight)]*anzahl_umtriebe
 w<-contributions[variant==v & component=='wrg',sum(corrected*weight)]*anzahl_umtriebe
 stopifnot(abs(b-annual[variant==v,basis_g_place_year])<1e-10,
           abs(w-annual[variant==v,wrg_g_place_year])<1e-10)
}
# Tabelle 4 bleibt am gemessenen Ende und enthält keine extrapolierten Mengen.
for(v in variants$variant)for(id in campaigns[role=='wrg',campaign]) {
 t<-report4[variant==v & campaign==id];f<-variants[variant==v]
 stopifnot(abs(t[housing=='housing_1',total_kg]-ends[campaign==id & housing=='housing_1',kg]*f$factor_barn1)<1e-12,
           abs(t[housing=='housing_2',total_kg]-ends[campaign==id & housing=='housing_2',kg]*f$factor_barn2)<1e-12)
}
cat('Berichtstabellen, Offsets, Einzelgewichte und grafisch gezeigte Prognosen geprüft.\n')
