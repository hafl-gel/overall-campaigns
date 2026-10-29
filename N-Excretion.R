# N-Ausscheidung: August 2026 aus Mast-PDFs; Futtergehalte 2024 vorlaeufig.
working_directory<-path.expand("~/git/overall-campaigns");setwd(working_directory)
source("kampagnen_daten.R")
overall_check_packages(c("data.table","readxl","ggplot2"))
suppressPackageStartupMessages({library(data.table);library(ggplot2)})
cfg_n<-list(
 input=file.path(working_directory,"daten","IMPEX_Gfeller_nach MA.xlsx"),sheet="R",
 # Excel ist die Hauptquelle. Zusatzdatei leer lassen, wenn August bereits im Excel steht.
 supplement=file.path(working_directory,"daten","N_Bilanz_August2026.csv"),
 out=file.path(working_directory,"ergebnisse_n_ausscheidung"),
 campaigns=c("feb","apr","jul","dec","aug"),
 cycles=8.5,source_cycles=8.5, # source_cycles: Jahresfaktor im bisherigen IMPEX-Export
 season_weights=c(Winter=.25,Transition=.50,Summer=.25)
)
if(exists("n_overrides",inherits=FALSE))cfg_n<-utils::modifyList(cfg_n,n_overrides)
stopifnot(cfg_n$cycles>0,cfg_n$source_cycles>0,abs(sum(cfg_n$season_weights)-1)<1e-12)
reg<-overall_campaign_registry()[match(cfg_n$campaigns,code)]
if(anyNA(reg$id))stop("Unbekannte Kampagne.")
dir.create(cfg_n$out,recursive=TRUE,showWarnings=FALSE)
writeLines("GESTARTET",file.path(cfg_n$out,"laufstatus.txt"))
if(!file.exists(cfg_n$supplement)){
 dir.create(dirname(cfg_n$supplement),recursive=TRUE,showWarnings=FALSE)
 template<-data.table(Stall=c("1","2"),Umtrieb="Aug-26",
  N_ausgeschieden_pro_Tier_g=NA_real_,TAN_pro_Tier_g=NA_real_,NH3_N_gemessen_pro_Tier_g=NA_real_)
 fwrite(template,cfg_n$supplement,sep=";",dec=",",bom=TRUE,na="")
}
normalise_input<-function(x,source_name){
 x<-as.data.table(x);setnames(x,gsub(" ","_",trimws(names(x)),fixed=TRUE))
 if(!all(c("Stall","Umtrieb") %in% names(x)))stop("Stall/Umtrieb fehlen: ",source_name)
 num<-function(name){
  if(!name %in% names(x))return(rep(NA_real_,nrow(x)))
  a<-x[[name]];v<-suppressWarnings(as.numeric(gsub(",",".",as.character(a),fixed=TRUE)))
  if(any(!is.na(a)&nzchar(trimws(as.character(a)))&is.na(v)))stop("Nichtnumerischer Wert in ",name)
  v
 }
 n_cycle<-num("N_ausgeschieden_pro_Tier_g")
 fallback<-num("N_Ausscheidung_pro_Tier_und_Jahr_g")/cfg_n$source_cycles
 n_cycle[!is.finite(n_cycle)]<-fallback[!is.finite(n_cycle)]
 tan_cycle<-num("TAN_pro_Tier_g")
 fallback<-num("TAN")/cfg_n$source_cycles
 tan_cycle[!is.finite(tan_cycle)]<-fallback[!is.finite(tan_cycle)]
 nh3n_cycle<-num("NH3_N_gemessen_pro_Tier_g")
 fallback<-num("NH3-N_gemessen_pro_Tier_g")
 nh3n_cycle[!is.finite(nh3n_cycle)]<-fallback[!is.finite(nh3n_cycle)]
 data.table(Stall=trimws(as.character(x$Stall)),Umtrieb=trimws(as.character(x$Umtrieb)),
  N_cycle=n_cycle,TAN_cycle=tan_cycle,NH3N_cycle=nh3n_cycle,
  Bilanzstatus=if("Bilanzstatus" %in% names(x))as.character(x$Bilanzstatus) else NA_character_,source=source_name)
}
original<-normalise_input(readxl::read_excel(cfg_n$input,sheet=cfg_n$sheet),cfg_n$input)
additional<-normalise_input(fread(cfg_n$supplement,sep=";",dec=",",na.strings=c("","NA")),cfg_n$supplement)
additional<-additional[is.finite(N_cycle)|is.finite(TAN_cycle)|is.finite(NH3N_cycle)]
values<-rbindlist(list(original,additional),fill=TRUE)
values<-values[Umtrieb %in% reg$label & Stall %in% c("1","2")]
if(anyDuplicated(values[,.(Stall,Umtrieb)]))stop("Doppelte Stall/Kampagnenwerte in Hauptdatei und Zusatzdatei; Quelle eindeutig festlegen.")
expected<-reg[,.(Stall=c("1","2")),by=.(Umtrieb=label,Season=season,wrg_active,code)]
df<-merge(expected,values,by=c("Stall","Umtrieb"),all.x=TRUE)
df[,`:=`(
 N_Ausscheidung_pro_Tier_und_Jahr_g=N_cycle*cfg_n$cycles,
 TAN=TAN_cycle*cfg_n$cycles,
 NH3_N_gemessen_pro_Tier_und_Jahr_g=NH3N_cycle*cfg_n$cycles)]
