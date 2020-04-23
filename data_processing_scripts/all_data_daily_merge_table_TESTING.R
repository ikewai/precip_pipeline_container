rm(list = ls())#remove all objects in R

options(warn=-1)#supress warnings for session
print(paste("all data daily merge run:",Sys.time()))#for cron log

#functions
rbind.all.columns <- function(x, y) {     #function to smart rbind
    x.diff <- setdiff(colnames(x), colnames(y))
    y.diff <- setdiff(colnames(y), colnames(x))
    x[, c(as.character(y.diff))] <- NA 
    y[, c(as.character(x.diff))] <- NA 
    return(rbind(x, y))}

#add master metadata with SKN and lat long
setwd("/home/mplucas/data/metadata") #server meta data path
geog_meta<-read.csv("Master_Sta_List_Meta_sub_14_01_2020.csv", colClasses=c("NESDIS.id"="character"))
geog_mini_meta<-geog_meta[,c("SKN","Station.Name","OBSERVER","Network","Island","ELEV.m.","LAT","LON")] #make mini meta data of disired station name fields

#names(geog_meta)
#str(geog_meta)
geog_meta_sub<-geog_meta[,c("SKN","NESDIS.id","SCAN.id","NWS.id","SMART_NODE_RF.id","LAT","LON")]
geog_meta_sub$no_sourceID<-geog_meta_sub$SKN
#head(geog_meta_sub)
print("master meta added!")
dates<-c("2020-04-01","2020-04-02","2020-04-03","2020-04-04")

