# GAM-Analyse der Abluftfeuchte; August 2026 ist eine Offsetkampagne ohne WRG.
working_directory<-path.expand("~/git/overall-campaigns");setwd(working_directory)
source("kampagnen_daten.R")
overall_check_packages(c("data.table","qs2","lubridate","ggplot2","mgcv"))
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(mgcv)})
cfg_gam<-list(root=path.expand("~/git"),campaigns=c("feb","apr","jul","dec","aug"),
 agg_interval="hour",exclude_location="turbo",diagnostic_seed=20261029,
 out=file.path(working_directory,"ergebnisse_klima","gam_rh"))
reg<-overall_campaign_registry(cfg_gam$root)[match(cfg_gam$campaigns,code)]
if(anyNA(reg$id))stop("Unbekannte Kampagne.")
path_datasets<-setNames(as.list(reg$path),reg$code)
all_rh<-rbindlist(lapply(seq_len(nrow(reg)),function(i)overall_rh(reg[i],cfg_gam$agg_interval,cfg_gam$exclude_location)))
all_rh<-overall_labels(all_rh,reg)
overall_csv(all_rh[!is.finite(rh_mean)|!is.finite(masttag)],cfg_gam$out,"fehlende_rh_intervalle")
all_rh<-all_rh[is.finite(rh_mean)&is.finite(masttag)]
rh_main<-all_rh[wrg_active==TRUE] # Februar, April, Juli 2024
rh_offsets<-all_rh[wrg_active==FALSE] # Dezember 2024 und August 2026
rh_dec<-all_rh[campaign_code=="dec"];rh_aug<-all_rh[campaign_code=="aug"]
dir.create(cfg_gam$out,recursive=TRUE,showWarnings=FALSE)
gam_models<-list();predictions<-list();model_notes<-character()
for(label in as.character(reg$label)){
 dat<-droplevels(all_rh[as.character(campaign)==label])
 model<-gam(rh_mean~s(masttag,by=housing)+housing,data=dat,method="REML")
 gam_models[[label]]<-model
 model_notes<-c(model_notes,paste0("\n### ",label," ###"),capture.output(summary(model)))
 grid<-rbindlist(lapply(levels(dat$housing),function(h){
  z<-dat[housing==h]
  data.table(masttag=seq(min(z$masttag),max(z$masttag),length.out=250),
    housing=factor(h,levels=levels(dat$housing)))
 }))
 pr<-predict(model,newdata=grid,se.fit=TRUE)
 grid[,`:=`(fit=as.numeric(pr$fit),se=as.numeric(pr$se.fit),campaign=label)]
 predictions[[label]]<-grid
 saveRDS(model,file.path(cfg_gam$out,paste0("gam_",gsub("-","_",label),".rds")))
}
fit_pool<-function(d){
 d<-droplevels(d)
 if(uniqueN(d$campaign)>1)gam(rh_mean~s(masttag,by=housing)+housing+campaign,data=d,method="REML")
 else gam(rh_mean~s(masttag,by=housing)+housing,data=d,method="REML")
}
gam_main<-if(nrow(rh_main))fit_pool(rh_main) else NULL
gam_offsets<-if(nrow(rh_offsets))fit_pool(rh_offsets) else NULL
gam_dec<-gam_models[["Dec-24"]];gam_aug<-gam_models[["Aug-26"]]
for(name in c("gam_main","gam_offsets")){
 model<-get(name)
 if(!is.null(model)){
  saveRDS(model,file.path(cfg_gam$out,paste0(name,".rds")))
  model_notes<-c(model_notes,paste0("\n### ",name," ###"),capture.output(summary(model)))
 }
}
writeLines(model_notes,file.path(cfg_gam$out,"gam_zusammenfassungen.txt"))
set.seed(cfg_gam$diagnostic_seed)
pdf(file.path(cfg_gam$out,"gam_diagnostik.pdf"),width=10,height=8)
diagnostic_text<-capture.output(for(name in names(gam_models)){
 cat("\n### ",name," ###\n");par(mfrow=c(2,2));gam.check(gam_models[[name]],k.rep=100)
})
writeLines(diagnostic_text,file.path(cfg_gam$out,"gam_diagnostik.txt"))
dev.off()
pred_df<-rbindlist(predictions)
pred_df[,campaign:=factor(campaign,levels=reg$label)]
p_rh<-ggplot(all_rh,aes(masttag,rh_mean,colour=housing,group=housing))+
 geom_line(linewidth=.7,alpha=.8)+facet_wrap(~campaign,ncol=2,scales="free_x")+
 scale_colour_manual(values=c("Barn 1"="red","Barn 2"="blue"))+
 labs(title="Relative Humidity in Exhaust Air During Fattening Cycles",
 x="Days after placement",y="Relative Humidity (%)",colour="Barn")+overall_theme()
p_fit<-ggplot(pred_df,aes(masttag,fit,colour=housing,fill=housing))+
 geom_ribbon(aes(ymin=fit-2*se,ymax=fit+2*se),alpha=.18,colour=NA)+geom_line(linewidth=.9)+
 facet_wrap(~campaign,ncol=2,scales="free_x")+
 scale_colour_manual(values=c("Barn 1"="red","Barn 2"="blue"))+
 scale_fill_manual(values=c("Barn 1"="red","Barn 2"="blue"))+
 labs(title="Separate GAM Fits by Campaign",x="Days after placement",y="Relative Humidity (%)",colour="Barn",fill="Barn",
 caption="Dec-24 and Aug-26: both barns without heat recovery.")+overall_theme()
if(interactive())print(p_rh);if(interactive())print(p_fit)
height<-1+3.2*ceiling(nrow(reg)/2)
overall_save_plot(p_rh,cfg_gam$out,"rh_alle_kampagnen",height)
overall_save_plot(p_fit,cfg_gam$out,"gam_je_kampagne",height)
overall_csv(all_rh,cfg_gam$out,"rh_modellwerte");overall_csv(pred_df,cfg_gam$out,"gam_prognosen")
qc<-all_rh[,.(intervals=.N,n_above_100=sum(n_rh_above_100),n_below_0=sum(n_rh_below_0)),by=.(campaign,housing)]
overall_csv(qc,cfg_gam$out,"rh_qualitaetskontrolle")
overall_provenance(reg,cfg_gam$out);dput(cfg_gam,file=file.path(cfg_gam$out,"parameter.R"))
writeLines(c("Einzelmodelle fuer alle fuenf Kampagnen.",
 "gam_main: nur WRG-Kampagnen Februar/April/Juli 2024; gam_offsets: Dezember 2024/August 2026 ohne WRG.",
 "Die gemeinsame Kampagnenanalyse enthaelt einen Kampagneneffekt. Keine explizite Korrektur serieller Autokorrelation.",
 "Deskriptive GAM-Analysen; p-Werte und punktweise Baender sind keine kausale WRG-Wirkung.",
 "RH-Werte ausserhalb 0-100 % bleiben enthalten und werden separat protokolliert."),file.path(cfg_gam$out,"methodik.txt"))
writeLines("ERFOLGREICH",file.path(cfg_gam$out,"laufstatus.txt"))
print(qc)
