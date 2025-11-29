library(dplyr)
library(ggplot2)

# 1. Filter the data for only the "Unknown" smoking status
data_unknown_only <- data %>%
  filter(smoking_status == "formerly smoked")

# 2. Create the distribution plot
plot_unknown_distribution <- ggplot(data_unknown_only, aes(x = age)) +
  # geom_bar automatically calculates the count (frequency) for each age.
  # width = 1 makes the bars touch, which is good for continuous-like data.
  geom_bar(width = 1, fill = "darkred") +
  labs(
    title = "Distribution of 'Unknown' Smoking Status by Age",
    x = "Age (in years)",
    y = "Frequency (Count of 'Unknown' Status)"
  ) +
  # Use a minimal theme for a clean look
  theme_minimal() +
  # Optional: Improve readability if you have a wide age range
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Display the plot
print(plot_unknown_distribution)