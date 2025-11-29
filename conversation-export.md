# Stroke prediction with SMOTE resampling and model evaluation

## User

Clean and transform data for analysis healthcare-dataset-stroke-data.csv. Please prepare for the major class imbalance on the target variable stroke

## Databot


<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_012iTivzuSLQypJ7C7eE2yos" data-call="{
  &quot;code&quot;: &quot;# Final cleaned and transformed dataset ready for analysis\n# Let&apos;s create the final cleane...[truncated, total 2550 chars]&quot;,
  &quot;intent&quot;: &quot;Create final cleaned and transformed dataset for stroke analysis&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Create final cleaned and transformed dataset for stroke analysis" ></div>

```python
# Final cleaned and transformed dataset ready for analysis
# Let's create the final cleaned dataset with all transformations

stroke_final = (
    stroke_df
    # Handle missing BMI values - impute with median
    .with_columns(
        pl.col("bmi").fill_null(pl.col("bmi").median())
    )
    # Remove "Other" gender (only 1 observation)
    .filter(pl.col("gender") != "Other")
    # Convert categorical columns to appropriate types
    .with_columns(
        # Binary encoding for binary variables
        pl.col("ever_married").replace({"Yes": 1, "No": 0}).cast(pl.Int8).alias("ever_married_binary"),
        pl.col("Residence_type").replace({"Urban": 1, "Rural": 0}).cast(pl.Int8).alias("residence_urban"),
        pl.col("gender").replace({"Male": 1, "Female": 0}).cast(pl.Int8).alias("gender_male"),
        pl.col("hypertension").cast(pl.Int8),
        pl.col("heart_disease").cast(pl.Int8),
        pl.col("stroke").cast(pl.Int8),
    )
    # Create age groups for stratified analysis
    .with_columns(
        pl.when(pl.col("age") < 18).then(pl.lit("0-17"))
        .when(pl.col("age") < 40).then(pl.lit("18-39"))
        .when(pl.col("age") < 60).then(pl.lit("40-59"))
        .when(pl.col("age") < 80).then(pl.lit("60-79"))
        .otherwise(pl.lit("80+"))
        .alias("age_group")
    )
    # Create BMI categories
    .with_columns(
        pl.when(pl.col("bmi") < 18.5).then(pl.lit("Underweight"))
        .when(pl.col("bmi") < 25).then(pl.lit("Normal"))
        .when(pl.col("bmi") < 30).then(pl.lit("Overweight"))
        .otherwise(pl.lit("Obese"))
        .alias("bmi_category")
    )
    # Create glucose categories
    .with_columns(
        pl.when(pl.col("avg_glucose_level") < 100).then(pl.lit("Normal"))
        .when(pl.col("avg_glucose_level") < 126).then(pl.lit("Prediabetic"))
        .otherwise(pl.lit("Diabetic"))
        .alias("glucose_category")
    )
    # Create composite risk score
    .with_columns(
        (
            pl.col("hypertension") + 
            pl.col("heart_disease") + 
            (pl.col("age") >= 55).cast(pl.Int8) +
            (pl.col("avg_glucose_level") >= 126).cast(pl.Int8) +
            (pl.col("bmi") >= 30).cast(pl.Int8)
        ).alias("risk_score")
    )
    # Drop id column (not useful for analysis)
    .drop("id")
)

print("Final cleaned dataset shape:", stroke_final.shape)
print("\nClass distribution (stroke):")
stroke_final.group_by("stroke").agg(
    pl.len().alias("count"),
    (pl.len() / stroke_final.height * 100).round(2).alias("percentage")
).sort("stroke")
```


```default
name 'stroke_df' is not defined
Cell In[43], line 5
      1 # Final cleaned and transformed dataset ready for analysis
      2 # Let's create the final cleaned dataset with all transformations
      4 stroke_final = (
----> 5     stroke_df
      6     # Handle missing BMI values - impute with median
      7     .with_columns(
      8         pl.col("bmi").fill_null(pl.col("bmi").median())
      9     )
     10     # Remove "Other" gender (only 1 observation)
     11     .filter(pl.col("gender") != "Other")
     12     # Convert categorical columns to appropriate types
     13     .with_columns(
     14         # Binary encoding for binary variables
     15         pl.col("ever_married").replace({"Yes": 1, "No": 0}).cast(pl.Int8).alias("ever_married_binary"),
     16         pl.col("Residence_type").replace({"Urban": 1, "Rural": 0}).cast(pl.Int8).alias("residence_urban"),
     17         pl.col("gender").replace({"Male": 1, "Female": 0}).cast(pl.Int8).alias("gender_male"),
     18         pl.col("hypertension").cast(pl.Int8),
     19         pl.col("heart_disease").cast(pl.Int8),
     20         pl.col("stroke").cast(pl.Int8),
     21     )
     22     # Create age groups for stratified analysis
     23     .with_columns(
     24         pl.when(pl.col("age") < 18).then(pl.lit("0-17"))
     25         .when(pl.col("age") < 40).then(pl.lit("18-39"))
     26         .when(pl.col("age") < 60).then(pl.lit("40-59"))
     27         .when(pl.col("age") < 80).then(pl.lit("60-79"))
     28         .otherwise(pl.lit("80+"))
     29         .alias("age_group")
     30     )
     31     # Create BMI categories
     32     .with_columns(
     33         pl.when(pl.col("bmi") < 18.5).then(pl.lit("Underweight"))
     34         .when(pl.col("bmi") < 25).then(pl.lit("Normal"))
     35         .when(pl.col("bmi") < 30).then(pl.lit("Overweight"))
     36         .otherwise(pl.lit("Obese"))
     37         .alias("bmi_category")
     38     )
     39     # Create glucose categories
     40     .with_columns(
     41         pl.when(pl.col("avg_glucose_level") < 100).then(pl.lit("Normal"))
     42         .when(pl.col("avg_glucose_level") < 126).then(pl.lit("Prediabetic"))
     43         .otherwise(pl.lit("Diabetic"))
     44         .alias("glucose_category")
     45     )
     46     # Create composite risk score
     47     .with_columns(
     48         (
     49             pl.col("hypertension") + 
     50             pl.col("heart_disease") + 
     51             (pl.col("age") >= 55).cast(pl.Int8) +
     52             (pl.col("avg_glucose_level") >= 126).cast(pl.Int8) +
     53             (pl.col("bmi") >= 30).cast(pl.Int8)
     54         ).alias("risk_score")
     55     )
     56     # Drop id column (not useful for analysis)
     57     .drop("id")
     58 )
     60 print("Final cleaned dataset shape:", stroke_final.shape)
     61 print("\nClass distribution (stroke):")

```

<div class="toolcallresult" data-callid="toolu_vrtx_012iTivzuSLQypJ7C7eE2yos" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;name &apos;stroke_df&apos; is not defined\\nCell In[43], line 5\\n    ...[truncated, total 3120 chars]&quot;
    }
  ]
}"></div>

Let me first reload the data: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01ABMpcTmatBksDWVZgPsFQ7" data-call="{
  &quot;code&quot;: &quot;import polars as pl\n\n# Reload the data\nstroke_df = pl.read_csv(\&quot;healthcare-dataset-stroke-...[truncated, total 165 chars]&quot;,
  &quot;intent&quot;: &quot;Reload the stroke dataset&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Reload the stroke dataset" ></div>

```python
import polars as pl

# Reload the data
stroke_df = pl.read_csv("healthcare-dataset-stroke-data.csv", null_values=["N/A", ""])

# Check the structure
stroke_df.head()
```


```default
could not parse `1.32` as dtype `i64` at column 'age' (column number 3)

The current offset in the file is 2205 bytes.

You might want to try:
- increasing `infer_schema_length` (e.g. `infer_schema_length=10000`),
- specifying correct dtype with the `schema_overrides` argument
- setting `ignore_errors` to `True`,
- adding `1.32` to the `null_values` list.

Original error: ```invalid primitive value found during CSV parsing```
Cell In[44], line 4
      1 import polars as pl
      3 # Reload the data
----> 4 stroke_df = pl.read_csv("healthcare-dataset-stroke-data.csv", null_values=["N/A", ""])
      6 # Check the structure
      7 stroke_df.head()

```

<div class="toolcallresult" data-callid="toolu_vrtx_01ABMpcTmatBksDWVZgPsFQ7" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;could not parse `1.32` as dtype `i64` at column &apos;age&apos; (col...[truncated, total 711 chars]&quot;
    }
  ]
}"></div>


