suppressPackageStartupMessages({library(data.table);library(readxl)})
base<-path.expand("~/git/overall-campaigns");setwd(base)
source("kampagnen_daten.R")
reg<-overall_campaign_registry()
stopifnot(nrow(reg)==5,reg[code=="aug",id]=="aug2026",!reg[code=="aug",wrg_active])
for(folder in c("aussentemperatur","rh","gam_rh")){
 p<-file.path(base,"ergebnisse_klima",folder)
 x<-fread(file.path(p,"kampagnen_und_quellen.csv"),dec=",")
 stopifnot(nrow(x)==5,"aug2026" %in% x$id,!"jul2025" %in% x$id,
  readLines(file.path(p,"laufstatus.txt"))[1]=="ERFOLGREICH")
}
t<-fread("ergebnisse_klima/aussentemperatur/temperatur_verlauf.csv",dec=",")
r<-fread("ergebnisse_klima/rh/rh_verlauf.csv",dec=",")
stopifnot(uniqueN(t$campaign)==5,uniqueN(r$campaign)==5,
 nrow(t[campaign=="Aug-26"])==1604,nrow(r[campaign=="Aug-26"])==1604)
# Direkter Abgleich der arithmetischen Sensormittel, unabhaengig vom Importhelfer.
for(id in c("feb2024","aug2026")){
 d<-as.data.table(qs2::qd_read(path.expand(paste0("~/git/mettmenstetten-",id,"/rsaves/final-dataset.qd"))))
 h<-d[tracer=="humidity" & flow_direction=="outflow" & grepl("^nh3_",sensor) & !grepl("turbo",location,ignore.case=TRUE),
  .(expected=mean(value,na.rm=TRUE)),by=.(housing,st)]
 label<-if(id=="feb2024")"Feb-24" else "Aug-26"
 a<-copy(r[campaign==label])
 a[,st:=as.POSIXct(st,tz="Europe/Zurich")]
 m<-merge(h,a,by.x=c("housing","st"),by.y=c("housing_code","st"))
 stopifnot(nrow(m)==nrow(h),max(abs(m$expected-m$rh_mean),na.rm=TRUE)<1e-10)
}
ma<-readRDS("ergebnisse_klima/gam_rh/gam_Aug_26.rds")
mo<-readRDS("ergebnisse_klima/gam_rh/gam_offsets.rds")
mw<-readRDS("ergebnisse_klima/gam_rh/gam_main.rds")
stopifnot(nrow(ma$model)>1500,setequal(as.character(unique(mo$model$campaign)),c("Dec-24","Aug-26")),
 setequal(as.character(unique(mw$model$campaign)),c("Feb-24","Apr-24","Jul-24")))
coverage<-fread("ergebnisse_n_ausscheidung/datenverfuegbarkeit.csv",dec=",")
summary<-fread("ergebnisse_n_ausscheidung/mittelwerte_nach_stall.csv",dec=",")
stopifnot(nrow(coverage)==10,all(coverage[Umtrieb=="Aug-26",N_available]),
 all(coverage[Umtrieb=="Aug-26",vorlaeufig]),all(summary$complete),all(is.finite(summary$mean_weighted)),all(summary$n_provisional==1))
stopifnot(all(abs(fread("ergebnisse_n_ausscheidung/n_ausscheidung_mit_gewichten.csv",dec=",")[Umtrieb=="Aug-26",gewicht]-.125)<1e-12))
# Synthetische Daten ausschliesslich in einem getrennten Testordner.
testdir<-file.path(base,"work","test_august_n_bilanz")
dir.create(testdir,recursive=TRUE,showWarnings=FALSE)
synthetic<-file.path(testdir,"synthetische_eingabe.csv")
fwrite(data.table(Stall=c(1,2),Umtrieb="Aug-26",N_ausgeschieden_pro_Tier_g=c(35,36),
 TAN_pro_Tier_g=c(21,21.6),NH3_N_gemessen_pro_Tier_g=c(.5,.52)),
 synthetic,sep=";",dec=",",na="",bom=TRUE)
env<-new.env(parent=globalenv())
env$n_overrides<-list(input=path.expand("~/Documents/0 - MSc HAFL/MA/analysen/IMPEX_Gfeller_nach MA.xlsx"),supplement=synthetic,out=file.path(testdir,"ergebnisse"))
sys.source(file.path(base,"N-Excretion.R"),envir=env)
stopifnot(nrow(env$known)==10,all(env$summary_table$complete),
 nrow(env$df_paired)==3,!any(as.character(env$df_paired$Umtrieb)=="Aug-26"))
g<-env$known[Umtrieb %in% c("Jul-24","Aug-26"),.(weight=sum(gewicht)),by=Stall]
stopifnot(all(abs(g$weight-.25)<1e-12),all(env$known[Umtrieb=="Aug-26",gewicht]==.125))
cat("Geprueft: alle fuenf Kampagnen, RH-Sensormittel, getrennte Offsetmodelle, vorlaeufige August-N-Bilanzen und getrennter Zusatzimport.\\n")
