# Unabhaengige Diagnose; veraendert weder Quelldaten noch Jahresauswertung.
suppressPackageStartupMessages({library(qs2);library(data.table)})
root<-path.expand('~/git')
out<-file.path(root,'overall-campaigns','diagnose_fruehe_emissionen')
dir.create(out,showWarnings=FALSE,recursive=TRUE)
ids<-c('feb2024','apr2024','jul2024','dec2024','aug2026')
labels<-c('Februar 2024','April 2024','Juli 2024','Dezember 2024','Juli/August 2026')
names(labels)<-ids
netlist<-list();balancelist<-list();stats<-list()
safe_cor<-function(a,b)if(sd(a,na.rm=TRUE)>0 && sd(b,na.rm=TRUE)>0) cor(a,b,use='complete.obs') else NA_real_
for(id in ids){
 x<-qs2::qd_read(file.path(root,paste0('mettmenstetten-',id),'rsaves/final-dataset.qd'))
 z<-copy(x[tracer=='nh3' & type=='flow' & location=='total' & flow_direction=='net'])
 z[,campaign:=id];netlist[[id]]<-z
 st<-z[,.(n_first7=sum(days<7),missing_first7=sum(!is.finite(value[days<7])),
  report_ymax_current=max(value,na.rm=TRUE),
  early_mean=mean(value[days<7],na.rm=TRUE),early_sd=sd(value[days<7],na.rm=TRUE),
  early_max=max(value[days<7],na.rm=TRUE),early_zero_fraction=mean(value[days<7]==0,na.rm=TRUE),
  early_hour_diff_sd=sd(diff(value[days<7]),na.rm=TRUE)),by=.(campaign,housing)]
 b<-dcast(x[tracer=='nh3' & type=='flow' & location=='total'],
  housing+st+et+days~flow_direction,value.var='value')
 q<-x[tracer=='airflow' & type=='flow' & location=='total' & flow_direction=='outflow',
  .(housing,st,et,q=value)]
 b<-merge(b,q,by=c('housing','st','et'));b[,signed:=outflow-inflow]
 b[,`:=`(cin=inflow/q,cout=outflow/q,delta_c=signed/q,campaign=id)]
 balancelist[[id]]<-b
 bs<-b[days<7,.(q_mean=mean(q,na.rm=TRUE),
  signed_mean=mean(signed,na.rm=TRUE),signed_negative_fraction=mean(signed<0,na.rm=TRUE),
  corr_net_airflow=safe_cor(net,q),corr_net_delta_c=safe_cor(net,delta_c)),by=housing]
 stats[[id]]<-merge(st,bs,by='housing')
}
net<-rbindlist(netlist,use.names=TRUE,fill=TRUE);balance<-rbindlist(balancelist,use.names=TRUE,fill=TRUE);stats<-rbindlist(stats)
fwrite(stats,file.path(out,'kennzahlen_ersten_7_tage.csv'),sep=';',dec=',',bom=TRUE)
fwrite(balance[days<7],file.path(out,'massenbilanz_ersten_7_tage.csv'),sep=';',dec=',',bom=TRUE)
cols<-c('#A7443F','#2479AD')
overview<-function(name,xx,yy){
 png(file.path(out,name),width=1700,height=1900,res=160)
 par(mfrow=c(5,2),mar=c(3.2,4,2.3,1),oma=c(2,0,3,0))
 for(id in ids)for(j in 1:2){
  z<-net[campaign==id & housing==paste0('housing_',j)]
  plot(z$days,z$value,type='s',xlim=xx,ylim=yy,xaxs='i',yaxs='i',
   col=cols[j],lwd=1.2,xlab='Mastdauer [Tage]',ylab='NH3 netto [mg/s]',
   main=paste(labels[id],paste('Stall',j),sep=' - '),las=1)
  grid(col='#dddddd')
 }
 mtext('Identische Achsen fuer alle Kampagnen und beide Staelle',outer=TRUE,side=3,font=2,line=1)
 mtext('Gespeicherte stuendliche Raten; negative Nettowerte wurden vorgaengig auf null gesetzt.',outer=TRUE,side=1,line=.5,cex=.8)
 dev.off()
}
overview('vergleich_ersten_7_tage_gleiche_achse.png',c(0,7),c(0,6))
overview('vergleich_gesamte_mast_gleiche_achse.png',c(0,35),c(0,100))
png(file.path(out,'aug2026_bilanz_und_luftmenge.png'),width=1700,height=1400,res=160)
par(mfrow=c(3,2),mar=c(4,4,2,1),oma=c(1,0,2,0))
for(metric in c('net','q','delta_c'))for(j in 1:2){
 z<-balance[campaign=='aug2026' & days<7 & housing==paste0('housing_',j)]
 val<-z[[metric]]
 plot(z$days,val,type='s',col=cols[j],lwd=1.3,xlim=c(0,7),
  xlab='Mastdauer [Tage]',ylab=switch(metric,net='NH3 netto [mg/s]',q='Luftvolumenstrom [m3/s]',delta_c='C Abluft - C Zuluft [mg/m3]'),
  main=paste('Stall',j),las=1);grid(col='#dddddd')
}
mtext('Juli/August 2026: Emission, Luftmenge und effektive Konzentrationsdifferenz',outer=TRUE,side=3,font=2)
dev.off()
print(stats[,.(campaign,housing,report_ymax_current,early_mean,early_sd,early_max,early_zero_fraction,q_mean,corr_net_airflow)])
stopifnot(nrow(stats)==10,all(stats$n_first7==168),all(stats$missing_first7==0))
message('Diagnose gespeichert: ',out)
