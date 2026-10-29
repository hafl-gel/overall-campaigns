# Einstreuanalysen Mettmenstetten: Boxplots und Berichtstabellen.
# Start: Rscript einstreu_mettmenstetten.R oder source("einstreu_mettmenstetten.R")
# install.packages(c("readxl","data.table","ggplot2","multcompView"))
# Fuer alternative Tests zusaetzlich: install.packages("rstatix")
working_directory<-path.expand("~/git/overall-campaigns")
setwd(working_directory)
cfg<-list(
 input=file.path(working_directory,"Einstreu","litter_data_all.xlsx"),sheet="Sheet 1",
 out=file.path(working_directory,"Einstreu","ergebnisse_einstreu"),
 campaigns=c("FEB","APR","JUL","DEC","AUG26"),
 historical_comparison=TRUE, # zusaetzlich die urspruenglichen vier Kampagnen
 # Fachlicher Hinweis, kein automatischer Ausschluss und keine Messwertkorrektur:
 sampling_caution_metrics="moisture_pct", # nur die Feuchtigkeit; kein pauschaler Hinweis fuer NH4-N, N oder pH
 sampling_caution="Feuchtigkeit, August 2026, Stall 2, Masttag 34: Der Mittelwert aus fuenf Proben ist moeglicherweise durch eine nicht repraesentative Probenahme beeinflusst. Werte sind enthalten.",
 comparison_day=34,
 test_method="anova_tukey", # Alternativen: "welch_games_howell", "kruskal_dunn"
 alpha=.05,dunn_adjust="holm",
 spread="sd", # Mittelwert +/- Standardabweichung; alternativ "se"
 decimal_mark=",", # "." entspricht der Schreibweise der Vorlagen
 colours=c("1"="#E41A1C","2"="#377EB8"),
 facet_columns=2,base_size=14,dpi=300,export_pdf=TRUE
)
if(exists("einstreu_overrides",inherits=FALSE))cfg<-utils::modifyList(cfg,einstreu_overrides)
stopifnot(cfg$test_method %in% c("anova_tukey","welch_games_howell","kruskal_dunn"),
 cfg$spread %in% c("sd","se"),cfg$alpha>0,cfg$alpha<1,cfg$comparison_day>0)
required<-c("readxl","data.table","ggplot2","multcompView")
if(cfg$test_method!="anova_tukey")required<-c(required,"rstatix")
missing<-required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing))stop("Fehlende Pakete: ",paste(missing,collapse=", "))
suppressPackageStartupMessages({library(data.table);library(ggplot2)})
registry<-data.table(campaign=c("FEB","APR","JUL","DEC","AUG26"),
 label=c("Februar 24","April 24","Juli 24","Dezember 24","August 26"),
 short=c("Feb24","Apr24","Jul24","Dec24","Aug26"),
 wrg_active=c(TRUE,TRUE,TRUE,FALSE,FALSE))
if(!all(cfg$campaigns %in% registry$campaign)||anyDuplicated(cfg$campaigns))stop("Kampagnenauswahl ungueltig.")
specs<-data.table(metric=c("moisture_pct","pH","N_total_gkg_TS","NH4_gkg_TS"),
 stem=c("feuchte","ph","n_total","nh4_n"),
 title=c("Moisture in % in litter","pH in litter","Total-N (g/kg DM) in litter","NH4-N (g/kg DM) in litter"),
 end_title=c("Moisture in litter","pH in litter","N total in g/kg DM in litter","NH4-N in g/kg DM in litter"),
 y=c("H2O (%)","pH","N total (g/kg DM)","NH4-N (g/kg DM)"),
 table_metric=c("Feuchtigkeit der Einstreu","pH der Einstreu","Gesamtstickstoff der Einstreu","Ammoniumstickstoff der Einstreu"),
 unit=c("%","pH","g/kg TS","g/kg TS"),digits=c(1,2,1,2),table_number=8:11)
