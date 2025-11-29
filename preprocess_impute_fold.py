import pandas as pd
import numpy as np
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import KNNImputer
from sklearn.preprocessing import StandardScaler
from composite_risk_features import create_composite_risk_features


class StrokeDataImputer(BaseEstimator, TransformerMixin):
    """
    Custom imputer for stroke dataset using the winning Pipeline P1 approach:
    1. Random Forest imputation for smoking status
    2. Create dummy variables for smoking
    3. KNN imputation for BMI

    Designed for use in cross-validation loops.
    """

    def __init__(self, smoking_random_state=42, bmi_n_neighbors=5):
        self.smoking_random_state = smoking_random_state
        self.bmi_n_neighbors = bmi_n_neighbors

        # Initialize imputers
        self.smoking_imputer = None
        self.bmi_imputer = None
        self.bmi_scaler = None

        # Track feature columns
        self.smoking_features = ['gender', 'age', 'hypertension', 'heart_disease',
                                'ever_married', 'Residence_type', 'avg_glucose_level']
        self.bmi_features = ['gender', 'age', 'hypertension', 'heart_disease',
                           'ever_married', 'Residence_type', 'avg_glucose_level',
                           'smoking_never', 'smoking_former', 'smoking_current']

        # Original smoking distribution for reference
        self.original_smoking_dist = None

    def fit(self, X, y=None):
        """
        Fit the imputer on training data.

        Parameters:
        X (pd.DataFrame): Training data with missing values
        y: Ignored, for compatibility

        Returns:
        self
        """
        X = X.copy()

        # Store original smoking distribution
        if 'smoking_status_encoded' in X.columns:
            self.original_smoking_dist = X['smoking_status_encoded'].value_counts(normalize=True).sort_index()

        # Step 1: Fit smoking imputer
        self._fit_smoking_imputer(X)

        # Step 2: Impute smoking on training data
        X = self._impute_smoking(X)

        # Step 3: Create smoking dummies
        X = self._create_smoking_dummies(X)

        # Step 4: Fit BMI imputer
        self._fit_bmi_imputer(X)

        return self

    def transform(self, X):
        """
        Transform data using fitted imputers.

        Parameters:
        X (pd.DataFrame): Data to impute

        Returns:
        pd.DataFrame: Imputed data
        """
        X = X.copy()

        # Step 1: Impute smoking
        X = self._impute_smoking(X)

        # Step 2: Create smoking dummies
        X = self._create_smoking_dummies(X)

        # Step 3: Impute BMI
        X = self._impute_bmi(X)

        return X

    def _fit_smoking_imputer(self, X):
        """Fit Random Forest imputer for smoking status."""
        # Prepare training data for smoking imputation
        train_mask = X['smoking_status_encoded'].notna()
        X_train = X.loc[train_mask, self.smoking_features].copy()

        # Handle BMI missing values in training data
        if X_train['avg_glucose_level'].isna().any():
            X_train['avg_glucose_level'] = X_train['avg_glucose_level'].fillna(X_train['avg_glucose_level'].median())

        y_train = X.loc[train_mask, 'smoking_status_encoded']

        # Fit Random Forest
        self.smoking_imputer = RandomForestClassifier(
            n_estimators=100,
            random_state=self.smoking_random_state,
            class_weight='balanced'
        )
        self.smoking_imputer.fit(X_train, y_train)

    def _impute_smoking(self, X):
        """Impute smoking status using fitted Random Forest."""
        if self.smoking_imputer is None:
            raise ValueError("Imputer not fitted. Call fit() first.")

        # Prepare data for prediction
        X_pred = X[self.smoking_features].copy()

        # Handle missing BMI in prediction data
        if X_pred['avg_glucose_level'].isna().any():
            X_pred['avg_glucose_level'] = X_pred['avg_glucose_level'].fillna(X_pred['avg_glucose_level'].median())

        # Predict missing smoking values
        na_mask = X['smoking_status_encoded'].isna()
        if na_mask.sum() > 0:
            predictions = self.smoking_imputer.predict(X_pred.loc[na_mask])
            X.loc[na_mask, 'smoking_status_encoded'] = predictions

        return X

    def _create_smoking_dummies(self, X):
        """Create dummy variables for smoking status."""
        X['smoking_never'] = (X['smoking_status_encoded'] == 0).astype(int)
        X['smoking_former'] = (X['smoking_status_encoded'] == 1).astype(int)
        X['smoking_current'] = (X['smoking_status_encoded'] == 2).astype(int)
        return X

    def _fit_bmi_imputer(self, X):
        """Fit KNN imputer for BMI."""
        # Prepare training data for BMI imputation
        train_mask = X['bmi'].notna()
        X_train = X.loc[train_mask, self.bmi_features].copy()

        # Scale features
        self.bmi_scaler = StandardScaler()
        X_train_scaled = self.bmi_scaler.fit_transform(X_train)

        # Add BMI column for imputation
        bmi_values = X.loc[train_mask, 'bmi'].values.reshape(-1, 1)
        X_train_full = np.column_stack([X_train_scaled, bmi_values])

        # Fit KNN imputer
        self.bmi_imputer = KNNImputer(n_neighbors=self.bmi_n_neighbors)
        self.bmi_imputer.fit(X_train_full)

    def _impute_bmi(self, X):
        """Impute BMI using fitted KNN imputer."""
        if self.bmi_imputer is None or self.bmi_scaler is None:
            raise ValueError("BMI imputer not fitted. Call fit() first.")

        # Prepare data for imputation
        X_pred = X[self.bmi_features].copy()
        X_pred_scaled = self.bmi_scaler.transform(X_pred)

        # Add placeholder BMI column
        bmi_placeholder = np.full((X_pred.shape[0], 1), np.nan)
        X_pred_full = np.column_stack([X_pred_scaled, bmi_placeholder])

        # Impute
        X_imputed = self.bmi_imputer.transform(X_pred_full)

        # Update BMI column
        X['bmi'] = X_imputed[:, -1]

        return X


