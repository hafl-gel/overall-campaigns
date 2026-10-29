suppressPackageStartupMessages(library(data.table))
base<-path.expand('~/git/overall-campaigns')
out<-file.path(base,'vergleich_extrapolation');dir.create(out,recursive=TRUE,showWarnings=FALSE)
csv<-function(x,n)fwrite(x,file.path(out,paste0(n,'.csv')),sep=';',dec=',',bom=TRUE)
d<-fread(file.path(base,'ergebnisse_bericht/tageswerte_kumuliert.csv'),dec=',')
methods<-c('quadratisch_frei8','quadratisch_verankert8','konstante_rate3','linearer_ratentrend5','gedaempfter_ratentrend5')
forecast<-function(train,target,method){
 train<-copy(train);setorder(train,day);x0<-tail(train$day,1);y0<-tail(train$ef,1);h<-target-x0
 if(method%in%c('quadratisch_frei8','quadratisch_verankert8')){
  f<-tail(train,8);f[,`:=`(t=day-x0,y=ef-y0)]
  if(method=='quadratisch_frei8'){m<-lm(ef~t+I(t^2),data=f);return(as.numeric(predict(m,data.frame(t=h))))}
  m<-lm(y~0+t+I(t^2),data=f);return(y0+as.numeric(predict(m,data.frame(t=h))))
 }
 rates<-data.table(day=(head(train$day,-1)+tail(train$day,-1))/2,
 rate=diff(train$ef)/diff(train$day))
 if(method=='konstante_rate3')return(y0+pmax(0,mean(tail(rates$rate,3)))*h)
 r<-tail(rates,5);r[,t:=day-x0];m<-lm(rate~t,data=r);r0<-coef(m)[1];b<-coef(m)[2]
 vapply(h,function(hh)y0+integrate(function(u){
  trend<-if(method=='gedaempfter_ratentrend5')(1-exp(-.5*u))/.5 else u
  pmax(r0+b*trend,0)
 },0,hh)$value,numeric(1))
}
backtests<-list();k<-0
for(id in unique(d$campaign))for(h in unique(d$housing)){
 z<-d[campaign==id & housing==h][order(day)]
 for(cutoff in 26:30){
  train<-z[day<=cutoff+1e-6];target<-cutoff+1:3
  truth<-approx(z$day,z$ef,xout=target)$y
  scale<-mean(abs(diff(tail(train$ef,8))))
  for(method in methods){
   k<-k+1;p<-forecast(train,target,method)
   backtests[[k]]<-data.table(campaign=id,housing=h,cutoff=cutoff,horizon=1:3,
    method=method,observed=truth,predicted=p,error=p-truth,
    scaled_abs_error=abs(p-truth)/max(scale,1e-8))
  }
 }
}
bt<-rbindlist(backtests);csv(bt,'ruecktests_einzelwerte')
metrics<-bt[,.(n=.N,mae_g_animal=mean(abs(error)),rmse_g_animal=sqrt(mean(error^2)),
 bias_g_animal=mean(error),scaled_mae=mean(scaled_abs_error)),by=method][order(scaled_mae)]
csv(metrics,'ruecktests_gesamt')
csv(bt[,.(mae=mean(abs(error)),scaled_mae=mean(scaled_abs_error)),by=.(method,campaign,housing)],'ruecktests_je_reihe')
csv(bt[,.(mae=mean(abs(error)),rmse=sqrt(mean(error^2)),scaled_mae=mean(scaled_abs_error)),by=.(method,horizon)],'ruecktests_je_horizont')
actual<-rbindlist(lapply(unique(d$campaign),function(id)rbindlist(lapply(unique(d$housing),function(h){
 z<-d[campaign==id & housing==h][order(day)]
 rbindlist(lapply(methods,function(method)data.table(campaign=id,housing=h,method=method,
  day=c(34.25,35.25,36.25),prediction=forecast(z,c(34.25,35.25,36.25),method))))
}))))
csv(actual,'prognosen_nach_messende')
cols<-c('#777777','#C54B44','#347EAD','#3C9B59','#A17AB5')
png(file.path(out,'methodenvergleich_kurven.png'),width=1900,height=2200,res=170)
layout(rbind(matrix(1:10,nrow=5,byrow=TRUE),c(11,11)),heights=c(rep(1,5),.45))
par(mar=c(4,4,2,1),oma=c(0,0,2,0))
for(id in unique(d$campaign))for(h in unique(d$housing)){
 z<-d[campaign==id & housing==h][order(day)];x0<-max(z$day)
 gridx<-seq(x0,36.25,length.out=100)
 pp<-sapply(methods,function(method)forecast(z,gridx,method))
 plot(z$day,z$ef,type='o',pch=16,cex=.45,xlim=c(27,36.5),
 ylim=range(z[day>=27,ef],pp),xlab='Mastdauer [Tage]',ylab='Kumuliert [g/Tier]',main=paste(id,h),las=1)
 grid(col='#dddddd');abline(v=x0,lty=3)
 for(i in seq_along(methods))lines(gridx,pp[,i],col=cols[i],lwd=1.7,lty=i)
}
mtext('Extrapolationsvergleich; Standard: linearer Trend der letzten fuenf Tagesraten',outer=TRUE,side=3,font=2)
par(mar=c(0,0,0,0));plot.new()
legend('center',legend=methods,col=cols,lty=1:5,lwd=1.7,ncol=3,bty='n',cex=.85)
dev.off()
png(file.path(out,'ruecktest_methodenvergleich.png'),width=1500,height=850,res=150)
par(mar=c(9,5,3,1));b<-barplot(metrics$scaled_mae,names.arg=metrics$method,las=2,
 col=cols[match(metrics$method,methods)],ylab='Mittlerer skalierter absoluter Fehler',main='Ruecktest: 5 Urspruenge x 3 Horizonte x 10 Reihen')
dev.off()
print(metrics)
cat('Keine Jahresauswertung oder Produktionsmethode veraendert.\n')