fmt<-function(x,digits=2)ifelse(is.na(x),"n.a.",formatC(x,format="f",digits=digits,decimal.mark=cfg$decimal_mark))
csv<-function(x,path)fwrite(x,path,sep=";",dec=",",bom=TRUE,na="NA")
if(!file.exists(cfg$input))stop("Eingabedatei fehlt.")
source_md5<-unname(tools::md5sum(cfg$input))
raw<-as.data.table(readxl::read_excel(cfg$input,sheet=cfg$sheet))
needed<-c("Probenr-HAFL","stall","masttag","Wiederholung","campaign","TS_pct",specs$metric)
if(!all(needed %in% names(raw)))stop("Fehlende Spalten: ",paste(setdiff(needed,names(raw)),collapse=", "))
raw[,excel_row:=.I+1L]
raw[,`:=`(campaign=trimws(as.character(campaign)),stall=trimws(as.character(stall)))]
for(k in c("masttag","Wiederholung","TS_pct",specs$metric)){
 old<-raw[[k]];v<-suppressWarnings(as.numeric(old))
 if(any(!is.na(old)&nzchar(trimws(as.character(old)))&is.na(v)))stop("Nichtnumerischer Wert in ",k)
 set(raw,j=k,value=v)
}
method_label<-switch(cfg$test_method,anova_tukey="Einfaktorielle ANOVA und Tukey-HSD",
 welch_games_howell="Welch-ANOVA und Games-Howell",
 kruskal_dunn=paste0("Kruskal-Wallis und zweiseitiger Dunn-Test (",cfg$dunn_adjust,")"))
spread_note<-if(cfg$spread=="sd")"Mittelwert +/- Standardabweichung der Proben (SD)" else "Mittelwert +/- Standardfehler (SE)"
letter_note<-paste0("Mindestens ein gemeinsamer Buchstabe: kein nachgewiesener Unterschied. Ohne gemeinsamen Buchstaben: adjustiertes p < ",
 fmt(cfg$alpha,2),". ",method_label,"; alle Kampagne-Stall-Gruppen je Merkmal werden verglichen.")
sampling_note<-paste0("Wiederholungen sind Einstreuproben innerhalb eines Stalls, keine unabhaengigen Staelle oder Kampagnen. ",
 "Die Tests sind explorativ und belegen keinen kausalen WRG-Effekt. Dezember 2024 und August 2026: beide Staelle ohne WRG. ",
 "Die Probenstreuung ist kein pauschaler Messfehler aus der NH3-Auswertung.")

