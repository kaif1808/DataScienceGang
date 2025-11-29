import pandas as pd
import numpy as np

def create_composite_risk_features(stroke_df):
    """
    Calculate composite risk interaction features for stroke prediction.

    Parameters:
    stroke_df (pd.DataFrame): Input DataFrame containing stroke data with various columns depending on version.

    Returns:
    pd.DataFrame: Modified DataFrame with added composite risk features where required columns exist.
    """
    # Handle smoking status formats
    smoking_available = all(col in stroke_df.columns for col in ['smoking_current', 'smoking_former', 'smoking_never'])
    if not smoking_available and 'smoking_status' in stroke_df.columns:
        # Encode smoking_status into binary columns
        stroke_df['smoking_never'] = (stroke_df['smoking_status'] == 'never smoked').astype(int)
        stroke_df['smoking_former'] = (stroke_df['smoking_status'] == 'formerly smoked').astype(int)
        stroke_df['smoking_current'] = (stroke_df['smoking_status'] == 'smokes').astype(int)
        smoking_available = True

    # Create interaction features
    # Multiplicative interaction: BMI × Glucose
    required = ['bmi', 'avg_glucose_level']
    if all(col in stroke_df.columns for col in required):
        stroke_df['bmi_glucose_interaction'] = stroke_df['bmi'] * stroke_df['avg_glucose_level']
    else:
        raise ValueError(f"Required columns {required} not found for bmi_glucose_interaction")

    # Multiplicative interaction: BMI × Age
    required = ['bmi', 'age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['bmi_age_interaction'] = stroke_df['bmi'] * stroke_df['age']
    else:
        raise ValueError(f"Required columns {required} not found for bmi_age_interaction")

    # Multiplicative interaction: Glucose × Age
    required = ['avg_glucose_level', 'age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['glucose_age_interaction'] = stroke_df['avg_glucose_level'] * stroke_df['age']
    else:
        raise ValueError(f"Required columns {required} not found for glucose_age_interaction")

    # Triple multiplicative interaction: BMI × Glucose × Age
    required = ['bmi', 'avg_glucose_level', 'age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['bmi_glucose_age_triple'] = stroke_df['bmi'] * stroke_df['avg_glucose_level'] * stroke_df['age']
    else:
        raise ValueError(f"Required columns {required} not found for bmi_glucose_age_triple")

    # BMI to glucose ratio, handling division by zero
    # Ratio: BMI / Glucose (with zero division handled by setting to 0)
    required = ['bmi', 'avg_glucose_level']
    if all(col in stroke_df.columns for col in required):
        stroke_df['bmi_glucose_ratio'] = np.where(stroke_df['avg_glucose_level'] == 0, 0, stroke_df['bmi'] / stroke_df['avg_glucose_level'])
    else:
        raise ValueError(f"Required columns {required} not found for bmi_glucose_ratio")

    # Age-adjusted BMI-glucose interaction, handling division by zero
    # Adjusted interaction: (BMI × Glucose) / Age (with zero division handled by setting to 0)
    required = ['bmi', 'avg_glucose_level', 'age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['age_adjusted_bmi_glucose'] = np.where(stroke_df['age'] == 0, 0, stroke_df['bmi'] * stroke_df['avg_glucose_level'] / stroke_df['age'])
    else:
        raise ValueError(f"Required columns {required} not found for age_adjusted_bmi_glucose")

    # New features from Stroke Risk Factor Literature Review

    # Age_Squared: Captures the non-linear, accelerating nature of stroke risk with age.
    # The physiological degradation of the vascular system is inherently time-dependent, with risk increasing exponentially in the elderly.
    # A ten-year increase in age from 20 to 30 yields negligible marginal increase, whereas from 60 to 70 represents a doubling or tripling of risk.
    # Polynomial transformation penalizes advanced age more heavily in linear models.
    required = ['age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Age_Squared'] = stroke_df['age'] ** 2
    else:
        raise ValueError(f"Required columns {required} not found for Age_Squared")

    # Is_Pediatric: Binary flag for pediatric cases (age < 18).
    # Stroke in this demographic is pathologically distinct from adult stroke, often driven by congenital heart defects, sickle cell disease, or vascular malformations rather than atherosclerosis and hypertension.
    # Including these records without differentiation introduces noise; this flag allows the model to shift baseline probability for this subgroup.
    required = ['age']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Is_Pediatric'] = stroke_df['age'] < 18
    else:
        raise ValueError(f"Required columns {required} not found for Is_Pediatric")

    # Vascular_Score: Aggregate count of circulatory system failures (hypertension + heart_disease).
    # Hypertension and heart disease have cumulative and synergistic impact on stroke risk.
    # The interaction between heart disease and hypertension is particularly lethal, creating a "Double Hit" profile.
    required = ['hypertension', 'heart_disease']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Vascular_Score'] = stroke_df['hypertension'] + stroke_df['heart_disease']
    else:
        raise ValueError(f"Required columns {required} not found for Vascular_Score")

    # Vasculature_Stress: Weights vascular failure by duration (age), calculated as Age × (1 + Vascular_Score).
    # Acts as a proxy for cumulative damage from hemodynamic stress, where duration and severity of hypertension/heart disease amplify risk.
    # A 30-year-old with hypertension has less cumulative damage than an 80-year-old with hypertension.
    required = ['age', 'hypertension', 'heart_disease']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Vasculature_Stress'] = stroke_df['age'] * (1 + stroke_df['Vascular_Score'])
    else:
        raise ValueError(f"Required columns {required} not found for Vasculature_Stress")

    # Log_Glucose: Logarithmic transformation of glucose levels to normalize right-skewed distribution.
    # Glucose levels are naturally right-skewed; most are normal (70-100), with a long tail into uncontrolled diabetes.
    # Log transformation compresses the long tail, reducing leverage of extreme outliers while preserving order, aligning with biological reality of diminishing marginal toxicity at extreme levels.
    required = ['avg_glucose_level']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Log_Glucose'] = np.log(stroke_df['avg_glucose_level'] + 1)
    else:
        raise ValueError(f"Required columns {required} not found for Log_Glucose")

    # Diabesity_Flag: Binary flag for co-occurrence of diabetes and obesity (glucose > 200 AND BMI > 30).
    # "Diabesity" represents a state of massive inflammatory and thrombotic risk from metabolic syndrome.
    # Isolates high-risk phenotype where both hyperglycemia and obesity cluster, allowing model to assign high-risk coefficient without learning thresholding from scratch.
    required = ['avg_glucose_level', 'bmi']
    if all(col in stroke_df.columns for col in required):
        stroke_df['Diabesity_Flag'] = (stroke_df['avg_glucose_level'] > 200) & (stroke_df['bmi'] > 30)
    else:
        raise ValueError(f"Required columns {required} not found for Diabesity_Flag")

    # BMI_Missing_Flag: Binary flag for missing BMI values.
    # Missing BMI is not random noise; it proxies for severity, frailty, or emergency status (e.g., bedridden, unconscious patients).
    # In clinical settings, BMI is often missing because patients cannot be weighed, correlating with poor prognosis and high acuity.
    required = ['bmi']
    if all(col in stroke_df.columns for col in required):
        stroke_df['BMI_Missing_Flag'] = stroke_df['bmi'].isna()
    else:
        raise ValueError(f"Required columns {required} not found for BMI_Missing_Flag")

    # Smoker_Hypertensive: Interaction between current smoking and hypertension.
    # Smoking damages endothelial lining; hypertension pushes blood against damaged lining at high pressure.
    # This combination is statistically more dangerous than the sum of its parts, particularly for identifying younger stroke victims.
    required = ['smoking_current', 'hypertension']
    if smoking_available and all(col in stroke_df.columns for col in required):
        stroke_df['Smoker_Hypertensive'] = stroke_df['smoking_current'] * stroke_df['hypertension']
    else:
        raise ValueError(f"Required columns {required} not found or smoking not available for Smoker_Hypertensive")

    # Smoking_History: Binary flag for any smoking exposure (current or former).
    # Captures cumulative vascular damage from smoking history.
    # Active smokers have highest immediate risk; former smokers carry cumulative damage but reduced acute risk.
    required = ['smoking_current', 'smoking_former']
    if smoking_available and all(col in stroke_df.columns for col in required):
        stroke_df['Smoking_History'] = stroke_df['smoking_current'] | stroke_df['smoking_former']
    else:
        raise ValueError(f"Required columns {required} not found or smoking not available for Smoking_History")

    # History_Completeness: Count of missing/unknown values in key fields (BMI, glucose, age, hypertension, heart_disease, smoking status).
    # High incompleteness correlates with emergency admissions or patients lacking social support, proxying for cognitive decline, isolation, or acuity.
    # Missing data quality as a predictive feature, where "Unknown" smoking or missing BMI signals frailty.
    required = ['bmi', 'avg_glucose_level', 'age', 'hypertension', 'heart_disease']
    if all(col in stroke_df.columns for col in required):
        if smoking_available:
            smoking_unknown = (stroke_df['smoking_current'] == 0) & (stroke_df['smoking_former'] == 0) & (stroke_df['smoking_never'] == 0)
        else:
            smoking_unknown = pd.Series([False] * len(stroke_df))
        stroke_df['History_Completeness'] = stroke_df[required].isna().sum(axis=1) + smoking_unknown.astype(int)
    else:
        raise ValueError(f"Required columns {required} not found for History_Completeness")

    # BMI_Deviation: Absolute deviation from median healthy BMI (22).
    # Captures the J-curve of BMI-related risk, where both underweight (BMI < 18.5) and obese (BMI > 30) are associated with higher mortality.
    # Creates V-shaped feature grouping high-risk tails, superior to linear interpretation where higher BMI is always worse.
    required = ['bmi']
    if all(col in stroke_df.columns for col in required):
        stroke_df['BMI_Deviation'] = np.abs(stroke_df['bmi'] - 22)
    else:
        raise ValueError(f"Required columns {required} not found for BMI_Deviation")

    # Premature_Risk_Flag: Binary flag for individuals under 55 with at least two major risk factors (hypertension, heart disease, smoking, or glucose > 140).
    # Identifies "high-risk young" or early-onset stroke cases, where lifestyle factors accelerate vascular aging.
    # Cases like 39-year-old with hypertension and smoking represent biological age far exceeding chronological age.
    required = ['age', 'hypertension', 'heart_disease', 'avg_glucose_level']
    if all(col in stroke_df.columns for col in required):
        if smoking_available:
            stroke_df['Premature_Risk_Flag'] = (stroke_df['age'] < 55) & ((stroke_df['hypertension'] == 1) | (stroke_df['heart_disease'] == 1) | (stroke_df['smoking_current'] == 1) | (stroke_df['avg_glucose_level'] > 140))
        else:
            stroke_df['Premature_Risk_Flag'] = (stroke_df['age'] < 55) & ((stroke_df['hypertension'] == 1) | (stroke_df['heart_disease'] == 1) | (stroke_df['avg_glucose_level'] > 140))
    else:
        raise ValueError(f"Required columns {required} not found for Premature_Risk_Flag")

    return stroke_df