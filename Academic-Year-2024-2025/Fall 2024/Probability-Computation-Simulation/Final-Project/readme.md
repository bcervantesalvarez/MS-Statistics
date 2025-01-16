## Project Overview

This project explores the impact of different missing data mechanisms on regression analyses. Using simulated data and the **Multiple Imputation by Chained Equations (MICE)** method, the project compares performance under the following mechanisms:

- **MCAR (Missing Completely at Random)**.
- **MAR (Missing at Random)**.
- **MNAR (Missing Not at Random)**.

The analysis includes:
- Coefficient estimates across missingness levels (10%, 30%, 50%, 70%).
- Bias comparisons.
- Standard error assessments.
- Visualizations of imputed data performance.

## Files

- **`order_dataset.csv`**: Input dataset containing variables such as refunds and sales revenue.
- **R Script**: The full script automates data preprocessing, simulation of missing data, imputation, analysis, and visualization.

## Steps to Run

1. Clone the repository or copy the provided script.
2. Place the `order_dataset.csv` in your working directory.
3. Install the required R packages.
4. Run the R script in RStudio or a similar IDE.
5. Generated plots and outputs will display results for various missingness levels.

## Acknowledgments

- **`readr`**: Wickham et al. (2018). For reading and handling CSV files.
- **`dplyr`**: Wickham et al. (2023). For data wrangling.
- **`mice`**: van Buuren & Groothuis-Oudshoorn (2011). For multiple imputation.
- **`broom`**: Robinson (2021). For tidying regression models.
- **`tidyr`**: Wickham (2023). For reshaping and unifying datasets.
- **`ggplot2`**: Wickham (2016). For creating customizable visualizations.
- **`showtext`**: Qiu (2022). For embedding Google fonts into visualizations. 

## Notes

- Ensure the `order_dataset.csv` file has no corrupted entries or missing columns before running the script.
- The output plots are tailored to highlight the performance of imputation under different mechanisms and levels of missingness.