def preprocess_and_impute_fold(train_df, test_df):
    """
    Modular, reusable function for preprocessing and imputing stroke data in cross-validation loops.

    Parameters:
    train_df (pd.DataFrame): Training data after initial import
    test_df (pd.DataFrame): Test data after initial import

    Returns:
    tuple: (imputed_train_df, imputed_test_df) with preprocessing, imputation, and composite risk features applied
    """
    # Make copies to avoid modifying original data
    train_processed = train_df.copy()
    test_processed = test_df.copy()

    # 1. Initial preprocessing for both train and test
    for i, df in enumerate([train_processed, test_processed]):
        # Filter out "Other" gender
        df = df[df["gender"] != "Other"].copy()

        # Encode categorical variables
        df["gender"] = df["gender"].map({"Male": 1, "Female": 0})
        df["ever_married"] = df["ever_married"].map({"Yes": 1, "No": 0})
        df["Residence_type"] = df["Residence_type"].map({"Urban": 1, "Rural": 0})

        # Handle smoking_status: encode and replace "Unknown" with NaN
        smoking_encoded = df['smoking_status'].map({
            'never smoked': 0,
            'formerly smoked': 1,
            'smokes': 2,
            'Unknown': np.nan
        })
        df['smoking_status_encoded'] = smoking_encoded

        # Cast numeric columns
        df['age'] = df['age'].astype(float)
        df['bmi'] = df['bmi'].astype(float)
        df['stroke'] = df['stroke'].astype(int)
        df['hypertension'] = df['hypertension'].astype(int)
        df['heart_disease'] = df['heart_disease'].astype(int)
        # BMI Missing Flag
        df['BMI_Missing_Flag'] = df['bmi'].isna()

        # Update the list
        if i == 0:
            train_processed = df
        else:
            test_processed = df

    # 2. Fit imputer on training data
    imputer = StrokeDataImputer()
    imputer.fit(train_processed)

    # 3. Transform both train and test data
    imputed_train_df = imputer.transform(train_processed)
    imputed_test_df = imputer.transform(test_processed)

    # 4. Add composite risk features to both
    imputed_train_df = create_composite_risk_features(imputed_train_df)
    imputed_test_df = create_composite_risk_features(imputed_test_df)
    #I want to drop 'id' and 'smoking_status_encoded' columns after creating composite features
    imputed_train_df = imputed_train_df.drop(['id', 'smoking_status_encoded'], axis=1, errors='ignore')
    imputed_test_df = imputed_test_df.drop(['id', 'smoking_status_encoded'], axis=1, errors='ignore')
    return imputed_train_df, imputed_test_df