#.rs.restartR()
rm(list=ls())

require(doParallel)
require(foreach)
require(data.table)
require(fitdistrplus)
require(tidyr)
require(e1071)
require(Metrics)
require(randomForest)
require(mgcv)
require(ggplot2)
require(caret)
require(geosphere)
require(dplyr)
require(ggplot2)

### Define functions
`%notin%` <- Negate(`%in%`)

comb <- function(x, ...) {  
  mapply(rbind,x,...,SIMPLIFY=FALSE)
}

#rf to prob function
rf_Prob<-function(rf,meanlog,sdlog,pop){
  if(rf>0){
    rf_per<-plnorm(rf,meanlog,sdlog, lower.tail = T)#get lower tail of daily rf val (ie:cumlitive prob of rf being this value or lower)
    return((1-pop)+(pop*rf_per))#include 1-pop into prob
  }else{ #if rf is zero
    return(1-pop) #assign 1-pop ie: prob of it not raining 
  }#end if/else
}#end function

#rf percent diff function
rfmmMker<-function(rfR,meanlog,sdlog,pop,maxPer,threshMM){
  perRx<-((maxPer+pop)-1)/pop #pop prob re-conversion
  rfMax<-qlnorm(perRx,meanlog,sdlog)  #prob to rf mm
  if(threshMM < rfMax){
    rfF<-rlnorm(1, meanlog = meanlog, sdlog = sdlog)
    diff<-abs(rfR-rfF)
    while(diff<threshMM){
      rfF<-rlnorm(1, meanlog = meanlog, sdlog = sdlog)
      diff<-abs(rfF-rfR)
    }
    return(rfF) }else{return(print("thresh rf mm exceeds max prob"))}
} 

#fix rf diff mm
fixRFmm<-function(rfR,mmDif){
  if((rfR-mmDif)<=0){
    rfF<-rfR+mmDif
  }else{
    rfF<-ifelse(runif(1)>=0.5,rfR+mmDif,rfR-mmDif)
  }
  return(rfF)
}

#make accuracy row function
acc_func<-function(method,machine,test_data,threshold,train_data){
  test_data_sub<-test_data
  if(length(grep("KNN*",method,ignore.case=TRUE))>0){
    pred<-predict(machine,test_data_sub,type = "class")
  }else{
    pred<-predict(machine,test_data_sub,type = "response")}
  if(is.factor(pred)){
    test_data$predict<-as.numeric(as.character(pred))
  }else{if(is.logical(pred)){
    test_data$predict<-as.numeric(pred)
  }else{if(is.numeric(pred)){
    test_data$predict<-as.numeric(pred>0.5)
  }}}
  tab<-table(test_data$predict,test_data$status)
  cm<-confusionMatrix(tab,positive = as.character(1))
  acc_df<-cbind(t(as.data.frame(cm$overall)),data.frame(Specificity=cm$byClass[2],Sensitivity=cm$byClass[1])) #% overall accuacy, % real values correctly classfied, % fake values correctly caught
  row.names(acc_df)<-NULL
  acc_df_all<-cbind(data.frame(domain=domain,method=method,indata=datatype,thresh=threshold,train_samp=nrow(train_data),train_real_ratio=(sum(train_data$status==1)/nrow(train_data)),test_samp=nrow(test_data),test_real_ratio=(sum(test_data$status==1)/nrow(test_data))),acc_df)
  return(acc_df_all)}

#make custom predict df function
pred_func<-function(method,machine,test_data,train_data){
  data<-rbind(test_data,train_data)
  if(length(grep("KNN*",method,ignore.case=TRUE))>0){
    pred<-predict(machine,data,type = "class")
  }else{
    pred<-predict(machine,data,type = "response")}
  if(is.factor(pred)){
    data$predict<-as.numeric(as.character(pred))
  }else{if(is.logical(pred)){
    data$predict<-as.numeric(pred)
  }else{if(is.numeric(pred)){
    data$predict<-as.numeric(pred>0.5)
  }}}
  data$method<-rep(method,nrow(data))
  return(data[,c("date_skn_target","method","predict")])
}

