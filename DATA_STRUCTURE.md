# Enhanced Data Structure: 4-Year Averages with Lagged Variables

## Visual Overview

```
INPUT DATA (Annual observations)
═════════════════════════════════════════════════════════════
Year:     2009    2010    2011    2012    2013    2014    ...
GDP:      45000   46000   47000   48000   49000   50000   ...
Pop:      300M    305M    310M    315M    320M    325M    ...
                              ↓
                    TRANSFORMATION
                              ↓
OUTPUT DATA (Olympic year + lags)
═════════════════════════════════════════════════════════════

Target Year: 2012
─────────────────
GDP_per_capita:        46500   ← Average(2009-2012)
GDP_per_capita_lag0:   48000   ← 2012 value
GDP_per_capita_lag1:   47000   ← 2011 value
GDP_per_capita_lag2:   46000   ← 2010 value
GDP_per_capita_lag3:   45000   ← 2009 value

Population:            307.5M  ← Average(2009-2012)
Population_lag0:       315M    ← 2012 value
Population_lag1:       310M    ← 2011 value
Population_lag2:       305M    ← 2010 value
Population_lag3:       300M    ← 2009 value

[... same pattern for ALL numeric variables ...]

gold:                  46      ← Olympic medals (2012 London)
silver:                29
bronze:                29
total:                 104
```

## Complete Column Structure

### Identifiers
- `Country Name` - Full country name
- `Country Code` - ISO 3-letter code
- `Year` - Target year (2012, 2014, 2016, 2018, 2020, 2022, 2024)

### For Each Numeric Variable X:
1. **X** - 4-year average
2. **X_lag0** - Current year value (t)
3. **X_lag1** - One year prior (t-1)
4. **X_lag2** - Two years prior (t-2)
5. **X_lag3** - Three years prior (t-3)

### Example Variables with Full Lag Structure:

#### Economic Indicators (from Ellie)
- `GDP_per_capita`, `GDP_per_capita_lag0`, `GDP_per_capita_lag1`, `GDP_per_capita_lag2`, `GDP_per_capita_lag3`
- `Inflation_Rate`, `Inflation_Rate_lag0`, `Inflation_Rate_lag1`, `Inflation_Rate_lag2`, `Inflation_Rate_lag3`
- `Population`, `Population_lag0`, `Population_lag1`, `Population_lag2`, `Population_lag3`
- `Unemployment_Rate`, `Unemployment_Rate_lag0`, `Unemployment_Rate_lag1`, `Unemployment_Rate_lag2`, `Unemployment_Rate_lag3`
- `Government_Spending`, `Government_Spending_lag0`, `Government_Spending_lag1`, `Government_Spending_lag2`, `Government_Spending_lag3`

#### Health Indicators (from Rayyaan)
- `Prevalence of overweight (% of adults)` + lag0, lag1, lag2, lag3

#### Social Indicators (from Amaani)
- `elec_access_percent` + lag0, lag1, lag2, lag3
- `internet_access_percent` + lag0, lag1, lag2, lag3
- `urban_percentage` + lag0, lag1, lag2, lag3
- `poverty_ratio` + lag0, lag1, lag2, lag3
- `mil_expenditure_percent` + lag0, lag1, lag2, lag3
- ... [22 series × 5 versions each]

#### Olympic Performance
- `gold`, `silver`, `bronze`, `total`
- `edition`, `edition_id`

## Data Dimensions

### Rows
- **8 target years** × **~200 countries** = ~1,600 observations
- (Actual number depends on data availability)

### Columns
- **3 identifiers** (Country Name, Country Code, Year)
- **~30-40 base variables** (from 3 data sources)
- **×5 versions each** (average + 4 lags) = ~150-200 columns
- **6 medal columns** (gold, silver, bronze, total, edition, edition_id)
- **Total: ~160-210 columns**

## Statistical Applications

### 1. Autoregressive Models
```r
# Model current GDP using past GDP
lm(GDP_per_capita_lag0 ~ GDP_per_capita_lag1 + GDP_per_capita_lag2, data)
```

### 2. Distributed Lag Models
```r
# Model medals using current and past economic conditions
lm(total ~ GDP_per_capita_lag0 + GDP_per_capita_lag1 + 
    GDP_per_capita_lag2 + GDP_per_capita_lag3, data)
```

### 3. Granger Causality Tests
```r
# Test if past X predicts current Y (beyond past Y)
model1 <- lm(medals_lag0 ~ medals_lag1 + medals_lag2, data)
model2 <- lm(medals_lag0 ~ medals_lag1 + medals_lag2 + 
             GDP_lag1 + GDP_lag2, data)
anova(model1, model2)  # Test if GDP adds predictive power
```

### 4. Growth Rate Analysis
```r
# Calculate growth rates from lags
data[, GDP_growth := (GDP_per_capita_lag0 - GDP_per_capita_lag1) / 
                      GDP_per_capita_lag1 * 100]
```

### 5. Lead-Lag Analysis
```r
# Does past investment predict current performance?
lm(total ~ gross_cap_form_gdp_lag1 + gross_cap_form_gdp_lag2, data)
```

## Advantages Over Simple Averages

| Feature | Simple Average | With Lags |
|---------|---------------|-----------|
| Temporal info | ❌ Lost | ✓ Preserved |
| Trend detection | ❌ No | ✓ Yes |
| Forecasting | ❌ Limited | ✓ Full |
| Autocorrelation | ❌ Can't test | ✓ Can test |
| Dynamic models | ❌ No | ✓ Yes |
| Smoothing | ✓ Yes | ✓ Yes |
| Noise reduction | ✓ Yes | ✓ Yes |

## Best Practices

1. **Check for missing lags**: Some countries may not have all 4 years of data
2. **Test for stationarity**: Lagged variables should be stationary for time-series models
3. **Consider growth rates**: Sometimes changes are more informative than levels
4. **Avoid multicollinearity**: Lags can be correlated; consider using selected lags
5. **Validate temporally**: Split by year for train/test, not randomly

## Column Naming Convention

```
[variable_name]        → 4-year average
[variable_name]_lag0   → t (current/target year)
[variable_name]_lag1   → t-1 (1 year before)
[variable_name]_lag2   → t-2 (2 years before)
[variable_name]_lag3   → t-3 (3 years before)
```

This structure maximizes analytical flexibility while maintaining clean, interpretable variable names.