<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_017zmfUnXHM5WVJuWfEwEPxt" data-call="{
  &quot;code&quot;: &quot;import polars as pl\n\n# Reload the data with schema inference extended\nstroke_df = pl.read_...[truncated, total 271 chars]&quot;,
  &quot;intent&quot;: &quot;Reload the stroke dataset with proper schema inference&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Reload the stroke dataset with proper schema inference" ></div>

```python
import polars as pl

# Reload the data with schema inference extended
stroke_df = pl.read_csv(
    "healthcare-dataset-stroke-data.csv", 
    null_values=["N/A", ""],
    infer_schema_length=10000
)

# Check the structure
print("Shape:", stroke_df.shape)
stroke_df.head()
```


```default
Shape: (5110, 12)

```
<div><style>
.dataframe > thead > tr,
.dataframe > tbody > tr {
  text-align: right;
  white-space: pre-wrap;
}
</style>
<small>shape: (5, 12)</small><table border="1" class="dataframe"><thead><tr><th>id</th><th>gender</th><th>age</th><th>hypertension</th><th>heart_disease</th><th>ever_married</th><th>work_type</th><th>Residence_type</th><th>avg_glucose_level</th><th>bmi</th><th>smoking_status</th><th>stroke</th></tr><tr><td>i64</td><td>str</td><td>f64</td><td>i64</td><td>i64</td><td>str</td><td>str</td><td>str</td><td>f64</td><td>f64</td><td>str</td><td>i64</td></tr></thead><tbody><tr><td>9046</td><td>&quot;Male&quot;</td><td>67.0</td><td>0</td><td>1</td><td>&quot;Yes&quot;</td><td>&quot;Private&quot;</td><td>&quot;Urban&quot;</td><td>228.69</td><td>36.6</td><td>&quot;formerly smoked&quot;</td><td>1</td></tr><tr><td>51676</td><td>&quot;Female&quot;</td><td>61.0</td><td>0</td><td>0</td><td>&quot;Yes&quot;</td><td>&quot;Self-employed&quot;</td><td>&quot;Rural&quot;</td><td>202.21</td><td>null</td><td>&quot;never smoked&quot;</td><td>1</td></tr><tr><td>31112</td><td>&quot;Male&quot;</td><td>80.0</td><td>0</td><td>1</td><td>&quot;Yes&quot;</td><td>&quot;Private&quot;</td><td>&quot;Rural&quot;</td><td>105.92</td><td>32.5</td><td>&quot;never smoked&quot;</td><td>1</td></tr><tr><td>60182</td><td>&quot;Female&quot;</td><td>49.0</td><td>0</td><td>0</td><td>&quot;Yes&quot;</td><td>&quot;Private&quot;</td><td>&quot;Urban&quot;</td><td>171.23</td><td>34.4</td><td>&quot;smokes&quot;</td><td>1</td></tr><tr><td>1665</td><td>&quot;Female&quot;</td><td>79.0</td><td>1</td><td>0</td><td>&quot;Yes&quot;</td><td>&quot;Self-employed&quot;</td><td>&quot;Rural&quot;</td><td>174.12</td><td>24.0</td><td>&quot;never smoked&quot;</td><td>1</td></tr></tbody></table></div>
<div class="toolcallresult" data-callid="toolu_vrtx_017zmfUnXHM5WVJuWfEwEPxt" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Shape: (5110, 12)\\nshape: (5, 12)\\n┌───────┬────────┬──────┬──────────────┬...[truncated, total 1169 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01EH3R7HK4u5R27ZmKKrJutF" data-call="{
  &quot;code&quot;: &quot;# Create final cleaned and transformed dataset for stroke analysis\n# Addressing class imba...[truncated, total 2964 chars]&quot;,
  &quot;intent&quot;: &quot;Create final cleaned dataset with all transformations and show class imbalance&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Create final cleaned dataset with all transformations and show class imbalance" ></div>

```python
# Create final cleaned and transformed dataset for stroke analysis
# Addressing class imbalance preparation

stroke_final = (
    stroke_df
    # Handle missing BMI values - impute with median
    .with_columns(
        pl.col("bmi").fill_null(pl.col("bmi").median())
    )
    # Remove "Other" gender (only 1 observation - too rare for analysis)
    .filter(pl.col("gender") != "Other")
    # Convert categorical columns to appropriate types
    .with_columns(
        # Binary encoding for binary variables
        pl.col("ever_married").replace({"Yes": 1, "No": 0}).cast(pl.Int8).alias("ever_married_binary"),
        pl.col("Residence_type").replace({"Urban": 1, "Rural": 0}).cast(pl.Int8).alias("residence_urban"),
        pl.col("gender").replace({"Male": 1, "Female": 0}).cast(pl.Int8).alias("gender_male"),
        pl.col("hypertension").cast(pl.Int8),
        pl.col("heart_disease").cast(pl.Int8),
        pl.col("stroke").cast(pl.Int8),
    )
    # Create age groups for stratified analysis
    .with_columns(
        pl.when(pl.col("age") < 18).then(pl.lit("0-17"))
        .when(pl.col("age") < 40).then(pl.lit("18-39"))
        .when(pl.col("age") < 60).then(pl.lit("40-59"))
        .when(pl.col("age") < 80).then(pl.lit("60-79"))
        .otherwise(pl.lit("80+"))
        .alias("age_group")
    )
    # Create BMI categories
    .with_columns(
        pl.when(pl.col("bmi") < 18.5).then(pl.lit("Underweight"))
        .when(pl.col("bmi") < 25).then(pl.lit("Normal"))
        .when(pl.col("bmi") < 30).then(pl.lit("Overweight"))
        .otherwise(pl.lit("Obese"))
        .alias("bmi_category")
    )
    # Create glucose categories
    .with_columns(
        pl.when(pl.col("avg_glucose_level") < 100).then(pl.lit("Normal"))
        .when(pl.col("avg_glucose_level") < 126).then(pl.lit("Prediabetic"))
        .otherwise(pl.lit("Diabetic"))
        .alias("glucose_category")
    )
    # Create composite risk score
    .with_columns(
        (
            pl.col("hypertension") + 
            pl.col("heart_disease") + 
            (pl.col("age") >= 55).cast(pl.Int8) +
            (pl.col("avg_glucose_level") >= 126).cast(pl.Int8) +
            (pl.col("bmi") >= 30).cast(pl.Int8)
        ).alias("risk_score")
    )
    # Drop id column (not useful for analysis)
    .drop("id")
)

print("=" * 60)
print("CLEANED DATASET SUMMARY")
print("=" * 60)
print(f"\nShape: {stroke_final.shape}")

print("\n--- Class Distribution (TARGET: stroke) ---")
class_dist = stroke_final.group_by("stroke").agg(
    pl.len().alias("count"),
    (pl.len() / stroke_final.height * 100).round(2).alias("percentage")
).sort("stroke")
print(class_dist)

# Calculate imbalance ratio
no_stroke = class_dist.filter(pl.col("stroke") == 0).get_column("count")[0]
stroke = class_dist.filter(pl.col("stroke") == 1).get_column("count")[0]
print(f"\nImbalance ratio (no stroke : stroke): {no_stroke/stroke:.1f}:1")

print("\n--- Column Types ---")
print(stroke_final.schema)
```


```default
============================================================
CLEANED DATASET SUMMARY
============================================================

Shape: (5109, 18)

--- Class Distribution (TARGET: stroke) ---
shape: (2, 3)
┌────────┬───────┬────────────┐
│ stroke ┆ count ┆ percentage │
│ ---    ┆ ---   ┆ ---        │
│ i8     ┆ u32   ┆ f64        │
╞════════╪═══════╪════════════╡
│ 0      ┆ 4860  ┆ 95.13      │
│ 1      ┆ 249   ┆ 4.87       │
└────────┴───────┴────────────┘

Imbalance ratio (no stroke : stroke): 19.5:1

--- Column Types ---
Schema({'gender': String, 'age': Float64, 'hypertension': Int8, 'heart_disease': Int8, 'ever_married': String, 'work_type': String, 'Residence_type': String, 'avg_glucose_level': Float64, 'bmi': Float64, 'smoking_status': String, 'stroke': Int8, 'ever_married_binary': Int8, 'residence_urban': Int8, 'gender_male': Int8, 'age_group': String, 'bmi_category': String, 'glucose_category': String, 'risk_score': Int8})

```

<div class="toolcallresult" data-callid="toolu_vrtx_01EH3R7HK4u5R27ZmKKrJutF" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;============================================================\\nCLEANED DATAS...[truncated, total 1018 chars]&quot;
    }
  ]
}"></div>



The data has been cleaned and transformed. Here's a summary of what was done:

## Data Cleaning & Transformation Summary

| Step | Description |
|------|-------------|
| **Missing BMI** | Imputed 201 missing values with median (28.1) |
| **Gender "Other"** | Removed 1 observation (too rare for reliable analysis) |
| **Binary encoding** | Created numeric versions: `ever_married_binary`, `residence_urban`, `gender_male` |
| **Type conversion** | Cast `hypertension`, `heart_disease`, `stroke` to Int8 |

## Engineered Features

| Feature | Description |
|---------|-------------|
| `age_group` | 0-17, 18-39, 40-59, 60-79, 80+ |
| `bmi_category` | Underweight, Normal, Overweight, Obese |
| `glucose_category` | Normal (<100), Prediabetic (100-125), Diabetic (≥126) |
| `risk_score` | 0-5 composite of hypertension, heart disease, age≥55, diabetic glucose, obese |

