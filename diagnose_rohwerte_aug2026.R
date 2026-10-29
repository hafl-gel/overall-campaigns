# Separate forensische Auswertung; Quellen und freigegebene Jahreswerte unveraendert.
suppressPackageStartupMessages({library(data.table);library(ibts);library(qs2)})
root<-path.expand('~/git');repo<-file.path(root,'mettmenstetten-aug2026')
out<-file.path(root,'overall-campaigns','diagnose_rohwerte_aug2026')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
csv<-function(x,n)fwrite(x,file.path(out,paste0(n,'.csv')),sep=';',dec=',',bom=TRUE,na='NA')
raw<-readRDS(file.path(repo,'rsaves/xnodes-raw-nh3-list.rds'))
cal<-readRDS(file.path(repo,'rsaves/xnodes-nh3-list.rds'))
cf<-readRDS(file.path(root,'xnode-intercomparisons/rsaves/xnode-nh3-ic-aug26-coefficients.rds'))[['1mins']]
fb<-readRDS(file.path(root,'xnode-intercomparisons/rsaves/xnode-nh3-ic-all-ics-coefficients.rds'))[['1mins']]
map<-fread(file.path(repo,'data/instruments.csv'))
map[,`:=`(location=gsub('-','_',location),housing=paste0('housing_',housing),
 sensor=sub('sensor-','nh3_',xnode))]
origin<-readRDS(file.path(repo,'rsaves/local-times.rds'))[[1]][['from']]
finish<-readRDS(file.path(repo,'rsaves/local-times.rds'))[[1]][['to']]
coefs<-list();pools<-list();raw_early<-list()
for(nm in names(raw)){
 r<-raw[[nm]];c<-cal[[nm]]
 stopifnot(nrow(r)==nrow(c),all(as.numeric(st(r))==as.numeric(st(c))))
 rr<-r[['mgm3']];cc<-c[['mgm3']];m<-lm(cc~rr);b<-unname(coef(m))
 sn<-sub('ensor-','',nm);source<-if(sn%in%names(cf))'aug26' else 'all-ics Ersatz'
 expected<-if(source=='aug26')cf[[sn]] else fb[[sn]]
 coefs[[nm]]<-data.table(sensor=sub('sensor-','nh3_',nm),intercept=b[1],slope=b[2],
   max_affine_residual=max(abs(resid(m))),source=source,
   file_intercept=expected[1],file_slope=expected[2])
 # Exakt die Stundenmittelung aus 3-a, gleiche Intervallgrenzen und Gewichtung.
 pp<-as.data.table(pool(r[,'mgm3'],granularity='1hours',st.to=origin,et.to=finish))
 setnames(pp,'mgm3','raw_c');pp[,sensor:=sub('sensor-','nh3_',nm)];pools[[nm]]<-pp
 # Roh-Minutenwerte nur aus erster Woche; Zeit, NH3, T, RH fuer Sensorvergleich.
 rd<-as.data.table(r);rd<-rd[et>=origin & st<origin+7*86400]
 rd[,sensor:=sub('sensor-','nh3_',nm)];raw_early[[nm]]<-rd
}
coefs<-rbindlist(coefs);stopifnot(max(coefs$max_affine_residual)<1e-8,
 max(abs(coefs$intercept-coefs$file_intercept))<1e-8,
 max(abs(coefs$slope-coefs$file_slope))<1e-8)
coefs<-merge(coefs,map[,.(sensor,housing,location,flow)],by='sensor')
csv(coefs,'angewendete_kalibrationsfaktoren')
ph<-rbindlist(pools,use.names=TRUE);ph<-merge(ph,map[,.(sensor,housing,location,flow)],by='sensor')
ph<-merge(ph,coefs[,.(sensor,intercept,slope)],by='sensor')
ph[,predicted_cal:=intercept+slope*raw_c]
x<-qd_read(file.path(repo,'rsaves/final-dataset.qd'))
actual<-x[tracer=='nh3' & units=='mg_m3' & sensor!='xnode_avg',
 .(sensor,housing,location,st,et,cal_c=value,coverage)]
ph<-merge(ph,actual,by=c('sensor','housing','location','st','et'),all.x=TRUE)
poolcheck<-ph[,.(max_hourly_error=max(abs(predicted_cal-cal_c),na.rm=TRUE),
 missing_raw=sum(!is.finite(raw_c)),missing_cal=sum(!is.finite(cal_c))),by=sensor]
