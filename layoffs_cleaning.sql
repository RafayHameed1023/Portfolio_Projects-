-- SQL Project - Data Cleaning
-- For this cleaning project we'll use a 'layoffs.csv' file which contain around 2300 rows about the information for different companies who laid 
-- off employees.

SELECT * 
FROM layoffs;


-- Before we start cleaning the data let's create a different staging table so that if we make any mistakes the original data remains intact.

CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT layoffs_staging 
SELECT * FROM layoffs;


-- We'll go through the following steps in order to clean our data:
-- 1. check for duplicates and remove if any.
-- 2. standardize data and fix errors if any.
-- 3. check for null values and see if there is any way to populate those values.
-- 4. at the end remove any columns and rows that are not necessary.


-- 1. Remove Duplicates

# First let's check for duplicates
SELECT *
FROM layoffs_staging
;

# We'll use row_number function to check for duplicates.
SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
# Let's just look at oda to confirm.
SELECT *
FROM layoffs_staging
WHERE company = 'Oda';
# After verifying this entry manually it is evident that it is in fact two different entries and we should not delete them.

# In order to find the duplicates properly, we will be partitioning the row_number on all the rows of the data set.
# These are our real duplicates.
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging
) duplicates
WHERE 
	row_num > 1;
# We want to delete all the values whose 'row_num' is greater than 1. 

# We'll do it something like this by using a CTE:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE;
# Unfortunately MySQL doesn't allow us to delete directly from CTEs. So we have to use a different way.

# One solution, which I think is a good one is to create a new column and add those row numbers in. 
# Then delete where row numbers are over 2, then delete that column at the end.

ALTER TABLE layoffs_staging ADD row_num INT;

SELECT *
FROM layoffs_staging
;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
`row_num` INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

# After creating that table, we can simply delete the duplicate values like this:
DELETE FROM layoffs_staging2
WHERE row_num >= 2;



-- 2. Standardize Data

SELECT * 
FROM layoffs_staging2;

# If we look at the industry column it looks like we have some null and empty rows, let's take a look at these:
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

# Let's take a look at these
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
# Nothing wrong here

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'airbnb%';

# It looks like airbnb is a travel industry, but this one is not populated.
# I'm sure it's the same for the others. 
# We can write a query that if there is another row with the same company name, it will update it to the non-null industry values.

# we should set the blanks to nulls since those are typically easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Now if we check those are all null:
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

# Now we need to populate those nulls if possible:
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# And if we check it looks like Bally's was the only one without a populated row to populate these null values.
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

# I also noticed the Crypto has multiple different variations. We need to standardize that - to Crypto
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

# Let's take a look at the industries now:
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

# Everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

# Let's also fix the date columns:
SELECT *
FROM layoffs_staging2;

# We'll use str_to_date function to change the data type of our date column:
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


SELECT *
FROM world_layoffs.layoffs_staging2;



-- 3. Look at Null Values

# The null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that.
# I like having them null because it makes it easier for calculations during the EDA phase.
# So there isn't anything I want to change with the null values


-- 4. Remove any columns and rows we need to

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# We don't really need the data of those companies who don't have the details for number of laid off employees.
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM layoffs_staging2;

































