# Cardiovascular Diseases Integrated Risk Model

## Project Overview
- This project integrates genomic, clinical, lifestyle, and social risk factors to predict coronary artery disease (CAD), atrial fibrillation (AFIB), and heart failure (HF)
- Genomic data is aggregated into a polygenic score (PGS), clinical risk factors are aggregated into clinical risk scores (CRS), and lifestyle and social risk factors are aggregated into a polyexposure score (PXS)
- This is an extension of a PSB paper published in 2026 that just focused on HF in All of Us (https://doi.org/10.1142/9789819824755_0046)
- This project did analyses in UK Biobank and All of Us

## Workflow of Analyses
1. Extract variants that are in PGS score files from PLINK files
2. Run PGSC-CALC to get PGS computed in study population
3. Conduct phenotyping for outcomes, covariates, and predictors for CRS and PXS
4. Split dataset into feature selection and IRM computation groups, and assess age, sex, and case/control distributions between the groups
5. Compute CRS
6. Normalize and scale PXS variables
7. Conduct feature selection on PXS variables
8. Select most important features for PXS
9. Run model evaluation script to get performance metrics (AUROC, AUPRC, F1 score, Balanced Accuracy)
10. Calculate case proportions in low, medium, and high risk groups defined by the risk scores
11. Make ROC/PRC curves