csv(poolcheck,'pruefung_rohwert_bis_finale_konzentration')
stopifnot(max(poolcheck$max_hourly_error)<1e-8)
ph[,days:=as.numeric(difftime(st,origin,units='days'))+.5/24]
csv(ph[days<7],'roh_und_kalibrierte_stundenwerte_erste_woche')

# Luftmengen je Abluftkanal und alle sechs Zuluftsensoren (arithmetisches Mittel).
q<-x[tracer=='airflow' & type=='flow' & sensor=='meas_fan' & location!='total',
 .(housing,location,st,et,q=value)]
bg<-ph[flow=='in',.(bg_cal=mean(cal_c,na.rm=TRUE),bg_raw=mean(raw_c,na.rm=TRUE),
 bg_intercept=mean(intercept[is.finite(cal_c)]),
 bg_scaled_raw=mean((slope*raw_c)[is.finite(cal_c)],na.rm=TRUE)),by=.(housing,st,et)]
bg_median<-ph[flow=='in',.(bg_median=median(cal_c,na.rm=TRUE)),by=.(housing,st,et)]
bg<-merge(bg,bg_median,by=c('housing','st','et'))
channels<-merge(ph[flow=='out'],q,by=c('housing','location','st','et'))
channels<-merge(channels,bg,by=c('housing','st','et'))
channels[,`:=`(net_cal=q*(cal_c-bg_cal),net_raw=q*(raw_c-bg_raw),
 net_gain=q*(slope*raw_c-bg_scaled_raw),net_intercept=q*(intercept-bg_intercept),
 net_median_bg=q*(cal_c-bg_median))]
stopifnot(max(abs(channels$net_cal-channels$net_gain-channels$net_intercept),na.rm=TRUE)<1e-8)
chsummary<-channels[days<7,.(mean_q=mean(q,na.rm=TRUE),
 raw_c_mean=mean(raw_c,na.rm=TRUE),cal_c_mean=mean(cal_c,na.rm=TRUE),
 gross_kg=sum(q*cal_c,na.rm=TRUE)*.0036,net_signed_kg=sum(net_cal,na.rm=TRUE)*.0036,
 intercept_kg=sum(net_intercept,na.rm=TRUE)*.0036),by=.(housing,location,sensor)]
csv(chsummary,'kanalbeitraege_erste_woche')
csv(channels[days<7],'kanalzerlegung_erste_woche')
balance<-channels[,.(q=sum(q),signed=sum(net_cal),raw_signed=sum(net_raw),
 gain=sum(net_gain),intercept=sum(net_intercept),
 median_bg_signed=sum(net_median_bg),bg_cal=bg_cal[1]),by=.(housing,st,et,days)]
stored<-x[tracer=='nh3' & type=='flow' & flow_direction=='net' & location=='total',
 .(housing,st,et,stored_net=value)]
balance<-merge(balance,stored,by=c('housing','st','et'))
stopifnot(max(abs(pmax(balance$signed,0)-balance$stored_net),na.rm=TRUE)<1e-8)
csv(balance,'aug2026_bilanz_ohne_nullsetzung')
peaks<-balance[housing=='housing_2' & days<7][order(-signed)][1:12]
csv(peaks,'stall2_fruehe_spitzen')
csv(channels[housing=='housing_2'][peaks,on=.(housing,st,et),nomatch=0],
 'stall2_spitzen_nach_sensor')

