-- SQL Exploratory Data Analysis Project (MySQL)
-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- EDA after Data Cleaning Step(s)

SELECT *
FROM world_layoffs.layoffs_staging2;

# View max total and percentage laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

# View companies that went under i.e. percentage laid off is 1 or 100%
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC; # sort by total laid off number

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC; # sort by funding amount

# View companies by all the total laid off
# Looks like many large corps such as Amazon, Google, Meta had over thousands of layoffs
SELECT company, SUM(total_laid_off), COUNT(company)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

# Check the date range of the layoffs data
# Looks like it starts from 2020 March to 2023 March, right when COVID came, and lasts for 3 years
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

# View industries that got hit the most
# Looks like Consumer and Retail were hit the hardest which makes sense with shops closing down in COVID
# Looks like Manufacturing, Fin-Tech, Aerospace, etc. had low numbers of recorded layoffs
SELECT industry, SUM(total_laid_off), COUNT(industry)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

# View layoffs by country
# Looks like USA had by far the most in the 3 years based on those reported in this dataset
SELECT country, SUM(total_laid_off), COUNT(country)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

# View layoffs by year
# Looks like 160k layoffs in 2022 which seems like the worst year, though ...
# Note that there's only 3 months of data for 2023 and there is 125k layoffs in this time
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

# View layoffs of stage of company
# Looks like most layoffs come from Post-IPO, Acquired, C, D, and B stages
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

# View companies average percentage laid off
# Looks like it isn't super relevant and doesn't help that much to dive in
SELECT company, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

# View layoffs by year-month
SELECT SUBSTRING(`date`, 1, 7) AS `year-month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `year-month`
ORDER BY 1 ASC;

# View the reported layoffs by their time progression with a rolling total/sum of layoffs month by month over the years
# Looks like by the end of 2020, there were 81k layoffs
# By end 2021, there were 96k layoffs cumulative, so comparitvely 2021 was not a bad year (only abt 15k for 2021)
# In 2022, layoffs start ramping up, going to 247k, abt a roughly 150k jump
WITH Rolling_Total AS  # take above table as a CTE
(
SELECT SUBSTRING(`date`, 1, 7) AS `year-month`, SUM(total_laid_off) AS total_off # rename for simplicity
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL # do away with the NULLs
GROUP BY `year-month`
ORDER BY 1 ASC
)
SELECT `year-month`, 
total_off, 
SUM(total_off) OVER (ORDER BY `year-month`) AS rolling_total
FROM Rolling_Total;

# View the large companies and how many they were laying off by year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

# TBA
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;