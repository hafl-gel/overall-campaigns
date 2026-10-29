suppressPackageStartupMessages(library(data.table))
base<-path.expand("~/git/overall-campaigns")
out<-file.path(base,"Einstreu","ergebnisse_einstreu")
hist<-file.path(out,"ohne_august2026")
p<-fread(file.path(hist,"tag34_paarvergleiche.csv"),dec=",")
s<-fread(file.path(hist,"tag34_deskriptiv_und_buchstaben.csv"),dec=",")
ids<-c("FEB_S1","FEB_S2","APR_S1","APR_S2","JUL_S1","JUL_S2","DEC_S1","DEC_S2")
expected<-list(moisture_pct=c("ab","ab","ab","c","a","cd","bd","a"),pH=rep("a",8),
 N_total_gkg_TS=c("a","a","a","a","b","a","a","a"),
 NH4_gkg_TS=c("ac","ab","abc","ab","ac","ab","b","c"))
shared<-function(a,b)length(intersect(strsplit(a,"")[[1]],strsplit(b,"")[[1]]))>0
checks<-lapply(names(expected),function(metric_id){
 e<-setNames(expected[[metric_id]],ids);z<-p[p$metric==metric_id]
 stopifnot(nrow(z)==28)
 ok<-vapply(seq_len(nrow(z)),function(i)(z$p_adj[i]>=.05)==shared(e[[z$group1[i]]],e[[z$group2[i]]]),logical(1))
 stopifnot(all(ok));data.table(metric=metric_id,pairs=nrow(z),matched=sum(ok))
})
checks<-rbindlist(checks)
m<-s[metric=="moisture_pct"][match(ids,group)]
stopifnot(identical(round(m$mean,1),c(35.5,32.9,36.1,23.8,38.0,25.5,30.8,39.4)),
 identical(round(m$sd,1),c(1.4,5.7,2.1,.7,4.2,2.6,2.8,3.6)),all(m$n==5))
modern<-fread(file.path(out,"tag34_deskriptiv_und_buchstaben.csv"),dec=",")
stopifnot(nrow(modern)==40,all(modern[campaign=="AUG26"&stall==1,n]==6),
 all(modern[campaign=="AUG26"&stall==2,n]==5),nrow(fread(file.path(out,"analysewerte.csv"),dec=","))==181,
 nrow(fread(file.path(hist,"analysewerte.csv"),dec=","))==150)
# Optionale Statistikzweige pruefen, ohne neue Grafikvarianten zu schreiben.
env<-new.env(parent=globalenv())
expr<-parse(file.path(base,"einstreu_mettmenstetten.R"))
for(e in head(expr,-3L))eval(e,env)
data<-copy(env$raw[campaign %in% env$cfg$campaigns & stall %in% c("1","2") & masttag==34])
data[,group:=factor(paste0(campaign,"_S",stall),levels=unlist(lapply(env$cfg$campaigns,function(id)paste0(id,"_S",1:2))))]
for(method in c("welch_games_howell","kruskal_dunn")){
 env$cfg$test_method<-method
 for(metric in names(expected)){
  z<-copy(data);z[,value:=get(metric)]
  a<-env$test_day(z)
  stopifnot(nrow(a$pair)==45,all(is.finite(a$pair$p_adj)),nrow(a$letters)==10)
 }
}
fwrite(checks,file.path(base,"work","Einstreu_Rekonstruktionspruefung.csv"),sep=";",dec=",",bom=TRUE)
print(checks)
cat("Historische Tabelle 8, alle 112 Paarentscheidungen, aktuelle Probenzahlen und beide Alternativtests geprueft.\n")
