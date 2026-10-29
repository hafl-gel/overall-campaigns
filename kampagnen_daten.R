# Gemeinsamer Kampagnenimport fuer Aussentemp.R, RH-Graph.R und gam_rh_analysis.R.
# QD ist das aktuelle Format der Kampagnenauswertungen. Quelldateien werden nur gelesen.
overall_campaign_registry<-function(root=path.expand("~/git")){
 data.table::data.table(code=c("feb","apr","jul","dec","aug"),
  id=c("feb2024","apr2024","jul2024","dec2024","aug2026"),
  label=c("Feb-24","Apr-24","Jul-24","Dec-24","Aug-26"),
  season=c("Winter","Transition","Summer","Winter","Summer"),
  wrg_active=c(TRUE,TRUE,TRUE,FALSE,FALSE))[
   ,path:=file.path(root,paste0("mettmenstetten-",id),"rsaves","final-dataset.qd")]
}
overall_check_packages<-function(packages){
 missing<-packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
 if(length(missing))stop("Fehlende Pakete: ",paste(missing,collapse=", "))
}
overall_csv<-function(x,out,name){
 dir.create(out,recursive=TRUE,showWarnings=FALSE)
 data.table::fwrite(x,file.path(out,paste0(name,".csv")),sep=";",dec=",",bom=TRUE,na="NA")
}
overall_source<-function(regrow){
 path<-path.expand(regrow$path)
 if(!file.exists(path))stop("Kampagnendatei fehlt: ",path)
 d<-data.table::as.data.table(qs2::qd_read(path))
 p<-readRDS(file.path(dirname(path),"local-times.rds"))
 if(!all(c("housing","st","sensor","value","tracer","flow_direction","location") %in% names(d)))stop("Unbekanntes Datenschema: ",regrow$id)
 starts<-setNames(vapply(c("housing_1","housing_2"),function(h)as.numeric(p[[h]][["from"]]),numeric(1)),c("housing_1","housing_2"))
 list(data=d,starts=starts)
}
overall_temperature<-function(regrow){
 src<-overall_source(regrow);d<-data.table::copy(src$data[sensor=="außentemp"])
 if(!nrow(d))stop("Aussentemperatur fehlt: ",regrow$id)
 if(any(!d$housing %in% names(src$starts)))stop("Unbekannter Stall.")
 d[,masttag:=(as.numeric(st)-src$starts[housing])/86400]
 d[,campaign:=regrow$code]
 data.table::setorder(d,housing,st)
 d[,.(st,masttag,value,housing,campaign)]
}
overall_rh<-function(regrow,interval="hour",exclude_location="turbo"){
 src<-overall_source(regrow)
 d<-data.table::copy(src$data[tracer=="humidity" & flow_direction=="outflow" & grepl("^nh3_",sensor)])
 if(nzchar(exclude_location))d<-d[!grepl(exclude_location,location,ignore.case=TRUE)]
 if(!nrow(d))stop("RH-Daten fehlen: ",regrow$id)
 if(any(d$units!="%"))stop("RH-Einheit ist nicht Prozent.")
 if(anyDuplicated(d[,.(housing,sensor,st)]))stop("Mehrdeutige Sensorreihe: ",regrow$id)
 d[,agg_time:=lubridate::floor_date(st,unit=interval)]
 ans<-d[,.(rh_mean=if(any(is.finite(value)))mean(value[is.finite(value)]) else NA_real_,
  rh_sd=if(sum(is.finite(value))>1)sd(value[is.finite(value)]) else NA_real_,
  n=.N,n_sensors=data.table::uniqueN(sensor),
  n_rh_above_100=sum(value>100,na.rm=TRUE),n_rh_below_0=sum(value<0,na.rm=TRUE)),
  by=.(housing,agg_time)]
 ans[,`:=`(st=agg_time,masttag=(as.numeric(agg_time)-src$starts[housing])/86400,campaign=regrow$code)]
 data.table::setorder(ans,housing,st)
 ans
}
overall_labels<-function(x,reg){
 x<-data.table::copy(x)
 x[,`:=`(campaign_code=as.character(campaign),housing_code=as.character(housing))]
 x[,campaign:=factor(campaign,levels=reg$code,labels=reg$label)]
 x[,housing:=factor(housing,levels=c("housing_1","housing_2"),labels=c("Barn 1","Barn 2"))]
 x[,`:=`(wrg_active=reg$wrg_active[match(campaign_code,reg$code)],season=reg$season[match(campaign_code,reg$code)])]
 if(anyNA(x$campaign)||anyNA(x$housing))stop("Fehlende Kampagnen-/Stallzuordnung.")
 x
}
overall_theme<-function(){
 ggplot2::theme_minimal(base_size=13)+ggplot2::theme(
  legend.position="bottom",strip.text=ggplot2::element_text(face="bold"),
  axis.text=ggplot2::element_text(colour="black"),
  plot.title=ggplot2::element_text(size=20,face="bold"))
}
overall_save_plot<-function(p,out,name,height=8.5){
 dir.create(out,recursive=TRUE,showWarnings=FALSE)
 ggplot2::ggsave(file.path(out,paste0(name,".png")),plot=p,width=12,height=height,dpi=300,bg="white")
 ggplot2::ggsave(file.path(out,paste0(name,".pdf")),plot=p,width=12,height=height,device=grDevices::cairo_pdf,bg="white")
}
overall_provenance<-function(reg,out){
 z<-data.table::copy(reg);z[,md5:=unname(tools::md5sum(path))]
 overall_csv(z,out,"kampagnen_und_quellen")
}
