# Statistical Analysis of Bank Customer Data — Engagement and Activity

> Course project for **Statistical Data Analysis** (*Análisis Estadístico de Datos*, 2026-2), Applied Mathematics and Computer Science (MACC), Universidad del Rosario, Bogotá.
> Author: **Samuel Hernando Flores Villarreal**.
> Report and slides are written in Spanish; this README documents everything in English.

## TL;DR

Using a dataset of **1,000,050 bank customers**, we asked whether customer characteristics (age, salary, engagement score, city, gender, subscription tier) help explain or predict whether a customer is **active** (`Is_Active`).

**Answer: no.** The main hypothesis (H₁: some characteristic is associated with activity) is **not supported**. Every effect is statistically and practically negligible, and a classifier built on all variables performs no better than a coin flip (AUC = 0.501). The data behave like **independent, simulated variables**, which is itself a useful finding: with n ≈ 10⁶, even trivial effects would normally reach significance, so a clean null at this scale is informative rather than a failure of the analysis.

| Item | Result |
|---|---|
| Rows / complete cases | 1,000,050 / 771,145 (77.1 %) |
| Active customers | 69.9 % (69.8 %–70.2 % in every subgroup) |
| Largest association (Cramér's V, categorical vs. activity) | 0.0029 |
| Largest standardized difference (Cohen's d) | 0.0042 (salary, p = 0.061; Holm-adjusted 0.727) |
| Largest correlation (\|r\|) | 0.0012 |
| ANOVA effect size (η², max) | 0.000009 |
| Linear regression R² (engagement) | ≈ 0.002 % |
| Logistic regression LRT | χ² = 15.90, df = 14, p = 0.320 |
| McFadden / Nagelkerke pseudo-R² | 0.00002 / 0.00003 |
| OR for engagement (per unit) | 1.002 [0.999, 1.005], p = 0.245 |
| Out-of-sample AUC (70/30 split) | **0.501** (Random Forest: 0.4996) |
| Accuracy vs. majority baseline | 49.4 % vs. 69.9 % |

## 1. Research question and hypotheses

- **Question.** Is customer activity (`Is_Active`) associated with, or predictable from, demographic and behavioral variables?
- **H₀.** Activity is independent of age, salary, engagement, city, gender and tier.
- **H₁.** At least one characteristic is associated with activity.
- **Decision rule.** α = 0.05, with Holm correction for multiple comparisons; effect sizes are reported alongside p-values because with n ≈ 10⁶ p-values alone are misleading.

## 2. Data

- **Source:** Kaggle, [`sandippandey123/bank-data`](https://www.kaggle.com/datasets/sandippandey123/bank-data) (`bank_data.csv`, ~51 MB, not redistributed here — download it from Kaggle).
- **Size:** 1,000,050 rows; 0 duplicate IDs (954 duplicate rows if the ID is ignored).
- **Variables used:** `Age`, `Salary`, `Engagement_Score`, `City`, `Gender`, `Subscription_Tier`, `Is_Active`.
- **Missingness:** Age 2 %, Salary 5 %, Engagement 8 %, City 10 %. Missingness is unrelated to activity (all p ≥ 0.435), so complete-case analysis is defensible; imputation was run as a sensitivity check.
- **Distributions:** age mean 48.5 (SD 17.9); salary mean ≈ 90,000 (SD ≈ 34,600), essentially **uniform** (kurtosis 1.80); engagement mean 60.0 (SD 15.0), essentially **normal** (kurtosis 3.00). Engagement values outside [0, 100] (25 below 0, 3,549 above 100) match what a N(60, 15²) generator would produce (≈ 3,580 expected), another hint of synthetic data.
- **Cleaned dataset:** [`data/bank_data_definitiva.csv.gz`](data/bank_data_definitiva.csv.gz) (the course deliverable, gzip-compressed from 89 MB to 18 MB). Load it directly in R with `readr::read_csv("data/bank_data_definitiva.csv.gz")`.

## 3. Methods

All methods come from the course syllabus and are implemented in R.

1. **Data quality & description** — missingness audit, duplicates, ranges, histograms, boxplots, QQ-plots, skewness/kurtosis, Shapiro–Wilk (on subsamples, n = 5,000).
2. **Bivariate tests** — χ² test + Cramér's V (categorical × activity); Welch t-test + Cohen's d (numeric × activity); Pearson and Spearman correlations; Holm adjustment across families of tests.
3. **ANOVA** — one-way and two-way ANOVA with interaction, Tukey HSD post-hoc, Kruskal–Wallis as non-parametric check, Levene and Bartlett for variance homogeneity.
4. **Multiple linear regression** (engagement as response) — with full diagnostics: Breusch–Pagan, Durbin–Watson, RESET, GVIF, Cook's distance, residual QQ/histograms.
5. **Logistic regression** (activity as response) — likelihood-ratio test, odds ratios with CIs, McFadden/Nagelkerke pseudo-R², 70/30 hold-out, ROC/AUC, calibration curve, linearity of the logit.
6. **Sensitivity analyses** — untruncated engagement, imputed data; the OR for engagement is 1.002 in every variant.
7. **Random Forest** (100k-row subsample) as a non-linear benchmark: AUC 0.4996.

Assumption checks: Levene p = 0.452, Bartlett p = 0.367, Breusch–Pagan p = 0.331, Durbin–Watson = 2.003, RESET p = 0.294, GVIF = 1.000, logit linearity p = 0.872, max Cook's distance 0.00009. Shapiro–Wilk rejects exact normality (p = 0.006 / 0.032), which is expected at this scale and harmless given the large n and the non-parametric confirmations.

## 4. Key findings

- **No categorical association with activity:** activity is 69.8 %–70.2 % in every city, gender and tier (V ≤ 0.0029).
- **No numeric association:** |d| ≤ 0.0042 and |r| ≤ 0.0012; the one nominal hit (salary, p = 0.046 in the logistic model) disappears after Holm correction (0.276).
- **ANOVA/regression:** η² ≤ 0.000009, Tukey differences ≤ 0.023 points (adjusted p ≥ 0.866), Kruskal–Wallis p = 0.823, interaction p = 0.244; the linear model explains ≈ 0.002 % of variance (age: −0.009 points per decade, 95 % CI [−0.027, 0.010]).
- **Prediction:** AUC 0.501 and accuracy below the always-"active" baseline — the model has no predictive value.
- **Interpretation:** the dataset is statistically compatible with independently generated variables. We report this honestly as a null result rather than searching for significance.

## 5. Limitations and extensions

- A single cross-sectional snapshot; no time dimension or real behavioral variables (transactions, products, tenure).
- Evidence that the data are synthetic limits external validity: conclusions concern *this* dataset, not real banking behavior.
- Complete-case analysis keeps 77.1 % of rows (sensitivity checks agree with it).
- **Extension script (not part of the graded analysis, run as confirmation):** [`code/Extension_Multivariada.R`](code/Extension_Multivariada.R) applies the remaining syllabus multivariate tools — Hotelling's T² / MANOVA, PCA, linear discriminant analysis, canonical correlation, K-means with silhouette, and correspondence analysis. Expected result, consistent with everything above: no structure.

## 6. Repository structure

```
.
├── README.md
├── data/
│   └── bank_data_definitiva.csv.gz      # cleaned dataset (deliverable), gzip
├── code/
│   ├── Codigo_Analisis.Rmd              # full analysis (code only), parameterized
│   ├── Codigo_Analisis_rendered.html    # knitted output of the Rmd
│   └── Extension_Multivariada.R         # Hotelling, PCA, LDA, CCA, K-means, CA
├── report/
│   ├── Informe_Final.tex                # LaTeX source of the final report
│   ├── resultados.tex                   # numbers exported by the Rmd (\rNombre macros)
│   ├── figs/                            # 39 figures generated by the Rmd
│   ├── tablas/                          # 18 LaTeX tables generated by the Rmd
│   ├── Final_Report.pdf                 # final report (Spanish)
│   └── First_Deliverable.pdf            # first deliverable (Spanish)
└── presentation/
    └── Defense_Slides.pdf               # 22-slide oral defense deck
```

## 7. Reproducing the analysis

**Requirements:** R ≥ 4.1 and the packages `rmarkdown, knitr, broom, car, corrplot, dplyr, ggplot2, moments, readr, scales, tibble, tidyr` (the extension script additionally uses `MASS`, `cluster`, `randomForest`/`ranger` as indicated in its header).

1. Download `bank_data.csv` from Kaggle (link above) and place it next to `code/Codigo_Analisis.Rmd` (or set `params$archivo`).
2. Knit `Codigo_Analisis.Rmd` (RStudio → *Knit*, or `rmarkdown::render("code/Codigo_Analisis.Rmd")`). Parameters: `alpha = 0.05`, `semilla = 2026` (random seed), `guardar_base = true`.
3. The knit creates, beside the Rmd: `figs/`, `tablas/`, `resultados.tex` and `bank_data_definitiva.csv`. The versions produced by the author's run are already in `report/`.
4. Copy `figs/`, `tablas/` and `resultados.tex` into the same folder as `report/Informe_Final.tex` and compile it with **XeLaTeX** (e.g., Overleaf → Menu → Compiler → XeLaTeX). All numbers in the report are injected from `resultados.tex`, so text and results stay in sync.

The seed (`2026`) makes subsampling, the train/test split and the Random Forest reproducible.

## 8. Course context and deliverables

Guidelines asked for: a report of at most 10 pages in APA 7, an AI-use declaration, a 90×120 cm poster with a QR code, source code and the definitive database — all included or linked here (the poster is a separate design file).

## 9. Use of AI tools

Generative AI (Claude, by Anthropic) was used as an assistant for code drafting, LaTeX formatting, slide/poster design and for structuring this repository. All analyses were run and verified by the author, who is responsible for the content. The formal declaration is in the final report.

## 10. References (main)

Kaur & Kaur (2020); Singh et al. (2024); Li & Yan (2025); Montgomery et al. (2021); Hosmer et al. (2013). Full APA 7 list in `report/Final_Report.pdf`.

## License / data note

Code and documents: for academic purposes. The raw dataset belongs to its Kaggle author and is not redistributed; only the cleaned course deliverable is included.
