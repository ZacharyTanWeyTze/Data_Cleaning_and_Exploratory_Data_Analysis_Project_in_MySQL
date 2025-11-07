-- SQL Data Cleaning Project (MySQL)
-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

# Create world_layoffs schema and import table in MySQL

# View layoffs data
SELECT * 
FROM world_layoffs.layoffs;

-- Data Cleaning And Preparation Steps

-- 1. Check For And Remove Duplicates
-- 2. Standardize Data And Fix Errors
-- 3. Look At Null Values Or Blank Values To Populate If Possible/Appropriate
-- 4. Remove Any Unnecessary Columns/Rows

-- Remove Duplicates

# Create a staging table to work in and clean the data
# Keep separate from raw data in case mistakes or layoffs_stagingsomething happens
CREATE TABLE layoffs_staging
LIKE layoffs;

# View staging table columns
SELECT *
FROM layoffs_staging;

# Insert data
INSERT layoffs_staging
SELECT *
FROM layoffs;

# Identify dupes by making a row number, PARTITION BY over every column
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num # backtick `date` as date is a keyword in MySQL
FROM layoffs_staging;

# Put above into CTE to filter for dupes (row_num >= 2)
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

# Create staging2 table, do a Copy to Clipboard Create Statement
CREATE TABLE `layoffs_staging2` ( # rename to staging2
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int # add this extra column
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# View staging2 table
SELECT *
FROM layoffs_staging2;

# Insert copy data with row_num into empty staging2 table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,  `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

# View and delete dupes i.e. rows were row_num is greater than 1
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

# View table after dupes deleted
SELECT *
FROM layoffs_staging2;

# If unable to UPDATE or DELETE, go into Edit > Preferences > SQL Editor > Uncheck Safe Updates

-- Remove Duplicates Step Completed

-- Standardize Data

# Remove white spaces in company column
SELECT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

# Look at industry column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

# Noticed that Crypto has multiple different variations
# Change all the Crypto-like industry to Crypto (large majority of values)
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2;

# Look at location column
# Everything under location looks fine, no visible issues
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

# Look at country column
# Noticed that some United States have a period at the end
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# Standarize them by removing the period using TRAILING
SELECT DISTINCT(country), TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# Currently date is a text column
# Change it to a datetime in order to do time series visualisations and stuff
# Format date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

# Change data type from text to date
# Note. Don't do this on the raw table, do on a staging table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Standardize Data Step Completed

-- Null Values or Blank Values

# Look at null value, blank/missing value, empty rows in industry 
SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

# For these 4 company with no industry, first try to see if they have other rows populated 
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

# Airbnb is a Travel industry, but this one row just isn't populated
# It's likely the same for some others who did mutliple layoffs, so ...
# Write a query that if there is another row with the same company name, it will update it to the non-null industry values
# Makes it easy so if there were thousands we wouldn't have to manually check them all

# Use a self join where the left table are the empty rows and the right table has the populated row values
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2. industry IS NOT NULL
;

# Set the blanks to nulls since those are typically easier to work with and is needed for this to work
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Update to set the blank industry to the populated industry for the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
    AND t1.location = t2.location
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL
AND t2. industry IS NOT NULL;

# Recheck Airbnb and everything again post update
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

# Check the null value for Bally's 
# Looks like Bally's was the only one without a populated row to populate this null value
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

# Check total_laid_off column for nulls
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

# Check for rows where both total and percentage laid off are null; these would be fairly useless and could be removed in step 4
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# The null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal
# We won't change that as having them null makes it easier for calculations during the EDA phase, also we don't have anything to populate or impute

-- Null or Blank Values Step Completed

-- Remove Columns and Rows

# With regard to rows with null total_laid_off and percentage_laid_off, we don't know if these companies did laid off people at all
# We are confident that these columns are going to be used a lot in EDA
# Delete these useless rows that can't really be used
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Drop unneeded row_num column
SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

-- Remove Columns and Rows Step Completed

-- Data Cleaning Steps Completed