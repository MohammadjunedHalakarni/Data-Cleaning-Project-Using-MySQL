🗃️ SQL Data Cleaning Project – World Layoffs Dataset
📌 Project Overview

This project focuses on cleaning and preparing the world_layoffs dataset using MySQL.
The dataset contains information about global layoffs across companies, industries, locations, and funding stages.
The goal of this project is to transform raw data into a clean and reliable format for further analysis.

⚙️ Steps in Data Cleaning
1. Remove Duplicates

    Created a staging table to avoid modifying raw data directly.

    Used ROW_NUMBER() with PARTITION BY to identify duplicate rows.

    Deleted duplicate entries while keeping only the first occurrence.


2. Standardize the Data

    Removed unwanted spaces using TRIM().

    Standardized industry names (e.g., "Crypto", "CryptoCurrency" → Crypto).

    Fixed inconsistent country names (United States. → United States).

    Converted date column from text to proper DATE format.


3. Handle NULL or Blank Values

    Replaced empty industry values with NULL.

    Filled missing industry values by comparing with other entries of the same company.

    Deleted records where both total_laid_off and percentage_laid_off were NULL.


4. Remove Unnecessary Columns

    Dropped helper columns like row_num created for duplicate removal.


📂 Files in the Project

layoffs.csv → Raw dataset file.

layoffs_cleaning.sql → SQL script for the entire data cleaning process.


📊 Key Learnings

Using CTE and ROW_NUMBER() to detect duplicates.

Standardizing categorical fields for consistency.

Converting date formats for time-series analysis.

Handling missing values effectively.
