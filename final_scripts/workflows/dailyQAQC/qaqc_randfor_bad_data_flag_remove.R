
#install.packages(c("reshape2","raster","rgdal","randomForest","geosphere","data.table"))
#.rs.restartR()
rm(list=ls())

library(reshape2)
library(raster)
library(rgdal)
library(geosphere)
library(data.table)
library(randomForest)

#dirs:pc
# rf_day_data_wd<-"C:\\Users\\Matt Lucas\\Documents\\dev\\hcdp\\daily_rainfall\\qaqc\\test_data"
# lognorm_ras_wd<-"C:\\Users\\Matt Lucas\\Documents\\dev\\hcdp\\daily_rainfall\\qaqc\\probRasters"
# qaqc_models_wd<-"C:\\Users\\Matt Lucas\\Documents\\dev\\hcdp\\daily_rainfall\\qaqc\\models_rds\\randfor"

#dirs
meta_data_wd<-"/home/mplucas/precip_pipeline_container/final_scripts/workflows/dependencies" #server meta data path
rf_day_data_wd<-"/home/mplucas/precip_pipeline_container/final_scripts/workflows/dailyDataCombine/rainfall"
lognorm_ras_wd<-"/home/mplucas/precip_pipeline_container/final_scripts/workflows/dependencies/probRasters"
qaqc_models_wd<-"/home/mplucas/precip_pipeline_container/final_scripts/workflows/dependencies/models"
rf_day_qaqc_data_wd<-"/home/mplucas/precip_pipeline_container/final_scripts/workflows/dailyQAQC/rainfall_QAQC"


#rf to prob function
rf_Prob<-function(rf,meanlog,sdlog,pop){
  if(rf>0){
    rf_per<-plnorm(rf,meanlog,sdlog, lower.tail = T)#get lower tail of daily rf val (ie:cumulative prob of rf being this value or lower)
    return((1-pop)+(pop*rf_per))#include 1-pop into prob
  }else{ #if rf is zero
    return(1-pop) #assign 1-pop ie: prob of it not raining 
  }#end if/else
}#end function

#calc log prob
get_LogProb<-function(sta_df,lnAnnRas,ln6moRas){
  coordinates(sta_df) = ~LON + LAT #make sta df spatial
  log_norm_sta<-as.data.frame(sta_df,extract(lnAnnRas,sta_df),extract(ln6moRas,sta_df))
  names(log_norm_sta)[4]<-"rf_mm"
  #calc ann & 6 mon rf prob
  sta_df$rf_6mo_per<-mapply(rf_Prob,rf=log_norm_sta$rf_mm,meanlog=log_norm_sta$meanlog_6mo,sdlog=log_norm_sta$sdlog_6mo, pop=log_norm_sta$pop_6mo)# convert random rf values	to 6mo per	
  sta_df$rf_ann_per<-mapply(rf_Prob,rf=log_norm_sta$rf_mm,meanlog=log_norm_sta$meanlog_ann,sdlog=log_norm_sta$sdlog_ann, pop=log_norm_sta$pop_ann)# convert random rf values	to ann per
  final_df<-as.data.frame(sta_df)[,c(1,4:6)]
  names(final_df)<-c("SKN_target","rf_target","rf_6mo_per_target","rf_ann_per_target")
  return(final_df)
}