for(i in dates){
#define date ranges
map_date<-as.Date(as.Date(i))# test date line
#map_date<-Sys.Date()-1# yesterday as date
file_date<-format(map_date,"%Y_%m")

#add HADS data
setwd("/home/mplucas/data/raw/hads/daily_agg")#set data source wd
hads_month_filename<-paste0("hads_daily_rf_5am_",file_date,".csv")#dynamic filename that includes month year so when month is done new file is writen
if(max(as.numeric(list.files()==hads_month_filename))>0){  #does HADS month file exsist? 
 hads<-read.csv(paste0(hads_month_filename),header=T,colClasses=c("staID"="character"))
 hads<-hads[,c("staID","date","rf")]
 names(hads)<-c("sourceID","date","x")#note 'source_id" IS "NESDIS.id" for hads
 hads$date<-as.Date(hads$date)
 hads_day<-hads[hads$date==map_date,] #date sub
 if(nrow(hads_day)>0){ #if hads_day has rows/data
  hads_day$date<-format(hads_day$date,"%Y.%m.%d")
  hads_day<-hads_day[,c("sourceID","date","x")]
  hads_day$x<-as.numeric(hads_day$x)
  #head(hads_day)
  hads_wide<- reshape(hads_day, idvar = "sourceID", timevar = "date", direction = "wide")
  hads_wide$datastream<-"hads"
  #tail(hads_wide)
  hads_wide_merged_all<-merge(hads_wide,geog_meta_sub[,c("NESDIS.id","SKN")],by.x="sourceID",by.y="NESDIS.id",all.x=T)
  missing_hads<-hads_wide_merged_all[is.na(hads_wide_merged_all$SKN),c("sourceID","datastream")] #missing stations
  hads_wide_merged<-hads_wide_merged_all[!is.na(hads_wide_merged_all$SKN),] #remove missing stations with no SKN
  names(hads_wide_merged)[2]<-gsub("x.","X",names(hads_wide_merged)[2])#make lower case x to uppercase X for continuitiy 
  #tail(hads_wide_merged)
  count_log_hads<-data.frame(datastream=as.character("hads"),station_count=as.numeric(nrow(hads_wide_merged)),unique=as.logical(0))
  print(paste(hads_month_filename,"found!",nrow(hads_wide_merged),"stations added!"))
  }else{ #else if nrow(hads_day) = 0
   hads_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("nws"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
   names(hads_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
   missing_hads<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
   count_log_hads<-data.frame(datastream=as.character("hads"),station_count=as.numeric(0),unique=as.logical(0))
   print(paste("NO HADS DATA:",map_date,"!"))
   }}else{ #else if hads month df is missing make a blank df
    hads_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("nws"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
    names(hads_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
	missing_hads<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
	count_log_hads<-data.frame(datastream=as.character("hads"),station_count=as.numeric(0),unique=as.logical(0))
    print(paste(hads_month_filename,"MISSING empty DF made!"))
    }

#add NWS data 
setwd("/home/mplucas/data/raw/nws/daily_agg")#set data source wd
nws_month_filename<-paste0("nws_24hr_daily_",file_date,".csv")#dynamic filename that includes month year so when month is done new file is writen
if(max(as.numeric(list.files()==nws_month_filename))>0){
 nws<-read.csv(nws_month_filename,header=T)
 nws<-nws[,c("nwsli","date","prec_mm_24hr")]
 names(nws)<-c("sourceID","date","x")
 nws$date<-as.Date(nws$date)#format as date
 nws_day<-nws[nws$date==map_date,]
 if(nrow(nws_day)>0){ #if nws_day has rows/data
  nws_day$date<-format(nws_day$date,"%Y.%m.%d")
  nws_day$x<-as.numeric(nws_day$x)
  nws_wide<- reshape(nws_day, idvar = "sourceID", timevar = "date", direction = "wide")
  nws_wide$datastream<-"nws"
  #head(nws_wide)
  #tail(nws_wide)
  nws_wide_merged_all<-merge(nws_wide,geog_meta_sub[,c("NWS.id","SKN")],by.x="sourceID",by.y="NWS.id",all.x=T)
  missing_nws<-nws_wide_merged_all[is.na(nws_wide_merged_all$SKN),c("sourceID","datastream")] #missing stations
  nws_wide_merged<-nws_wide_merged_all[!is.na(nws_wide_merged_all$SKN),] #remove missing stations with no SKN
  names(nws_wide_merged)[2]<-gsub("x.","X",names(nws_wide_merged)[2])#make lower case x to uppercase X for continuitiy 
  #tail(nws_wide_merged)
  count_log_nws<-data.frame(datastream=as.character("nws"),station_count=as.numeric(nrow(nws_wide_merged)),unique=as.logical(0))
  print(paste(nws_month_filename,"found!",nrow(nws_wide_merged),"stations added!"))
  }else{ #else if nrow(nws_day) = 0
   nws_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("nws"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
   names(nws_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
   missing_nws<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
   count_log_nws<-data.frame(datastream=as.character("nws"),station_count=as.numeric(0),unique=as.logical(0))
   print(paste("NO NWS DATA:",map_date,"!"))
   }}else{ #else if nws month df is missing make a blank df
    nws_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("nws"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
    names(nws_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
	missing_nws<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
	count_log_nws<-data.frame(datastream=as.character("nws"),station_count=as.numeric(0),unique=as.logical(0))
    print(paste(nws_month_filename,"MISSING empty DF made!"))
    }

#add SCAN data
setwd("/home/mplucas/data/raw/scan/daily_agg")#set data source wd
scan_month_filename<-paste0("scan_daily_rf_",file_date,".csv")
if(max(as.numeric(list.files()==scan_month_filename))>0){
 scan<-read.csv(scan_month_filename,header=T)
 names(scan)<-c("sourceID","date","x")
 scan$date<-as.Date(scan$date)
 scan_day<- scan[scan$date==map_date,]
 if(nrow(scan_day)>0){ #if scan_day has rows/data
  scan_day$date<-format(scan_day$date,"%Y.%m.%d")
  scan_day$x<-as.numeric(scan_day$x)
  #head(scan_day)
  scan_wide<- reshape(scan_day, idvar = "sourceID", timevar = "date", direction = "wide")
  scan_wide$datastream<-"scan"
  #head(scan_wide)
  scan_wide_merged<-merge(scan_wide,geog_meta_sub[,c("SKN","SCAN.id")],by.x="sourceID",by.y="SCAN.id",all.x=T)
  missing_scan<- scan_wide_merged[is.na( scan_wide_merged$SKN),c("sourceID","datastream")] #missing stations
  scan_wide_merged<- scan_wide_merged[!is.na( scan_wide_merged$SKN),] #remove missing stations with no SKN
  names(scan_wide_merged)[2]<-gsub("x.","X",names(scan_wide_merged)[2])#make lower case x to uppercase X for continuitiy 
  #tail(scan_wide_merged)
  count_log_scan<-data.frame(datastream=as.character("scan"),station_count=as.numeric(nrow(scan_wide_merged)),unique=as.logical(0))
  print(paste(scan_month_filename,"found!",nrow(scan_wide_merged),"stations added!"))
  }else{ #else if nrow(scan_day) = 0
   scan_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("scan"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
   names(scan_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
   missing_scan<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
   count_log_scan<-data.frame(datastream=as.character("scan"),station_count=as.numeric(0),unique=as.logical(0))
   print(paste("NO SCAN DATA:",map_date,"!"))
   }}else{ #else if scan month df is missing make a blank df
    scan_wide_merged<-data.frame(sourceID=as.character(NA),date_day=as.numeric(NA),datastream=as.character("scan"),SKN=as.numeric(NA),LAT=as.numeric(NA),LON=as.numeric(NA))
    names(scan_wide_merged)[2]<-format(Sys.Date()-1,"X%Y.%m.%d")
	missing_scan<-data.frame(sourceID=as.character(NA),datastream=as.character(NA)) #missing stations blank df
    count_log_scan<-data.frame(datastream=as.character("scan"),station_count=as.numeric(0),unique=as.logical(0))
	print(paste(scan_month_filename,"MISSING empty DF made!"))
    }

#make and write table of all missing stations from aquired data
all_missing<-rbind(missing_hads,missing_nws,missing_scan)
all_missing<-all_missing[!is.na(all_missing$sourceID),]#remove na obs
setwd("/home/mplucas/data/clean/daily_run_results/tables/missing")#set output wd
missing_files<-list.files()
missing_month_filename<-paste0("missing_daily_rf_",file_date,".csv") #dynamic filename that includes month year so when month is done new file is writen

#conditional statment that adds obs of missing stations and removes dublicate for the month
if(max(as.numeric(missing_files==missing_month_filename))>0){
	rf_missing_df<-read.csv(missing_month_filename)
	rf_missing_df<-rbind(rf_missing_df,all_missing)
	rf_missing_df_nodups<-rf_missing_df[!duplicated(rf_missing_df$sourceID),]
	write.csv(rf_missing_df_nodups,missing_month_filename, row.names=F)
	}else{
	write.csv(all_missing,missing_month_filename, row.names=F)
	}

#rbind all datastreams and merge with geog meta
print("combinding all data...")
hads_nws_wide<-rbind.all.columns(hads_wide_merged,nws_wide_merged)
hads_nws_scan_wide<-rbind.all.columns(hads_nws_wide,scan_wide_merged)
print("all data combind!")

#remove stations with NA values
rf_col<-paste0("X",format(map_date,"%Y.%m.%d"))#define rf day col name
hads_nws_scan_wide<-hads_nws_scan_wide[!is.na(hads_nws_scan_wide[,rf_col]),]

#check if no data for the day exist: if cond make dummy df to append to month year table 

#reorder to define datastream priority
data_priority <- c("hads","nws","scan")
hads_nws_scan_wide<-hads_nws_scan_wide[order(match(hads_nws_scan_wide$datastream, data_priority)),]
dim(hads_nws_scan_wide)
str(hads_nws_scan_wide)
head(hads_nws_scan_wide)
tail(hads_nws_scan_wide)
print("combind data sorted!")

#remove dup stations based on SKN but keeping data in order defined above
hads_nws_scan_wide_no_dup<-hads_nws_scan_wide[!duplicated(hads_nws_scan_wide$SKN), ]
str(hads_nws_scan_wide_no_dup)
print(paste("station count with dups:",nrow(hads_nws_scan_wide)))#~258+
print(paste("station count without dups:",nrow(hads_nws_scan_wide_no_dup)))#~159+

#sub cols rainfall
hads_nws_scan_wide_no_dup_rf<-hads_nws_scan_wide_no_dup[,c("SKN",rf_col)]#remove rf meta cols except SKN & RF DAY col
head(hads_nws_scan_wide_no_dup_rf)

#make rainfall source table and sub cols
hads_nws_scan_wide_no_dup_source<-hads_nws_scan_wide_no_dup[,c("SKN","datastream")]#remove meta cols except SKN & datastream cols
names(hads_nws_scan_wide_no_dup_source)<-names(hads_nws_scan_wide_no_dup_rf)#rename cols so source is date
head(hads_nws_scan_wide_no_dup_source)

#make and write table of source log station counts from aquired data
count_log_per<-rbind(count_log_hads,count_log_nws,count_log_scan)
count_log_unq<-data.frame(table(hads_nws_scan_wide_no_dup$datastream))
names(count_log_unq)<-c("datastream","station_count")
count_log_unq$unique<-as.logical(1)
count_log_all<-rbind(count_log_per,
				data.frame(datastream="SUBTOTAL",station_count=sum(count_log_per$station_count),unique=as.logical(0)),
				count_log_unq,
				data.frame(datastream="TOTAL",station_count=sum(count_log_unq$station_count),unique=as.logical(1)))
count_log_all$date<-map_date #add data date 

setwd("/home/mplucas/data/clean/daily_run_results/tables/count")
count_log_month_filename<-paste0("count_log_daily_rf_",file_date,".csv")#dynamic filename that includes month year so when month is done new file is writen
count_files<-list.files()
	
#conditional statment that adds obs of per day station counts
if(max(as.numeric(count_files==count_log_month_filename))>0){
	write.table(count_log_all,count_log_month_filename, row.names=F,sep = ",",col.names = F, append = T)
	print(paste(count_log_month_filename,"appended!"))
	}else{
	write.csv(count_log_all,count_log_month_filename, row.names=F)
	print(paste(count_log_month_filename,"written!"))
	}

#write data by creating or appending day to month for rf and source tables
#write or append daily rf data
setwd("/home/mplucas/data/clean/daily_run_results/tables/rainfall")#set rainfall output wd

rf_files<-list.files()
rf_month_filename<-paste0("daily_rf_",file_date,".csv")#dynamic filename that includes month year so when month is done new file is writen
#conditional statment that adds new obs
if(max(as.numeric(rf_files==rf_month_filename))>0){
	rf_month_df<-read.csv(rf_month_filename)
	sub_cols<-c("SKN",names(rf_month_df)[grep("X*",names(rf_month_df))])
	add_rf_data_sub<-merge(rf_month_df[,sub_cols],hads_nws_scan_wide_no_dup_rf,by="SKN",all=T)
	final_rf_data<-merge(geog_mini_meta,add_rf_data_sub,by="SKN")
	write.csv(final_rf_data,rf_month_filename, row.names=F)
	print("monthly table appended!")
    }else{ #if month year file does not exist make a new month year file
	final_rf_data<-merge(geog_mini_meta,hads_nws_scan_wide_no_dup_rf,by="SKN")
	write.csv(final_rf_data,rf_month_filename, row.names=F)
	print("monthly table written!")
	}
head(final_rf_data)
tail(final_rf_data)
print("^final data table^")

#write or append daily source data
setwd("/home/mplucas/data/clean/daily_run_results/tables/source")#set rainfall output wd
source_files<-list.files()
source_month_filename<-paste0("daily_rf_source_",file_date,".csv")#dynamic filename that includes month year so when month is done new file is writen

#conditional statment that adds new obs
if(max(as.numeric(source_files==source_month_filename))>0){
	source_month_df<-read.csv(source_month_filename)
	#sub_cols<-c("SKN",names(source_month_df)[grep("X*",names(source_month_df))])
	final_source_data<-merge(source_month_df,hads_nws_scan_wide_no_dup_source,by="SKN",all=T)
	#final_source_data<-merge(geog_mini_meta,source_month_df_add,by="SKN")
	write.csv(final_source_data,source_month_filename, row.names=F)
	print("monthly table appended!")
    }else{ #if month year file does not exist make a new month year file
	final_source_data<-merge(geog_mini_meta,hads_nws_scan_wide_no_dup_source,by="SKN")
	write.csv(final_source_data,source_month_filename, row.names=F)
	print("monthly table written!")
	}
head(final_source_data)
tail(final_source_data)
print("^final source data table^")

paste("CODE PAU!",i)
}
print("loop end!")
