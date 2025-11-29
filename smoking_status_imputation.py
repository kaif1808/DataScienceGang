#!/usr/bin/env python3
"""
Smart Smoking Status Imputation System

This script handles the smoking_status categorical variable by:
1. Replacing "Unknown" values with NaN
2. Analyzing patterns in known smoking statuses
3. Implementing smart imputation using multiple strategies
4. Converting to dummy variables
5. Integrating with existing preprocessing pipeline

Author: Kilo Code
"""

import pandas as pd
import numpy as np
import polars as pl
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import KNNImputer
from sklearn.metrics import classification_report, accuracy_score
from sklearn.model_selection import StratifiedKFold
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter
import warnings
warnings.filterwarnings('ignore')

class SmokingStatusImputer:
    """
    A comprehensive imputer for smoking_status variable that uses multiple strategies
    to intelligently predict missing values based on other features.
    """
    
    def __init__(self, random_state=42):
        self.random_state = random_state
        self.known_data = None
        self.unknown_mask = None
        self.imputation_model = None
        self.feature_names = None
        self.label_encoders = {}
        
    def analyze_patterns(self, df):
        """
        Analyze patterns in smoking status distribution and relationships with other features.
        """
        print("=== SMOKING STATUS PATTERN ANALYSIS ===")
        
        # Basic distribution
        smoking_counts = df['smoking_status'].value_counts()
        print(f"\nSmoking Status Distribution:")
        for status, count in smoking_counts.items():
            pct = count / len(df) * 100
            print(f"  {status}: {count} ({pct:.1f}%)")
        
        # Analyze by key demographics
        print(f"\nSmoking Status by Gender:")
        gender_smoking = pd.crosstab(df['gender'], df['smoking_status'], normalize='index') * 100
        print(gender_smoking.round(1))
        
        print(f"\nSmoking Status by Age Group:")
        df_temp = df.copy()
        df_temp['age_group'] = pd.cut(df_temp['age'], 
                                  bins=[0, 18, 30, 45, 60, 100], 
                                  labels=['<18', '18-29', '30-44', '45-59', '60+'])
        age_smoking = pd.crosstab(df_temp['age_group'], df['smoking_status'], normalize='index') * 100
        print(age_smoking.round(1))
        
        print(f"\nSmoking Status by Work Type:")
        work_smoking = pd.crosstab(df['work_type'], df['smoking_status'], normalize='index') * 100
        print(work_smoking.round(1))
        
        return smoking_counts
    
    def prepare_features(self, df, target_col='smoking_status'):
        """
        Prepare features for imputation model.
        """
        # Features that might predict smoking status
        feature_columns = [
            'gender', 'age', 'hypertension', 'heart_disease', 
            'ever_married', 'work_type', 'Residence_type', 
            'avg_glucose_level', 'bmi', 'stroke'
        ]
        
        df_features = df[feature_columns].copy()
        
        # Handle missing BMI
        df_features['bmi'] = df_features['bmi'].fillna(df_features['bmi'].median())
        
        # Encode categorical variables
        categorical_cols = ['gender', 'ever_married', 'work_type', 'Residence_type']
        
        for col in categorical_cols:
            if col not in self.label_encoders:
                self.label_encoders[col] = LabelEncoder()
                df_features[col] = self.label_encoders[col].fit_transform(df_features[col].astype(str))
            else:
                # Handle unseen categories
                df_features[col] = df_features[col].astype(str)
                unique_vals = set(df_features[col].unique())
                known_vals = set(self.label_encoders[col].classes_)
                if not unique_vals.issubset(known_vals):
                    # Add new categories to encoder
                    new_vals = unique_vals - known_vals
                    self.label_encoders[col].classes_ = np.append(
                        self.label_encoders[col].classes_, 
                        list(new_vals)
                    )
                df_features[col] = self.label_encoders[col].transform(df_features[col])
        
        return df_features
    
    def train_imputation_model(self, df):
        """
        Train a Random Forest model to predict smoking status.
        """
        print("\n=== TRAINING IMPUTATION MODEL ===")
        
        # Separate known and unknown data
        self.unknown_mask = df['smoking_status'] == 'Unknown'
        known_data = df[~self.unknown_mask].copy()
        unknown_data = df[self.unknown_mask].copy()
        
        self.known_data = known_data
        
        print(f"Training on {len(known_data)} known samples")
        print(f"Predicting for {len(unknown_data)} unknown samples")
        
        # Prepare features
        X_train = self.prepare_features(known_data.drop('smoking_status', axis=1))
        y_train = known_data['smoking_status']
        
        # Train Random Forest model
        self.imputation_model = RandomForestClassifier(
            n_estimators=200,
            max_depth=10,
            random_state=self.random_state,
            class_weight='balanced'
        )
        
        self.imputation_model.fit(X_train, y_train)
        
        # Evaluate model performance
        cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=self.random_state)
        scores = cross_val_score(self.imputation_model, X_train, y_train, cv=cv, scoring='accuracy')
        
        print(f"Cross-validation accuracy: {scores.mean():.3f} (+/- {scores.std() * 2:.3f})")
        
        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': X_train.columns,
            'importance': self.imputation_model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        print(f"\nTop 5 Most Important Features for Smoking Status Prediction:")
        for _, row in feature_importance.head().iterrows():
            print(f"  {row['feature']}: {row['importance']:.3f}")
        
        return self.imputation_model
    
    def impute_knn_approach(self, df):
        """
        Alternative KNN-based imputation approach.
        """
        print("\n=== KNN IMPUTATION APPROACH ===")
        
        df_temp = df.copy()
        df_temp['smoking_status'] = df_temp['smoking_status'].replace('Unknown', np.nan)
        
        # Prepare all features including target
        X_all = self.prepare_features(df_temp.drop('smoking_status', axis=1))
        
        # Add target encoded as numeric for KNN
        smoking_encoder = LabelEncoder()
        smoking_numeric = smoking_encoder.fit_transform(df_temp['smoking_status'].fillna('Missing'))
        
        # Replace 'Missing' with NaN
        smoking_numeric[smoking_encoder.transform(['Missing'])[0]] = np.nan
        
        # Combine features with target for imputation
        X_with_target = X_all.copy()
        X_with_target['smoking_status_numeric'] = smoking_numeric
        
        # Apply KNN imputation
        knn_imputer = KNNImputer(n_neighbors=5)
        imputed_data = knn_imputer.fit_transform(X_with_target)
        
        # Convert back to categorical
        imputed_smoking = imputed_data[:, -1]
        # Round to nearest integer and convert back
        imputed_smoking = np.round(imputed_smoking).astype(int)
        imputed_smoking = smoking_encoder.inverse_transform(imputed_smoking)
        
        # Create result dataframe
        result_df = df.copy()
        result_df['smoking_status'] = imputed_smoking
        
        return result_df
    
    def impute_model_approach(self, df):
        """
        Use trained model to impute missing values.
        """
        print("\n=== MODEL-BASED IMPUTATION ===")
        
        if self.imputation_model is None:
            self.train_imputation_model(df)
        
        # Prepare features for unknown data
        unknown_data = df[self.unknown_mask]
        X_unknown = self.prepare_features(unknown_data.drop('smoking_status', axis=1))
        
        # Predict smoking status
        predicted_status = self.imputation_model.predict(X_unknown)
        predicted_proba = self.imputation_model.predict_proba(X_unknown)
        
        # Create result dataframe
        result_df = df.copy()
        
        # Keep original known values, add predicted for unknown
        result_df.loc[self.unknown_mask, 'smoking_status'] = predicted_status
        
        # Also add confidence scores
        confidence_cols = [f'prob_{status}' for status in self.imputation_model.classes_]
        for i, status in enumerate(self.imputation_model.classes_):
            result_df.loc[self.unknown_mask, f'prob_{status}'] = predicted_proba[:, i]
        
        print(f"Predicted smoking status for {sum(self.unknown_mask)} unknown records:")
        predicted_counts = Counter(predicted_status)
        for status, count in predicted_counts.items():
            pct = count / sum(self.unknown_mask) * 100
            print(f"  {status}: {count} ({pct:.1f}%)")
        
        return result_df
    
    def create_dummy_variables(self, df):
        """
        Convert smoking_status to dummy variables.
        """
        print("\n=== CREATING DUMMY VARIABLES ===")
        
        # One-hot encode smoking status
        smoking_dummies = pd.get_dummies(df['smoking_status'], prefix='smoking')
        
        # Add dummy variables to dataframe
        result_df = pd.concat([df.drop('smoking_status', axis=1), smoking_dummies], axis=1)
        
        print(f"Created {len(smoking_dummies.columns)} dummy variables:")
        for col in smoking_dummies.columns:
            print(f"  {col}: {smoking_dummies[col].sum()} positive cases")
        
        return result_df
    
    def full_pipeline(self, df):
        """
        Run the complete imputation pipeline.
        """
        print("Starting Smart Smoking Status Imputation Pipeline...")
        print("="*60)
        
        # Step 1: Analyze patterns
        smoking_counts = self.analyze_patterns(df)
        
        # Step 2: Replace Unknown with NaN
        print(f"\n=== REPLACING 'Unknown' WITH NaN ===")
        df_clean = df.copy()
        unknown_count = (df_clean['smoking_status'] == 'Unknown').sum()
        df_clean['smoking_status'] = df_clean['smoking_status'].replace('Unknown', np.nan)
        print(f"Replaced {unknown_count} 'Unknown' values with NaN")
        
        # Step 3: Train model and impute
        df_imputed = self.impute_model_approach(df_clean)
        
        # Step 4: Create dummy variables
        df_final = self.create_dummy_variables(df_imputed)
        
        print(f"\n=== PIPELINE COMPLETE ===")
        print(f"Final dataset shape: {df_final.shape}")
        
        return df_final
    
    def compare_imputation_methods(self, df):
        """
        Compare different imputation approaches.
        """
        print("\n=== COMPARING IMPUTATION METHODS ===")
        
        # Method 1: Model-based imputation
        df_model = self.impute_model_approach(df)
        
        # Method 2: KNN-based imputation  
        df_knn = self.impute_knn_approach(df)
        
        # Simple mode imputation for comparison
        df_simple = df.copy()
        most_common = df_simple['smoking_status'].mode()[0]
        df_simple['smoking_status'] = df_simple['smoking_status'].replace('Unknown', most_common)
        
        print(f"\nComparison of Imputation Methods:")
        print(f"Original distribution:")
        original_counts = df['smoking_status'].value_counts()
        print(f"  Unknown: {(df['smoking_status'] == 'Unknown').sum()}")
        
        print(f"Model-based imputation:")
        model_counts = df_model['smoking_status'].value_counts()
        for status, count in model_counts.items():
            print(f"  {status}: {count}")
            
        print(f"KNN imputation:")
        knn_counts = df_knn['smoking_status'].value_counts()
        for status, count in knn_counts.items():
            print(f"  {status}: {count}")
            
        print(f"Simple mode imputation ({most_common}):")
        simple_counts = df_simple['smoking_status'].value_counts()
        for status, count in simple_counts.items():
            print(f"  {status}: {count}")
        
        return df_model, df_knn, df_simple