#calc close 10 with probs
close10RF<-function(day_df,ln6moRas,lnAnnRas){
  dist <- as.data.frame(distm(day_df[,c("LON","LAT")]))#dist of all stations to all other stations for day col 'i'
  names(dist)<-as.character(day_df$SKN)
  #row.names(dist)<-as.character(day_df$SKN)
  dist$SKN<-as.character(day_df$SKN)
  dist_long<-reshape2::melt(dist, id.vars=c("SKN"))
  names(dist_long)<-c("SKN_obs","SKN_target","dist")
  dist_long$SKN_obs<-as.character(dist_long$SKN_obs)
  dist_long$SKN_target<-as.character(dist_long$SKN_target)
  targets<-unique(dist_long$SKN_target)
  dist10_day<-data.frame()
  for(p in targets){
    dist_SKN<-dist_long[dist_long$SKN_target==p,]
    dist_SKN<-dist_SKN[dist_SKN$SKN_target!=dist_SKN$SKN_obs,]
    dist10_SKN<-dist_SKN[(order(dist_SKN[,"dist"])[1:10]),]#10 closest stations
    row.names(dist10_SKN)<-NULL
    dist10_SKN$dist_rank<-row.names(dist10_SKN)
    dist10_SKN<-dist10_SKN[,c(2,1,3,4)]
    dist10_SKN$date<-rep(as.character(names(day_df)[4]))
    dist10_SKN$date_skn_target<-paste(dist10_SKN$date,dist10_SKN$SKN_target,sep="_")
    dist10_SKN$date_skn_obs<-paste(dist10_SKN$date,dist10_SKN$SKN_obs,sep="_")
    dist10_SKN$date_skn_tar_obs<-paste(dist10_SKN$date,dist10_SKN$SKN_obs,dist10_SKN$SKN_target,sep="_")
    dist10_day<-as.data.frame(rbind(dist10_day,dist10_SKN))
  }
  
  day_df_prob<-get_LogProb(day_df,lnAnnRas,ln6moRas)
  #str(day_df_prob)
  dist10_day_merge<-merge(dist10_day,day_df_prob,by="SKN_target")
  names(day_df_prob)<-gsub("target","obs",names(day_df_prob))
  dist10_day_long<-merge(dist10_day_merge,day_df_prob,by="SKN_obs")
  dist10_day_wide <- data.table::dcast(as.data.table(dist10_day_long), SKN_target + rf_target + rf_6mo_per_target + rf_ann_per_target ~ dist_rank, value.var = c("dist","rf_obs","rf_6mo_per_obs","rf_ann_per_obs"))
  names(day_df)[1]<-"SKN_target"
  final10dist<-merge(day_df[,c("SKN_target","LON","LAT")],as.data.frame(dist10_day_wide),by="SKN_target")
  final10dist<-final10dist[,c("SKN_target","LON","LAT","rf_target","rf_6mo_per_target","rf_ann_per_target","dist_1","dist_2","dist_3","dist_4","dist_5","dist_6","dist_7","dist_8","dist_9","rf_obs_1","rf_obs_10","rf_obs_2","rf_obs_3","rf_obs_4","rf_obs_5","rf_obs_6","rf_obs_7","rf_obs_8","rf_obs_9","dist_10",
                              "rf_6mo_per_obs_1","rf_6mo_per_obs_2","rf_6mo_per_obs_3","rf_6mo_per_obs_4","rf_6mo_per_obs_5","rf_6mo_per_obs_6","rf_6mo_per_obs_7","rf_6mo_per_obs_8","rf_6mo_per_obs_9","rf_6mo_per_obs_10",
                              "rf_ann_per_obs_1","rf_ann_per_obs_2","rf_ann_per_obs_3","rf_ann_per_obs_4","rf_ann_per_obs_5","rf_ann_per_obs_6","rf_ann_per_obs_7","rf_ann_per_obs_8","rf_ann_per_obs_9","rf_ann_per_obs_10")]
  return(final10dist)
}

#bad pred function
pred_bad<-function(close10DF,rfDayCol,rfZ,rfNZ){
  close10DFNZ<-close10DF[close10DF$rf_target>0,]
  close10DFZERO<-close10DF[close10DF$rf_target==0,]
  close10DFNZ$statusPred<-as.numeric(as.character(predict(rfNZ,as.data.frame(close10DFNZ))))
  close10DFNZ$probBad<-as.data.frame(predict(rfNZ,as.data.frame(close10DFNZ),type="prob"))[,"1"]
  close10DFZERO$statusPred<-as.numeric(as.character(predict(rfZ,as.data.frame(close10DFZERO))))
  close10DFZERO$probBad<-as.data.frame(predict(rfZ,as.data.frame(close10DFZERO),type="prob"))[,"1"]
  predDF<-rbind(close10DFNZ[,c("SKN_target","statusPred","probBad")],close10DFZERO[,c("SKN_target","statusPred","probBad")])
  finalPredDF<-merge(close10DF[,c("SKN_target","LON","LAT","rf_target")],predDF,by="SKN_target")
  names(finalPredDF)[c(1,4)]<-c("SKN",rfDayCol)
  return(finalPredDF)
}

#get metadata
setwd(meta_data_wd)
geog_meta<-read.csv("Master_Sta_List_Meta_2020_11_09.csv", colClasses=c("NESDIS.id"="character"))
geog_mini_meta<-geog_meta[,c("SKN","Station.Name","Observer","Network","Island","ELEV.m.","LAT","LON")] #make mini meta data of desired station name fields

#define date
map_date<-Sys.Date()-1# yesterday as date
#map_date<-as.Date("2021-05-02") #test date as date

file_date<-format(map_date,"%Y_%m")

#get month data
setwd(rf_day_data_wd)
rf_month_filename<-paste0("daily_rf_",file_date,".csv") #dynamic file name that includes month year so when month is done new file is written
monthly_rf<-read.csv(rf_month_filename)
monthly_rf$co<-as.factor(monthly_rf$Island)
levels(monthly_rf$co)[levels(monthly_rf$co)=="MA"|levels(monthly_rf$co)=="KO"|levels(monthly_rf$co)=="LA"|levels(monthly_rf$co)=="MO"]<-"MN"
str(monthly_rf)

