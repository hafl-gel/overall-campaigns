# Aussentemperatur aller Kampagnen einschliesslich August 2026.
working_directory<-path.expand("~/git/overall-campaigns");setwd(working_directory)
source("kampagnen_daten.R")
overall_check_packages(c("data.table","qs2","ggplot2"))
suppressPackageStartupMessages({library(data.table);library(ggplot2)})
cfg_temp<-list(root=path.expand("~/git"),campaigns=c("feb","apr","jul","dec","aug"),
 out=file.path(working_directory,"ergebnisse_klima","aussentemperatur"))
reg<-overall_campaign_registry(cfg_temp$root)[match(cfg_temp$campaigns,code)]
if(anyNA(reg$id))stop("Unbekannte Kampagne.")
path_datasets<-setNames(as.list(reg$path),reg$code)
all_temp<-rbindlist(lapply(seq_len(nrow(reg)),function(i)overall_temperature(reg[i])))
all_temp<-overall_labels(all_temp,reg)
p_temp<-ggplot(all_temp,aes(masttag,value,colour=housing,group=housing))+
 geom_line(linewidth=.75,alpha=.85)+facet_wrap(~campaign,ncol=2,scales="free_x")+
 labs(title="Outdoor Temperature Profiles During Fattening Cycles",
  x="Days after placement",y="Temperature [°C]",colour="Barn")+
 scale_colour_manual(values=c("Barn 1"="red","Barn 2"="blue"))+overall_theme()
if(interactive())print(p_temp)
overall_save_plot(p_temp,cfg_temp$out,"aussentemperatur",height=1+3.2*ceiling(nrow(reg)/2))
# Unveraendert arithmetischer Mittelwert ueber beide Stallmessungen.
temp_summary_campaign<-all_temp[,.(mean_temp=mean(value,na.rm=TRUE),
 min_temp=min(value,na.rm=TRUE),max_temp=max(value,na.rm=TRUE),n=sum(is.finite(value))),by=campaign][order(campaign)]
temp_summary_barn<-all_temp[,.(mean_temp=mean(value,na.rm=TRUE),
 min_temp=min(value,na.rm=TRUE),max_temp=max(value,na.rm=TRUE),n=sum(is.finite(value))),by=.(campaign,housing)][order(campaign,housing)]
overall_csv(temp_summary_campaign,cfg_temp$out,"temperatur_nach_kampagne")
overall_csv(temp_summary_barn,cfg_temp$out,"temperatur_nach_kampagne_stall")
overall_csv(all_temp,cfg_temp$out,"temperatur_verlauf")
overall_provenance(reg,cfg_temp$out)
dput(cfg_temp,file=file.path(cfg_temp$out,"parameter.R"))
writeLines("ERFOLGREICH",file.path(cfg_temp$out,"laufstatus.txt"))
print(temp_summary_campaign)