df[,Anteil_NH3_Emission:=ifelse(is.finite(TAN)&TAN>0,NH3_N_gemessen_pro_Tier_und_Jahr_g/TAN,NA_real_)]
df[,Anteil_NH3_Emission_pct:=100*Anteil_NH3_Emission]
df[,`:=`(Stall=factor(Stall,levels=c("1","2")),
 Umtrieb=factor(Umtrieb,levels=reg$label),Season_en=factor(Season,levels=names(cfg_n$season_weights)))]
df[,vorlaeufig:=!is.na(Bilanzstatus)&grepl("vorl",Bilanzstatus,ignore.case=TRUE)]
setorder(df,Umtrieb,Stall)
coverage<-df[,.(Umtrieb,Stall,Season,wrg_active,N_available=is.finite(N_cycle),
 TAN_available=is.finite(TAN_cycle),NH3N_available=is.finite(NH3N_cycle),vorlaeufig,Bilanzstatus,source)]
overall_csv(coverage,cfg_n$out,"datenverfuegbarkeit")
known<-df[is.finite(N_Ausscheidung_pro_Tier_und_Jahr_g)]
known[,gewicht:=cfg_n$season_weights[as.character(Season_en)]/.N,by=.(Stall,Season_en)]
unweighted_summary<-known[,.(n=.N,mean_unweighted=mean(N_Ausscheidung_pro_Tier_und_Jahr_g),
 sd_unweighted=sd(N_Ausscheidung_pro_Tier_und_Jahr_g),
 se_unweighted=sd(N_Ausscheidung_pro_Tier_und_Jahr_g)/sqrt(.N)),by=Stall]
weighted_summary<-known[,.(n_available=.N,expected_campaigns=nrow(reg),
 seasons_available=uniqueN(Season_en),weight_sum=sum(gewicht),
 mean_weighted_available=sum(N_Ausscheidung_pro_Tier_und_Jahr_g*gewicht)/sum(gewicht)),by=Stall]
provisional_summary<-known[,.(n_provisional=sum(vorlaeufig)),by=Stall]
weighted_summary<-merge(weighted_summary,provisional_summary,by="Stall")
weighted_summary[,complete:=n_available==expected_campaigns & seasons_available==length(cfg_n$season_weights)]
weighted_summary[,mean_weighted:=ifelse(complete,mean_weighted_available,NA_real_)]
summary_table<-merge(unweighted_summary,weighted_summary,by="Stall")
# Gepaarter Stallvergleich ausschliesslich in WRG-Kampagnen.
# Dezember 2024 und August 2026 sind ausgeschlossen, da beide Staelle ohne WRG liefen.
df_paired<-dcast(known[wrg_active==TRUE],Umtrieb~Stall,value.var="N_Ausscheidung_pro_Tier_und_Jahr_g")
setnames(df_paired,c("1","2"),c("Stall_1","Stall_2"))
df_paired<-df_paired[is.finite(Stall_1)&is.finite(Stall_2)]
df_paired[,diff:=Stall_1-Stall_2]
stats_log<-character()
add_test<-function(label,expression){
 stats_log<<-c(stats_log,paste0("\n### ",label," ###"),
  tryCatch(capture.output(force(expression)),error=function(e)paste("Nicht berechenbar:",conditionMessage(e))))
}
add_test("Gepaarter Wilcoxon-Test N-Ausscheidung (nur WRG-Kampagnen)",
 wilcox.test(df_paired$Stall_1,df_paired$Stall_2,paired=TRUE,exact=TRUE))