#calc close 10 rf function
close10StaRF<-function(day_df){
  #day_df<-final_day_data#testing
  dist <- as.data.frame(distm(day_df[,c("LON","LAT")]))#dist of all stations to all other stations for day col 'i'
  names(dist)<-as.character(day_df$SKN_target)
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
    dist10_SKN$date<-rep(as.character(unique(day_df$date)))
    dist10_SKN$date_skn_target<-paste(dist10_SKN$date,dist10_SKN$SKN_target,sep="_")
    dist10_SKN$date_skn_obs<-paste(dist10_SKN$date,dist10_SKN$SKN_obs,sep="_")
    dist10_SKN$date_skn_tar_obs<-paste(dist10_SKN$date,dist10_SKN$SKN_obs,dist10_SKN$SKN_target,sep="_")
    dist10_day<-as.data.frame(rbind(dist10_day,dist10_SKN))
  }
  day_rf<-as.data.frame(day_df[,c("SKN_target","rf_target","rf_6mo_per_target","rf_ann_per_target","status")])
  day_rf$rf_obs<-as.numeric(day_rf$rf_target)
  day_rf$rf_6mo_per_obs<-as.numeric(day_rf$rf_6mo_per_target)
  day_rf$rf_ann_per_obs<-as.numeric(day_rf$rf_ann_per_target)
  
  dist10_day_merge<-merge(dist10_day,day_rf[,c("SKN_target","status","rf_target","rf_6mo_per_target","rf_ann_per_target")],by.x="SKN_target",by.y="SKN_target")
  dist10_day_long<-merge(dist10_day_merge,day_rf[,c("SKN_target","rf_obs","rf_6mo_per_obs","rf_ann_per_obs")],by.x="SKN_obs",by.y="SKN_target")
  dist10_day_wide <- data.table::dcast(as.data.table(dist10_day_long), SKN_target + rf_target + rf_6mo_per_target + rf_ann_per_target + status ~ dist_rank, value.var = c("dist","rf_obs","rf_6mo_per_obs","rf_ann_per_obs"))
  return(as.data.frame(dist10_day_wide))
}

#bad pred function
pred_bad<-function(close10DF,rfZ,rfNZ){
  close10DFNZ<-close10DF[close10DF$rf_target>0,]
  close10DFZERO<-close10DF[close10DF$rf_target==0,]
  close10DFNZ$statusPred<-as.integer(as.character(unlist(predict(rfNZ,as.data.frame(close10DFNZ),type="response"))))
  close10DFNZ$probBad<-as.numeric(unlist(predict(rfNZ,as.data.frame(close10DFNZ),type="prob")[,"1"]))
  close10DFZERO$statusPred<-as.integer(as.character(unlist(predict(rfZ,as.data.frame(close10DFZERO),type="response"))))
  close10DFZERO$probBad<-as.numeric(unlist(predict(rfZ,as.data.frame(close10DFZERO),type="prob")[,"1"]))
  predDF<-rbind(close10DFNZ[,c("SKN_target","statusPred","probBad")],close10DFZERO[,c("SKN_target","statusPred","probBad")])
  return(merge(close10DF,predDF,by="SKN_target"))
}

#round checker function
roundCheck<-function(df,dfbad,round){
  if(round>0){
    return(data.frame(staStart=nrow(df)+1,staRemain=nrow(df),county=domain,iteration=round,good_removed=sum(dfbad$status==0),bad_removed=sum(dfbad$status==1),good_remain=sum(df$status==0),bad_remain=sum(df$status==1),bad_pred=sum(df$statusPred==1),mean_pred=mean(df$probBad),median_pred=median(df$probBad)))
  }else{
    return(data.frame(staStart=nrow(df),staRemain=nrow(df),county=domain,iteration=round,good_removed=0,bad_removed=0,good_remain=sum(df$status==0),bad_remain=sum(df$status==1),bad_pred=as.numeric(NA),mean_pred=as.numeric(NA),median_pred=as.numeric(NA)))
    }}

