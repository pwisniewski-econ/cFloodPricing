#Title: Regressions
#Description: Perform multiple fixed effects regressions
#             within a spatial discontinuity framework

# Loading Libraries ----------
library(lfe)
library(tidyverse)
library(here)
library(data.table)
library(arrow)
library(stargazer)

#Load Datasets ----------
UKDATA_DF <- read_feather(here("results_building", "uk_regression_ready.feather")) |> setDT()
FRDATA_DF <- read_feather(here("results_building", "fr_regression_ready.feather")) |> setDT()

#Main regression ----------
reg_fun <- function(data, high=F){
  if(high==T){
    data$floodable <- data$floodable_highOnly
  }else if(high=="FR3"){
    data$floodable <- data$floodable_riverOnly
  }
  mod <- felm(log(price) ~ floor_area + n_rooms + property_type + floodable | town, data=data)
  return(mod)
}

uk1 <- reg_fun(UKDATA_DF)
uk2 <- reg_fun(UKDATA_DF, T)
fr1 <- reg_fun(FRDATA_DF)
fr2 <- reg_fun(FRDATA_DF, T)
fr3 <- reg_fun(FRDATA_DF, "FR3")

#Export with stargazer ----------
exp_reg <- function(mod_ls, filename, notes){
  sink(here("results_analysis", filename))
  stargazer(
    mod_ls, 
    type = "latex", model.numbers=FALSE, digits = 4,
    title = paste0(notes, "\\vspace*{-0.2cm}"),
    column.labels = c("France", "United Kingdom"), font.size = "small",
    covariate.labels = c("Floor Area (m2)", "Number of Rooms", "House", "Floodable"),
    single.row = TRUE, no.space = TRUE, dep.var.caption = "log(price)", 
    dep.var.labels.include = FALSE
  )
  sink()
}

exp_reg(list(fr1, uk1), "regression1.tex", notes = c("High/Moderate Flooding Risk"))
exp_reg(list(fr2, uk2), "regression2.tex", notes = c("High Flooding Risk Only"))
exp_reg(list(fr3), "regression3.tex", notes = c("High/Moderate Flooding Risk (Rivers Only)"))
