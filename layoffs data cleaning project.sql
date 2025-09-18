USE world_layoffs;

-- ======================================
-- Data Cleaning Project Steps:
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Handle NULL / Blank Values
-- 4. Remove Unnecessary Columns
-- ======================================

-- View raw layoffs data
SELECT * 
FROM layoffs;

-- Create a new staging table with the same structure as layoffs
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Insert raw data into staging table for cleaning
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Check data in staging table
SELECT * 
FROM layoffs_staging;

-- =======================
-- 1. REMOVE DUPLICATES
-- =======================

-- Use ROW_NUMBER() to identify duplicates based on key columns
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, industry, total_laid_off,
                      percentage_laid_off, 'date') AS row_num
FROM layoffs_staging;

-- Using CTE to find duplicate rows (row_num > 1 means duplicate)
WITH duplicate_cte AS
( 
    SELECT *,
           ROW_NUMBER() OVER (
             PARTITION BY company, location, industry, total_laid_off, 
                          percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1;

-- Create a second staging table with row_num column
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data with row numbers into staging2
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, location, industry, total_laid_off, 
                      percentage_laid_off, date, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

-- View duplicate rows
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicate rows
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Confirm duplicates removed
SELECT * 
FROM layoffs_staging2;

-- =======================
-- 2. STANDARDIZE THE DATA
-- =======================

-- Check inconsistent company names (extra spaces, etc.)
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2;

-- Remove leading/trailing spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Review distinct industry names
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Find variations in "Crypto"
SELECT industry 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardize "Crypto" industries
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Review distinct country values
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Identify "United States." with extra dot
SELECT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- Fix inconsistent "United States." entries
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Check and convert date format (from text to MySQL DATE)
SELECT date, STR_TO_DATE(date,'%m/%d/%Y')
FROM layoffs_staging2;

-- Update date column with proper date format
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date,'%m/%d/%Y');

-- Change column type from TEXT → DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- Verify cleaned table
SELECT * 
FROM layoffs_staging2;

-- ==============================
-- 3. HANDLE NULL / BLANK VALUES
-- ==============================

-- Convert empty industry strings to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Check for rows with NULL/blank industry
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Check industries for Airbnb as example
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Try to fill NULL industries using other rows of same company/location
SELECT t1.industry, t2.industry 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
   AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Update NULL industries with values from same company/location
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
  AND t2.industry IS NOT NULL;

-- Verify updates
SELECT * 
FROM layoffs_staging2;

-- Identify rows where both layoff counts are NULL
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Delete rows with no useful layoff data
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Final check
SELECT * 
FROM layoffs_staging2;

-- =======================
-- 4. REMOVE COLUMNS
-- =======================

-- Drop helper column row_num (not needed in final dataset)
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