add_test("Shapiro-Wilk der gepaarten Differenzen",shapiro.test(df_paired$diff))
mean_raw<-mean(known$N_Ausscheidung_pro_Tier_und_Jahr_g)
sd_raw<-sd(known$N_Ausscheidung_pro_Tier_und_Jahr_g)
stats_log<-c(stats_log,paste("Ungewichteter Gesamtmittelwert vorhandener Werte:",mean_raw,
 "g/Tier/Jahr; SD:",sd_raw,"; n=",nrow(known)))
p_hist<-ggplot(df_paired,aes(diff))+geom_histogram(bins=10,fill="steelblue",colour="black")+
 labs(title="Differences in Annual N Excretion (Barn 1 - Barn 2)",x="N excretion difference [g/year]",y="Frequency")+overall_theme()
p_qq<-ggplot(df_paired,aes(sample=diff))+stat_qq()+stat_qq_line(colour="red")+
 labs(title="QQ Plot of Paired Differences",x="Theoretical quantiles",y="Observed quantiles")+overall_theme()
p_barn<-ggplot(known,aes(Stall,N_Ausscheidung_pro_Tier_und_Jahr_g,fill=Stall))+geom_boxplot()+
 scale_fill_manual(values=c("1"="red","2"="blue"))+
 labs(title="Annual Nitrogen Excretion per Animal Place",x="Barn",y="N excretion [g/year]",fill="Barn",
 caption=paste("Bilanzdaten:",paste(unique(as.character(known$Umtrieb)),collapse=", "),"| August: Futtergehalte 2024 vorlaeufig."))+overall_theme()
df_test<-df[wrg_active==TRUE & is.finite(Anteil_NH3_Emission_pct)]
for(h in c("1","2"))add_test(paste("Shapiro-Wilk NH3-N/TAN Stall",h),shapiro.test(df_test[Stall==h,Anteil_NH3_Emission_pct]))
dev<-abs(df_test$Anteil_NH3_Emission_pct-ave(df_test$Anteil_NH3_Emission_pct,df_test$Stall,FUN=median))
add_test("Levene mit Medianzentrum, NH3-N/TAN",summary(aov(dev~df_test$Stall)))
# Bisherige unverbundene Tests bleiben als explorative Vergleichsausgaben erhalten.
add_test("Wilcoxon-Rangsumme NH3-N/TAN (explorativ)",wilcox.test(Anteil_NH3_Emission_pct~Stall,data=df_test,exact=TRUE))
add_test("Welch-t-Test NH3-N/TAN (explorativ)",t.test(Anteil_NH3_Emission_pct~Stall,data=df_test))
p_share<-ggplot(df_test,aes(Stall,Anteil_NH3_Emission_pct,fill=Stall))+geom_boxplot()+
 scale_fill_manual(values=c("1"="red","2"="blue"))+
 labs(title="NH3-N Emissions Relative to TAN",x="Barn",y="NH3-N / TAN [%]",fill="Barn",
 caption="Nur WRG-Kampagnen; Prozentdarstellung = 100 * Anteil. Eingabewerte aus IMPEX.")+overall_theme()
season_summary<-known[,.(n=.N,mean=mean(N_Ausscheidung_pro_Tier_und_Jahr_g),
 sd=sd(N_Ausscheidung_pro_Tier_und_Jahr_g)),by=Season_en]