#subset day
rfcol<-format(as.Date(map_date),"X%Y.%m.%d")
vars<-c("SKN","co","LAT","LON",rfcol)
daily_rf<-monthly_rf[!is.na(monthly_rf[,rfcol]),vars]
row.names(daily_rf)<-NULL
str(daily_rf)

#get mean log sd log & pop rasters
setwd(lognorm_ras_wd)
state_ann<-stack(list.files("ann",full.names = T))
names(state_ann)<-c("meanlog_ann","pop_ann","sdlog_ann")
is_mjjaso<-(as.numeric(format(as.Date(map_date),"%m"))>=5 & as.numeric(format(as.Date(map_date),"%m"))<=10)
state_6mo<-if(is_mjjaso){stack(Sys.glob("6mo/hi_statewide_*mjjaso.tif"))}else{stack(Sys.glob("6mo/hi_statewide_*ndjfma.tif"))}
names(state_6mo)<-c("meanlog_6mo","pop_6mo","sdlog_6mo")

#working / test
daily_rf_all_pred<-data.frame()#blank df to store final data checked
daily_rf_checked<-data.frame()#blank df to store removed data

s<-Sys.time()
#flag remove repeat bad data
for(i in unique(daily_rf$co)){
  daily_rf_co<-daily_rf[daily_rf[!is.na(daily_rf[,rfcol]),"co"]==i,-2]
  setwd(qaqc_models_wd)
  modNZ<-readRDS(paste0(i,"_no_human_rf_nonzero_randfor.rds"))
  modZ<-readRDS(paste0(i,"_no_human_rf_zero_randfor.rds"))
  close10DF<-close10RF(day_df=daily_rf_co,ln6moRas=state_6mo,lnAnnRas=state_ann)
  daily_rf_co_pred<-pred_bad(close10DF,rfcol,modZ,modNZ)
  if(daily_rf_co_pred[which.max(daily_rf_co_pred$probBad),"statusPred"]==1){
    daily_rf_checked<-rbind(daily_rf_checked,daily_rf_co_pred[which.max(daily_rf_co_pred$probBad),])
    daily_rf_co_pred<-daily_rf_co_pred[-which.max(daily_rf_co_pred$probBad),]
  }
  nbad<-sum(daily_rf_co_pred$statusPred)
  while(nbad>0){
    daily_rf_co<-daily_rf_co_pred[,1:4]
    close10DF<-close10RF(day_df=daily_rf_co,ln6moRas=state_6mo,lnAnnRas=state_ann)
    daily_rf_co_pred<-pred_bad(close10DF,rfcol,modZ,modNZ)
    if(daily_rf_co_pred[which.max(daily_rf_co_pred$probBad),"statusPred"]==1){
      daily_rf_checked<-rbind(daily_rf_checked,daily_rf_co_pred[which.max(daily_rf_co_pred$probBad),])
      daily_rf_co_pred<-daily_rf_co_pred[-which.max(daily_rf_co_pred$probBad),]
    }
    nbad<-sum(daily_rf_co_pred$statusPred)
    if(nrow(daily_rf_co_pred)<=11){nbad<-0}
  }#remove bad while loop
  daily_rf_all_pred<-rbind(daily_rf_all_pred,daily_rf_co_pred)
}#co loop end
e<-Sys.time()
(e-s)

#row.names(daily_rf_all_pred)<-NULL
#print(daily_rf_all_pred)

#combine all data together
daily_rf_checked<-rbind(daily_rf_all_pred,daily_rf_checked)
daily_rf_checked<-daily_rf_checked[order(as.numeric(row.names(daily_rf_checked))),]
row.names(daily_rf_checked)<-NULL
str(daily_rf_checked)

#write or append daily rf QAQC flag & prob data
setwd(rf_day_qaqc_data_wd) #set rainfall output wd
qaqc_files<-list.files()
rf_qaqc_month_filename<-paste0("daily_rf_flag_",file_date,".csv") #dynamic file name that includes month year so when month is done new file is written
rf_qaqc_prob_month_filename<-paste0("daily_rf_prob_",file_date,".csv") #dynamic file name that includes month year so when month is done new file is written

