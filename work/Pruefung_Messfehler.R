suppressPackageStartupMessages(library(data.table))
source(path.expand('~/git/overall-campaigns/messfehler_mettmenstetten.R'))
base <- path.expand('~/git/overall-campaigns/ergebnisse_bericht')
settings <- readRDS(file.path(base,'laufparameter.rds'))
cfg <- settings$cfg; campaigns <- settings$campaigns
e <- fread(file.path(base,'kampagnenvergleich_gemessene_endwerte.csv'),dec=',')[variant=='unkorrigiert']
w <- fread(file.path(base,'kampagnenvergleich_schlachttaggewichtet.csv'),dec=',')[variant=='unkorrigiert']
ends <- rbindlist(lapply(1:2,function(h) e[,.(campaign,housing=paste0('housing_',h),
 kg=get(paste0('barn',h,'_total_kg')),g_animal=get(paste0('barn',h)))]))
weighted <- rbindlist(lapply(1:2,function(h) w[,.(campaign,housing=paste0('housing_',h),
 g_animal=get(paste0('barn',h)))]))
ends <- merge(ends,campaigns,by='campaign'); weighted <- merge(weighted,campaigns,by='campaign')
u <- sqrt(cfg$uncertainty_fan^2+cfg$uncertainty_xnode^2)
z <- measurement_uncertainties(ends,weighted,campaigns,cfg)
d <- z$detail[group=='end' & variant=='unkorrigiert' & metric=='barn1']
stopifnot(max(abs(d$propagated_error-u*d$value))<1e-9)
# Unabhaengige Herleitung fuer korrigierten Stall 2: Originalmenge / Mittelratio.
rr <- vapply(campaigns[role=='offset',campaign], function(id)
 ends[campaign==id & housing=='housing_2',g_animal]/ends[campaign==id & housing=='housing_1',g_animal],numeric(1))
ur <- sqrt(sum(2*u^2*rr^2)/length(rr)^2)/mean(rr)
d <- z$detail[group=='end' & variant=='stall1_realitaet' & metric=='barn2' &
               campaign %in% campaigns[role=='wrg',campaign]]
stopifnot(max(abs(d$propagated_error-d$value*sqrt(u^2+ur^2)))<1e-9)
# Gemeinsame Skalierung muss sich im Quotienten inklusive Fehler herauskuerzen.
d <- dcast(z$detail[group=='end' & metric=='ratio' & variant!='unkorrigiert'],
           campaign~variant,value.var='propagated_error')
stopifnot(max(abs(d$stall1_realitaet-d$mittel_beider_staelle))<1e-9)
# Mit nur einem Offset sind dort die korrigierten Staelle algebraisch identisch:
# der gemeinsame Offset darf nicht zweimal als unabhaengiger Fehler zaehlen.
c4 <- campaigns[campaign!='aug2026']
z4 <- measurement_uncertainties(ends[campaign!='aug2026'],weighted[campaign!='aug2026'],c4,cfg)
stopifnot(max(z4$detail[group=='end' & campaign=='dec2024' & variant!='unkorrigiert' &
 metric=='difference',propagated_error])<1e-8)
# Voll korrelierter, staendiger Stallbias hebt sich in der Offsetkorrektur auf.
corr_cfg <- cfg; corr_cfg$measurement_campaign_correlation <- 1
zc <- measurement_uncertainties(ends,weighted,campaigns,corr_cfg)
stopifnot(max(zc$detail[group=='end' & metric=='ratio' & variant!='unkorrigiert',propagated_error])<1e-7)
zero_cfg <- cfg; zero_cfg$uncertainty_fan <- zero_cfg$uncertainty_xnode <- 0
zz <- measurement_uncertainties(ends,weighted,campaigns,zero_cfg)
stopifnot(all(zz$detail$measurement_error==0))
prop_cfg <- cfg; prop_cfg$reduction_error <- 'ratio_independent'
zp <- measurement_uncertainties(ends,weighted,campaigns,prop_cfg)
stopifnot(all(zp$detail$measurement_error==zp$detail$propagated_error))
cat('Geprueft: rohe Fehler, Offsetfortpflanzung, Skalierungsinvarianz, gemeinsamer Offset, Korrelation, Nullfehler und beide Reduktionskonventionen.\n')