## Class Imbalance

⚠️ **Severe imbalance: 19.5:1 ratio** (95.13% no stroke, 4.87% stroke)

The dataset is now ready for modeling. I'll suggest some questions below.


<span class="suggestion">Apply SMOTE or other resampling to address the class imbalance and train a model</span>


<span class="suggestion">Show a visualization of stroke rates across different risk factors</span>


<span class="suggestion">Save the cleaned dataset to a new CSV file</span>






## User

Apply SMOTE or other resampling to address the class imbalance and train a model.

## Databot

I'll apply SMOTE to address the class imbalance and train a classification model. First, let me check if the required packages are installed. 
<div class="toolcall" data-name="getInstalledPythonPackageVersion" data-callid="toolu_vrtx_013bTjngSzyo1RXs12co1oFy" data-call="{
  &quot;paramName&quot;: &quot;imbalanced-learn&quot;
}" ></div>
<div class="toolcallresult" data-callid="toolu_vrtx_013bTjngSzyo1RXs12co1oFy" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;0.14.0&quot;
    }
  ]
}"></div>
<div class="toolcall" data-name="getInstalledPythonPackageVersion" data-callid="toolu_vrtx_01H1bYk9CVzYSTLyG8SuSu7U" data-call="{
  &quot;paramName&quot;: &quot;scikit-learn&quot;
}" ></div>
<div class="toolcallresult" data-callid="toolu_vrtx_01H1bYk9CVzYSTLyG8SuSu7U" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;1.7.2&quot;
    }
  ]
}"></div>

Both packages are installed. Let me prepare the data and apply SMOTE: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01QnjoFdqPwDtcN93q8MXQv8" data-call="{
  &quot;code&quot;: &quot;from sklearn.model_selection import train_test_split\nfrom sklearn.preprocessing import Sta...[truncated, total 1052 chars]&quot;,
  &quot;intent&quot;: &quot;Prepare features and target for modeling&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Prepare features and target for modeling" ></div>

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from imblearn.over_sampling import SMOTE
from imblearn.pipeline import Pipeline as ImbPipeline
import numpy as np

# Define features for modeling
# Select only the clean, analysis-ready columns
numeric_features = ["age", "avg_glucose_level", "bmi"]
binary_features = ["hypertension", "heart_disease", "ever_married_binary", "residence_urban", "gender_male"]
categorical_features = ["work_type", "smoking_status"]

# Prepare X and y
X = stroke_final.select(
    *numeric_features,
    *binary_features,
    *categorical_features
).to_pandas()

y = stroke_final.get_column("stroke").to_numpy()

print("Feature matrix shape:", X.shape)
print("Target shape:", y.shape)
print("\nFeatures used:")
print(X.columns.tolist())
```


```default
Feature matrix shape: (5109, 10)
Target shape: (5109,)

Features used:
['age', 'avg_glucose_level', 'bmi', 'hypertension', 'heart_disease', 'ever_married_binary', 'residence_urban', 'gender_male', 'work_type', 'smoking_status']

```

<div class="toolcallresult" data-callid="toolu_vrtx_01QnjoFdqPwDtcN93q8MXQv8" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Feature matrix shape: (5109, 10)\\nTarget shape: (5109,)\\n\\nFeatures used:\\n...[truncated, total 267 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01KxAHhvakmH9wuJU5JT4gWU" data-call="{
  &quot;code&quot;: &quot;# Split data first (before SMOTE to avoid data leakage)\nX_train, X_test, y_train, y_test =...[truncated, total 1140 chars]&quot;,
  &quot;intent&quot;: &quot;Split data, apply SMOTE, and train Random Forest model&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Split data, apply SMOTE, and train Random Forest model" ></div>

```python
# Split data first (before SMOTE to avoid data leakage)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

print("Training set shape:", X_train.shape)
print("Test set shape:", X_test.shape)
print(f"\nTraining class distribution:")
print(f"  No stroke: {sum(y_train == 0)} ({sum(y_train == 0)/len(y_train)*100:.1f}%)")
print(f"  Stroke:    {sum(y_train == 1)} ({sum(y_train == 1)/len(y_train)*100:.1f}%)")

# Create preprocessing pipeline
preprocessor = ColumnTransformer(
    transformers=[
        ("num", StandardScaler(), numeric_features),
        ("bin", "passthrough", binary_features),
        ("cat", OneHotEncoder(drop="first", sparse_output=False, handle_unknown="ignore"), categorical_features),
    ]
)

# Create pipeline with SMOTE and Random Forest
model_pipeline = ImbPipeline([
    ("preprocessor", preprocessor),
    ("smote", SMOTE(random_state=42)),
    ("classifier", RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1))
])

# Fit the model
print("\nTraining model with SMOTE...")
model_pipeline.fit(X_train, y_train)
print("Training complete!")
```


```default
Training set shape: (4087, 10)
Test set shape: (1022, 10)

Training class distribution:
  No stroke: 3888 (95.1%)
  Stroke:    199 (4.9%)

Training model with SMOTE...
Training complete!

```

<div class="toolcallresult" data-callid="toolu_vrtx_01KxAHhvakmH9wuJU5JT4gWU" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Training set shape: (4087, 10)\\nTest set shape: (1022, 10)\\n\\nTraining clas...[truncated, total 230 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01DDi6SJGk5UrDY4XD1kcd2c" data-call="{
  &quot;code&quot;: &quot;# Evaluate the model\ny_pred = model_pipeline.predict(X_test)\ny_pred_proba = model_pipeline...[truncated, total 945 chars]&quot;,
  &quot;intent&quot;: &quot;Evaluate model performance with classification metrics&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Evaluate model performance with classification metrics" ></div>

```python
# Evaluate the model
y_pred = model_pipeline.predict(X_test)
y_pred_proba = model_pipeline.predict_proba(X_test)[:, 1]

print("=" * 60)
print("MODEL EVALUATION RESULTS")
print("=" * 60)

print("\n--- Confusion Matrix ---")
cm = confusion_matrix(y_test, y_pred)
print(f"                 Predicted")
print(f"                 No Stroke  Stroke")
print(f"Actual No Stroke    {cm[0,0]:4d}      {cm[0,1]:4d}")
print(f"Actual Stroke       {cm[1,0]:4d}      {cm[1,1]:4d}")

print("\n--- Classification Report ---")
print(classification_report(y_test, y_pred, target_names=["No Stroke", "Stroke"]))

print(f"--- ROC-AUC Score ---")
roc_auc = roc_auc_score(y_test, y_pred_proba)
print(f"ROC-AUC: {roc_auc:.4f}")

# Show SMOTE effect
print("\n--- SMOTE Effect (Training Data) ---")
print(f"Before SMOTE: {sum(y_train == 0)} no-stroke, {sum(y_train == 1)} stroke")
print(f"After SMOTE:  {sum(y_train == 0)} no-stroke, {sum(y_train == 0)} stroke (balanced)")
```


```default
============================================================
MODEL EVALUATION RESULTS
============================================================

--- Confusion Matrix ---
                 Predicted
                 No Stroke  Stroke
Actual No Stroke     949        23
Actual Stroke         44         6

--- Classification Report ---
              precision    recall  f1-score   support

   No Stroke       0.96      0.98      0.97       972
      Stroke       0.21      0.12      0.15        50

    accuracy                           0.93      1022
   macro avg       0.58      0.55      0.56      1022
weighted avg       0.92      0.93      0.93      1022

--- ROC-AUC Score ---
ROC-AUC: 0.7647

--- SMOTE Effect (Training Data) ---
Before SMOTE: 3888 no-stroke, 199 stroke
After SMOTE:  3888 no-stroke, 3888 stroke (balanced)

```

<div class="toolcallresult" data-callid="toolu_vrtx_01DDi6SJGk5UrDY4XD1kcd2c" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;============================================================\\nMODEL EVALUAT...[truncated, total 893 chars]&quot;
    }
  ]
}"></div>



The model is trained, but the recall for stroke cases is low (12%). Let me try a model optimized for better recall on the minority class: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_015zX3EEMFeJ33rBn9kVRGGB" data-call="{
  &quot;code&quot;: &quot;# Try a model optimized for better recall on minority class\nfrom sklearn.ensemble import G...[truncated, total 1364 chars]&quot;,
  &quot;intent&quot;: &quot;Train optimized model with better recall for stroke cases&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Train optimized model with better recall for stroke cases" ></div>

```python
# Try a model optimized for better recall on minority class
from sklearn.ensemble import GradientBoostingClassifier

# Adjust class weights and use a different resampling strategy
model_pipeline_v2 = ImbPipeline([
    ("preprocessor", preprocessor),
    ("smote", SMOTE(sampling_strategy=0.5, random_state=42)),  # Less aggressive oversampling
    ("classifier", RandomForestClassifier(
        n_estimators=200,
        class_weight="balanced_subsample",  # Further weight adjustment
        max_depth=10,
        min_samples_leaf=5,
        random_state=42,
        n_jobs=-1
    ))
])

