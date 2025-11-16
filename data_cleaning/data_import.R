library(data.table)
library(ggplot2)
library(tidyverse)
library(dplyr)
library(glmnet)

#Import Data
amaani_data <- fread("fresh_data/Amaani_2.csv")
ellie_data <- fread("fresh_data/ellie_2.csv")
rayyaan_data <- fread("fresh_data/rayyaan_2.csv", header = TRUE)

indicator_map <- data.table(
	indicator = c(
		"",
		"Life expectancy at birth, total (years)",
		"Literacy rate, adult total (% of people ages 15 and above)",
		"Prevalence of overweight (% of adults)",
		"UIS: Mean years of schooling (ISCED 1 or higher), population 25+ years, male"
	),
	indicator_slim = c(
		"missing_indicator",
		"life_expectancy_total_years",
		"literacy_rate_adult_total_pct",
		"overweight_prevalence_adults_pct",
		"uis_mean_schooling_male_25plus"
	)
)

rayyaan_data[indicator_map, indicator_slim := i.indicator_slim, on = "indicator"]
rayyaan_data$indicator <- NULL