# Exakte Gegenrechnung ohne Nettowert-Nullsetzung fuer alle fuenf Kampagnen.
# Fehlstellen werden wie im Produktionsskript linear interpoliert, nicht genullt.
ids<-c('feb2024','apr2024','jul2024','dec2024','aug2026')
all_rates<-list();totals<-list()
for(id in ids){
 z<-qd_read(file.path(root,paste0('mettmenstetten-',id),'rsaves/final-dataset.qd'))
 f<-dcast(z[tracer=='nh3' & type=='flow' & location=='total'],
 housing+st+et+days~flow_direction,value.var='value')
 f[,signed:=outflow-inflow];setorder(f,housing,st)
 for(h in c('housing_1','housing_2')){
  a<-copy(f[housing==h]);dt<-as.numeric(a$et-a$st,units='secs')
  interpolate<-function(v)if(anyNA(v))approx(as.numeric(a$st),v,xout=as.numeric(a$st))$y else v
  pos<-interpolate(a$net);signed_values<-interpolate(a$signed)
  stopifnot(all(is.finite(pos)),all(is.finite(signed_values)),all(dt==3600))
  a[,`:=`(campaign=id,cum_positive=cumsum(pos*dt*1e-6),
           cum_signed=cumsum(signed_values*dt*1e-6),signed_interpolated=signed_values)]
  old<-z[tracer=='nh3' & type=='cum_flow' & flow_direction=='net' & location=='total' & housing==h][order(et)]
  old_end<-tail(old$value,1)
  stopifnot(abs(tail(a$cum_positive,1)-old_end)<1e-8)
  animals<-z[location=='bfn' & sensor=='tiere' & housing==h][order(et)]
  n<-tail(animals$value,1)
  totals[[paste(id,h)]]<-data.table(campaign=id,housing=h,
   kg_with_zeroing=old_end,kg_without_zeroing=tail(a$cum_signed,1),
   change_kg=tail(a$cum_signed,1)-old_end,
   g_animal_with_zeroing=old_end/n*1000,g_animal_without_zeroing=tail(a$cum_signed,1)/n*1000,
   negative_hours=sum(a$signed<0,na.rm=TRUE),missing_hours=sum(!is.finite(a$signed)),
   early7_signed_kg=sum(a$signed_interpolated[a$days<7])*.0036,
   early7_positive_kg=sum(pos[a$days<7])*.0036,
   min_signed_mgs=min(a$signed,na.rm=TRUE))
  all_rates[[paste(id,h)]]<-a
 }
}
rates<-rbindlist(all_rates,use.names=TRUE,fill=TRUE);totals<-rbindlist(totals)
totals[,change_pct:=100*(kg_without_zeroing/kg_with_zeroing-1)]
csv(totals,'alle_kampagnen_endmengen_mit_ohne_nullsetzung')
csv(rates,'alle_kampagnen_raten_und_kumulierung')

# Hintergrund-Sensitivitaet: einen der sechs Zuluftsensoren weglassen, Diagnose.
loo<-rbindlist(lapply(ph[flow=='in',unique(sensor)],function(s){
 bh<-ph[flow=='in' & sensor!=s,.(bg_loo=mean(cal_c,na.rm=TRUE)),by=.(housing,st,et)]
 d<-merge(channels,bh,by=c('housing','st','et'))
 d<-d[,.(net_loo=sum(q*(cal_c-bg_loo))),by=.(housing,st,et,days)]
 b<-merge(d,balance[,.(housing,st,et,signed)],by=c('housing','st','et'))
 b[days<7,.(omitted_sensor=s,mean_change=mean(net_loo-signed,na.rm=TRUE),
 max_abs_change=max(abs(net_loo-signed),na.rm=TRUE)),by=housing]
}))
csv(loo,'hintergrund_leave_one_out_erste_woche')

# Deskriptive Korrelationen; keine kausale Varianzaufteilung behaupten.
early_stats<-balance[days<7,.(q_mean=mean(q,na.rm=TRUE),signed_mean=mean(signed,na.rm=TRUE),
 raw_mean=mean(raw_signed,na.rm=TRUE),gain_mean=mean(gain,na.rm=TRUE),intercept_mean=mean(intercept,na.rm=TRUE),
 median_background_mean=mean(median_bg_signed,na.rm=TRUE),
 corr_signed_q=cor(signed,q,use='complete.obs')) ,by=housing]
csv(early_stats,'bilanzzerlegung_erste_woche')

# Original-Minutenwerte rund um den ersten Peak; keine Nullsetzung.
minute<-rbindlist(raw_early,use.names=TRUE,fill=TRUE)
minute<-merge(minute,coefs[,.(sensor,housing,flow,location,intercept,slope)],by='sensor')
minute[,calculated_cal:=intercept+slope*mgm3]
csv(minute[housing=='housing_2' & st<origin+2*86400], 'stall2_rohminuten_ersten_2_tage')

