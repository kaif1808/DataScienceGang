# Helper functions for EDA plotting

def plot_categorical_rates(df, cat_vars, figsize=(18, 18)):
    """
    Plot stroke rates for categorical variables in a grid layout.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns

    n_vars = len(cat_vars)
    n_cols = 3
    n_rows = (n_vars + n_cols - 1) // n_cols  # Ceiling division

    fig, axes = plt.subplots(n_rows, n_cols, figsize=figsize)
    axes = axes.flatten() if n_rows > 1 else [axes] if n_cols == 1 else axes

    for i, var in enumerate(cat_vars):
        ax = axes[i]
        stroke_rates = df.groupby(var)["stroke"].mean().reset_index()
        sns.barplot(data=stroke_rates, x=var, y="stroke", hue=var, ax=ax, palette="viridis", legend=False)
        ax.set_title(f"Stroke Rate by {var.replace('_', ' ').title()}")
        ax.set_ylabel("Stroke Rate")
        ax.set_xlabel("")

        for p in ax.patches:
            ax.annotate(f"{p.get_height():.3f}", (p.get_x() + p.get_width() / 2., p.get_height()),
                        ha='center', va='center', xytext=(0, 10), textcoords='offset points')

    # Hide unused subplots
    for j in range(len(cat_vars), len(axes)):
        axes[j].set_visible(False)

    plt.tight_layout()
    plt.show()


def plot_numerical_boxplots(df, num_vars, figsize=(18, 6)):
    """
    Plot boxplots for numerical variables by stroke status.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns

    fig, axes = plt.subplots(1, len(num_vars), figsize=figsize)
    if len(num_vars) == 1:
        axes = [axes]

    for i, var in enumerate(num_vars):
        sns.boxplot(data=df, x="stroke", y=var, hue="stroke", ax=axes[i], palette="Set2", legend=False)
        axes[i].set_title(f"{var.replace('_', ' ').title()} by Stroke Status")
        axes[i].set_xlabel("Stroke")
        axes[i].set_ylabel(var.replace('_', ' ').title())

        # Annotate means and medians
        for j, status in enumerate([0, 1]):
            subset = df[df["stroke"] == status][var]
            mean_val = subset.mean()
            median_val = subset.median()
            axes[i].annotate(f"Mean: {mean_val:.1f}\nMedian: {median_val:.1f}",
                            xy=(j, mean_val), xytext=(j + 0.1 if j == 0 else j - 0.4, mean_val + 0.05 * (subset.max() - subset.min())),
                            fontsize=9, ha='left' if j == 0 else 'right')

    plt.tight_layout()
    plt.show()


def plot_binned_ratios(df, num_vars, bin_dict, figsize=(18, 6)):
    """
    Plot strokes/non-strokes ratios by binned numerical variables.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns
    import pandas as pd

    fig, axes = plt.subplots(1, len(num_vars), figsize=figsize)

    for i, var in enumerate(num_vars):
        bins = bin_dict[var]
        df[f'{var}_bin'] = pd.cut(df[var], bins=bins)
        bin_stats = df.groupby(f'{var}_bin', observed=False)['stroke'].agg(lambda x: (x.sum(), (1 - x).sum())).reset_index()
        bin_stats['ratio'] = bin_stats['stroke'].apply(lambda x: x[0] / x[1] if x[1] > 0 else 0)
        bin_stats['label'] = bin_stats[f'{var}_bin'].apply(lambda x: f'{x.left:.1f}-{x.right:.1f}' if x.right < 100 else f'{x.left:.1f}+')

        sns.barplot(data=bin_stats, x='label', y='ratio', ax=axes[i])
        for bar in axes[i].patches:
            axes[i].annotate(f'{bar.get_height():.3f}', (bar.get_x() + bar.get_width() / 2, bar.get_height()), ha='center', va='bottom', fontsize=8)

        axes[i].set_title(f'Strokes / Non-Strokes Ratio by {var.replace("_", " ").title()}')
        axes[i].set_xlabel(var.replace("_", " ").title())
        axes[i].set_ylabel('Strokes / Non-Strokes')
        axes[i].tick_params(axis='x', rotation=45)

    plt.tight_layout()
    plt.show()


def plot_categorical_rates_by_gender(df, cat_vars, figsize=(18, 12)):
    """
    Plot stroke rates for categorical variables broken down by gender.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns

    n_vars = len(cat_vars)
    n_cols = 3
    n_rows = (n_vars + n_cols - 1) // n_cols

    fig, axes = plt.subplots(n_rows, n_cols, figsize=figsize)
    axes = axes.flatten()

    for i, var in enumerate(cat_vars):
        ax = axes[i]
        stroke_rates = df.groupby([var, "gender"])["stroke"].mean().reset_index()
        sns.barplot(data=stroke_rates, x=var, y="stroke", hue="gender", ax=ax, palette="viridis")
        ax.set_title(f"Stroke Rate by {var.replace('_', ' ').title()} and Gender")
        ax.set_ylabel("Stroke Rate")
        ax.set_xlabel("")
        ax.legend(title="Gender", bbox_to_anchor=(1.05, 1), loc='upper left')

        for p in ax.patches:
            ax.annotate(f"{p.get_height():.3f}", (p.get_x() + p.get_width() / 2., p.get_height()),
                        ha='center', va='center', xytext=(0, 10), textcoords='offset points')

    # Hide unused subplots
    for j in range(len(cat_vars), len(axes)):
        axes[j].set_visible(False)

    plt.tight_layout()
    plt.show()


