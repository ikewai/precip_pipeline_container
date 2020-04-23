
rm(list = ls())
library(raster)
library(rgdal)
library(sp)
library(automap)

#define month yr of data
data_date<-Sys.Date()-1#yesterday's date
month1<-format(data_date,"%m")	#yesterday's month
data_mon_yr<-format(data_date,"%Y_%m") #month year 

#### GET Mean annual RF from RF Atlas at each individual station 

#Read in File containg Monthly RF observations
setwd("/home/mplucas/data/clean/daily_run_results/tables/rainfall") #set wd of test daily dataset server
monthly_rf_file<-paste0("daily_rf_",data_mon_yr,".csv")
RF_MoYr <- read.csv(file = monthly_rf_file, header = TRUE)
head(RF_MoYr)

#Read in Mean RF Grids from a folder and convert to raster 
#setwd("C:/Users/mpluc/OneDrive/Documents/rf_grid_mapping/rf_tiffs")#set mean rf raster: local pc
setwd("/home/mplucas/data/metadata/tiffs/daily_test")#set mean rf raster: server

#list.files()
Mean_RF_stack <- brick("statemean_daily_rf_mm.tif")
Mean_RF<-Mean_RF_stack[[as.numeric(month1)]]

#crackerjack qa/qc: remove stations na stations
rf_day_col<-paste0("X",format(data_date,"%Y.%m.%d"))#define rf day col
print(rf_day_col) #check rf col
RF_MoYr<-RF_MoYr[!is.na(RF_MoYr[rf_day_col]),] #remove stations with NA day vals


#make spatial dataframe with Lat and Lon
RF_MoYr$x<-RF_MoYr$LON
RF_MoYr$y<-RF_MoYr$LAT
coordinates(RF_MoYr) <- ~x+y
crs(RF_MoYr)<-crs(Mean_RF) #add crs from raster
print(RF_MoYr)
print("Stations Spatial DF Made!")

#extract Values from raster
#Creates a df where each column is a daily map with the values extracted for each coordinate
RF_MoYr$RF_Mean_Extract <- extract(Mean_RF, RF_MoYr)
head(RF_MoYr) #some na vals? still bad lat lon? 
"Mean Monthly daily RF extracted!"


### Calculate anomailies
#set all 0 RF values to 0.000000001 to avoide dividing into zero during the anomaly calcualtion
RF_MoYr<-RF_MoYr[!is.na(RF_MoYr$RF_Mean_Extract),]
if(max(RF_MoYr$RF_Mean_Extract)==0){RF_MoYr[RF_MoYr$RF_Mean_Extract==0,"RF_Mean_Extract"] <- 0.000000001} #if zeros exsist be sure to not divide by them
 RF_MoYr$RF_MoYr_Anom <- as.data.frame(RF_MoYr)[,rf_day_col] / RF_MoYr$RF_Mean_Extract #calc anom" rf obs/mean monthly
 
 head(RF_MoYr)
print("Anoms Calculated!")


###Set up for interpolation
#add in island rasters masks
#setwd("C:/Users/mpluc/OneDrive/Documents/rf_grid_mapping/rf_tiffs/island_masks")#set mean rf raster: local pc
setwd("/home/mplucas/data/metadata/tiffs/island_masks")#set mean rf raster: server

list.files()
bi_mask<-raster("bi_mask.tif")
mn_mask<-raster("mn_mask.tif")
oa_mask<-raster("oa_mask.tif")
ka_mask<-raster("ka_mask.tif")

#subset each island using mask rasters
BI_masked<-extract(bi_mask,RF_MoYr)
MN_masked<-extract(mn_mask,RF_MoYr)
OA_masked<-extract(oa_mask,RF_MoYr)
KA_masked<-extract(ka_mask,RF_MoYr)