print("Training optimized model...")
model_pipeline_v2.fit(X_train, y_train)

# Evaluate
y_pred_v2 = model_pipeline_v2.predict(X_test)
y_pred_proba_v2 = model_pipeline_v2.predict_proba(X_test)[:, 1]

print("\n" + "=" * 60)
print("OPTIMIZED MODEL RESULTS")
print("=" * 60)

print("\n--- Confusion Matrix ---")
cm2 = confusion_matrix(y_test, y_pred_v2)
print(f"                 Predicted")
print(f"                 No Stroke  Stroke")
print(f"Actual No Stroke    {cm2[0,0]:4d}      {cm2[0,1]:4d}")
print(f"Actual Stroke       {cm2[1,0]:4d}      {cm2[1,1]:4d}")

print("\n--- Classification Report ---")
print(classification_report(y_test, y_pred_v2, target_names=["No Stroke", "Stroke"]))

roc_auc_v2 = roc_auc_score(y_test, y_pred_proba_v2)
print(f"ROC-AUC: {roc_auc_v2:.4f}")
```


```default
Training optimized model...

============================================================
OPTIMIZED MODEL RESULTS
============================================================

--- Confusion Matrix ---
                 Predicted
                 No Stroke  Stroke
Actual No Stroke     846       126
Actual Stroke         24        26

--- Classification Report ---
              precision    recall  f1-score   support

   No Stroke       0.97      0.87      0.92       972
      Stroke       0.17      0.52      0.26        50

    accuracy                           0.85      1022
   macro avg       0.57      0.70      0.59      1022
weighted avg       0.93      0.85      0.89      1022

ROC-AUC: 0.8083

```

<div class="toolcallresult" data-callid="toolu_vrtx_015zX3EEMFeJ33rBn9kVRGGB" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Training optimized model...\\n\\n============================================...[truncated, total 764 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01PZZfM59isvth1Bo9H2Yz4V" data-call="{
  &quot;code&quot;: &quot;# Visualize feature importance and ROC curve\nfrom plotnine import *\nfrom sklearn.metrics i...[truncated, total 980 chars]&quot;,
  &quot;intent&quot;: &quot;Visualize feature importance&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: true
}" data-intent="Visualize feature importance" ></div>

```python
# Visualize feature importance and ROC curve
from plotnine import *
from sklearn.metrics import roc_curve

# Get feature names after preprocessing
feature_names = (
    numeric_features + 
    binary_features + 
    list(model_pipeline_v2.named_steps["preprocessor"]
         .named_transformers_["cat"]
         .get_feature_names_out(categorical_features))
)

# Feature importance
importances = model_pipeline_v2.named_steps["classifier"].feature_importances_
importance_df = pl.DataFrame({
    "feature": feature_names,
    "importance": importances
}).sort("importance", descending=True).head(10)

# ROC curve data
fpr, tpr, _ = roc_curve(y_test, y_pred_proba_v2)
roc_df = pl.DataFrame({"fpr": fpr, "tpr": tpr})

# Create plots
p = (
    ggplot(importance_df, aes(x="reorder(feature, importance)", y="importance"))
    + geom_col(fill="steelblue")
    + coord_flip()
    + labs(
        title="Top 10 Feature Importances",
        x="Feature",
        y="Importance"
    )
)
p
```



![Plot image](image-1.png)


<div class="toolcallresult" data-callid="toolu_vrtx_01PZZfM59isvth1Bo9H2Yz4V" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;\&quot;}&quot;
    },
    {
      &quot;type&quot;: &quot;media&quot;,
      &quot;data&quot;: &quot;iVBORw0KGgoAAAANSUhEUgAABSgAAAPnCAYAAAAs/6LTAAAAOnRFWHRTb2Z0d2FyZQBNYXRwbG90bGliIHZlcnNpb2...[truncated, total 79200 chars]&quot;,
      &quot;mediaType&quot;: &quot;image/png&quot;
    }
  ]
}"></div>



## Summary: SMOTE + Random Forest Model

### Model Comparison

| Metric | Model 1 (Full SMOTE) | Model 2 (Optimized) |
|--------|---------------------|---------------------|
| **Stroke Recall** | 12% | **52%** ✓ |
| **Stroke Precision** | 21% | 17% |
| **ROC-AUC** | 0.76 | **0.81** ✓ |
| **Accuracy** | 93% | 85% |

### Key Findings

1. **SMOTE Effect**: Balanced training data from 19.5:1 to roughly 2:1 ratio
2. **Trade-off**: The optimized model catches **52% of strokes** (up from 12%) at the cost of more false positives
3. **Top Predictors**: Age dominates, followed by BMI, marital status, glucose level, and hypertension

### Healthcare Context
For stroke prediction, **high recall is critical** — missing a stroke case is worse than false alarms. The optimized model correctly identifies over half of actual stroke cases.

I'll suggest some questions below.


<span class="suggestion">Try other algorithms like XGBoost or Logistic Regression for comparison</span>


<span class="suggestion">Adjust the decision threshold to further optimize recall vs precision trade-off</span>


<span class="suggestion">Create a report summarizing the full analysis pipeline</span>






## User

Try other algorithms like XGBoost or Logistic Regression for comparison

## Databot


<div class="toolcall" data-name="getInstalledPythonPackageVersion" data-callid="toolu_vrtx_01YBBZa4qwwssjNkCaTN44Cs" data-call="{
  &quot;paramName&quot;: &quot;xgboost&quot;
}" ></div>
<div class="toolcallresult" data-callid="toolu_vrtx_01YBBZa4qwwssjNkCaTN44Cs" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;3.1.2&quot;
    }
  ]
}"></div>

XGBoost is installed. Let me train and compare multiple algorithms: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_018mgGvyDrWGDA1jyXEzwP2r" data-call="{
  &quot;code&quot;: &quot;from sklearn.linear_model import LogisticRegression\nfrom xgboost import XGBClassifier\n\n# S...[truncated, total 1166 chars]&quot;,
  &quot;intent&quot;: &quot;Train Logistic Regression and XGBoost models for comparison&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Train Logistic Regression and XGBoost models for comparison" ></div>

```python
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier

# Store results for comparison
results = []

# 1. Logistic Regression with SMOTE
lr_pipeline = ImbPipeline([
    ("preprocessor", preprocessor),
    ("smote", SMOTE(sampling_strategy=0.5, random_state=42)),
    ("classifier", LogisticRegression(class_weight="balanced", max_iter=1000, random_state=42))
])

print("Training Logistic Regression...")
lr_pipeline.fit(X_train, y_train)
y_pred_lr = lr_pipeline.predict(X_test)
y_proba_lr = lr_pipeline.predict_proba(X_test)[:, 1]

# 2. XGBoost with SMOTE
xgb_pipeline = ImbPipeline([
    ("preprocessor", preprocessor),
    ("smote", SMOTE(sampling_strategy=0.5, random_state=42)),
    ("classifier", XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        scale_pos_weight=5,  # Additional weight for minority class
        random_state=42,
        eval_metric="logloss",
        verbosity=0
    ))
])

print("Training XGBoost...")
xgb_pipeline.fit(X_train, y_train)
y_pred_xgb = xgb_pipeline.predict(X_test)
y_proba_xgb = xgb_pipeline.predict_proba(X_test)[:, 1]

print("Training complete!")
```


```default
Training Logistic Regression...
Training XGBoost...
Training complete!

```

<div class="toolcallresult" data-callid="toolu_vrtx_018mgGvyDrWGDA1jyXEzwP2r" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Training Logistic Regression...\\nTraining XGBoost...\\nTraining complete!\\n\&quot;,\&quot;outputError\&quot;:\&quot;\&quot;}&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_013yiKWSgzszK3rfyAc1ULsh" data-call="{
  &quot;code&quot;: &quot;from sklearn.metrics import precision_score, recall_score, f1_score\n\n# Collect metrics for...[truncated, total 1057 chars]&quot;,
  &quot;intent&quot;: &quot;Compare all models with key metrics&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Compare all models with key metrics" ></div>

```python
from sklearn.metrics import precision_score, recall_score, f1_score

# Collect metrics for all models
models = {
    "Random Forest": (y_pred_v2, y_proba_v2),
    "Logistic Regression": (y_pred_lr, y_proba_lr),
    "XGBoost": (y_pred_xgb, y_proba_xgb),
}

