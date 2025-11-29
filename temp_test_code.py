stroke_final = (
    stroke_df
    # Handle missing BMI values - impute with median
    .with_columns(
        pl.col("bmi").fill_null(pl.col("bmi").median())
    )
    # Remove "Other" gender
    .filter(pl.col("gender") != "Other")
    # Convert categorical columns to appropriate types and create binary features
    .with_columns(
        pl.col("ever_married").replace({"Yes": 1, "No": 0}).cast(pl.Int8).alias("ever_married_binary"),
        pl.col("Residence_type").replace({"Urban": 1, "Rural": 0}).cast(pl.Int8).alias("residence_urban"),
        pl.col("gender").replace({"Male": 1, "Female": 0}).cast(pl.Int8).alias("gender_male"),
        pl.col("hypertension").cast(pl.Int8),
        pl.col("heart_disease").cast(pl.Int8),
        pl.col("stroke").cast(pl.Int8),
    )
    # Create age groups
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
    # Drop id column
    .drop("id")
)



print("Cleaned dataset shape:", stroke_final.shape)

print("\nClass distribution:")
print(stroke_final.group_by("stroke").len().sort("stroke"))



# Validation: Check for remaining null values
print("\nMissing values after cleaning:")
print(stroke_final.null_count())



# Export cleaned data
stroke_final.write_csv("stroke_cleaned.csv")
print("\nCleaned data exported to 'stroke_cleaned.csv'")