bi_anom<-RF_MoYr[!is.na(BI_masked),"RF_MoYr_Anom"]
mn_anom<-RF_MoYr[!is.na(MN_masked),"RF_MoYr_Anom"]
oa_anom<-RF_MoYr[!is.na(OA_masked),"RF_MoYr_Anom"]
ka_anom<-RF_MoYr[!is.na(KA_masked),"RF_MoYr_Anom"]

##prep data for kriging: remove crs and make blank spatial points from island masks pixels
#BI
crs(bi_anom)<-NULL #remove crs
crs(bi_mask)<-NULL #remove crs
bi_temp<-SpatialPoints(as.data.frame(bi_mask,xy=T,na.rm=T)[,c(1,2)]) #make spatial points data frame with x y coords from mask and remove NA pixels
#MN
crs(mn_anom)<-NULL #remove crs
crs(mn_mask)<-NULL #remove crs
mn_temp<-SpatialPoints(as.data.frame(mn_mask,xy=T,na.rm=T)[,c(1,2)]) #make spatial points data frame with x y coords from mask and remove NA pixels
#OA
crs(oa_anom)<-NULL #remove crs
crs(oa_mask)<-NULL #remove crs
oa_temp<-SpatialPoints(as.data.frame(oa_mask,xy=T,na.rm=T)[,c(1,2)]) #make spatial points data frame with x y coords from mask and remove NA pixels
#KA
crs(ka_anom)<-NULL #remove crs
crs(ka_mask)<-NULL #remove crs
ka_temp<-SpatialPoints(as.data.frame(ka_mask,xy=T,na.rm=T)[,c(1,2)]) #make spatial points data frame with x y coords from mask and remove NA pixels

##krig per island
#big island: bi
bi_krige <- autoKrige(as.formula(paste0(names(bi_anom), "~1")),bi_anom, new_data = bi_temp)
bi_krig_out<-(bi_krige$krige_output[1]) #anom krig result
#bi_krig_out_SE <- bi_krige$krige_output[2] #anom standard error result
bi_krig_out$var1.pred[bi_krig_out$var1.pred<0]<-0 #make negitive krig RF zero
bi_krig_anom_ras<-rasterize(bi_krig_out, bi_mask, bi_krig_out$var1.pred) #make krig points into raster
#bi_krig_anom_se_ras<-rasterize(bi_krig_out_SE, bi_mask, bi_krig_out_SE$var1.var) #make krig points into raster
#add crs
crs(bi_krig_anom_ras)<-crs(Mean_RF)
#crs(bi_krig_anom_se_ras)<-crs(Mean_RF)
#convert anom to rf mm
bi_krig_ras<-bi_krig_anom_ras*Mean_RF
#bi_krig_se_ras<-bi_krig_anom_se_ras*Mean_RF
#plot anom
#plot(bi_krig_anom_ras)
#plot(bi_krig_anom_se_ras)
#plot rf
#plot(bi_krig_ras)
#plot(bi_krig_se_ras)
print("BI Krigged!")

#maui nui: mn
mn_krige <- autoKrige(as.formula(paste0(names(mn_anom), "~1")),mn_anom, new_data = mn_temp)
mn_krig_out<-(mn_krige$krige_output[1]) #anom krig result
#mn_krig_out_SE <- mn_krige$krige_output[2] #anom standard error result
mn_krig_out$var1.pred[mn_krig_out$var1.pred<0]<-0 #make negitive krig RF zero
mn_krig_anom_ras<-rasterize(mn_krig_out, mn_mask, mn_krig_out$var1.pred) #make krig points into raster
#mn_krig_anom_se_ras<-rasterize(mn_krig_out_SE, mn_mask, mn_krig_out_SE$var1.var) #make krig points into raster
#add crs
crs(mn_krig_anom_ras)<-crs(Mean_RF)
#crs(mn_krig_anom_se_ras)<-crs(Mean_RF)
#convert anom to rf mm
mn_krig_ras<-mn_krig_anom_ras*Mean_RF
#mn_krig_se_ras<-mn_krig_anom_se_ras*Mean_RF
#plot anom
#plot(mn_krig_anom_ras)
#plot(mn_krig_anom_se_ras)
#plot rf
#plot(mn_krig_ras)
#plot(mn_krig_se_ras)
print("MN Krigged!")