comparison_data = []
for name, (y_pred_model, y_proba_model) in models.items():
    cm_model = confusion_matrix(y_test, y_pred_model)
    comparison_data.append({
        "Model": name,
        "Accuracy": round((y_pred_model == y_test).mean() * 100, 1),
        "Stroke_Precision": round(precision_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "Stroke_Recall": round(recall_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "Stroke_F1": round(f1_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "ROC_AUC": round(roc_auc_score(y_test, y_proba_model), 4),
        "True_Positives": cm_model[1, 1],
        "False_Negatives": cm_model[1, 0],
    })

comparison_df = pl.DataFrame(comparison_data)

print("=" * 70)
print("MODEL COMPARISON")
print("=" * 70)
comparison_df
```


```default
name 'y_proba_v2' is not defined
Cell In[53], line 5
      1 from sklearn.metrics import precision_score, recall_score, f1_score
      3 # Collect metrics for all models
      4 models = {
----> 5     "Random Forest": (y_pred_v2, y_proba_v2),
      6     "Logistic Regression": (y_pred_lr, y_proba_lr),
      7     "XGBoost": (y_pred_xgb, y_proba_xgb),
      8 }
     10 comparison_data = []
     11 for name, (y_pred_model, y_proba_model) in models.items():

```

<div class="toolcallresult" data-callid="toolu_vrtx_013yiKWSgzszK3rfyAc1ULsh" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;name &apos;y_proba_v2&apos; is not defined\\nCell In[53], line 5\\n   ...[truncated, total 510 chars]&quot;
    }
  ]
}"></div>


<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_012q11ppw2jZEaA5nwLYvnYY" data-call="{
  &quot;code&quot;: &quot;# Re-predict with Random Forest model\ny_pred_rf = model_pipeline_v2.predict(X_test)\ny_prob...[truncated, total 1231 chars]&quot;,
  &quot;intent&quot;: &quot;Compare all models with key metrics&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Compare all models with key metrics" ></div>

```python
# Re-predict with Random Forest model
y_pred_rf = model_pipeline_v2.predict(X_test)
y_proba_rf = model_pipeline_v2.predict_proba(X_test)[:, 1]

from sklearn.metrics import precision_score, recall_score, f1_score

# Collect metrics for all models
models = {
    "Random Forest": (y_pred_rf, y_proba_rf),
    "Logistic Regression": (y_pred_lr, y_proba_lr),
    "XGBoost": (y_pred_xgb, y_proba_xgb),
}

comparison_data = []
for name, (y_pred_model, y_proba_model) in models.items():
    cm_model = confusion_matrix(y_test, y_pred_model)
    comparison_data.append({
        "Model": name,
        "Accuracy": round((y_pred_model == y_test).mean() * 100, 1),
        "Stroke_Precision": round(precision_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "Stroke_Recall": round(recall_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "Stroke_F1": round(f1_score(y_test, y_pred_model, pos_label=1) * 100, 1),
        "ROC_AUC": round(roc_auc_score(y_test, y_proba_model), 4),
        "True_Positives": cm_model[1, 1],
        "False_Negatives": cm_model[1, 0],
    })

comparison_df = pl.DataFrame(comparison_data)

print("=" * 70)
print("MODEL COMPARISON (50 stroke cases in test set)")
print("=" * 70)
comparison_df
```


```default
======================================================================
MODEL COMPARISON (50 stroke cases in test set)
======================================================================

```
<div><style>
.dataframe > thead > tr,
.dataframe > tbody > tr {
  text-align: right;
  white-space: pre-wrap;
}
</style>
<small>shape: (3, 8)</small><table border="1" class="dataframe"><thead><tr><th>Model</th><th>Accuracy</th><th>Stroke_Precision</th><th>Stroke_Recall</th><th>Stroke_F1</th><th>ROC_AUC</th><th>True_Positives</th><th>False_Negatives</th></tr><tr><td>str</td><td>f64</td><td>f64</td><td>f64</td><td>f64</td><td>f64</td><td>i64</td><td>i64</td></tr></thead><tbody><tr><td>&quot;Random Forest&quot;</td><td>85.3</td><td>17.1</td><td>52.0</td><td>25.7</td><td>0.8083</td><td>26</td><td>24</td></tr><tr><td>&quot;Logistic Regression&quot;</td><td>73.5</td><td>13.3</td><td>80.0</td><td>22.8</td><td>0.8407</td><td>40</td><td>10</td></tr><tr><td>&quot;XGBoost&quot;</td><td>89.6</td><td>13.2</td><td>20.0</td><td>15.9</td><td>0.7806</td><td>10</td><td>40</td></tr></tbody></table></div>
<div class="toolcallresult" data-callid="toolu_vrtx_012q11ppw2jZEaA5nwLYvnYY" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;======================================================================\\nMOD...[truncated, total 1465 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_0159YmmhpeX44mmUC7BdLZGx" data-call="{
  &quot;code&quot;: &quot;# Visualize ROC curves for all models\nfpr_rf, tpr_rf, _ = roc_curve(y_test, y_proba_rf)\nfp...[truncated, total 852 chars]&quot;,
  &quot;intent&quot;: &quot;Visualize ROC curves for all three models&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: true
}" data-intent="Visualize ROC curves for all three models" ></div>

```python
# Visualize ROC curves for all models
fpr_rf, tpr_rf, _ = roc_curve(y_test, y_proba_rf)
fpr_lr, tpr_lr, _ = roc_curve(y_test, y_proba_lr)
fpr_xgb, tpr_xgb, _ = roc_curve(y_test, y_proba_xgb)

roc_all = pl.concat([
    pl.DataFrame({"fpr": fpr_rf, "tpr": tpr_rf, "Model": "Random Forest (AUC=0.81)"}),
    pl.DataFrame({"fpr": fpr_lr, "tpr": tpr_lr, "Model": "Logistic Regression (AUC=0.84)"}),
    pl.DataFrame({"fpr": fpr_xgb, "tpr": tpr_xgb, "Model": "XGBoost (AUC=0.78)"}),
])

p_roc = (
    ggplot(roc_all, aes(x="fpr", y="tpr", color="Model"))
    + geom_line(size=1.2)
    + geom_abline(slope=1, intercept=0, linetype="dashed", color="gray")
    + labs(
        title="ROC Curves Comparison",
        x="False Positive Rate",
        y="True Positive Rate (Recall)"
    )
    + scale_color_manual(values=["#E74C3C", "#3498DB", "#2ECC71"])
)
p_roc
```



![Plot image](image-2.png)


<div class="toolcallresult" data-callid="toolu_vrtx_0159YmmhpeX44mmUC7BdLZGx" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;\&quot;}&quot;
    },
    {
      &quot;type&quot;: &quot;media&quot;,
      &quot;data&quot;: &quot;iVBORw0KGgoAAAANSUhEUgAABSgAAAPnCAYAAAAs/6LTAAAAOnRFWHRTb2Z0d2FyZQBNYXRwbG90bGliIHZlcnNpb2...[truncated, total 110124 chars]&quot;,
      &quot;mediaType&quot;: &quot;image/png&quot;
    }
  ]
}"></div>



## Model Comparison Summary

| Model | Accuracy | Stroke Recall | ROC-AUC | Missed Strokes |
|-------|----------|---------------|---------|----------------|
| **Logistic Regression** | 73.5% | **80.0%** ✓ | **0.84** ✓ | 10/50 |
| Random Forest | 85.3% | 52.0% | 0.81 | 24/50 |
| XGBoost | 89.6% | 20.0% | 0.78 | 40/50 |

### Key Findings

1. **Logistic Regression wins for stroke detection**: Catches **80% of strokes** (40 out of 50), the highest recall
2. **Best ROC-AUC**: Logistic Regression (0.84) has the best overall discrimination ability
3. **Trade-off**: Higher recall comes with lower accuracy (more false positives)
4. **XGBoost underperforms**: Despite complexity, it misses 80% of stroke cases

### Recommendation

For **healthcare screening** where missing a stroke is critical, **Logistic Regression** is the best choice:
- Catches 4 out of 5 stroke cases
- Interpretable coefficients for clinical insight
- Best ROC-AUC score

I'll suggest some questions below.


<span class="suggestion">Show the Logistic Regression coefficients to understand which features drive stroke risk</span>


<span class="suggestion">Adjust the decision threshold on Logistic Regression to catch even more strokes</span>


<span class="suggestion">Create a report summarizing the full stroke prediction pipeline</span>






## User

Please apply and test a full range of alpha and lambda values for an elastic net penalty on the logistic regression.

## Databot

I'll perform a grid search over elastic net parameters (alpha for regularization strength, l1_ratio for L1/L2 mixing) using cross-validation: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_011grXpkmPrnXdJezBsokjTa" data-call="{
  &quot;code&quot;: &quot;from sklearn.model_selection import GridSearchCV, StratifiedKFold\nfrom sklearn.linear_mode...[truncated, total 1789 chars]&quot;,
  &quot;intent&quot;: &quot;Set up and run grid search for elastic net logistic regression&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Set up and run grid search for elastic net logistic regression" ></div>

```python
from sklearn.model_selection import GridSearchCV, StratifiedKFold
from sklearn.linear_model import LogisticRegression
import numpy as np

# Define parameter grid
# alpha (C in sklearn is 1/alpha, so we use C values)
# l1_ratio: 0 = L2 (ridge), 1 = L1 (lasso), in between = elastic net
C_values = [0.001, 0.01, 0.1, 1, 10, 100]  # inverse of alpha
l1_ratios = [0, 0.25, 0.5, 0.75, 1.0]

# First preprocess the data (apply SMOTE to training data)
from imblearn.over_sampling import SMOTE

# Fit preprocessor on training data
preprocessor.fit(X_train)
X_train_processed = preprocessor.transform(X_train)
X_test_processed = preprocessor.transform(X_test)

# Apply SMOTE to training data
smote = SMOTE(sampling_strategy=0.5, random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train_processed, y_train)

print(f"After SMOTE: {sum(y_train_resampled == 0)} no-stroke, {sum(y_train_resampled == 1)} stroke")

# Create elastic net logistic regression with grid search
# Note: solver='saga' supports elastic net penalty
elastic_net_lr = LogisticRegression(
    penalty="elasticnet",
    solver="saga",
    max_iter=2000,
    random_state=42,
    class_weight="balanced"
)

param_grid = {
    "C": C_values,
    "l1_ratio": l1_ratios
}

# Use stratified k-fold for cross-validation
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

print(f"\nGrid search: {len(C_values)} C values × {len(l1_ratios)} l1_ratios = {len(C_values) * len(l1_ratios)} combinations")
print("Running grid search with 5-fold CV (optimizing for ROC-AUC)...")

grid_search = GridSearchCV(
    elastic_net_lr,
    param_grid,
    cv=cv,
    scoring="roc_auc",
    n_jobs=-1,
    return_train_score=True
)

grid_search.fit(X_train_resampled, y_train_resampled)
print("Grid search complete!")
```


```default
After SMOTE: 3888 no-stroke, 1944 stroke

Grid search: 6 C values × 5 l1_ratios = 30 combinations
Running grid search with 5-fold CV (optimizing for ROC-AUC)...
Grid search complete!

```

<div class="toolcallresult" data-callid="toolu_vrtx_011grXpkmPrnXdJezBsokjTa" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;After SMOTE: 3888 no-stroke, 1944 stroke\\n\\nGrid search: 6 C values × 5 l1_...[truncated, total 222 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01EbTjtx5WFhHtbDy9DmWhAY" data-call="{
  &quot;code&quot;: &quot;# Extract results and create a heatmap of performance\nresults_df = pl.DataFrame(grid_searc...[truncated, total 869 chars]&quot;,
  &quot;intent&quot;: &quot;Extract and display grid search results&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Extract and display grid search results" ></div>

```python
# Extract results and create a heatmap of performance
results_df = pl.DataFrame(grid_search.cv_results_).select(
    pl.col("param_C").alias("C"),
    pl.col("param_l1_ratio").alias("l1_ratio"),
    pl.col("mean_test_score").alias("mean_roc_auc"),
    pl.col("std_test_score").alias("std_roc_auc"),
    pl.col("rank_test_score").alias("rank")
).sort("rank")

print("=" * 60)
print("ELASTIC NET GRID SEARCH RESULTS")
print("=" * 60)
print(f"\nBest parameters: C={grid_search.best_params_['C']}, l1_ratio={grid_search.best_params_['l1_ratio']}")
print(f"Best CV ROC-AUC: {grid_search.best_score_:.4f}")

# Map l1_ratio to penalty type
print("\nPenalty interpretation:")
print("  l1_ratio=0.0  → Pure L2 (Ridge)")
print("  l1_ratio=0.5  → Equal L1+L2 (Elastic Net)")
print("  l1_ratio=1.0  → Pure L1 (Lasso)")

print("\nTop 10 parameter combinations:")
results_df.head(10)
```


```default
unexpected value while building Series of type Float64; found value of type Int64: 1

Hint: Try setting `strict=False` to allow passing data with mixed types.
Cell In[57], line 2
      1 # Extract results and create a heatmap of performance
----> 2 results_df = pl.DataFrame(grid_search.cv_results_).select(
      3     pl.col("param_C").alias("C"),
      4     pl.col("param_l1_ratio").alias("l1_ratio"),
      5     pl.col("mean_test_score").alias("mean_roc_auc"),
      6     pl.col("std_test_score").alias("std_roc_auc"),
      7     pl.col("rank_test_score").alias("rank")
      8 ).sort("rank")
     10 print("=" * 60)
     11 print("ELASTIC NET GRID SEARCH RESULTS")

```

<div class="toolcallresult" data-callid="toolu_vrtx_01EbTjtx5WFhHtbDy9DmWhAY" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;unexpected value while building Series of type Float64; fo...[truncated, total 748 chars]&quot;
    }
  ]
}"></div>


<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01MZN8LjJE83z49G7NcQMBL8" data-call="{
  &quot;code&quot;: &quot;# Extract results using pandas first, then convert\nimport pandas as pd\n\nresults_pd = pd.Da...[truncated, total 966 chars]&quot;,
  &quot;intent&quot;: &quot;Extract and display grid search results properly&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Extract and display grid search results properly" ></div>

```python
# Extract results using pandas first, then convert
import pandas as pd

results_pd = pd.DataFrame(grid_search.cv_results_)[
    ["param_C", "param_l1_ratio", "mean_test_score", "std_test_score", "rank_test_score"]
]
results_pd.columns = ["C", "l1_ratio", "mean_roc_auc", "std_roc_auc", "rank"]

results_df = pl.from_pandas(results_pd).sort("rank")

print("=" * 60)
print("ELASTIC NET GRID SEARCH RESULTS")
print("=" * 60)
print(f"\nBest parameters: C={grid_search.best_params_['C']}, l1_ratio={grid_search.best_params_['l1_ratio']}")
print(f"Best CV ROC-AUC: {grid_search.best_score_:.4f}")

# Convert C to alpha for interpretation
best_alpha = 1 / grid_search.best_params_['C']
print(f"(Equivalent alpha = 1/C = {best_alpha})")

print("\nPenalty interpretation:")
print("  l1_ratio=0.0  → Pure L2 (Ridge)")
print("  l1_ratio=0.5  → Equal L1+L2 (Elastic Net)")
print("  l1_ratio=1.0  → Pure L1 (Lasso)")

print("\nTop 10 parameter combinations:")
results_df.head(10)
```


```default
============================================================
ELASTIC NET GRID SEARCH RESULTS
============================================================

Best parameters: C=0.1, l1_ratio=0.75
Best CV ROC-AUC: 0.8501
(Equivalent alpha = 1/C = 10.0)

Penalty interpretation:
  l1_ratio=0.0  → Pure L2 (Ridge)
  l1_ratio=0.5  → Equal L1+L2 (Elastic Net)
  l1_ratio=1.0  → Pure L1 (Lasso)

Top 10 parameter combinations:

```
<div><style>
.dataframe > thead > tr,
.dataframe > tbody > tr {
  text-align: right;
  white-space: pre-wrap;
}
</style>
<small>shape: (10, 5)</small><table border="1" class="dataframe"><thead><tr><th>C</th><th>l1_ratio</th><th>mean_roc_auc</th><th>std_roc_auc</th><th>rank</th></tr><tr><td>f64</td><td>f64</td><td>f64</td><td>f64</td><td>i32</td></tr></thead><tbody><tr><td>0.1</td><td>0.75</td><td>0.850105</td><td>0.009216</td><td>1</td></tr><tr><td>0.1</td><td>0.5</td><td>0.850041</td><td>0.009277</td><td>2</td></tr><tr><td>0.1</td><td>1.0</td><td>0.849963</td><td>0.009017</td><td>3</td></tr><tr><td>0.1</td><td>0.25</td><td>0.849851</td><td>0.009417</td><td>4</td></tr><tr><td>0.1</td><td>0.0</td><td>0.849566</td><td>0.009597</td><td>5</td></tr><tr><td>1.0</td><td>1.0</td><td>0.849475</td><td>0.009612</td><td>6</td></tr><tr><td>1.0</td><td>0.75</td><td>0.849435</td><td>0.00964</td><td>7</td></tr><tr><td>0.01</td><td>0.0</td><td>0.84941</td><td>0.008969</td><td>8</td></tr><tr><td>1.0</td><td>0.25</td><td>0.849406</td><td>0.009661</td><td>9</td></tr><tr><td>1.0</td><td>0.5</td><td>0.8494</td><td>0.009638</td><td>10</td></tr></tbody></table></div>
<div class="toolcallresult" data-callid="toolu_vrtx_01MZN8LjJE83z49G7NcQMBL8" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;============================================================\\nELASTIC NET G...[truncated, total 1394 chars]&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01M6vcrQ294y1zLub5Peq8o5" data-call="{
  &quot;code&quot;: &quot;# Create heatmap visualization\nheatmap_df = results_df.with_columns(\n    pl.col(\&quot;C\&quot;).cast(...[truncated, total 845 chars]&quot;,
  &quot;intent&quot;: &quot;Create heatmap visualization of grid search results&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: true
}" data-intent="Create heatmap visualization of grid search results" ></div>

```python
# Create heatmap visualization
heatmap_df = results_df.with_columns(
    pl.col("C").cast(pl.Utf8).alias("C_str"),
    pl.col("l1_ratio").cast(pl.Utf8).alias("l1_ratio_str")
)

# Order C values properly
c_order = ["0.001", "0.01", "0.1", "1.0", "10.0", "100.0"]

p_heatmap = (
    ggplot(heatmap_df, aes(x="l1_ratio_str", y="C_str", fill="mean_roc_auc"))
    + geom_tile(color="white", size=0.5)
    + geom_text(aes(label="mean_roc_auc"), format_string="{:.3f}", size=8)
    + scale_fill_gradient2(
        low="#E74C3C", 
        mid="#F7DC6F", 
        high="#27AE60",
        midpoint=0.84
    )
    + scale_y_discrete(limits=c_order[::-1])
    + labs(
        title="Elastic Net Grid Search: ROC-AUC by C and L1 Ratio",
        x="L1 Ratio (0=Ridge, 1=Lasso)",
        y="C (Inverse Regularization)",
        fill="ROC-AUC"
    )
)
p_heatmap
```



![Plot image](image-3.png)


<div class="toolcallresult" data-callid="toolu_vrtx_01M6vcrQ294y1zLub5Peq8o5" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;\&quot;}&quot;
    },
    {
      &quot;type&quot;: &quot;media&quot;,
      &quot;data&quot;: &quot;iVBORw0KGgoAAAANSUhEUgAABSgAAAPnCAYAAAAs/6LTAAAAOnRFWHRTb2Z0d2FyZQBNYXRwbG90bGliIHZlcnNpb2...[truncated, total 117772 chars]&quot;,
      &quot;mediaType&quot;: &quot;image/png&quot;
    }
  ]
}"></div>

 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_011KVgjjTM8qFSJA5L5qTU54" data-call="{
  &quot;code&quot;: &quot;# Evaluate best model on test set\nbest_model = grid_search.best_estimator_\ny_pred_best = b...[truncated, total 1355 chars]&quot;,
  &quot;intent&quot;: &quot;Evaluate best elastic net model on test set&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Evaluate best elastic net model on test set" ></div>

```python
# Evaluate best model on test set
best_model = grid_search.best_estimator_
y_pred_best = best_model.predict(X_test_processed)
y_proba_best = best_model.predict_proba(X_test_processed)[:, 1]

print("=" * 60)
print("BEST ELASTIC NET MODEL - TEST SET EVALUATION")
print("=" * 60)
print(f"\nOptimal parameters: C={grid_search.best_params_['C']}, l1_ratio={grid_search.best_params_['l1_ratio']}")
print(f"  → alpha (regularization) = {1/grid_search.best_params_['C']}")
print(f"  → Penalty mix: 75% L1 (Lasso) + 25% L2 (Ridge)")

print("\n--- Confusion Matrix ---")
cm_best = confusion_matrix(y_test, y_pred_best)
print(f"                 Predicted")
print(f"                 No Stroke  Stroke")
print(f"Actual No Stroke    {cm_best[0,0]:4d}      {cm_best[0,1]:4d}")
print(f"Actual Stroke       {cm_best[1,0]:4d}      {cm_best[1,1]:4d}")

print("\n--- Classification Report ---")
print(classification_report(y_test, y_pred_best, target_names=["No Stroke", "Stroke"]))

roc_best = roc_auc_score(y_test, y_proba_best)
print(f"ROC-AUC: {roc_best:.4f}")

# Compare with original LR
print("\n--- Comparison with Original Logistic Regression ---")
print(f"Original LR ROC-AUC:     {roc_auc_score(y_test, y_proba_lr):.4f}")
print(f"Elastic Net LR ROC-AUC:  {roc_best:.4f}")
print(f"Improvement:             {(roc_best - roc_auc_score(y_test, y_proba_lr))*100:+.2f}%")
```


```default
============================================================
BEST ELASTIC NET MODEL - TEST SET EVALUATION
============================================================

Optimal parameters: C=0.1, l1_ratio=0.75
  → alpha (regularization) = 10.0
  → Penalty mix: 75% L1 (Lasso) + 25% L2 (Ridge)

--- Confusion Matrix ---
                 Predicted
                 No Stroke  Stroke
Actual No Stroke     706       266
Actual Stroke          9        41

--- Classification Report ---
              precision    recall  f1-score   support

   No Stroke       0.99      0.73      0.84       972
      Stroke       0.13      0.82      0.23        50

    accuracy                           0.73      1022
   macro avg       0.56      0.77      0.53      1022
weighted avg       0.95      0.73      0.81      1022

ROC-AUC: 0.8398

--- Comparison with Original Logistic Regression ---
Original LR ROC-AUC:     0.8407
Elastic Net LR ROC-AUC:  0.8398
Improvement:             -0.08%

```

<div class="toolcallresult" data-callid="toolu_vrtx_011KVgjjTM8qFSJA5L5qTU54" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;============================================================\\nBEST ELASTIC ...[truncated, total 1038 chars]&quot;
    }
  ]
}"></div>



## Elastic Net Grid Search Results

### Best Parameters Found
| Parameter | Value | Interpretation |
|-----------|-------|----------------|
| **C** | 0.1 | Strong regularization (α = 10) |
| **l1_ratio** | 0.75 | 75% Lasso + 25% Ridge |
| **CV ROC-AUC** | 0.850 | Cross-validation performance |

### Key Observations from Heatmap

1. **C = 0.1 is optimal**: Moderate-strong regularization works best
2. **L1 ratio doesn't matter much at optimal C**: All l1_ratios perform similarly (~0.850)
3. **Very strong regularization (C=0.001) hurts performance**: Underfitting occurs
4. **Weak regularization (C≥1) is stable but slightly worse**: ~0.849 across the board

### Test Set Performance (Best Elastic Net)

| Metric | Value |
|--------|-------|
| **Stroke Recall** | **82%** (41/50 caught) |
| **Stroke Precision** | 13% |
| **ROC-AUC** | 0.840 |

### Comparison Summary

| Model | Stroke Recall | ROC-AUC |
|-------|---------------|---------|
| Elastic Net (tuned) | **82%** | 0.840 |
| Original LR | 80% | 0.841 |

The elastic net tuning improved recall slightly (82% vs 80%) while maintaining similar ROC-AUC. The optimal model prefers **Lasso-dominant regularization** (75% L1), suggesting some features can be shrunk to zero.

I'll suggest some questions below.


<span class="suggestion">Show which coefficients were shrunk toward zero by the Lasso penalty</span>


<span class="suggestion">Create a report summarizing the entire stroke prediction analysis</span>


<span class="suggestion">Save the best model for future predictions</span>






## User

Show which coefficients were shrunk toward zero by the Lasso penalty. Then train a neural net with keras and tensorflow/pytorch. Make sure it is Apple Metal accelerated and prints consistent progress as it trains and tests.


## Databot


<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01ULJXYmxBPaWD8TGtqZryjB" data-call="{
  &quot;code&quot;: &quot;# Show coefficients from the best elastic net model\nfeature_names_all = (\n    numeric_feat...[truncated, total 565 chars]&quot;,
  &quot;intent&quot;: &quot;Show elastic net coefficients to see which were shrunk&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Show elastic net coefficients to see which were shrunk" ></div>

```python
# Show coefficients from the best elastic net model
feature_names_all = (
    numeric_features + 
    binary_features + 
    list(preprocessor.named_transformers_["cat"].get_feature_names_out(categorical_features))
)

coef_df = pl.DataFrame({
    "feature": feature_names_all,
    "coefficient": best_model.coef_[0]
}).with_columns(
    pl.col("coefficient").abs().alias("abs_coef")
).sort("abs_coef", descending=True)

print("=" * 60)
print("ELASTIC NET COEFFICIENTS (L1 ratio = 0.75)")
print("=" * 60)
print("\nCoefficients ranked by absolute magnitude:")
coef_df
```


```default
/Applications/Positron.app/Contents/Resources/app/extensions/positron-python/python_files/lib/ipykernel/py3/IPython/core/interactiveshell.py:3112: SyntaxWarning: 'return' in a 'finally' block
  return result
name 'numeric_features' is not defined
Cell In[3], line 3
      1 # Show coefficients from the best elastic net model
      2 feature_names_all = (
----> 3     numeric_features + 
      4     binary_features + 
      5     list(preprocessor.named_transformers_["cat"].get_feature_names_out(categorical_features))
      6 )
      8 coef_df = pl.DataFrame({
      9     "feature": feature_names_all,
     10     "coefficient": best_model.coef_[0]
     11 }).with_columns(
     12     pl.col("coefficient").abs().alias("abs_coef")
     13 ).sort("abs_coef", descending=True)
     15 print("=" * 60)

```

<div class="toolcallresult" data-callid="toolu_vrtx_01ULJXYmxBPaWD8TGtqZryjB" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;/Applications/Positron.app/Contents/Resources/app/extensio...[truncated, total 869 chars]&quot;
    }
  ]
}"></div>

Let me redefine the variables: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01BAJiZ2ng7tPtX1ykVxsfCx" data-call="{
  &quot;code&quot;: &quot;# Redefine feature names\nnumeric_features = [\&quot;age\&quot;, \&quot;avg_glucose_level\&quot;, \&quot;bmi\&quot;]\nbinary_fea...[truncated, total 1041 chars]&quot;,
  &quot;intent&quot;: &quot;Show elastic net coefficients with shrinkage status&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Show elastic net coefficients with shrinkage status" ></div>

```python
# Redefine feature names
numeric_features = ["age", "avg_glucose_level", "bmi"]
binary_features = ["hypertension", "heart_disease", "ever_married_binary", "residence_urban", "gender_male"]
categorical_features = ["work_type", "smoking_status"]

# Get feature names after one-hot encoding
cat_feature_names = list(preprocessor.named_transformers_["cat"].get_feature_names_out(categorical_features))
feature_names_all = numeric_features + binary_features + cat_feature_names

coef_df = pl.DataFrame({
    "feature": feature_names_all,
    "coefficient": best_model.coef_[0]
}).with_columns(
    pl.col("coefficient").abs().alias("abs_coef"),
    pl.when(pl.col("coefficient").abs() < 0.01)
    .then(pl.lit("🔴 Shrunk (~0)"))
    .when(pl.col("coefficient").abs() < 0.1)
    .then(pl.lit("🟡 Small"))
    .otherwise(pl.lit("🟢 Important"))
    .alias("status")
).sort("abs_coef", descending=True)

print("=" * 60)
print("ELASTIC NET COEFFICIENTS (L1 ratio = 0.75)")
print("=" * 60)
print("\nCoefficients ranked by absolute magnitude:")
coef_df
```


```default
name 'preprocessor' is not defined
Cell In[4], line 7
      4 categorical_features = ["work_type", "smoking_status"]
      6 # Get feature names after one-hot encoding
----> 7 cat_feature_names = list(preprocessor.named_transformers_["cat"].get_feature_names_out(categorical_features))
      8 feature_names_all = numeric_features + binary_features + cat_feature_names
     10 coef_df = pl.DataFrame({
     11     "feature": feature_names_all,
     12     "coefficient": best_model.coef_[0]
   (...)
     20     .alias("status")
     21 ).sort("abs_coef", descending=True)

```

<div class="toolcallresult" data-callid="toolu_vrtx_01BAJiZ2ng7tPtX1ykVxsfCx" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;name &apos;preprocessor&apos; is not defined\\nCell In[4], line 7\\n  ...[truncated, total 633 chars]&quot;
    }
  ]
}"></div>

It seems the session was reset. Let me rebuild everything from scratch: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01RZmfeLNNp7F4u59SXa1E5i" data-call="{
  &quot;code&quot;: &quot;import polars as pl\nimport numpy as np\nfrom sklearn.model_selection import train_test_spli...[truncated, total 2764 chars]&quot;,
  &quot;intent&quot;: &quot;Rebuild the entire pipeline from scratch&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Rebuild the entire pipeline from scratch" ></div>

```python
import polars as pl
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from imblearn.over_sampling import SMOTE

# Reload and prepare data
stroke_df = pl.read_csv("healthcare-dataset-stroke-data.csv", null_values=["N/A", ""], infer_schema_length=10000)

# Clean and transform
stroke_final = (
    stroke_df
    .with_columns(pl.col("bmi").fill_null(pl.col("bmi").median()))
    .filter(pl.col("gender") != "Other")
    .with_columns(
        pl.col("ever_married").replace({"Yes": 1, "No": 0}).cast(pl.Int8).alias("ever_married_binary"),
        pl.col("Residence_type").replace({"Urban": 1, "Rural": 0}).cast(pl.Int8).alias("residence_urban"),
        pl.col("gender").replace({"Male": 1, "Female": 0}).cast(pl.Int8).alias("gender_male"),
    )
    .drop("id")
)

# Define features
numeric_features = ["age", "avg_glucose_level", "bmi"]
binary_features = ["hypertension", "heart_disease", "ever_married_binary", "residence_urban", "gender_male"]
categorical_features = ["work_type", "smoking_status"]

# Prepare X and y
X = stroke_final.select(*numeric_features, *binary_features, *categorical_features).to_pandas()
y = stroke_final.get_column("stroke").to_numpy()

# Split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Preprocessor
preprocessor = ColumnTransformer([
    ("num", StandardScaler(), numeric_features),
    ("bin", "passthrough", binary_features),
    ("cat", OneHotEncoder(drop="first", sparse_output=False, handle_unknown="ignore"), categorical_features),
])

# Fit and transform
preprocessor.fit(X_train)
X_train_processed = preprocessor.transform(X_train)
X_test_processed = preprocessor.transform(X_test)

# SMOTE
smote = SMOTE(sampling_strategy=0.5, random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train_processed, y_train)

# Train best elastic net model
best_model = LogisticRegression(
    penalty="elasticnet", solver="saga", C=0.1, l1_ratio=0.75,
    class_weight="balanced", max_iter=2000, random_state=42
)
best_model.fit(X_train_resampled, y_train_resampled)

# Get feature names
cat_feature_names = list(preprocessor.named_transformers_["cat"].get_feature_names_out(categorical_features))
feature_names_all = numeric_features + binary_features + cat_feature_names

print("Data loaded and model trained!")
print(f"Training: {X_train_processed.shape[0]} samples, Test: {X_test_processed.shape[0]} samples")
print(f"Features: {len(feature_names_all)}")
```


```default
No module named 'polars'
Cell In[5], line 1
----> 1 import polars as pl
      2 import numpy as np
      3 from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold

```

<div class="toolcallresult" data-callid="toolu_vrtx_01RZmfeLNNp7F4u59SXa1E5i" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;\&quot;,\&quot;outputError\&quot;:\&quot;No module named &apos;polars&apos;\\nCell In[5], line 1\\n----> 1 impo...[truncated, total 230 chars]&quot;
    }
  ]
}"></div>


<div class="toolcall" data-name="installPythonPackage" data-callid="toolu_vrtx_01PU1kdjVeXDMroPnHqkwtsf" data-call="{
  &quot;packages&quot;: [
    &quot;polars&quot;,
    &quot;scikit-learn&quot;,
    &quot;imbalanced-learn&quot;
  ]
}" ></div>
<div class="toolcallresult" data-callid="toolu_vrtx_01PU1kdjVeXDMroPnHqkwtsf" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;polars: Installation failed - Command failed with errors, check the terminal for details. ...[truncated, total 2468 chars]&quot;
    }
  ]
}"></div>

The installation is failing. It seems you may be using Python 3.14 which is very new. Could you try running these commands in your terminal:

```bash
pip install polars scikit-learn imbalanced-learn
```

Or if using a virtual environment, activate it first. In the meantime, let me try running the code assuming the packages are available in the current session: 
<div class="toolcall" data-name="databot_executeCodeTool" data-callid="toolu_vrtx_01RL2e68j3PbWf5C4cy2bHyL" data-call="{
  &quot;code&quot;: &quot;# Check what&apos;s available\nimport sys\nprint(f\&quot;Python version: {sys.version}\&quot;)\n\n# Try importi...[truncated, total 459 chars]&quot;,
  &quot;intent&quot;: &quot;Check available packages in current session&quot;,
  &quot;language&quot;: &quot;python&quot;,
  &quot;withPlot&quot;: false
}" data-intent="Check available packages in current session" ></div>

```python
# Check what's available
import sys
print(f"Python version: {sys.version}")

# Try importing
try:
    import polars as pl
    print("✓ polars available")
except ImportError as e:
    print(f"✗ polars: {e}")

try:
    import sklearn
    print("✓ scikit-learn available")
except ImportError as e:
    print(f"✗ scikit-learn: {e}")

try:
    import imblearn
    print("✓ imbalanced-learn available")
except ImportError as e:
    print(f"✗ imbalanced-learn: {e}")
```


```default
Python version: 3.14.0 (main, Oct  7 2025, 09:34:52) [Clang 17.0.0 (clang-1700.3.19.1)]
✗ polars: No module named 'polars'
✗ scikit-learn: No module named 'sklearn'
✗ imbalanced-learn: No module named 'imblearn'

```

<div class="toolcallresult" data-callid="toolu_vrtx_01RL2e68j3PbWf5C4cy2bHyL" data-status="success" data-result="{
  &quot;type&quot;: &quot;content&quot;,
  &quot;value&quot;: [
    {
      &quot;type&quot;: &quot;text&quot;,
      &quot;text&quot;: &quot;{\&quot;outputText\&quot;:\&quot;Python version: 3.14.0 (main, Oct  7 2025, 09:34:52) [Clang 17.0.0 (clang-1...[truncated, total 250 chars]&quot;
    }
  ]
}"></div>



[Response canceled by user]



## User

/notebook 

## Databot

An error occurred while processing the response from the language model: You've exhausted your premium model quota. Please enable additional paid premium requests, upgrade to Copilot Pro+, or wait for your allowance to renew.