add_test("Kruskal-Wallis ueber Saisons",kruskal.test(N_Ausscheidung_pro_Tier_und_Jahr_g~Season_en,data=known))
kw_result<-kruskal.test(N_Ausscheidung_pro_Tier_und_Jahr_g~Season_en,data=known)
if(kw_result$p.value<.05 && requireNamespace("rstatix",quietly=TRUE)){
 dunn_result<-rstatix::dunn_test(as.data.frame(known),N_Ausscheidung_pro_Tier_und_Jahr_g~Season_en,p.adjust.method="BH")
 overall_csv(as.data.table(dunn_result),cfg_n$out,"dunn_saison_bh")
}
p_season<-ggplot(known,aes(Season_en,N_Ausscheidung_pro_Tier_und_Jahr_g,fill=Season_en))+geom_boxplot()+
 scale_fill_brewer(palette="Set2")+labs(title="Annual Nitrogen Excretion by Season",x="Season",y="N excretion [g/year]",fill="Season",caption="August 2026 vorlaeufig: Futtergehalte 2024; Bestandsfutter als Endmastfutter.")+overall_theme()
plots<-list(histogramm_differenzen=p_hist,qq_differenzen=p_qq,n_nach_stall=p_barn,nh3_n_anteil_tan=p_share,n_nach_saison=p_season)
for(name in names(plots)){if(interactive())print(plots[[name]]);overall_save_plot(plots[[name]],cfg_n$out,name,7)}
overall_csv(df,cfg_n$out,"alle_kampagnen_mit_fehlenden_werten")
overall_csv(known,cfg_n$out,"n_ausscheidung_mit_gewichten")
overall_csv(summary_table,cfg_n$out,"mittelwerte_nach_stall")
overall_csv(season_summary,cfg_n$out,"mittelwerte_nach_saison")
overall_csv(df_paired,cfg_n$out,"gepaarte_wrg_kampagnen")
writeLines(stats_log,file.path(cfg_n$out,"statistische_tests.txt"))
dput(cfg_n,file=file.path(cfg_n$out,"parameter.R"))
missing_rows<-coverage[N_available==FALSE]
notes<-c("N-Ausscheidung und TAN werden mit der einstellbaren Umtriebszahl annualisiert.",
 "Saisongewichte: Winter 25 %, Uebergang 50 %, Sommer 25 %. Kampagnen werden je Stall innerhalb der Saison gleich gewichtet.",
 "mean_weighted ist nur bei vollstaendigem Kampagnensatz belegt. mean_weighted_available beschreibt ausschliesslich die vorhandenen Kampagnen und ist bei fehlendem August vorlaeufig.",
 "August 2026 und Dezember 2024 liefern keinen WRG-Stallvergleich. August fliesst in die allgemeinen N-/Saisonmittel ein.",
 "August: Tier-/Futtermengen aus Mast-PDFs; vorlaeufige Berechnung mit Laborgehalten 2024 auf Nutzerwunsch. Anfangs-/Restbestand dem Endmastfutter zugerechnet.",
 "August N-Nenner: ausgestallte Tiere (8600/8384) wie in bisherigen R-Zeilen. NH3 kumulierter Messendwert Tag 33,42; N-Bilanz ganzer Mastumtrieb 35/36 Tage. Diese Quoten haben deshalb unterschiedliche Zeitabdeckung.",
 "Die NH3-N/TAN-Quoten stammen aus den Eingabedaten, nicht automatisch aus dem separaten Emissionskorrekturskript.",
 "Stalljahre sind Modellwerte bei einem Tier pro Tierplatz und Umtrieb. Wenige, gepaarte Kampagnen: Tests explorativ.")
writeLines(notes,file.path(cfg_n$out,"methodik.txt"))
if(nrow(missing_rows)){
 status<-paste0("UNVOLLSTAENDIGE DATEN: N-Bilanz fehlt fuer ",paste(paste(missing_rows$Umtrieb,missing_rows$Stall,sep="/S"),collapse=", "))
 warning(status,call.=FALSE)
}else if(any(df$vorlaeufig))status<-"ERFOLGREICH MIT VORLAEUFIGER AUGUST-N-BILANZ (Futtergehalte 2024; Bestandsfutter als Endmastfutter)" else status<-"ERFOLGREICH"
writeLines(c(status,paste("Vorhandene N-Bilanzen:",nrow(known),"/",nrow(df))),file.path(cfg_n$out,"laufstatus.txt"))
print(summary_table)
cat(status,"\n")
