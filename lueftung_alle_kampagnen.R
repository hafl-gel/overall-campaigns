# Vergleich aus aktuellen gespeicherten Luftmengen, keine Aenderung der Quellen.
suppressPackageStartupMessages({library(qs2);library(data.table);library(ibts)})
root<-path.expand('~/git');out<-file.path(root,'overall-campaigns','vergleich_lueftung')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
ids<-c('feb2024','apr2024','jul2024','dec2024','aug2026')
labels<-setNames(c('Februar 2024','April 2024','Juli 2024','Dezember 2024','Juli/August 2026'),ids)
csv<-function(x,n)fwrite(x,file.path(out,paste0(n,'.csv')),sep=';',dec=',',bom=TRUE)
wm<-function(x,w){ok<-is.finite(x)&is.finite(w);if(any(ok))weighted.mean(x[ok],w[ok]) else NA_real_}
co<-function(x,y){ok<-is.finite(x)&is.finite(y);if(sum(ok)>3 && sd(x[ok])>0 && sd(y[ok])>0)cor(x[ok],y[ok]) else NA_real_}
totals<-list();channels<-list();paths<-character()
for(id in ids){
 path<-file.path(root,paste0('mettmenstetten-',id),'rsaves/final-dataset.qd');paths<-c(paths,path)
 x<-qd_read(path)
 q<-copy(x[tracer=='airflow' & type=='flow' & location=='total' & sensor=='meas_fan'])
 q[,campaign:=id]
 n<-x[location=='bfn' & sensor=='tiere',.(housing,st,et,animals=value)]
 temp<-dcast(x[location=='bfn' & sensor%in%c('temp','außentemp','lueftung_bed_normalisiert','abluft_vent_turbo')],
 housing+st+et~sensor,value.var='value')
 setnames(temp,c('temp','außentemp'),c('inside','outside'))
 q<-merge(merge(q,n,by=c('housing','st','et'),all.x=TRUE),temp,by=c('housing','st','et'),all.x=TRUE)
 q[,`:=`(duration=as.numeric(et-st,units='secs'),
  hour=as.integer(format(st+1800,tz='Europe/Zurich',format='%H')),
  day=floor(days),m3_h_animal=value*3600/animals)]
 q[,phase:=cut(days,c(0,7,21,33,Inf),right=FALSE,labels=c('0-7','7-21','21-33','33+'))]
 totals[[id]]<-q
 c<-copy(x[tracer=='airflow' & type=='flow' & location!='total' & sensor=='meas_fan'])
 c[,`:=`(campaign=id,duration=as.numeric(et-st,units='secs'))]
 c[,phase:=cut(days,c(0,7,21,33,Inf),right=FALSE,labels=c('0-7','7-21','21-33','33+'))]
 # Kontrollsumme der Einzelkanaele muss Gesamtluftmenge ergeben.
 check<-merge(c[,.(sumq=sum(value)),by=.(housing,st,et)],q[,.(housing,st,et,total=value)],by=c('housing','st','et'))
 stopifnot(max(abs(check$sumq-check$total),na.rm=TRUE)<1e-8)
 channels[[id]]<-c
}
q<-rbindlist(totals,use.names=TRUE,fill=TRUE);ch<-rbindlist(channels,use.names=TRUE,fill=TRUE)
stopifnot(all(q$duration==3600),all(is.finite(q$value)),all(q$value>=0))
summarise<-function(z) z[,.(hours=.N,q_mean=wm(value,duration),q_max=max(value),
 q_p05=quantile(value,.05),q_p95=quantile(value,.95),m3_total=sum(value*duration),
 m3_h_animal=wm(m3_h_animal,duration),outside_mean=wm(outside,duration),
 outside_max=max(outside,na.rm=TRUE),inside_mean=wm(inside,duration),
 q_under_01_fraction=mean(value<.1),q_above_10_fraction=mean(value>10),
 day_q=mean(value[hour>=12 & hour<18]),night_q=mean(value[hour<6]),
 corr_q_outside=co(value,outside),coverage_mean=wm(coverage,duration)),by=.(campaign,housing)]
whole<-summarise(q);common<-summarise(q[days<33]);early<-summarise(q[days<7])
csv(whole,'gesamte_mast');csv(common,'gemeinsame_33_tage');csv(early,'erste_7_tage')
stage<-q[days<33,.(q_mean=wm(value,duration),q_max=max(value),q_sd=sd(value),
 outside_mean=wm(outside,duration),inside_mean=wm(inside,duration),
 q_under_01_fraction=mean(value<.1),day_q=mean(value[hour>=12 & hour<18]),night_q=mean(value[hour<6]),
 corr_q_outside=co(value,outside),corr_q_demand=co(value,lueftung_bed_normalisiert)),by=.(campaign,housing,phase)]