#iteration class remove recalc loop/funtion
interateError<-function(roundChecks,final_day_data,data_day_c10,ranfor_Zero_rf,ranfor_NZ_rf,intialOnly=FALSE){
  for(i in 1:ifelse(intialOnly,1,nrow(final_day_data))){
    c10pred<-pred_bad(close10DF=data_day_c10,rfZ=ranfor_Zero_rf,rfNZ=ranfor_NZ_rf)
    roundChecks$mean_pred[i]<-mean(c10pred$probBad)
    roundChecks$median_pred[i]<-median(c10pred$probBad)
    c10pred$SKN_target<-as.character(c10pred$SKN_target)
    remove<-final_day_data[final_day_data$SKN_target %in% c10pred[c10pred$probBad==max(c10pred$probBad) & c10pred$statusPred==1 ,"SKN_target"],] #subset out best bad prediction
    remove$SKN_target<-as.character(remove$SKN_target)
    roundremove<-rbind(roundremove,remove)
    final_day_data$SKN_target<-as.character(final_day_data$SKN_target)
    roundSub<-final_day_data[final_day_data$SKN_target %notin% roundremove$SKN_target,] #remove out best bad prediction
    roundSub<-merge(roundSub,c10pred[,c("SKN_target","statusPred","probBad")],by="SKN_target")
    roundCheckRow<-roundCheck(roundSub,roundremove,round=i)
    roundChecks<-rbind(roundChecks,roundCheckRow)#save results
    if(nrow(roundSub)>=11){
      data_day_c10<-close10StaRF(roundSub)#Remake close 10 rf df to predict onto
    }
  }#end station loop
  roundChecks$bad_pred[1]<-roundChecks$bad_pred[2]+1 #add intial bad data check
  roundChecks$totalSta<-rep(roundChecks$staStart[1],nrow(roundChecks))
  roundChecks$totalBad<-rep(roundChecks$bad_remain[1],nrow(roundChecks))
  roundChecks$totalGood<-rep(roundChecks$good_remain[1],nrow(roundChecks))
  roundChecks$date<-rep(day,nrow(roundChecks)) #add date all
  roundChecks$perBad<-rep(perBad,nrow(roundChecks)) #add percent bad all
  roundChecks$perGoodRemove<-roundChecks$good_removed/roundChecks$totalGood
  roundChecks$perBadRemove<-roundChecks$bad_removed/roundChecks$totalBad
  roundChecks$perGoodRemain<-roundChecks$good_remain/roundChecks$totalGood
  roundChecks$perIteration <-roundChecks$iteration/roundChecks$totalSta
  roundChecks$perTotalBad<-roundChecks$totalBad[1]/roundChecks$totalSta[1]
  if(intialOnly){
    return(roundChecks[1,])
  }else{
    return(roundChecks)
  }
}#interateError func end

#end custom functions

#set wd load file names for loop
setwd("/workflows/qaqc/data_attribute_run/output/finalData")
files<-Sys.glob("*no_human_data_wide_FINAL_2020_11_13.csv")

#define per county train thresh
co_thresh<-data.frame(co=c("BI","MN","OA","KA"),threshNZ=c(11,7,9,6),threshZ=c(1,1,1,1))

rf_para<-data.frame(co=c("BI","MN","OA","KA"),ntree_Z_best=c(1000,750,500,500),mtry_Z_best=c(3,4,3,6),ntree_NZ_best=c(1000,1250,1000,1250),mtry_NZ_best=c(19,17,14,21))

roundChecksAll<-data.frame()

