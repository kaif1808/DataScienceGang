import json
import re
import os

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def main():
    # 1. Load resources
    print("Loading files...")
    nb_content = json.loads(read_file('letsgo.ipynb'))
    composite_features_code = read_file('composite_risk_features.py')
    preprocess_code = read_file('preprocess_impute_fold.py')

    # Clean up external code for inline insertion
    # Remove imports that refer to the files themselves
    preprocess_code = preprocess_code.replace('from composite_risk_features import create_composite_risk_features', '')
    
    # 2. Define New Content Blocks

    # Imports
    imports_source = [
        "# 1. Imports & Setup\n",
        "import os\n",
        "import pandas as pd\n",
        "import numpy as np\n",
        "import matplotlib.pyplot as plt\n",
        "import seaborn as sns\n",
        "import polars as pl\n",
        "import torch\n",
        "import torch.nn as nn\n",
        "import torch.optim as optim\n",
        "from torch.utils.data import DataLoader, TensorDataset\n",
        "from tqdm import tqdm\n",
        "import xgboost as xgb\n",
        "\n",
        "from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold, cross_val_predict\n",
        "from sklearn.preprocessing import StandardScaler, OneHotEncoder\n",
        "from sklearn.compose import ColumnTransformer\n",
        "from sklearn.pipeline import Pipeline\n",
        "from sklearn.linear_model import LogisticRegression\n",
        "from sklearn.ensemble import RandomForestClassifier, StackingClassifier\n",
        "from sklearn.svm import SVC\n",
        "from sklearn.neighbors import KNeighborsClassifier\n",
        "from sklearn.naive_bayes import GaussianNB\n",
        "from sklearn.metrics import (\n",
        "    classification_report, confusion_matrix, roc_auc_score, roc_curve, \n",
        "    precision_score, recall_score, f1_score, precision_recall_curve\n",
        ")\n",
        "from sklearn.base import BaseEstimator, TransformerMixin\n",
        "from sklearn.impute import KNNImputer\n",
        "from sklearn.feature_selection import VarianceThreshold\n",
        "\n",
        "from imblearn.over_sampling import SMOTE, RandomOverSampler\n",
        "from imblearn.pipeline import Pipeline as ImbPipeline\n",
        "from imblearn.ensemble import BalancedBaggingClassifier, BalancedRandomForestClassifier\n",
        "\n",
        "# Set random seed\n",
        "np.random.seed(42)\n",
        "torch.manual_seed(42)\n",
        "os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'\n",
        "\n",
        "print(f\"PyTorch Device: {'mps' if torch.backends.mps.is_available() else 'cpu'}\")"
    ]

    # Visualization Helpers
    viz_helpers_source = [
        "# Visualization Helper Functions\n",
        "\n",
        "def plot_categorical_rates(df, cat_vars, target='stroke', hue=None):\n",
        "    '''Plot stroke rates for categorical variables.'''\n",
        "    n_cols = 3\n",
        "    n_rows = (len(cat_vars) + n_cols - 1) // n_cols\n",
        "    fig, axes = plt.subplots(n_rows, n_cols, figsize=(6*n_cols, 6*n_rows))\n",
        "    axes = axes.flatten()\n",
        "    \n",
        "    for i, var in enumerate(cat_vars):\n",
        "        if i >= len(axes): break\n",
        "        ax = axes[i]\n",
        "        \n",
        "        if hue:\n",
        "            # Calculate mean stroke rate by category and hue\n",
        "            stroke_rates = df.groupby([var, hue])[target].mean().reset_index()\n",
        "            sns.barplot(data=stroke_rates, x=var, y=target, hue=hue, ax=ax, palette=\"viridis\")\n",
        "            ax.legend(title=hue, bbox_to_anchor=(1.05, 1), loc='upper left')\n",
        "        else:\n",
        "            stroke_rates = df.groupby(var)[target].mean().reset_index()\n",
        "            sns.barplot(data=stroke_rates, x=var, y=target, hue=var, ax=ax, palette=\"viridis\", legend=False)\n",
        "            \n",
        "        ax.set_title(f\"Stroke Rate by {var.replace('_', ' ').title()}\")\n",
        "        ax.set_ylabel(\"Stroke Rate\")\n",
        "        ax.set_xlabel(\"\")\n",
        "        \n",
        "        # Annotate\n",
        "        for p in ax.patches:\n",
        "            if p.get_height() > 0:\n",
        "                ax.annotate(f\"{p.get_height():.3f}\", \n",
        "                           (p.get_x() + p.get_width() / 2., p.get_height()),\n",
        "                           ha='center', va='center', xytext=(0, 10), textcoords='offset points')\n",
        "\n",
        "    # Hide unused subplots\n",
        "    for j in range(len(cat_vars), len(axes)):\n",
        "        axes[j].set_visible(False)\n",
        "        \n",
        "    plt.tight_layout()\n",
        "    plt.show()\n",
        "\n",
        "def plot_numerical_dist(df, num_vars, target='stroke', hue=None):\n",
        "    '''Plot distribution of numerical variables by target.'''\n",
        "    n_cols = 3\n",
        "    n_rows = (len(num_vars) + n_cols - 1) // n_cols\n",
        "    fig, axes = plt.subplots(n_rows, n_cols, figsize=(6*n_cols, 6*n_rows))\n",
        "    if n_rows == 1 and n_cols > 1: axes = axes.flatten()\n",
        "    elif n_rows == 1 and n_cols == 1: axes = [axes]\n",
        "    else: axes = axes.flatten()\n",
        "    \n",
        "    for i, var in enumerate(num_vars):\n",
        "        if i >= len(axes): break\n",
        "        ax = axes[i]\n",
        "        \n",
        "        sns.boxplot(data=df, x=target, y=var, hue=hue if hue else target, ax=ax, palette=\"Set2\", legend=(hue is not None))\n",
        "        ax.set_title(f\"{var.replace('_', ' ').title()} by Stroke Status\")\n",
        "        \n",
        "    plt.tight_layout()\n",
        "    plt.show()\n",
        "\n",
        "def plot_binned_ratios(df, bin_dict, target='stroke', hue=None):\n",
        "    '''Plot target ratio by binned numerical variables.'''\n",
        "    num_vars = list(bin_dict.keys())\n",
        "    \n",
        "    if hue:\n",
        "        # Create a grid: rows = vars, cols = hue values\n",
        "        hue_vals = df[hue].unique()\n",
        "        fig, axes = plt.subplots(len(num_vars), len(hue_vals), figsize=(6*len(hue_vals), 6*len(num_vars)))\n",
        "        if len(num_vars) == 1: axes = axes.reshape(1, -1)\n",
        "        \n",
        "        for i, var in enumerate(num_vars):\n",
        "            for j, h_val in enumerate(hue_vals):\n",
        "                ax = axes[i, j]\n",
        "                subset = df[df[hue] == h_val].copy()\n",
        "                _plot_single_bin(subset, var, bin_dict[var], ax, target, title_suffix=f\" - {h_val}\")\n",
        "    else:\n",
        "        fig, axes = plt.subplots(1, len(num_vars), figsize=(6*len(num_vars), 6))\n",
        "        if len(num_vars) == 1: axes = [axes]\n",
        "        for i, var in enumerate(num_vars):\n",
        "            _plot_single_bin(df, var, bin_dict[var], axes[i], target)\n",
        "            \n",
        "    plt.tight_layout()\n",
        "    plt.show()\n",
        "\n",
        "def _plot_single_bin(df, var, bins, ax, target, title_suffix=\"\"):\n",
        "    df = df.copy()\n",
        "    df[f'{var}_bin'] = pd.cut(df[var], bins=bins)\n",
        "    \n",
        "    # Calculate ratios\n",
        "    bin_stats = df.groupby(f'{var}_bin', observed=False)[target].agg(lambda x: (x.sum(), (1 - x).sum())).reset_index()\n",
        "    \n",
        "    # Reindex to ensure all bins are present\n",
        "    all_bins = pd.cut([], bins=bins).categories\n",
        "    bin_stats = bin_stats.set_index(f'{var}_bin').reindex(all_bins, fill_value={target: (0, 0)}).reset_index()\n",
        "    \n",
        "    # Calculate ratio safely\n",
        "    bin_stats['ratio'] = bin_stats[target].apply(lambda x: x[0] / x[1] if isinstance(x, tuple) and x[1] > 0 else 0)\n",
        "    \n",
        "    # Labels\n",
        "    bin_stats['label'] = bin_stats[f'{var}_bin'].apply(lambda x: f'{x.left:.1f}-{x.right:.1f}' if x.right < 100 else f'{x.left:.1f}+')\n",
        "    \n",
        "    sns.barplot(data=bin_stats, x='label', y='ratio', ax=ax)\n",
        "    \n",
        "    for bar in ax.patches:\n",
        "        if bar.get_height() > 0:\n",
        "            ax.annotate(f'{bar.get_height():.3f}', (bar.get_x() + bar.get_width() / 2, bar.get_height()), ha='center', va='bottom', fontsize=8)\n",
        "            \n",
        "    ax.set_title(f'Strokes / Non-Strokes Ratio by {var.replace(\"_\", \" \").title()}{title_suffix}')\n",
        "    ax.tick_params(axis='x', rotation=45)\n"
    ]

    # Core Logic
    core_logic_source = [
        "# ---------------------------------------------------------\n",
        "# CORE LOGIC: Feature Engineering & Imputation\n",
        "# ---------------------------------------------------------\n",
        "\n"
    ] + composite_features_code.splitlines(keepends=True) + ["\n", "\n"] + preprocess_code.splitlines(keepends=True)

    # Data Loading
    data_loading_source = [
        "# 2. Data Loading\n",
        "stroke_df = pd.read_csv(\"healthcare-dataset-stroke-data.csv\", na_values=[\"N/A\", \"\"])\n",
        "\n",
        "# Initial Cleaning (Minimal - Pipeline handles most)\n",
        "stroke_df = stroke_df[stroke_df[\"gender\"] != \"Other\"].copy()\n",
        "\n",
        "# Basic mapping for EDA purposes (Pipeline will re-map or handle raw, but we need this for EDA)\n",
        "# Note: We create a copy for EDA to not interfere with the raw data expected by the pipeline if it expects strings\n",
        "# However, looking at the pipeline code, it maps 'Male'/'Female' to 1/0. \n",
        "# If we map here, we must ensure we pass compatible data to the pipeline later.\n",
        "# The pipeline function `preprocess_and_impute_fold` takes `train_df` and `test_df`.\n",
        "# It performs mapping internally. To avoid double mapping issues, we will use a separate dataframe for EDA.\n",
        "\n",
        "eda_df = stroke_df.copy()\n",
        "eda_df[\"gender\"] = eda_df[\"gender\"].map({\"Male\": 1, \"Female\": 0})\n",
        "eda_df[\"ever_married\"] = eda_df[\"ever_married\"].map({\"Yes\": 1, \"No\": 0})\n",
        "eda_df[\"Residence_type\"] = eda_df[\"Residence_type\"].map({\"Urban\": 1, \"Rural\": 0})\n",
        "eda_df[\"smoking_status\"] = eda_df[\"smoking_status\"].fillna(\"Unknown\")\n",
        "eda_df.loc[(eda_df['age'] <= 10) & (eda_df['smoking_status'] == 'Unknown'), 'smoking_status'] = 'never smoked'\n",
        "\n",
        "print(f\"Dataset shape: {stroke_df.shape}\")\n",
        "eda_df.head()"
    ]

    # EDA
    eda_source = [
        "# 3. Exploratory Data Analysis\n",
        "\n",
        "# Categorical Variables\n",
        "cat_vars = [\"gender\", \"hypertension\", \"heart_disease\", \"ever_married\", \"work_type\", \"Residence_type\", \"smoking_status\"]\n",
        "plot_categorical_rates(eda_df, cat_vars)\n",
        "\n",
        "# Numerical Variables\n",
        "num_vars = [\"age\", \"avg_glucose_level\", \"bmi\"]\n",
        "plot_numerical_dist(eda_df, num_vars)\n",
        "\n",
        "# Binned Ratios\n",
        "bins_age = [0, 18, 25, 30, 40, 50, 60, 70, 80, 90, 100]\n",
        "bins_glucose = [0, 80, 90, 100, 110, 126, 150, 200, 300, 500]\n",
        "bins_bmi = [0, 18.5, 20, 23, 25, 27, 30, 35, 40, 50, 60]\n",
        "bin_dict = {\"age\": bins_age, \"avg_glucose_level\": bins_glucose, \"bmi\": bins_bmi}\n",
        "\n",
        "plot_binned_ratios(eda_df, bin_dict)\n",
        "\n",
        "# Analysis by Gender\n",
        "print(\"\\n--- Analysis by Gender ---\\n\")\n",
        "cat_vars_gender = [\"hypertension\", \"heart_disease\", \"ever_married\", \"work_type\", \"Residence_type\", \"smoking_status\"]\n",
        "plot_categorical_rates(eda_df, cat_vars_gender, hue=\"gender\")\n",
        "plot_numerical_dist(eda_df, num_vars, hue=\"gender\")\n"
    ]

    # 3. Construct New Notebook Cells
    new_cells = []

    # Header
    new_cells.append({
        "cell_type": "markdown",
        "metadata": {},
        "source": ["# Stroke Prediction Analysis\n", "\n", "This notebook implements a complete data science workflow for stroke prediction, addressing class imbalance and comparing multiple models including Random Forest, Logistic Regression, XGBoost, and a Neural Network."]
    })

    # Setup
    new_cells.append({
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": imports_source
    })

    new_cells.append({
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": viz_helpers_source
    })

    new_cells.append({
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": core_logic_source
    })

    # Data Loading
    new_cells.append({
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": data_loading_source
    })

    # EDA
    new_cells.append({
        "cell_type": "code",
        "metadata": {},
        "execution_count": None,
        "outputs": [],
        "source": eda_source
    })

    # 4. Extract and Process Existing Cells
    # We need to find:
    # - The "Visualising relationship between missing bmi and stroke" section (keep)
    # - The "Comprehensive Stroke Prediction Model Evaluation Suite" (keep & clean)
    # - The "Modified Comprehensive Imputation Pipeline Comparison Suite" (move to appendix)

    original_cells = nb_content['cells']
    
    # Helper to find cell index by content
    def find_cell_index(cells, content_snippet):
        for i, cell in enumerate(cells):
            source = "".join(cell['source'])
            if content_snippet in source:
                return i
        return -1

    # Find specific sections
    missing_bmi_idx = find_cell_index(original_cells, "Visualising relationship between missing bmi and stroke")
    eval_suite_idx = find_cell_index(original_cells, "Comprehensive Stroke Prediction Model Evaluation Suite")
    imputation_pipeline_idx = find_cell_index(original_cells, "Modified Comprehensive Imputation Pipeline Comparison Suite")

    # Add "Missing BMI" section if found
    if missing_bmi_idx != -1:
        # Assuming this section goes until the next major header or the smoking viz
        # Looking at the file, it seems to be a single cell or a few cells.
        # Let's grab just that cell for now, or check if there are subsequent cells.
        # In the provided text, it looked like one large block, but in JSON it might be split.
        # We'll take the cell at missing_bmi_idx.
        new_cells.append({
            "cell_type": "markdown",
            "metadata": {},
            "source": ["### Missing BMI Analysis"]
        })
        # The cell at missing_bmi_idx in the text view seemed to contain code.
        # Let's check if it's markdown or code.
        cell = original_cells[missing_bmi_idx]
        if cell['cell_type'] == 'markdown':
             new_cells.append(cell)
             # The code likely follows
             if missing_bmi_idx + 1 < len(original_cells):
                 new_cells.append(original_cells[missing_bmi_idx + 1])
        else:
            new_cells.append(cell)

    # Add Model Evaluation Section
    new_cells.append({
        "cell_type": "markdown",
        "metadata": {},
        "source": ["## 4. Model Evaluation"]
    })

    if eval_suite_idx != -1:
        # We want to capture all cells from eval_suite_idx onwards, 
        # BUT excluding the "Modified Comprehensive Imputation Pipeline Comparison Suite" if it appears later (it shouldn't, it was earlier in the file usually).
        # Actually, in the provided text, the Imputation Pipeline (commented out) was BEFORE the Model Evaluation.
        # So we just need to grab from eval_suite_idx to the end.
        
        for i in range(eval_suite_idx, len(original_cells)):
            cell = original_cells[i]
            source = "".join(cell['source'])
            
            # Clean imports
            if "from preprocess_impute_fold import" in source:
                # Replace the import line with a comment or empty string
                new_source = []
                for line in cell['source']:
                    if "from preprocess_impute_fold import" in line:
                        new_source.append("# " + line)
                    else:
                        new_source.append(line)
                cell['source'] = new_source
            
            new_cells.append(cell)

    # Add Appendix
    new_cells.append({
        "cell_type": "markdown",
        "metadata": {},
        "source": ["## Appendix: Reference Code\n", "### Comprehensive Imputation Pipeline Comparison (Archived)"]
    })

    if imputation_pipeline_idx != -1:
        # This is likely a single huge cell or a few cells.
        # In the text view it was lines 956-2600.
        # We'll append this cell.
        new_cells.append(original_cells[imputation_pipeline_idx])

    # 5. Save
    nb_content['cells'] = new_cells
    
    print(f"Saving refactored notebook with {len(new_cells)} cells...")
    with open('letsgo.ipynb', 'w') as f:
        json.dump(nb_content, f, indent=1)
    print("Done.")

if __name__ == "__main__":
    main()