csv(stage,'mastphasen')
daily<-q[days<33,.(q_mean=wm(value,duration),q_max=max(value),q_min=min(value),
 outside_mean=wm(outside,duration),outside_max=max(outside,na.rm=TRUE)),by=.(campaign,housing,day)]
csv(daily,'tagesmittel')
profiles<-q[days<7,.(q_mean=mean(value),q_median=median(value)),by=.(campaign,housing,hour)]
csv(profiles,'tagesgang_erste_woche')
fan<-ch[days<33,.(q_mean=wm(value,duration),q_max=max(value),volume=sum(value*duration),
 coverage_mean=wm(coverage,duration),bfn_time_mean=wm(bfn_extrapolated,duration),
 bfn_volume_indicator=wm(bfn_extrapolated,value*duration),
 low_time_mean=wm(low_frequency,duration),low_known_fraction=mean(is.finite(low_frequency)),
 low_volume_indicator=wm(low_frequency,value*duration)),by=.(campaign,housing,location)]
fan[,volume_share:=volume/sum(volume),by=.(campaign,housing)]
csv(fan,'einzelventilatoren_33_tage')
quality<-ch[days<33,.(channel_coverage_mean=wm(coverage,duration),
 bfn_channel_time_mean=wm(bfn_extrapolated,duration),bfn_volume_indicator=wm(bfn_extrapolated,value*duration),
 low_channel_time_mean=wm(low_frequency,duration),low_known_fraction=mean(is.finite(low_frequency)),
 low_volume_indicator=wm(low_frequency,value*duration)),by=.(campaign,housing)]
csv(quality,'datenherkunft_33_tage')
csv(q,'stundenwerte_gesamt');csv(ch,'stundenwerte_kanaele')

# Rein deskriptiv: Zusammenhang mit Temperatur bei Kontrolle des Mastalters.
reg<-q[days<33,{
 m<-lm(value~splines::ns(days,df=4)+outside)
 a<-lm(value~splines::ns(days,df=4))
 .(outside_coefficient=coef(m)['outside'],r2_age=summary(a)$r.squared,
 r2_age_temperature=summary(m)$r.squared)
},by=.(campaign,housing)]
csv(reg,'deskriptive_temperatur_regression')

cols<-c('#4679B0','#329752','#D19122','#7A67AD','#C3473D')
for(early_plot in c(FALSE,TRUE)){
 name<-if(early_plot)'luftmenge_ersten_7_tage.png' else 'luftmenge_ganze_mast.png'
 png(file.path(out,name),width=1800,height=2000,res=160)
 par(mfrow=c(5,2),mar=c(3.8,4,2,1),oma=c(1,0,2,0))
 for(id in ids)for(j in 1:2){
  d<-q[campaign==id & housing==paste0('housing_',j)]
  if(early_plot)d<-d[days<7]
  plot(d$days,d$value,type='s',col=cols[match(id,ids)],lwd=1.1,
   xlim=if(early_plot)c(0,7) else c(0,35),ylim=c(0,25),xaxs='i',yaxs='i',
   main=paste(labels[id],'- Stall',j),xlab='Mastdauer [Tage]',ylab='Luft [m3/s]',las=1)
  grid(col='#dddddd')
 }
 mtext('Luftvolumenstrom: identische Achsen, aktuelle gespeicherte Stundenwerte',outer=TRUE,side=3,font=2)
 dev.off()
}
png(file.path(out,'tagesgang_und_mastphasen.png'),width=1800,height=1400,res=160)
par(mfrow=c(2,2),mar=c(4.5,4.5,3,1))
for(mode in c('hour','phase'))for(j in 1:2){
 plot(NA,xlim=if(mode=='hour')c(0,23) else c(1,3),ylim=c(0,22),
  xaxt=if(mode=='phase')'n' else 's',xlab=if(mode=='hour')'Uhrzeit (Europe/Zurich)' else 'Mastphase [Tage]',
  ylab='Mittlerer Luftstrom [m3/s]',main=paste('Stall',j,if(mode=='hour')'- erste Woche' else '- nach Mastphase'),las=1)
 grid(col='#dddddd')
 if(mode=='phase')axis(1,at=1:3,labels=c('0-7','7-21','21-33'))
 for(i in seq_along(ids)){
  if(mode=='hour'){d<-profiles[campaign==ids[i] & housing==paste0('housing_',j)][order(hour)];lines(d$hour,d$q_mean,col=cols[i],lwd=2)}
  else{d<-stage[campaign==ids[i] & housing==paste0('housing_',j)][order(phase)];lines(1:3,d$q_mean,col=cols[i],lwd=2,type='b',pch=16)}
 }
 legend('topleft',legend=unname(labels),col=cols,lty=1,bty='n',cex=.7)
}
dev.off()
locations<-c('vent_links','vent_mlinks','vent_mrechts','vent_rechts','vent_turbo','vent_wrg')
png(file.path(out,'anteile_einzelventilatoren.png'),width=1800,height=1050,res=160)
par(mfrow=c(1,2),mar=c(5,4,3,1),oma=c(4,0,0,0))
fcols<-c('#347CAD','#66A591','#B9CB77','#D7AA49','#BB6763','#8B75A5')
for(j in 1:2){
 m<-matrix(0,nrow=length(locations),ncol=length(ids),dimnames=list(locations,ids))
 d<-fan[housing==paste0('housing_',j)]
 for(k in seq_len(nrow(d)))m[d$location[k],d$campaign[k]]<-d$q_mean[k]
 barplot(m,col=fcols,names.arg=c('Feb24','Apr24','Jul24','Dez24','Aug26'),
 ylim=c(0,16),ylab='Mittlerer Luftstrom [m3/s]',main=paste('Stall',j,'- erste 33 Tage'),las=1)
}
par(fig=c(0,1,0,.15),new=TRUE,mar=c(0,0,0,0));plot.new()
legend('center',legend=locations,fill=fcols,bty='n',ncol=3,cex=.9)
dev.off()