s<-Sys.time()
#county domain loop
for(f in files){
  roundChecksCounty<-data.frame()#reset for runs within county
  
  setwd("/workflows/qaqc/data_attribute_run/output/finalData")
  all_dat<-fread(f) #get county file
  #all_dat<-all_dat[all_dat$date %in% unique(all_dat$date)[sample(length(unique(all_dat$date)),100)],] #sample 100 days TESTING
  domain<-as.character(unique(all_dat$county))
  
  #define county training threshold
  threshNZ<- co_thresh[co_thresh$co==domain,"threshNZ"]
  threshZ<- co_thresh[co_thresh$co==domain,"threshZ"]
  
  for(run in 1:3){
  all_dat$date<-substr(all_dat$date_skn_target,1,10)#make date col
  
  #subset 365 of random days
  #date_samp<-unique(all_dat$date)[sample(length(unique(all_dat$date)),10)] #sample 10 days TESTING
  date_samp<-unique(all_dat$date)[sample(length(unique(all_dat$date)),365)] #sample 365 days
  
  ###TRAINING DATASETS
  train_dat<-all_dat[all_dat$date %notin% date_samp,]
  
  #subset rain no-rain datasets
  nozero_dat_train<-train_dat[train_dat$rf_target>0,] #only rainfall station days, no zeros
  zero_dat_train<-train_dat[train_dat$rf_target==0,] #only rainfall station days with only zeros
  
  #NZ dataset
  #subset to make 1/2 real and 1/2 fake data train data
  randset<-sample(nrow(nozero_dat_train), floor(nrow(nozero_dat_train)/2)) #1/2 rows
  nozero_train_real<-nozero_dat_train[!randset,] #random 1/2 rows
  nozero_train_fake<-nozero_dat_train[randset,] #random 1/2 rows
      
      #make random values to make fake/bad data
      #maxPer<-max(train_fake$rf_ann_per_target)
      nozero_train_fake$rf_target<-mapply(rfmmMker,rfR=nozero_train_fake$rf_target,meanlog=nozero_train_fake$target_meanlog_ann,sdlog=nozero_train_fake$target_sdlog_ann, pop=nozero_train_fake$target_pop_ann, threshMM=threshNZ, maxPer=0.9999)# random generate rf values	
      nozero_train_fake$rf_ann_per_target<-mapply(rf_Prob,rf=nozero_train_fake$rf_target,meanlog=nozero_train_fake$target_meanlog_ann,sdlog=nozero_train_fake$target_sdlog_ann, pop=nozero_train_fake$target_pop_ann)# convert random rf values	to ann per
      nozero_train_fake$rf_6mo_per_target<-mapply(rf_Prob,rf=nozero_train_fake$rf_target,meanlog=nozero_train_fake$target_meanlog_6mo,sdlog=nozero_train_fake$target_sdlog_6mo, pop=nozero_train_fake$target_pop_6mo)# convert random rf values	to 6mo per	
      nozero_train_fake$rf_3mo_per_target<-mapply(rf_Prob,rf=nozero_train_fake$rf_target,meanlog=nozero_train_fake$target_meanlog_3mo,sdlog=nozero_train_fake$target_sdlog_3mo, pop=nozero_train_fake$target_pop_3mo)# convert random rf values	to 3mo per	
      
      #add train class column 
      nozero_train_fake$status<-rep(1,nrow(nozero_train_fake)) #1 is fake 
      nozero_train_real$status<-rep(0,nrow(nozero_train_real)) #0 is real
      
      #combind nozero fake/real data together
      nozero_train<-rbind(nozero_train_fake,nozero_train_real)

      #Zero dataset
      #subset to make 1/2 real zero and 1/2 fake zero data
      if(nrow(nozero_dat_train)<nrow(zero_dat_train)){ #if more non-zero obs than zero obs
        randset<-sample(nrow(zero_dat_train),nrow(nozero_dat_train))
        sub_Z_real<-zero_dat_train[randset,]
        sub_Z_fake<-nozero_dat_train
      }else{ #if more zero obs than non-zero obs 
        randset<-sample(nrow(nozero_dat_train),nrow(zero_dat_train))
        sub_Z_fake<-nozero_dat_train[randset,] #random subset of non-zero to make into zero data
        sub_Z_real<-zero_dat_train
      }
      
      #make 0 rf values to make fake/bad data
      sub_Z_fake$rf_target<- as.numeric(rep(0,nrow(sub_Z_fake))) #propigate 0 mm rf to replace observed rf mm
      sub_Z_fake$rf_3mo_per_target<-sub_Z_fake$target_pop_3mo #make 3mo pop percentile values replace observed values
      sub_Z_fake$rf_6mo_per_target<-sub_Z_fake$target_pop_6mo #make 6mo pop percentile values replace observed values
      sub_Z_fake$rf_ann_per_target<-sub_Z_fake$target_pop_ann #make Ann pop percentile values replace observed values
      
      #add train class column 
      sub_Z_fake$status<-rep(1,nrow(sub_Z_fake)) #1 is fake 
      sub_Z_real$status<-rep(0,nrow(sub_Z_real)) #0 is real
      
      #combind fake/real data together 
      zero_train<-rbind(sub_Z_fake,sub_Z_real)

      ###Build RF models      
      #NZ data raw rainfall
      ncore<-10
      ntreePara<-rf_para[rf_para$co==domain,"ntree_NZ_best"]/ncore
      cl <- makeCluster(ncore)
      registerDoParallel(cl)
      ranfor_NZ_rf <- foreach(ntree=rep(ntreePara,ncore), .combine=randomForest::combine, .multicombine=TRUE, .packages='randomForest'
                      )%dopar%{
                      randomForest::randomForest(formula = as.factor(status) ~ 
                                                   rf_target+
                                                   rf_obs_1+rf_obs_2+rf_obs_3+rf_obs_4+rf_obs_5+rf_obs_6+rf_obs_7+rf_obs_8+rf_obs_9+rf_obs_10
                                                 +dist_1+dist_2+dist_3+dist_4+dist_5+dist_6+dist_7+dist_8+dist_9+dist_10, data=nozero_train,
                                                 ntree=ntree,mtry=rf_para[rf_para$co==domain,"mtry_NZ_best"])
                      }
      stopCluster(cl) # unhook cluster
      
      #ZERO data raw rainfall
      if(domain=="MN"){
        ncore<-10
        ntreePara<-rf_para[rf_para$co==domain,"ntree_NZ_best"]/ncore
        cl <- makeCluster(ncore)
        registerDoParallel(cl)
        ranfor_Zero_rf <- foreach(ntree=rep(ntreePara,ncore), .combine=randomForest::combine, .multicombine=TRUE, .packages='randomForest'
        )%dopar%{  
        randomForest::randomForest(formula = as.factor(status)~ rf_6mo_per_target+
                                                       rf_6mo_per_obs_1+rf_6mo_per_obs_2+rf_6mo_per_obs_3+rf_6mo_per_obs_4+rf_6mo_per_obs_5+rf_6mo_per_obs_6+rf_6mo_per_obs_7+rf_6mo_per_obs_8+rf_6mo_per_obs_9+rf_6mo_per_obs_10+
                                                       dist_1+dist_2+dist_3+dist_4+dist_5+dist_6+dist_7+dist_8+dist_9+dist_10, data=zero_train,
                                                       ntree=ntree,mtry=rf_para[rf_para$co==domain,"mtry_Z_best"])
        }
        stopCluster(cl) # unhook cluster
        
        }else{
        ncore<-10
        ntreePara<-rf_para[rf_para$co==domain,"ntree_NZ_best"]/ncore
        cl <- makeCluster(ncore)
        registerDoParallel(cl)
        ranfor_Zero_rf<-foreach(ntree=rep(ntreePara,ncore), .combine=randomForest::combine, .multicombine=TRUE, .packages='randomForest'
        )%dopar%{ 
        randomForest::randomForest(formula = as.factor(status)~ rf_ann_per_target+
                                                       rf_ann_per_obs_1+ rf_ann_per_obs_2+ rf_ann_per_obs_3+ rf_ann_per_obs_4+ rf_ann_per_obs_5+ rf_ann_per_obs_6+ rf_ann_per_obs_7+ rf_ann_per_obs_8+ rf_ann_per_obs_9+ rf_ann_per_obs_10+
                                                       dist_1+dist_2+dist_3+dist_4+dist_5+dist_6+dist_7+dist_8+dist_9+dist_10, data=zero_train,
                                                       ntree=ntree,mtry=rf_para[rf_para$co==domain,"mtry_Z_best"])
        }
      stopCluster(cl) # unhook cluster
      
      }#end zero dat domain cond statement
      
      

  #Set up parallel processing 
  
  cl <- makeCluster(12)
  registerDoParallel(cl)
  roundCheckedDays<-foreach(d = 1:length(date_samp), .combine = rbind, .packages=c("mgcv","randomForest","Metrics","caret","e1071","Metrics","data.table","geosphere"), .inorder=T) %dopar% {
    #d=1
    #make N bad stations
      perBad<-runif(1,0.01,0.25)#random % percent bad stations
      day<-date_samp[d]
      sub_dat<-all_dat[all_dat$date %in% day,]
      badSamp<-sample(nrow(sub_dat),ifelse(round(nrow(sub_dat)*perBad)<1,1,round(nrow(sub_dat)*perBad)))
      good_dat<-sub_dat[!badSamp,]
      bad_dat<-sub_dat[badSamp,]
  
      #make data bad
      if(sum(bad_dat$rf_target>threshZ)>0 & sum(bad_dat$rf_target==0)>0){
        bad_Z_thresh_dat<-bad_dat[bad_dat$rf_target>threshZ,]
        if(nrow(bad_Z_thresh_dat)<sum(bad_dat$rf_target==0)){
        bad_Z_data<-bad_Z_thresh_dat
        }else{
        bad_Z_data<-bad_Z_thresh_dat[sample(nrow(bad_Z_thresh_dat),sum(bad_dat$rf_target==0))]
        }
        #make 0 rf values to make fake/bad data
        bad_Z_data$rf_target<- as.numeric(rep(0,nrow(bad_Z_data))) #propigate 0 mm rf to replace observed rf mm
        bad_Z_data$rf_3mo_per_target<-bad_Z_data$target_pop_3mo #make 3mo pop percentile values replace observed values
        bad_Z_data$rf_6mo_per_target<-bad_Z_data$target_pop_6mo #make 6mo pop percentile values replace observed values
        bad_Z_data$rf_ann_per_target<-bad_Z_data$target_pop_ann #make Ann pop percentile values replace observed values
        bad_NZ_data<-bad_dat[bad_dat$SKN_target %notin% bad_Z_data$SKN_target,]
        #make random values to make fake/bad data
        bad_NZ_data$rf_target<-mapply(rfmmMker,rfR=bad_NZ_data$rf_target,meanlog=bad_NZ_data$target_meanlog_ann,sdlog=bad_NZ_data$target_sdlog_ann, pop=bad_NZ_data$target_pop_ann, threshMM=threshNZ, maxPer=0.9999)# random generate rf values	
        bad_NZ_data$rf_ann_per_target<-mapply(rf_Prob,rf=bad_NZ_data$rf_target,meanlog=bad_NZ_data$target_meanlog_ann,sdlog=bad_NZ_data$target_sdlog_ann, pop=bad_NZ_data$target_pop_ann)# convert random rf values	to ann per
        bad_NZ_data$rf_6mo_per_target<-mapply(rf_Prob,rf=bad_NZ_data$rf_target,meanlog=bad_NZ_data$target_meanlog_6mo,sdlog=bad_NZ_data$target_sdlog_6mo, pop=bad_NZ_data$target_pop_6mo)# convert random rf values	to 6mo per	
        bad_NZ_data$rf_3mo_per_target<-mapply(rf_Prob,rf=bad_NZ_data$rf_target,meanlog=bad_NZ_data$target_meanlog_3mo,sdlog=bad_NZ_data$target_sdlog_3mo, pop=bad_NZ_data$target_pop_3mo)# convert random rf values	to 3mo per	
        bad_dat_final<-rbind(bad_Z_data,bad_NZ_data)
        }else{
        bad_dat$rf_target<-mapply(rfmmMker,rfR=bad_dat$rf_target,meanlog=bad_dat$target_meanlog_ann,sdlog=bad_dat$target_sdlog_ann, pop=bad_dat$target_pop_ann, threshMM=threshNZ, maxPer=0.9999)# random generate rf values	
        bad_dat$rf_ann_per_target<-mapply(rf_Prob,rf=bad_dat$rf_target,meanlog=bad_dat$target_meanlog_ann,sdlog=bad_dat$target_sdlog_ann, pop=bad_dat$target_pop_ann)# convert random rf values	to ann per
        bad_dat$rf_6mo_per_target<-mapply(rf_Prob,rf=bad_dat$rf_target,meanlog=bad_dat$target_meanlog_6mo,sdlog=bad_dat$target_sdlog_6mo, pop=bad_dat$target_pop_6mo)# convert random rf values	to 6mo per	
        bad_dat$rf_3mo_per_target<-mapply(rf_Prob,rf=bad_dat$rf_target,meanlog=bad_dat$target_meanlog_3mo,sdlog=bad_dat$target_sdlog_3mo, pop=bad_dat$target_pop_3mo)# convert random rf values	to 3mo per	  
        bad_dat_final<-bad_dat
        }
        
        bad_dat_final$status<-rep(1,nrow(bad_dat_final))
        good_dat$status<-rep(0,nrow(good_dat))
        day_data<-rbind(good_dat,bad_dat_final)
        subvars<-c("SKN_target","Station.Name","Observer","Network","Island","ELEV.m.","LAT","LON","date","date_skn_target","rf_target","rf_ann_per_target","rf_6mo_per_target","status")
        final_day_data<-day_data[,subvars,with=F]
  
        #make close 10 rf df to predict onto
        data_day_c10<-close10StaRF(final_day_data)

        #pred_bad(data_day_c10,ranfor_Zero_rf,ranfor_NZ_rf)
        roundremove<-data.frame()
        roundChecks<-roundCheck(data_day_c10,roundremove,round=0)

        #interative predictions
        roundChecked<-interateError(roundChecks,final_day_data,data_day_c10,ranfor_Zero_rf,ranfor_NZ_rf)
        roundChecked #print for para
     }#end day para-loop
    stopCluster(cl) # unhook cluster
    #str(roundCheckedDays)
    roundCheckedDays$run<-rep(run,nrow(roundCheckedDays)) #add run
    #append data to co
    roundChecksCounty<-rbind(roundChecksCounty,roundCheckedDays)
  }#end run loop
  e1<-Sys.time()
  roundChecksCounty$runDateID<-paste(roundChecksCounty$county,roundChecksCounty$run,roundChecksCounty$date,sep="_")
  setwd("/workflows/qaqc/data_attribute_run/final_results/iteration_analysis/")
  write.csv(roundChecksCounty,paste0(domain,"_bad_sta_intial_round.csv"),row.names = F)
  write(difftime(e1,s,units = "hours"),paste0(domain,"_intial_run_TT.txt"))
  roundChecksAll<-rbind(roundChecksAll,roundChecksCounty)#add county data to all data
  } #end county loop
e2<-Sys.time()

setwd("/workflows/qaqc/data_attribute_run/final_results/iteration_analysis/")
write(difftime(e2,s,units = "hours"),"intial_run_TT.txt")
write.csv(roundChecksAll,"all_bad_sta_intial_round.csv",row.names = F)




























