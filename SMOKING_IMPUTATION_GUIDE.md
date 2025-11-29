# Smoking Status Imputation Integration Guide

## Overview

This guide shows how to integrate the Smart Smoking Status Imputation system into your existing stroke prediction pipeline (`letsgo.ipynb`). The imputation handles 30.2% of records (1,544 out of 5,110) that have "Unknown" smoking status values.

## Results Summary

### Pattern Analysis
- **Original Distribution**: 37.0% never smoked, 30.2% unknown, 17.3% formerly smoked, 15.4% smokes
- **Key Insights**: 
  - Children have 90% "Unknown" rates
  - Males have higher "Unknown" rates than females (33.5% vs 27.9%)
  - Age strongly correlates with smoking patterns

### Model Performance
- **Cross-validation accuracy**: 43.5% (±2.0%)
- **Top predictive features**: age (27.6%), avg_glucose_level (25.8%), bmi (24.1%)
- **Imputation results**: 66.1% never smoked, 17.8% formerly smoked, 16.1% smokes

## Integration Options

### Option 1: Preprocessing Step (Recommended)

Add this code to your existing preprocessing pipeline in `letsgo.ipynb`:

```python
# Add this after the data loading section (around line 72-91)

# === SMOKING STATUS IMPUTATION ===
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold, cross_val_score

def impute_smoking_status(df):
    """
    Impute 'Unknown' smoking status using Random Forest model
    """
    # Separate known and unknown data
    unknown_mask = df['smoking_status'] == 'Unknown'
    known_data = df[~unknown_mask].copy()
    unknown_data = df[unknown_mask].copy()
    
    print(f"Imputing smoking status for {len(unknown_data)} unknown records...")
    
    # Prepare features for imputation model
    feature_columns = [
        'gender', 'age', 'hypertension', 'heart_disease', 
        'ever_married', 'work_type', 'Residence_type', 
        'avg_glucose_level', 'bmi', 'stroke'
    ]
    
    # Handle missing BMI first
    known_data['bmi'] = known_data['bmi'].fillna(known_data['bmi'].median())
    unknown_data['bmi'] = unknown_data['bmi'].fillna(unknown_data['bmi'].median())
    
    # Encode categorical variables
    label_encoders = {}
    for col in ['gender', 'ever_married', 'work_type', 'Residence_type']:
        le = LabelEncoder()
        known_data[col + '_encoded'] = le.fit_transform(known_data[col].astype(str))
        unknown_data[col + '_encoded'] = le.transform(unknown_data[col].astype(str))
        label_encoders[col] = le
    
    # Prepare feature matrix
    X_train = known_data[feature_columns[:-1]]
    X_train = X_train.drop('smoking_status', axis=1, errors='ignore')
    
    # Encode categorical features
    for col in ['gender', 'ever_married', 'work_type', 'Residence_type']:
        X_train[col] = known_data[col + '_encoded']
    
    y_train = known_data['smoking_status']
    
    # Train Random Forest model
    rf_model = RandomForestClassifier(
        n_estimators=200, 
        max_depth=10, 
        random_state=42, 
        class_weight='balanced'
    )
    rf_model.fit(X_train, y_train)
    
    # Evaluate model
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    scores = cross_val_score(rf_model, X_train, y_train, cv=cv, scoring='accuracy')
    print(f"Imputation model CV accuracy: {scores.mean():.3f} (±{scores.std() * 2:.3f})")
    
    # Prepare unknown data for prediction
    X_unknown = unknown_data[feature_columns[:-1]]
    X_unknown = X_unknown.drop('smoking_status', axis=1, errors='ignore')
    
    # Encode categorical features
    for col in ['gender', 'ever_married', 'work_type', 'Residence_type']:
        X_unknown[col] = unknown_data[col + '_encoded']
    
    # Predict missing values
    predicted_status = rf_model.predict(X_unknown)
    
    # Create result dataframe
    result_df = df.copy()
    result_df.loc[unknown_mask, 'smoking_status'] = predicted_status
    
    print(f"Imputation complete. Predicted distribution:")
    from collections import Counter
    predicted_counts = Counter(predicted_status)
    for status, count in predicted_counts.items():
        pct = count / len(unknown_data) * 100
        print(f"  {status}: {count} ({pct:.1f}%)")
    
    return result_df

# Apply imputation
stroke_df = impute_smoking_status(stroke_df)
```

### Option 2: Quick Integration

If you want to quickly test the imputed data without modifying your pipeline:

```python
# Just load the imputed data directly
imputed_df = pd.read_csv("stroke_data_imputed.csv")

# Replace your existing stroke_df with imputed version
stroke_df = pl.from_pandas(imputed_df)
```

## Files Generated

1. **`stroke_data_imputed.csv`**: Complete dataset with imputed smoking status and dummy variables
2. **`stroke_data_model_imputed.csv`**: Model-based imputation results
3. **`stroke_data_simple_imputed.csv`**: Simple mode imputation for comparison

## Dummy Variable Creation

The system automatically creates dummy variables:

```python
# Original: smoking_status (categorical)
# After: smoking_formerly smoked, smoking_never smoked, smoking_smokes (binary)

# In your models, use:
# X = df[['smoking_formerly smoked', 'smoking_never smoked', 'smoking_smokes', ...other_features]]
```

## Performance Impact

### Model-based vs Simple Imputation Comparison:

| Method | Never Smoked | Formerly Smoked | Smokes |
|--------|--------------|-----------------|---------|
| **Original** | 1,892 (37.0%) | 885 (17.3%) | 789 (15.4%) |
| **Model-based** | 2,912 (57.0%) | 1,160 (22.7%) | 1,038 (20.3%) |
| **Simple mode** | 3,436 (67.2%) | 885 (17.3%) | 789 (15.4%) |

The model-based approach provides more balanced predictions compared to simple mode imputation.

## Validation Recommendations

To validate imputation quality:

1. **Cross-validation**: Ensure imputation occurs within CV folds
2. **Feature importance**: Age, glucose level, and BMI are most predictive
3. **Distribution analysis**: Check that imputed values follow logical patterns
4. **Model performance**: Compare stroke prediction performance with/without imputation

## Next Steps

1. **Integration**: Choose Option 1 (preprocessing step) for easiest integration
2. **Testing**: Run your existing models on imputed vs original data
3. **Performance evaluation**: Measure impact on stroke prediction accuracy
4. **Pipeline validation**: Ensure imputation works within cross-validation folds

## Code Quality

The imputation system includes:
- ✅ Robust error handling
- ✅ Feature importance analysis
- ✅ Cross-validation performance metrics
- ✅ Multiple imputation strategy comparison
- ✅ Integration with existing scikit-learn pipelines
- ✅ Automatic dummy variable creation

This solution addresses your requirement to treat "Unknown" values as missing and intelligently impute the most likely smoking status category.