#conditional statement that adds new qaqc daily data
if(max(as.numeric(qaqc_files==rf_qaqc_month_filename))>0){
  #add flag
  rf_month_qaqc_df<-read.csv(rf_qaqc_month_filename)
  sub_cols<-c("SKN",names(rf_month_qaqc_df)[grep("X",names(rf_month_qaqc_df))])
  rf_month_qaqc_df<-merge(rf_month_qaqc_df,daily_rf_flag[,sub_cols],by="SKN",all=T)
  daily_rf_flag<-daily_rf_checked[,c("SKN","statusPred")]
  names(daily_rf_flag)[2]<-rfcol
  final_rf_daily_month_qaqc_flag<-merge(geog_mini_meta,,by="SKN")
  #write.csv(final_rf_daily_month_qaqc_flag,rf_qaqc_month_filename, row.names=F)
  
  #prob bad
  rf_month_prob_df<-read.csv(rf_qaqc_prob_month_filename)
  sub_cols<-c("SKN",names(rf_month_prob_df)[grep("X",names(rf_month_prob_df))])
  rf_month_prob_df<-merge(geog_mini_meta,rf_month_prob_df[,sub_cols],by="SKN",all=T)
  daily_rf_prob<-daily_rf_checked[,c("SKN","probBad")]
  names(daily_rf_prob)[2]<-rfcol
  final_rf_daily_month_qaqc_prob<-merge(rf_month_prob_df,daily_rf_prob,by="SKN",all=T)
  #write.csv(final_rf_daily_month_qaqc_prob,rf_qaqc_prob_month_filename, row.names=F)
  
  print(paste(rf_qaqc_month_filename,"daily rainfall table appended!"))
  print(paste(rf_qaqc_prob_month_filename,"daily rainfall table appended!"))
  
  }else{ #if month year file does not exist make a new month year file
  #flag
  daily_rf_flag<-daily_rf_checked[,c("SKN","statusPred")]
  names(daily_rf_flag)[2]<-rfcol
  final_rf_daily_month_qaqc_flag<-merge(monthly_rf[,1:8],daily_rf_flag,by="SKN")
  #write.csv(final_rf_daily_month_qaqc_flag,rf_qaqc_month_filename, row.names=F)
  #prob
  daily_rf_prob<-daily_rf_checked[,c("SKN","probBad")]
  names(daily_rf_prob)[2]<-rfcol
  final_rf_daily_month_qaqc_prob<-merge(monthly_rf[,1:8],daily_rf_prob,by="SKN")
  #write.csv(final_rf_daily_month_qaqc_prob,rf_qaqc_prob_month_filename, row.names=F)
  
  print(paste(rf_qaqc_month_filename,"daily rainfall table written!"))
  print(paste(rf_qaqc_prob_month_filename,"daily rainfall table written!"))
  
}

#remove rf values from flagged stations and write/append
final_rf_daily_QAQC_filename<-paste0("daily_rf_QAQC_",file_date,".csv") #dynamic file name that includes month year so when month is done new file is written

if(max(as.numeric(qaqc_files==final_rf_daily_QAQC_filename))>0){
  #append qaqc rf
  rf_month_qaqc<-read.csv(final_rf_daily_QAQC_filename)
  sub_cols<-c("SKN",names(rf_month_qaqc)[grep("X",names(rf_month_qaqc))])
  rf_month_qaqc<-merge(geog_mini_meta,rf_month_qaqc[,sub_cols],by="SKN",all=T)
  daily_rf_flag<-daily_rf_checked[,c("SKN","statusPred")]
  names(daily_rf_flag)[2]<-rfcol
  final_rf_daily_month_qaqc_flag<-merge(rf_month_qaqc,daily_rf_flag,by="SKN",all=T)
  write.csv(final_rf_daily_month_qaqc_flag,rf_qaqc_month_filename, row.names=F)
  
  print(paste(rf_qaqc_month_filename,"daily rainfall table appended!"))

}else{ #if month year file does not exist make a new month year file
  #write new qaqc
  names(daily_rf_flag)[2]<-"FLAG"
  daily_rf_merge<-merge(daily_rf_flag,daily_rf[,c("SKN",rfcol)],by="SKN")
  daily_rf_merge<-daily_rf_merge[!daily_rf_merge$FLAG,c("SKN",rfcol)]
  final_rf_daily_QAQC<-merge(geog_mini_meta,daily_rf_merge,by="SKN")
  write.csv(final_rf_daily_QAQC,final_rf_daily_QAQC_filename, row.names=F)
  print(paste(final_rf_daily_QAQC_filename,"daily rainfall table written!"))
}







str(daily_rf)
str(daily_rf_flag)
str(df)










################
allPred<-merge(monthly_rf[,1:6],daily_rf_checked,by="SKN",all.x=T)


allPred<-allPred[rev(row.names(allPred)),]
finalPred<-allPred[!duplicated(allPred$SKN),]

summary(daily_rf_pred$rf_target)
nrow(daily_rf_pred)








teast<-allPred[1:50,-c(10:11)]
names(teast)[9]<-"X2005.04.22"
teast$mean_jday122<-round(runif(50,0.5,40),3)
teast$Anom_X2005.04.22<-teast$X2005.04.22/teast$mean_jday122