cols<-c('#A7443F','#2479AD')
png(file.path(out,'aug2026_mit_ohne_nullsetzung.png'),width=1800,height=1600,res=160)
par(mfrow=c(3,2),mar=c(4,4,2,1),oma=c(1,0,2,0))
for(mode in c('early','full','cum'))for(j in 1:2){
 d<-rates[campaign=='aug2026' & housing==paste0('housing_',j)]
 if(mode=='early')d<-d[days<7]
 y1<-if(mode=='cum')d$cum_positive else d$net
 y2<-if(mode=='cum')d$cum_signed else d$signed
 plot(d$days,y2,type='s',col=cols[j],lwd=1.4,ylim=range(y1,y2,na.rm=TRUE),
  xlab='Mastdauer [Tage]',ylab=if(mode=='cum')'Kumuliert [kg NH3]' else 'NH3 netto [mg/s]',
  main=paste('Stall',j,switch(mode,early='- erste Woche',full='- ganze Mast',cum='- kumuliert')),las=1)
 lines(d$days,y1,type='s',col='#33333388',lty=2,lwd=1.3);abline(h=0,col='#555555',lty=3)
 legend('topleft',legend=c('Ohne Nullsetzung','Bisher: negative Nettoemission = 0'),
 col=c(cols[j],'#33333388'),lty=c(1,2),bty='n',cex=.75)
}
mtext('Juli/August 2026: alleiniger Effekt der Nettowert-Nullsetzung',outer=TRUE,side=3,font=2)
dev.off()

png(file.path(out,'stall2_rohkonzentrationen_und_lueftung.png'),width=1800,height=2100,res=160)
par(mfrow=c(4,1),mar=c(4.8,4.5,2.5,1),oma=c(1,0,2,0))
pal<-c('#006AA7','#E07B16','#288F4C','#B03475','#555555')
sensors<-sprintf('nh3_%02i',15:19)
for(metric in c('raw_c','cal_c','bg','q')){
 d<-channels[housing=='housing_2' & days<7]
 if(metric%in%c('raw_c','cal_c')){
  rr<-range(d[[metric]],na.rm=TRUE)
  plot(NA,xlim=c(0,7),ylim=rr,xlab='Mastdauer [Tage]',ylab='NH3 [mg/m3]',
   main=if(metric=='raw_c')'Abluftsensoren: unkalibrierte Rohwerte, Stundenmittel' else 'Abluftsensoren: nach angewendeter Kalibration',las=1)
  for(j in seq_along(sensors)){a<-d[sensor==sensors[j]];lines(a$days,a[[metric]],col=pal[j],lwd=1.2)}
  legend('topright',legend=sensors,col=pal,lty=1,bty='n',horiz=TRUE,cex=.8)
 }else if(metric=='bg'){
  a<-ph[housing=='housing_2' & flow=='in' & days<7]
  rr<-range(a$cal_c,na.rm=TRUE);plot(NA,xlim=c(0,7),ylim=rr,xlab='Mastdauer [Tage]',ylab='NH3 [mg/m3]',main='Sechs Zuluftsensoren und verwendeter Hintergrundmittelwert',las=1)
  for(s in unique(a$sensor)){b<-a[sensor==s];lines(b$days,b$cal_c,col='#88888866')}
  b<-balance[housing=='housing_2' & days<7];lines(b$days,b$bg_cal,col='black',lwd=2)
 }else{
  a<-balance[housing=='housing_2' & days<7];plot(a$days,a$q,type='s',col='#2479AD',xlab='Mastdauer [Tage]',ylab='Luft [m3/s]',main='Gesamter Luftvolumenstrom Stall 2',las=1)
 }
 grid(col='#dddddd')
}
mtext('Stall 2: Rohsignal, Kalibration, Hintergrund und Luftmenge',outer=TRUE,side=3,font=2)
dev.off()
print(early_stats);print(totals);print(chsummary[housing=='housing_2'])
message('Rekonstruktion und Kalibration numerisch geprueft. Ausgabe: ',out)


