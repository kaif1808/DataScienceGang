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
#Rayyaan Indicator Name Change
rayyaan_data[indicator_map, indicator_slim := i.indicator_slim, on = "indicator"]
rayyaan_data$indicator <- NULL

rayyaan_year_cols <- setdiff(names(rayyaan_data), c("country", "code", "indicator_slim"))

rayyaan_long <- melt(
	rayyaan_data,
	id.vars = c("country", "code", "indicator_slim"),
	measure.vars = rayyaan_year_cols,
	variable.name = "year",
	value.name = "value",
	variable.factor = FALSE
)

setnames(rayyaan_long, "code", "country_code")
rayyaan_long[, year := as.integer(year)]

rayyaan_dedup <- rayyaan_long[
	,
	.(value = mean(value, na.rm = TRUE)),
	by = .(country, country_code, year, indicator_slim)
]

rayyaan_wide <- dcast(
	rayyaan_dedup,
	country + country_code + year ~ indicator_slim,
	value.var = "value"
)[order(country, country_code, year)]

#Amaani Series Name Change
series_names <- fread("series_names.csv")
amaani_data[series_names, Series_Name_clean := i.Series_Name_clean, on = "Series Name"]
amaani_data$`Series Name` <- NULL

setnames(
	amaani_data,
	old = c("Country Name", "Country Code", "Time", "Value"),
	new = c("country", "country_code", "year", "value")
)

amaani_dedup <- amaani_data[
	,
	.(value = mean(value, na.rm = TRUE)),
	by = .(country, country_code, year, Series_Name_clean)
]

amaani_wide <- dcast(
	amaani_dedup,
	country + country_code + year ~ Series_Name_clean,
	value.var = "value"
)[order(country, country_code, year)]

##
rm(list=setdiff(ls(), c("ellie_data", "rayyaan_wide", "amaani_wide")))

## merge
merged_data <- ellie_data[amaani_wide, on = .(country, year), nomatch = 0]
merged_data <- merged_data[rayyaan_wide, on = .(country, year), nomatch = 0]

merged_data$i.country_code <-NULL
merged_data$i.country_code.1 <- NULL

##processing, adding lags + averages, condensing to only olympics years

id_cols <- c("country", "country_code", "year")
value_cols <- setdiff(names(merged_data), id_cols)

max_year <- max(merged_data$year, na.rm = TRUE)
last_olympic <- max(1996L, max_year - (max_year %% 2L))
olympic_years <- seq(1996L, last_olympic, by = 2L)

collect_window <- function(target_year) {
	merged_data[
		year >= target_year - 4L & year <= target_year - 1L,
		if (uniqueN(year) == 4L) lapply(.SD, mean, na.rm = TRUE) else NULL,
		by = .(country, country_code),
		.SDcols = value_cols
	][
		,
		year := target_year
	]
}

olympic_windows <- rbindlist(
	lapply(olympic_years, collect_window),
	use.names = TRUE,
	fill = TRUE
)[order(country, year)]

olympic_value_cols <- setdiff(names(olympic_windows), id_cols)

setorderv(olympic_windows, c("country", "year"))

for (k in 1:4) {
	olympic_windows[
		,
		paste0(olympic_value_cols, "_lag", k) := lapply(.SD, shift, n = k, type = "lag"),
		by = country,
		.SDcols = olympic_value_cols
	]
}

