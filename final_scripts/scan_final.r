rm(list = ls())#start fresh!
Sys.setenv(TZ='Pacific/Honolulu') #set TZ to honolulu

#install.packages(c("RNRCS","metScanR","lubridate"))
require(RNRCS)
require(metScanR)
library(lubridate)
require(xts)

#define function
rbind.all.columns <- function(x, y) {     #function to smart rbind
    if(length(x)==0){return(y)
		}else{
		 if(length(y)==0){return(x)}else{
    		 x.diff <- setdiff(colnames(x), colnames(y))
   		 y.diff <- setdiff(colnames(y), colnames(x))
    		 x[, c(as.character(y.diff))] <- NA 
   		 y[, c(as.character(x.diff))] <- NA 
   		 return(rbind(x, y))}}}

#get list of NRCS SCAN stations
HI_NRCS<-names(getNetwork(network=c("NRCS"),getTerritory(territory=c("HI")))) #names of stations
ID<-substr(HI_NRCS, 6,999)#SCAN station numbers

#Get & agg hrly data for day
rundate<-Sys.Date()-1 #yesterday
all_scan_raw_data<-data.frame() #blank DF for all raw SCAN data
all_scan_daily_precip<-data.frame() #blank DF for final daily data
for(i in ID){
		sta_data_hrly<-grabNRCS.data(network="SCAN", site_id = i, timescale = "hourly", DayBgn = rundate, DayEnd = rundate)
		if(length(sta_data_hrly)==0){
			sta_data_daily<-data.frame(scan_id=i,Date=rundate,prec.mm=as.numeric(NA))
			}else{
			if(max(names(sta_data_hrly)=="Precipitation.Increment..in.")==as.logical(0)){		
				all_scan_raw_data<-rbind.all.columns(all_scan_raw_data,sta_data_hrly)#save all station hrly data
				sta_data_daily<-data.frame(scan_id=i,Date=rundate,prec.mm=as.numeric(NA))#save NA row for station
				}else{
				all_scan_raw_data<-rbind.all.columns(all_scan_raw_data,sta_data_hrly)#save all station hrly data
				sta_data_hrly$prec.mm<-(sta_data_hrly$Precipitation.Increment..in.*25.4)
				sta_data_hrly$obs_time<-strptime(sta_data_hrly$Date, format="%Y-%m-%d %H:%M", tz='Pacific/Honolulu')#cast date time as date time ASSUMING midnight obs is from 00:00-00:59?
				scan_precip_data_hrly<-sta_data_hrly[!is.na(sta_data_hrly$prec.mm),c("obs_time","prec.mm")] #subset rainfall and no NA rows
				scan_precip_data_hrly_xts<-xts(scan_precip_data_hrly$prec.mm,order.by=scan_precip_data_hrly$obs_time,unique = TRUE) #make xtended timeseries object
				precip_data_daily<-as.numeric(apply.daily(scan_precip_data_hrly_xts,FUN=sum))#daily sum of all all lag observations
				obs_daily_xts<-as.numeric(apply.daily(scan_precip_data_hrly_xts,FUN=length))#vec of count of hourly obs per day
				sta_data_daily<-data.frame(scan_id=i,Date=rundate,prec.mm=if(obs_daily_xts==24){precip_data_daily}else{as.numeric(NA)})
				}}
		all_scan_daily_precip<-rbind.all.columns(all_scan_daily_precip,sta_data_daily)
		}
print("data collected and processed!")

#write or append all raw hourly data
setwd("/work/data/raw/scan/raw_parsed")#server path raw files
files<-list.files()
all_month_filename<-paste0("scan_raw_all_data_",format((Sys.Date()-1),"%Y_%m"),".csv")#dynamic filename that includes month year so when month is done new file is writen
if(max(as.numeric(files==all_month_filename))>0){
	write.table(all_scan_raw_data,all_month_filename, row.names=F,sep = ",", col.names = F, append = T)
      }else{write.csv(all_scan_raw_data,all_month_filename, row.names=F)}


#write or append daily rf data
setwd("/work/data/raw/scan/daily_agg")#server path
files<-list.files()
rf_month_filename<-paste0("scan_daily_rf_",format((Sys.Date()-1),"%Y_%m"),".csv")#dynamic filename that includes month year so when month is done new file is writen
if(max(as.numeric(files==rf_month_filename))>0){
	write.table(all_scan_daily_precip,rf_month_filename, row.names=F,sep = ",", col.names = F, append = T)
      }else{write.csv(all_scan_daily_precip,rf_month_filename, row.names=F)}

print("Daily SCAN data made and saved!!!!!")

#CODE PAU!