# In this query file I will be writing down the queries which will be used as a input data for our COVID - 19 tableau visualisation.


# 1. 

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE continent IS NOT NULL  
ORDER BY 1,2


# 2. 
-- The data has few location in the database which are not required by us. The 'and' clause gets all the location exluding 'world', 'european union' and 'international'. 

SELECT location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- 3.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- 4.

SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