# Gueltigkeitsbereich der zur Anwendung gekommenen Vergleichs-Kalibration.
icdata<-qd_read(file.path(root,'xnode-intercomparisons/rsaves/xnode-processed-nh3-ic-aug26.qd'))[['1mins']]
support<-rbindlist(lapply(names(cf),function(s){
 v<-icdata[[s]];ref<-icdata[['avg']];pred<-cf[[s]][1]+cf[[s]][2]*v
 residual<-pred-ref;ok<-is.finite(v)&is.finite(ref)
 a<-ph[sensor==sub('s','nh3_',s) & days<7]
 data.table(sensor=sub('s','nh3_',s),n_ic=sum(ok),
  raw_ic_min=min(v[ok]),raw_ic_max=max(v[ok]),reference_min=min(ref[ok]),reference_max=max(ref[ok]),
  residual_sd=sd(residual[ok]),residual_low_rmse=sqrt(mean(residual[ok & ref<1]^2)),
  early_raw_below_ic_fraction=mean(a$raw_c<min(v[ok]),na.rm=TRUE),
  early_cal_below_reference_fraction=mean(a$cal_c<min(ref[ok]),na.rm=TRUE))
}))
csv(support,'kalibrationsbereich_und_residuen')
stopifnot(max(abs(icdata[['avg']]-icdata[['cal-s12']]),na.rm=TRUE)<1e-10)
raw_cor<-dcast(ph[housing=='housing_2' & flow=='out' & sensor!='nh3_15' & days<7],
 st~sensor,value.var='raw_c')
cm<-as.data.table(cor(as.matrix(raw_cor[,-1]),use='pairwise.complete.obs'),keep.rownames='sensor')
csv(cm,'korrelation_rohwerte_stall2_abluft')
minutesummary<-minute[flow=='out',.(raw_max=max(mgm3,na.rm=TRUE),ppm_max=max(ppm,na.rm=TRUE),
 temperature_min=min(temperature,na.rm=TRUE),temperature_max=max(temperature,na.rm=TRUE),
 humidity_min=min(humidity,na.rm=TRUE),humidity_max=max(humidity,na.rm=TRUE),
 voltage_min=min(supplyVoltage,na.rm=TRUE),voltage_max=max(supplyVoltage,na.rm=TRUE)),by=sensor]
csv(minutesummary,'roh_minuten_sensorstatus_erste_woche')
qquality<-x[tracer=='airflow' & type=='flow' & sensor=='meas_fan' & days<7,
 .(coverage_mean=mean(coverage,na.rm=TRUE),bfn_extrapolated_mean=mean(bfn_extrapolated,na.rm=TRUE),
 low_frequency_mean=mean(low_frequency,na.rm=TRUE)),by=.(housing,location)]
csv(qquality,'luftmenge_datenherkunft_erste_woche')
bsensitivity<-copy(balance)
bsensitivity[,bg_constant:=mean(bg_cal[days<7],na.rm=TRUE),by=housing]
bsensitivity[,net_constant_bg:=signed+q*(bg_cal-bg_constant)]
bsensitivity[,time_local:=format(st,tz='Europe/Zurich',format='%Y-%m-%d %H:%M:%S %Z')]
csv(bsensitivity[housing=='housing_2' & days<7],'stall2_hintergrund_sensitivitaet')
src<-c(file.path(repo,'rsaves',c('final-dataset.qd','xnodes-raw-nh3-list.rds','xnodes-nh3-list.rds')),
 file.path(root,'xnode-intercomparisons/rsaves',c('xnode-nh3-ic-aug26-coefficients.rds',
 'xnode-nh3-ic-all-ics-coefficients.rds','xnode-processed-nh3-ic-aug26.qd')))
csv(data.table(path=src,md5=unname(tools::md5sum(src))),'quellen_pruefsummen')
writeLines(c('Kalibrationsreferenz des gespeicherten Intercomparisons: avg entspricht exakt cal-s12.',
 'Keine unabhaengige Nullgasvalidierung aus diesen Vergleichsdaten ableitbar.',
 'Bei der Ohne-Nullsetzung-Rechnung wurden nur negative NH3-Nettowerte beibehalten.',
 'Echte Null-Luftstroeme bei abgeschalteten Ventilatoren bleiben erhalten.',
 'Die bestehende Kumulierung mit Nullsetzung wurde in allen fuenf Kampagnen auf 1e-8 kg reproduziert.',
 'CSV-Zeitspalten st/et werden von fwrite in UTC ausgegeben; time_local ist explizit Europe/Zurich.'),
 file.path(out,'Validierung_und_Zeitbasis.txt'))