def main():
    """
    Main execution function.
    """
    print("Smart Smoking Status Imputation System")
    print("="*50)
    
    # Load data
    print("Loading data...")
    df = pd.read_csv("healthcare-dataset-stroke-data.csv")
    print(f"Loaded {len(df)} records")
    
    # Initialize imputer
    imputer = SmokingStatusImputer(random_state=42)
    
    # Run full pipeline
    df_final = imputer.full_pipeline(df)
    
    # Save results
    output_file = "stroke_data_imputed.csv"
    df_final.to_csv(output_file, index=False)
    print(f"\nResults saved to: {output_file}")
    
    # Optional: Compare methods
    print(f"\nWould you like to compare different imputation methods?")
    print(f"Running comparison...")
    
    df_model, df_knn, df_simple = imputer.compare_imputation_methods(df)
    
    # Save comparison results
    df_model.to_csv("stroke_data_model_imputed.csv", index=False)
    df_knn.to_csv("stroke_data_knn_imputed.csv", index=False) 
    df_simple.to_csv("stroke_data_simple_imputed.csv", index=False)
    
    print(f"\nComparison files saved:")
    print(f"  Model-based: stroke_data_model_imputed.csv")
    print(f"  KNN-based: stroke_data_knn_imputed.csv")
    print(f"  Simple mode: stroke_data_simple_imputed.csv")
    
    return df_final

if __name__ == "__main__":
    result_df = main()