def plot_numerical_boxplots_by_gender(df, num_vars, figsize=(18, 6)):
    """
    Plot boxplots for numerical variables by stroke status and gender.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns

    fig, axes = plt.subplots(1, len(num_vars), figsize=figsize)

    for i, var in enumerate(num_vars):
        sns.boxplot(data=df, x="stroke", y=var, hue="gender", ax=axes[i], palette="Set2")
        axes[i].set_title(f"{var.replace('_', ' ').title()} by Stroke Status and Gender")
        axes[i].set_xlabel("Stroke")
        axes[i].set_ylabel(var.replace('_', ' ').title())
        axes[i].legend(title="Gender", bbox_to_anchor=(1.05, 1), loc='upper left')

    plt.tight_layout()
    plt.show()


def plot_binned_ratios_by_gender(df, num_vars, bin_dict, figsize=(12, 18)):
    """
    Plot strokes/non-strokes ratios by binned numerical variables, by gender.
    """
    import matplotlib.pyplot as plt
    import seaborn as sns
    import pandas as pd

    fig, axes = plt.subplots(len(num_vars), 2, figsize=figsize)

    for i, var in enumerate(num_vars):
        for j, gender in enumerate(['Male', 'Female']):
            ax = axes[i, j]
            subset = df[df['gender'] == gender].copy()
            subset[f'{var}_bin'] = pd.cut(subset[var], bins=bin_dict[var])
            bin_stats = subset.groupby(f'{var}_bin', observed=False)['stroke'].agg(lambda x: (x.sum(), (1 - x).sum())).reset_index()

            # Reindex to include empty bins
            all_bins = pd.cut([], bins=bin_dict[var]).categories
            all_bins.name = f'{var}_bin'
            bin_stats = bin_stats.set_index(f'{var}_bin').reindex(all_bins, fill_value={'stroke': (0, 0)}).reset_index()
            bin_stats['ratio'] = bin_stats['stroke'].apply(lambda x: x[0] / x[1] if x[1] > 0 else 0)
            bin_stats['label'] = bin_stats[f'{var}_bin'].apply(lambda x: f'{x.left:.1f}-{x.right:.1f}' if x.right < 100 else f'{x.left:.1f}+')

            sns.barplot(data=bin_stats, x='label', y='ratio', ax=ax)
            for bar in ax.patches:
                ax.annotate(f'{bar.get_height():.3f}', (bar.get_x() + bar.get_width() / 2, bar.get_height()), ha='center', va='bottom', fontsize=8)

            ax.set_title(f'{var.replace("_", " ").title()} - {gender}')
            ax.set_xlabel(var.replace("_", " ").title())
            ax.set_ylabel('Strokes / Non-Strokes')
            ax.tick_params(axis='x', rotation=45)

    plt.tight_layout()
    plt.show()