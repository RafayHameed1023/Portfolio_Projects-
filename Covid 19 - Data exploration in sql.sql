/* COVID 19 Data Exploration. 
Since I don't have a windows system I am using BigQuery insteda of SSMS for my Queries.  
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types. */

# For reference - 'spry-bus-413817' is my project name in BigQuery and 'CovidDataExploration' is my dataset name.
# We have two different tables for our data that contain data for deaths and vaccinations, let's take a look at them. 

SELECT * 
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
ORDER BY 3, 4
LIMIT 500

SELECT * 
FROM spry-bus-413817.CovidDataExploration.CovidVaccinations
ORDER BY 3, 4
LIMIT 500


# Let's take a look at the data we need. 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


# Total cases vs total death. 
# This will show the likelihood percentage of dying becuase of covid in your country. 
# For this case we'll look at India instead of all the countries.

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE location LIKE '%India%'
AND continent IS NOT NULL 
ORDER BY 1,2


# Total cases vs population. 
# This will show us the percentage of population infected within a country. 

SELECT Location, date, Population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
--WHERE location LIKE '%India%'
ORDER BY 1,2


# Countries with highest infection rate.

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
--WHERE location LIKE '%India%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


# Similarly we'll look at countries with highest death count. 

SELECT Location, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
--WHERE location LIKE '%India%'
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount desc


# After looking at the different countries, let's take a look at the data according to different continents.
# Continent with highest death count. 

SELECT continent, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount desc


# Total deaths and death percentange around the world. 

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM spry-bus-413817.CovidDataExploration.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


# Now we'll look at the CovidVaccinations table as well. 
# Total population vs vaccinated - population that has received atleast one dose of vaccination.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM spry-bus-413817.CovidDataExploration.CovidDeaths dea
JOIN spry-bus-413817.CovidDataExploration.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3


# Now we'll calculate the percentage population vaccinated using cte. 

WITH 
  PopvsVac 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM spry-bus-413817.CovidDataExploration.CovidDeaths dea
JOIN spry-bus-413817.CovidDataExploration.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PopulationVaccinatedPercentage
FROM PopvsVac


# We can also use a temp table in order to obtain the result that we got from the previous query.

DROP Table IF EXISTS PercentPopulationVaccinated

CREATE TABLE spry-bus-413817.CovidDataExploration.PercentPopulationVaccinated
(
Continent string,
Location string,
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO spry-bus-413817.CovidDataExploration.PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM spry-bus-413817.CovidDataExploration.CovidDeaths dea
JOIN spry-bus-413817.CovidDataExploration.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM spry-bus-413817.CovidDataExploration.PercentPopulationVaccinated


# I will be using this data to make some visualisation in tableau so let's create a  View to store data for later visualizations. 

CREATE VIEW spry-bus-413817.CovidDataExploration.ViewPercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM spry-bus-413817.CovidDataExploration.CovidDeaths dea
JOIN spry-bus-413817.CovidDataExploration.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
