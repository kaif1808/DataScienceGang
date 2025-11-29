import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load the data
df = pd.read_csv('healthcare-dataset-stroke-data.csv')

# Replace 'N/A' with NaN
df.replace('N/A', pd.NA, inplace=True)

# Convert columns to appropriate types
df['age'] = pd.to_numeric(df['age'], errors='coerce')
df['bmi'] = pd.to_numeric(df['bmi'], errors='coerce')
df['stroke'] = pd.to_numeric(df['stroke'], errors='coerce')

# Check for NA values in bmi and age columns
print("NA values in bmi:", df['bmi'].isna().sum())
print("NA values in age:", df['age'].isna().sum())

# Create bmi_na column
df['bmi_na'] = df['bmi'].isna()

# 1. Bar plot of stroke rate for bmi NA vs not NA
stroke_rate_bmi = df.groupby('bmi_na')['stroke'].mean()
plt.figure(figsize=(8, 6))
stroke_rate_bmi.plot(kind='bar', color=['blue', 'orange'])
plt.title('Stroke Rate by BMI NA Status')
plt.xlabel('BMI is NA')
plt.ylabel('Mean Stroke Rate')
plt.xticks([0, 1], ['BMI Not NA', 'BMI NA'], rotation=0)
plt.show()

# 2. Bar plot of stroke rate by age groups and bmi NA
# Define age groups
bins = [0, 40, 60, 100]
labels = ['<40', '40-60', '>60']
df['age_group'] = pd.cut(df['age'], bins=bins, labels=labels, right=False)

# Group by age_group and bmi_na
stroke_rate_age_bmi = df.groupby(['age_group', 'bmi_na'])['stroke'].mean().unstack()

plt.figure(figsize=(10, 6))
stroke_rate_age_bmi.plot(kind='bar', figsize=(10, 6))
plt.title('Stroke Rate by Age Group and BMI NA Status')
plt.xlabel('Age Group')
plt.ylabel('Mean Stroke Rate')
plt.legend(['BMI Not NA', 'BMI NA'])
plt.show()

# 3. Additional graph: Distribution of age for stroke vs no stroke, colored by bmi NA
plt.figure(figsize=(10, 6))
sns.histplot(data=df, x='age', hue='stroke', multiple='stack', bins=30, alpha=0.7)
plt.title('Age Distribution by Stroke Status')
plt.xlabel('Age')
plt.ylabel('Count')
plt.show()

# Another graph: Boxplot of bmi by stroke status
plt.figure(figsize=(8, 6))
sns.boxplot(data=df, x='stroke', y='bmi')
plt.title('BMI Distribution by Stroke Status')
plt.xlabel('Stroke')
plt.ylabel('BMI')
plt.xticks([0, 1], ['No Stroke', 'Stroke'])
plt.show()