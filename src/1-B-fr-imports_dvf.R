#Title: DVF Import
#Description: Imports and standardize data from the French 'Demandes de valeurs foncières' dataset

# Loading Libraries ----------
library(here)
library(stringr)
library(data.table)
library(arrow)

# Read and clean data structure ----------
DVF2019 <- fread(here("data", "external", "dvf_fr", "valeursfoncieres-2019.txt"), sep = "|", dec=",")
  
DVF2019 <- DVF2019[, 1:7 := NULL][, "year" := 2019]
  
names(DVF2019) <- names(DVF2019) |> tolower() |> str_replace_all(" ", "_")

# Export to Arrow IPC ----------
arrow::write_feather(DVF2019, here("data","imported","fr_dvf2019.feather"), compression = "zstd")
