#Title: Price Paid Import
#Description: Imports and filters data from the UK 'Price Paid' dataset.
#             Merges the data with a table that adds the UPRN.

#Loading Libraries ----------
library(tidyverse)
library(here)
library(data.table)
library(arrow)

#Import price paid  ----------
ppd_names <- c("transactionid", "price", "transfer_date", "postcode", "property_type", "new", "duration", "paon", 
               "saon", "street", "locality", "town", "district", "county", "ppd_cat", "record_status")

ppd_classes <- c("character", "integer", "Date", "factor", 
                "factor", "character", "factor", "character", 
                 "character", "character",  "character", "character", 
                 "character", "character",  "factor", "factor")

PRICE_PAID_DF <- fread(
  here("data", "external", "uk_price_paid", "pp-complete.csv"), 
  col.names = ppd_names, 
  colClasses = ppd_classes,
  integer64 = "character")

PRICE_PAID_DF[, "new" := fifelse(new=="Y", T, F)]

PRICE_PAID_DF <- PRICE_PAID_DF[
  transfer_date > "2018-12-31" & transfer_date < "2020-01-01"
]

#Import UPRN mapping table  ----------
PPID_UPRN_DF <- fread(here("data", "external", "uk_price_paid", "ppdid_uprn_usrn.csv"), 
                      colClasses = rep("character", 4))

#Merge datasets ----------
PRICE_PAID_DF <- PPID_UPRN_DF[PRICE_PAID_DF, on = .(transactionid)]

#Export to Arrow  ----------
write_feather(
  PRICE_PAID_DF, 
  here("data", "imported", "uk_pricepaid2019.feather"), 
  compression = "zstd"
)