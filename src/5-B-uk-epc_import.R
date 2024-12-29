#Title: Energy Performance Certificates import
#Description: Import only certificates from the UK EPC data.
#             Parallelization is used as there is more than 300 distinct files.
#             Keep only needed variables full dataset is arround 50GB.

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)
library(parallel)

#Get the paths to all certificates  ----------
files <- list.files(here("data", "external", "uk_epc"), recursive = TRUE, full.names = TRUE)
files <- files[str_detect(files, "certificates.csv")]

#Define import function ----------
import_epc <- function(file){
  
  DF <- data.table::fread(
    file, 
    integer64 = "character", 
    select = c("PROPERTY_TYPE", "LODGEMENT_DATE", "TOTAL_FLOOR_AREA", "NUMBER_HABITABLE_ROOMS", "UPRN"), 
    colClasses = c("PROPERTY_TYPE"="factor", "LODGEMENT_DATE"="Date", "TOTAL_FLOOR_AREA"="numeric",
                   "NUMBER_HABITABLE_ROOMS"="integer", UPRN="character")
  )
  
  names(DF) <- tolower(names(DF))
  
  return(DF)
}

#Import in parallel  ----------
cl <- makeCluster(14)

EPC_DF <- parLapply(cl, files, import_epc) 

stopCluster(cl)

#Rbind and export to Arrow  ----------
EPC_DF <- EPC_DF |> rbindlist()

write_feather(EPC_DF, here("data", "interim", "uk_epc_certificates.feather"), compression = "zstd")