# Audit: Turbo-Bericht versus aufgezeichnete Frequenz und Steuerung 2026.
path<-file.path(root,'mettmenstetten-aug2026/rsaves/all-meas.fan.rds')
f9<-readRDS(path)[['frequi9']]
origin<-readRDS(file.path(root,'mettmenstetten-aug2026/rsaves/local-times.rds'))[[1]][['from']]
end<-readRDS(file.path(root,'mettmenstetten-aug2026/rsaves/local-times.rds'))[[1]][['to']]
r<-as.data.table(pool(f9[,c('Hz','flow_m3_s')],granularity='1hours',st.to=origin,et.to=end))
d<-merge(r,ch[campaign=='aug2026' & housing=='housing_1' & location=='vent_turbo',.(st,et,final_q=value)],by=c('st','et'))
d<-merge(d,q[campaign=='aug2026' & housing=='housing_1',.(st,et,days,abluft_vent_turbo)],by=c('st','et'))
csv(d,'audit_turbo_2026')
audit<-d[,.(mean_Hz=mean(Hz,na.rm=TRUE),max_Hz=max(Hz,na.rm=TRUE),
 mean_raw_q=mean(flow_m3_s,na.rm=TRUE),mean_final_q=mean(final_q),
 above8_control_fraction=mean(abluft_vent_turbo>8,na.rm=TRUE),
 corr_raw_final=co(flow_m3_s,final_q),corr_control_q=co(abluft_vent_turbo,final_q))]
csv(audit,'audit_turbo_zusammenfassung')
csv(data.table(path=paths,mtime=as.character(file.info(paths)$mtime),md5=unname(tools::md5sum(paths))),'quellen')
print(common[,.(campaign,housing,q_mean,m3_h_animal,outside_mean,coverage_mean)])
print(stage[,.(campaign,housing,phase,q_mean,day_q,night_q)])
print(fan[campaign=='aug2026',.(housing,location,q_mean,volume_share)])
print(quality);print(audit)
stopifnot(nrow(common)==10,all(common$hours==792),nrow(stage)==30)
message('Vergleich gespeichert: ',out)


# Gemeinsamer Tagesverlauf aller Kampagnen, identische Skala beider Staelle.
png(file.path(out,'luftmenge_tagesverlauf_alle_kampagnen.png'),width=1900,height=1200,res=170)
par(mfrow=c(2,1),mar=c(4,4.5,2.5,1),oma=c(1,0,2,0))
for(j in 1:2){
 plot(NA,xlim=c(0,33),ylim=c(0,25),xaxs='i',yaxs='i',
  xlab='Mastdauer [Tage]',ylab='Luftvolumenstrom [m3/s]',main=paste('Stall',j),las=1)
 grid(col='#dddddd')
 for(i in seq_along(ids)){
  a<-daily[campaign==ids[i] & housing==paste0('housing_',j)][order(day)]
  lines(a$day+.5,a$q_mean,col=cols[i],lwd=2,type='o',pch=16,cex=.45)
 }
 legend('topleft',legend=unname(labels),col=cols,lty=1,lwd=2,bty='n',cex=.8,ncol=2)
}
mtext('Lueftungsverlauf aller Kampagnen: Tagesmittel der ersten 33 Masttage',outer=TRUE,side=3,font=2)
dev.off()