test_day<-function(z){
 df<-data.frame(value=z$value,group=droplevels(z$group))
 counts<-table(df$group)
 if(length(counts)<2L||any(counts<2L))stop("Mindestens zwei Werte je Gruppe am ausgewaehlten Vergleichstag erforderlich.")
 model<-aov(value~group,data=df);av<-summary(model)[[1]]
 shapiro<-tryCatch(shapiro.test(residuals(model))$p.value,error=function(e)NA_real_)
 absdev<-abs(df$value-ave(df$value,df$group,FUN=median))
 levene<-summary(aov(absdev~df$group))[[1]][["Pr(>F)"]][1]
 if(cfg$test_method=="anova_tukey"){
  pair<-as.data.table(TukeyHSD(model,conf.level=1-cfg$alpha)$group,keep.rownames="comparison")
  ab<-tstrsplit(pair$comparison,"-",fixed=TRUE)
  pair[,`:=`(group1=ab[[1]],group2=ab[[2]])]
  setnames(pair,c("diff","lwr","upr","p adj"),c("estimate","conf_low","conf_high","p_adj"))
  pair[,estimate_definition:="mean(group1) - mean(group2)"]
  global_p<-av[["Pr(>F)"]][1]
 }else if(cfg$test_method=="welch_games_howell"){
  global_p<-oneway.test(value~group,data=df,var.equal=FALSE)$p.value
  pair<-as.data.table(rstatix::games_howell_test(df,value~group,conf.level=1-cfg$alpha,detailed=TRUE))
  setnames(pair,c("p.adj","conf.low","conf.high"),c("p_adj","conf_low","conf_high"))
  pair[,`:=`(group1=as.character(group1),group2=as.character(group2))]
  pair[,comparison:=paste(group1,group2,sep="-")]
 }else{
  global_p<-kruskal.test(value~group,data=df)$p.value
  pair<-as.data.table(rstatix::dunn_test(df,value~group,p.adjust.method=cfg$dunn_adjust,detailed=TRUE))
  setnames(pair,"p.adj","p_adj")
  pair[,`:=`(group1=as.character(group1),group2=as.character(group2))]
  pair[,comparison:=paste(group1,group2,sep="-")]
 }
 if(any(!is.finite(pair$p_adj)))stop("Paarvergleich nicht berechenbar; keine irrefuehrenden Buchstaben.")
 pv<-setNames(pair$p_adj,pair$comparison)
 cl<-multcompView::multcompLetters(pv,threshold=cfg$alpha)$Letters
 letters<-data.table(group=names(cl),letters=unname(cl))
 for(i in seq_len(nrow(pair))){
  a<-letters[group==pair$group1[i],letters];b<-letters[group==pair$group2[i],letters]
  shared<-length(intersect(strsplit(a,"",fixed=TRUE)[[1]],strsplit(b,"",fixed=TRUE)[[1]]))>0
  stopifnot(shared==(pair$p_adj[i]>=cfg$alpha))
 }
 list(pair=pair,letters=letters,diagnostic=data.table(method=cfg$test_method,n=nrow(df),groups=nlevels(df$group),
  global_p=global_p,anova_p=av[["Pr(>F)"]][1],shapiro_residual_p=shapiro,levene_median_p=levene,
  assumption_warning=isTRUE(shapiro<cfg$alpha)||isTRUE(levene<cfg$alpha),
  kruskal_wallis_p=kruskal.test(value~group,data=df)$p.value))
}
table_html<-function(stats,sp,reg){
 h<-paste0("<table><thead><tr><th>Stall</th><th>Messkampagne</th><th>",sp$table_metric,
 " am ",cfg$comparison_day,". Masttag [",sp$unit,"]</th></tr></thead><tbody>")
 for(id in reg$campaign){
  z<-stats[as.character(campaign)==id][order(stall)]
  for(i in seq_len(nrow(z))){
   barn<-if(z$stall[i]=="1")"Stall 1 (Referenz)" else if(reg[campaign==id,wrg_active])"Stall 2 (WRG)" else "Stall 2 (WRG nicht in Betrieb)"
   amount<-paste0(fmt(z$mean[i],sp$digits)," &plusmn; ",fmt(z$spread[i],sp$digits),"<sup>",z$letters[i],"</sup>")
   h<-paste0(h,"<tr><td>",barn,"</td>",if(i==1)paste0("<td rowspan='",nrow(z),"'>",reg[campaign==id,label],"</td>") else "",
    "<td>",amount,"</td></tr>")
  }
 }
 paste0(h,"</tbody></table>")
}
table_image<-function(stats,sp,reg,out){
 n<-nrow(stats);height_px<-430+76*n
 draw<-function(){
  grid::grid.newpage()
  title<-paste0("Tabelle ",sp$table_number,": ",sp$table_metric," am ",cfg$comparison_day,". Masttag")
  grid::grid.text(title,x=.03,y=.96,just="left",gp=grid::gpar(fontsize=15,fontface="italic"))
  heads<-c("Stall","Messkampagne",paste0(sp$table_metric," am ",cfg$comparison_day,". Masttag [",sp$unit,"]"))
  xx<-c(.15,.39,.75)
  for(j in 1:3)grid::grid.text(paste(strwrap(heads[j],width=if(j==3)42 else 23),collapse="\n"),
   x=xx[j],y=.86,gp=grid::gpar(fontsize=12,fontface="bold"))
  top<-.79;bottom<-.17;step<-(top-bottom)/n
  for(y in c(.91,top))grid::grid.lines(x=c(.03,.97),y=c(y,y))
  for(i in seq_len(n)){
   z<-stats[i];y<-top-(i-.5)*step
   lab<-if(z$stall=="1")"Stall 1 (Referenz)" else if(reg[campaign==as.character(z$campaign),wrg_active])"Stall 2 (WRG)" else "Stall 2 (WRG nicht in Betrieb)"
   grid::grid.text(paste(strwrap(lab,width=28),collapse="\n"),x=xx[1],y=y,gp=grid::gpar(fontsize=11))
   text<-paste0(fmt(z$mean,sp$digits)," \u00b1 ",fmt(z$spread,sp$digits));letter<-z$letters
   grid::grid.text(bquote(.(text)^.(letter)),x=xx[3],y=y,gp=grid::gpar(fontsize=12))
   yy<-top-i*step
   if(i%%2==1)for(bounds in list(c(.03,.27),c(.51,.97)))grid::grid.lines(x=bounds,y=c(yy,yy),gp=grid::gpar(col="#777777"))
   else grid::grid.lines(x=c(.03,.97),y=c(yy,yy),gp=grid::gpar(col="#777777"))
  }
  for(id in reg$campaign){
   ix<-which(as.character(stats$campaign)==id)
   grid::grid.text(reg[campaign==id,label],x=xx[2],y=mean(top-(ix-.5)*step),gp=grid::gpar(fontsize=12))
  }
  count_note<-paste0(reg$short,": S1 n=",vapply(reg$campaign,function(id)stats[as.character(campaign)==id & stall=="1",n],integer(1)),
   ", S2 n=",vapply(reg$campaign,function(id)stats[as.character(campaign)==id & stall=="2",n],integer(1)),collapse="; ")
  grid::grid.text(paste(strwrap(paste0(spread_note,". ",count_note),width=140),collapse="\n"),
   x=.03,y=.105,just="left",gp=grid::gpar(fontsize=9))
  brief<-paste0("Gemeinsamer Buchstabe: kein nachgewiesener Unterschied. ",method_label,"; alpha = ",fmt(cfg$alpha,2),". Explorative Tests an Proben innerhalb der Staelle.",
 if(sp$metric %in% cfg$sampling_caution_metrics && "AUG26" %in% reg$campaign && cfg$comparison_day==34)
 " Feuchtigkeit August26/S2: Probenahmeverdacht; Werte enthalten." else "")
  grid::grid.text(paste(strwrap(brief,width=140),collapse="\n"),x=.03,y=.045,just="left",gp=grid::gpar(fontsize=9))
 }
 stem<-file.path(out,paste0("tabelle",sp$table_number,"_",sp$stem,"_tag",cfg$comparison_day))
 png(paste0(stem,".png"),width=2200,height=height_px,res=180);draw();dev.off()
 if(cfg$export_pdf){pdf(paste0(stem,".pdf"),width=2200/180,height=height_px/180,useDingbats=FALSE);draw();dev.off()}
}
save_plot<-function(plot,stem,width,height){
 ggsave(paste0(stem,".png"),plot=plot,width=width,height=height,dpi=cfg$dpi,bg="white")
 if(cfg$export_pdf)ggsave(paste0(stem,".pdf"),plot=plot,width=width,height=height,device=grDevices::cairo_pdf,bg="white")
}
run_analysis<-function(selected,out){
 dir.create(out,recursive=TRUE,showWarnings=FALSE);started<-Sys.time()
 writeLines(c("GESTARTET",format(started)),file.path(out,"laufstatus.txt"))
 reg<-registry[match(selected,campaign)]
 caution<-if("AUG26" %in% selected && cfg$comparison_day==34)cfg$sampling_caution else NULL
 d<-copy(raw[campaign %in% selected & stall %in% c("1","2")])
 d[,`:=`(campaign=factor(campaign,levels=selected),stall=factor(stall,levels=c("1","2")))]
 if(anyDuplicated(d[,.(campaign,stall,masttag,Wiederholung)]))stop("Doppelte Kampagne-Stall-Masttag-Wiederholung.")
 if(!all(selected %in% as.character(d$campaign)))stop("Gewaehlte Kampagne ohne Daten.")
 ids<-unlist(lapply(selected,function(id)paste0(id,"_S",1:2)))
 group_labels<-setNames(unlist(lapply(reg$short,function(id)paste0(id,"_S",1:2))),ids)
 d[,group:=factor(paste0(campaign,"_S",stall),levels=ids)]
 excluded<-copy(raw[!(campaign %in% selected & stall %in% c("1","2"))])
 excluded[,reason:=ifelse(!(campaign %in% selected),"Kampagne nicht ausgewaehlt","AKB bzw. kein Stall 1/2")]
 csv(excluded,file.path(out,"nicht_verwendete_zeilen.csv"));csv(d,file.path(out,"analysewerte.csv"))
 if(any(!is.na(d$moisture_pct)&abs(d$moisture_pct-(100-d$TS_pct))>1e-8))stop("Feuchte stimmt nicht mit 100-TS ueberein.")
 qa<-d[pH<4 | pH>10 | N_total_gkg_TS<15,.(excel_row,Probenr=get("Probenr-HAFL"),campaign,stall,masttag,pH,N_total_gkg_TS)]
 csv(qa,file.path(out,"pruefhinweise.csv"))
 base_theme<-theme_bw(base_size=cfg$base_size)+theme(plot.title=element_text(face="bold"),
  strip.background=element_rect(fill="#D9D9D9"),strip.text=element_text(size=10),
  panel.grid.minor=element_line(colour="#F1F1F1"),legend.position="right")
 summaries<-pairs<-diagnostics<-list();sections<-character()
 for(i in seq_len(nrow(specs))){
  sp<-specs[i];metric<-sp$metric
  metric_caution<-if(metric %in% cfg$sampling_caution_metrics)caution else NULL
  z<-copy(d);z[,value:=get(metric)]
  missing_rows<-z[!is.finite(value),.(excel_row,campaign,stall,masttag)]
  if(nrow(missing_rows))csv(missing_rows,file.path(out,paste0(sp$stem,"_fehlende_werte.csv")))
  z<-z[is.finite(value)];day<-copy(z[masttag==cfg$comparison_day]);day[,group:=droplevels(group)]
  if(nlevels(day$group)!=length(ids))stop("Am Vergleichstag fehlen Gruppen fuer ",metric)
  st<-test_day(day)
  sm<-day[,.(n=.N,mean=mean(value),sd=sd(value),se=sd(value)/sqrt(.N),
   median=median(value),minimum=min(value),maximum=max(value)),by=.(campaign,stall,group)]
  sm<-merge(sm,st$letters,by="group",sort=FALSE)
  sm[,`:=`(metric=metric,spread=if(cfg$spread=="sd")sd else se,spread_type=cfg$spread)]
  sm[,group_order:=match(as.character(group),ids)];setorder(sm,group_order);sm[,group_order:=NULL]
  st$pair[,metric:=metric];st$diagnostic[,metric:=metric]
  summaries[[metric]]<-sm;pairs[[metric]]<-st$pair;diagnostics[[metric]]<-st$diagnostic
  p1<-ggplot(z,aes(x=factor(masttag),y=value,fill=stall))+
   geom_boxplot(width=.75,outlier.size=1.5,position=position_dodge2(preserve="single"))+
   facet_wrap(~campaign,ncol=cfg$facet_columns,scales="free_x")+
   scale_fill_manual(values=cfg$colours,name="Barn",drop=FALSE)+
   labs(title=sp$title,x="day of age",y=sp$y,caption=metric_caution)+base_theme
  save_plot(p1,file.path(out,paste0(sp$stem,"_mastverlauf")),12,1+3.2*ceiling(nrow(reg)/cfg$facet_columns))
  span<-diff(range(day$value));pad<-max(.20,span*.12);label_y<-max(day$value)+pad
  p2<-ggplot(day,aes(x=group,y=value,fill=stall))+geom_boxplot(width=.7,outlier.size=1.5)+
   geom_text(data=sm,aes(x=group,y=label_y,label=letters),inherit.aes=FALSE,fontface="bold",size=4.2)+
   scale_x_discrete(labels=group_labels)+scale_fill_manual(values=cfg$colours,name="Barn",drop=FALSE)+
   expand_limits(y=label_y+pad*.6)+labs(title=paste0(sp$end_title," (day ",cfg$comparison_day,")"),
   x="campaign and barn",y=sp$y,caption=paste0(method_label,"; alpha = ",fmt(cfg$alpha,2),". Explorative Gruppenvergleiche an Proben innerhalb der Staelle.",if(length(metric_caution))paste0("\n",metric_caution) else ""))+base_theme+theme(axis.text.x=element_text(angle=45,hjust=1))
  save_plot(p2,file.path(out,paste0(sp$stem,"_tag",cfg$comparison_day)),12,7.2)
  t<-data.frame(Stall=ifelse(as.character(sm$stall)=="1","Stall 1 (Referenz)",
   ifelse(reg[match(as.character(sm$campaign),campaign),wrg_active],"Stall 2 (WRG)","Stall 2 (WRG nicht in Betrieb)")),
   Messkampagne=reg[match(as.character(sm$campaign),campaign),label],
   value=paste0(fmt(sm$mean,sp$digits)," +/- ",fmt(sm$spread,sp$digits)," ",sm$letters),check.names=FALSE)
  names(t)[3]<-paste0(sp$table_metric," am ",cfg$comparison_day,". Masttag [",sp$unit,"]")
  fwrite(t,file.path(out,paste0("tabelle",sp$table_number,"_",sp$stem,"_tag",cfg$comparison_day,".csv")),sep=";",bom=TRUE)
  table_image(sm,sp,reg,out)
  sections<-c(sections,paste0("<h2>",sp$title,"</h2>",
   if(length(metric_caution))paste0("<p><strong>Hinweis zur Feuchtemessung:</strong> ",metric_caution,"</p>") else "",
   "<img src='",sp$stem,
   "_mastverlauf.png' alt='Mastverlauf'><img src='",sp$stem,"_tag",cfg$comparison_day,".png' alt='Vergleichstag'>",
   "<p><em>Tabelle ",sp$table_number,": ",sp$table_metric," am ",cfg$comparison_day,". Masttag.</em></p>",table_html(sm,sp,reg)))
 }
 all_summary<-rbindlist(summaries);all_pairs<-rbindlist(pairs,fill=TRUE);all_diagnostic<-rbindlist(diagnostics,fill=TRUE)
 csv(all_summary,file.path(out,paste0("tag",cfg$comparison_day,"_deskriptiv_und_buchstaben.csv")))
 csv(all_pairs,file.path(out,paste0("tag",cfg$comparison_day,"_paarvergleiche.csv")))
 csv(all_diagnostic,file.path(out,paste0("tag",cfg$comparison_day,"_tests_und_diagnostik.csv")))
 counts<-d[,.(n=.N),by=.(campaign,stall,masttag)];csv(counts,file.path(out,"probenzahlen.csv"))
 warning_note<-if(any(all_diagnostic$assumption_warning))
  "Mindestens ein Merkmal zeigt Abweichungen von Normalverteilung oder gleicher Varianz. Es wird die eingestellte Methode verwendet, ohne datenabhaengigen Methodenwechsel. Alternativen sind im Skript einstellbar."
 else "Diagnosetests siehe CSV. Nicht signifikante Tests beweisen die Modellannahmen nicht."
 n_note<-paste0(nrow(d)," Proben; Tag ",cfg$comparison_day,": ",sum(counts[masttag==cfg$comparison_day,n]),
  " Proben in ",length(ids)," Gruppen. Kampagnen: ",paste(reg$label,collapse=", "),".")
 html<-c("<!doctype html><html lang='de'><meta charset='utf-8'><title>Einstreuanalysen Mettmenstetten</title>",
  "<style>body{font:16px Arial;max-width:1200px;margin:35px auto;line-height:1.5}img{width:100%;height:auto;margin:20px 0}table{width:100%;border-collapse:collapse;margin:20px 0 35px}th,td{padding:10px;text-align:center;border-bottom:1px solid #aaa}thead{border-top:2px solid #222;border-bottom:2px solid #222}h2{margin-top:45px}sup{font-size:.75em}@media print{img,table{break-inside:avoid}h2{break-before:page}}</style>",
  "<h1>Einstreuanalysen Mettmenstetten</h1>",paste0("<p>",n_note,"</p><p>",spread_note,". ",letter_note,"</p><p>",sampling_note,"</p><p>",warning_note,"</p>"),
  "<p>Auffaellige Quellwerte bleiben enthalten, unter anderem pH 0,52 im Juli 2024. NH4-N bezeichnet den Laborparameter Ammoniumstickstoff. DM und TS bezeichnen dieselbe Trockenmassebasis. Die bekannten Phosphor-/Mineralstoff-Beschriftungsprobleme betreffen die vier verwendeten Merkmale nicht.</p>",
  sections,"<h2>Verfahren</h2><p>R-Dokumentation: <a href='https://stat.ethz.ch/R-manual/R-devel/library/stats/html/TukeyHSD.html'>TukeyHSD</a>; <a href='https://cran.r-project.org/web/packages/multcompView/refman/multcompView.html'>multcompView</a>. Korrektur der Paarvergleiche je Merkmal innerhalb des dargestellten Kampagnensatzes; keine zusaetzliche Korrektur ueber verschiedene Merkmale.</p></html>")
 writeLines(html,file.path(out,"Einstreuanalysen.html"))
 active_cfg<-cfg;active_cfg$campaigns<-selected;active_cfg$out<-out
 dput(active_cfg,file=file.path(out,"parameter.R"))
 saveRDS(list(cfg=active_cfg,campaigns=reg,source=cfg$input,source_md5=source_md5),file.path(out,"laufparameter.rds"))
 writeLines(c(n_note,spread_note,letter_note,sampling_note,warning_note,caution),file.path(out,"methodik.txt"))
 capture.output(sessionInfo(),file=file.path(out,"sessionInfo.txt"))
 stopifnot(unname(tools::md5sum(cfg$input))==source_md5)
 writeLines(c("ERFOLGREICH",format(Sys.time()),n_note),file.path(out,"laufstatus.txt"))
 generated<-list.files(out,full.names=TRUE);generated<-generated[!dir.exists(generated)&file.info(generated)$mtime>=started]
 csv(data.table(file=basename(generated),bytes=file.info(generated)$size),file.path(out,"ausgabedateien.csv"))
 message("ERFOLGREICH: ",normalizePath(out)," (",nrow(d)," Proben)")
 invisible(list(summary=all_summary,pairs=all_pairs,diagnostics=all_diagnostic))
}
result<-run_analysis(cfg$campaigns,cfg$out)
historical<-intersect(c("FEB","APR","JUL","DEC"),cfg$campaigns)
if(cfg$historical_comparison && !identical(cfg$campaigns,historical) && length(historical)>=2)
 historical_result<-run_analysis(historical,file.path(cfg$out,"ohne_august2026"))