#oahu: oa
oa_krige <- autoKrige(as.formula(paste0(names(oa_anom), "~1")),oa_anom, new_data = oa_temp)
oa_krig_out<-(oa_krige$krige_output[1]) #anom krig result
#oa_krig_out_SE <- oa_krige$krige_output[2] #anom standard error result
oa_krig_out$var1.pred[oa_krig_out$var1.pred<0]<-0 #make negitive krig RF zero
oa_krig_anom_ras<-rasterize(oa_krig_out, oa_mask, oa_krig_out$var1.pred) #make krig points into raster
#oa_krig_anom_se_ras<-rasterize(oa_krig_out_SE, oa_mask, oa_krig_out_SE$var1.var) #make krig points into raster
#add crs
crs(oa_krig_anom_ras)<-crs(Mean_RF)
#crs(oa_krig_anom_se_ras)<-crs(Mean_RF)
#convert anom to rf mm
oa_krig_ras<-oa_krig_anom_ras*Mean_RF
#oa_krig_se_ras<-oa_krig_anom_se_ras*Mean_RF
#plot anom
#plot(oa_krig_anom_ras)
#plot(oa_krig_anom_se_ras)
#plot rf
#plot(oa_krig_ras)
#plot(oa_krig_se_ras)
print("OA Krigged!")

#kauai: ka
ka_krige <- autoKrige(as.formula(paste0(names(ka_anom), "~1")),ka_anom, new_data = ka_temp)
ka_krig_out<-(ka_krige$krige_output[1]) #anom krig result
#ka_krig_out_SE <- ka_krige$krige_output[2] #anom standard error result
ka_krig_out$var1.pred[ka_krig_out$var1.pred<0]<-0 #make negitive krig RF zero
ka_krig_anom_ras<-rasterize(ka_krig_out, ka_mask, ka_krig_out$var1.pred) #make krig points into raster
#ka_krig_anom_se_ras<-rasterize(ka_krig_out_SE, ka_mask, ka_krig_out_SE$var1.var) #make krig points into raster
#add crs
crs(ka_krig_anom_ras)<-crs(Mean_RF)
#crs(ka_krig_anom_se_ras)<-crs(Mean_RF)
#convert anom to rf mm
ka_krig_ras<-ka_krig_anom_ras*Mean_RF
#ka_krig_se_ras<-ka_krig_anom_se_ras*Mean_RF
#plot anom
#plot(ka_krig_anom_ras)
#plot(ka_krig_anom_se_ras)
#plot rf
#plot(ka_krig_ras)
#plot(ka_krig_se_ras)
print("KA Krigged!")


##combind and write statewide rf
hi_statewide_krig_ras<-mosaic(bi_krig_ras, mn_krig_ras, fun=max)
hi_statewide_krig_ras<-mosaic(hi_statewide_krig_ras, oa_krig_ras, fun=max)
hi_statewide_krig_ras<-mosaic(hi_statewide_krig_ras, ka_krig_ras, fun=max)
#plot(hi_statewide_krig_ras)

#write day map
setwd("/home/mplucas/data/clean/daily_run_results/rasters/rainfall")
writeRaster(hi_statewide_krig_ras,paste0("rf_mm_",format(data_date,"%Y_%m_%d"),".tif"),overwrite=TRUE)


#update current month rf raster
setwd("/var/www/html") #output tiffs dir:server
R<-round(hi_statewide_krig_ras*10)
#dataType(R)<-"INT2U"
writeRaster(R,"daily_statewide_rf_TEST.tif",overwrite=TRUE)
print("Statewide daily RF tiff Updated!!!")

print("PAU!")
