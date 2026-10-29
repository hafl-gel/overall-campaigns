# Relative Feuchte der Abluft: alle Kampagnen einschliesslich August 2026.
working_directory<-path.expand("~/git/overall-campaigns");setwd(working_directory)
source("kampagnen_daten.R")
overall_check_packages(c("data.table","qs2","lubridate","ggplot2","mgcv"))
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(mgcv)})
cfg_rh<-list(root=path.expand("~/git"),campaigns=c("feb","apr","jul","dec","aug"),
 agg_interval="1minute",exclude_location="turbo",
 # FALSE erhaelt das bisherige deskriptive Sammelmodell. TRUE beruecksichtigt Kampagnenniveaus.
 include_campaign_effect=FALSE,
 out=file.path(working_directory,"ergebnisse_klima","rh"))
reg<-overall_campaign_registry(cfg_rh$root)[match(cfg_rh$campaigns,code)]
if(anyNA(reg$id))stop("Unbekannte Kampagne.")
path_datasets<-setNames(as.list(reg$path),reg$code);agg_interval<-cfg_rh$agg_interval
all_rh<-rbindlist(lapply(seq_len(nrow(reg)),function(i)overall_rh(reg[i],agg_interval,cfg_rh$exclude_location)))
all_rh<-overall_labels(all_rh,reg)
p_rh<-ggplot(all_rh,aes(masttag,rh_mean,colour=housing,group=housing))+
 geom_line(linewidth=.75,alpha=.85)+facet_wrap(~campaign,ncol=2,scales="free_x")+
 labs(title="Relative Humidity in Exhaust Air",x="Days after placement",y="RH [%]",colour="Barn")+
 scale_colour_manual(values=c("Barn 1"="red","Barn 2"="blue"))+overall_theme()
if(interactive())print(p_rh);overall_save_plot(p_rh,cfg_rh$out,"rh_verlauf",1+3.2*ceiling(nrow(reg)/2))
gam_data<-all_rh[is.finite(masttag)&is.finite(rh_mean)]
model_formula<-if(cfg_rh$include_campaign_effect)rh_mean~s(masttag,by=housing)+housing+campaign else rh_mean~s(masttag,by=housing)+housing
gam_model<-gam(model_formula,data=gam_data,method="REML")
pred_df<-rbindlist(lapply(seq_len(nrow(reg)),function(i){
 rr<-reg[i]
 rbindlist(lapply(levels(gam_data$housing),function(h){
  z<-gam_data[campaign_code==rr$code & housing==h]
  data.table(masttag=seq(min(z$masttag),max(z$masttag),length.out=250),
   housing=factor(h,levels=levels(gam_data$housing)),
   campaign=factor(rr$label,levels=levels(gam_data$campaign)))
 }))
}))
pr<-predict(gam_model,newdata=pred_df,se.fit=TRUE)
pred_df[,`:=`(fit=as.numeric(pr$fit),se=as.numeric(pr$se.fit))]
p_gam<-ggplot(gam_data,aes(masttag,rh_mean,colour=housing))+
 geom_point(alpha=.12,size=.35)+
 geom_ribbon(data=pred_df,aes(x=masttag,y=fit,ymin=fit-2*se,ymax=fit+2*se,fill=housing),alpha=.18,colour=NA)+
 geom_line(data=pred_df,aes(y=fit,group=housing),linewidth=1)+facet_wrap(~campaign,ncol=2)+
 scale_colour_manual(values=c("Barn 1"="red","Barn 2"="blue"))+
 scale_fill_manual(values=c("Barn 1"="red","Barn 2"="blue"))+
 labs(title="GAM-Modelled RH Trajectories in Exhaust Air",x="Days after placement",y="RH [%]",colour="Barn",fill="Barn",
 caption="Deskriptives Sammelmodell ueber alle dargestellten Kampagnen; keine isolierte WRG-Wirkung.")+overall_theme()
if(interactive())print(p_gam);overall_save_plot(p_gam,cfg_rh$out,"rh_gam",1+3.2*ceiling(nrow(reg)/2))
overall_csv(all_rh,cfg_rh$out,"rh_verlauf")
overall_csv(pred_df,cfg_rh$out,"rh_gam_prognosen")
qc<-all_rh[,.(intervals=.N,n_above_100=sum(n_rh_above_100),n_below_0=sum(n_rh_below_0),
 min_sensor_mean=min(rh_mean,na.rm=TRUE),max_sensor_mean=max(rh_mean,na.rm=TRUE)),by=.(campaign,housing)]
overall_csv(qc,cfg_rh$out,"rh_qualitaetskontrolle")
capture.output(summary(gam_model),file=file.path(cfg_rh$out,"gam_zusammenfassung.txt"))
saveRDS(gam_model,file.path(cfg_rh$out,"gam_modell.rds"))
overall_provenance(reg,cfg_rh$out);dput(cfg_rh,file=file.path(cfg_rh$out,"parameter.R"))
writeLines(c("Arithmetischer Sensormittelwert, nicht nach Luftvolumenstrom gewichtet.",
 "Vorhandene RH-Werte ausserhalb 0-100 % werden protokolliert und nicht gekappt.",
 "Mastdauer aus local-times.rds. Aggregation nach Zeitintervall, ohne versehentliche Gruppierung nach jedem Einzelzeitpunkt.",
 "Die GAM-Fehlerbaender setzen keine explizite Zeitreihen-Autokorrelation um."),file.path(cfg_rh$out,"methodik.txt"))
writeLines("ERFOLGREICH",file.path(cfg_rh$out,"laufstatus.txt"))
print(qc)
