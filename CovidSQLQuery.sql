SELECT *
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM COVIDProject.dbo.CovidVaccinations
--ORDER BY 3,4

-- Case and Death statistics by location and date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVIDProject.dbo.CovidDeaths
ORDER BY 1,2

-- Looking at the total cases vs total deaths showing the likelihood of dying if you contract covid by country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVIDProject.dbo.CovidDeaths
ORDER BY 1,2

-- Above query only on the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVIDProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Median age by location sorting youngest to oldest

SELECT location, AVG(median_age) AS average_age
FROM COVIDProject.dbo.CovidVaccinations
WHERE median_age IS NOT NULL
GROUP BY location
ORDER BY 2 ASC

-- Median age by continent sorting oldest to youngest

SELECT continent, AVG(median_age) AS average_age
FROM COVIDProject.dbo.CovidVaccinations
WHERE median_age IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


-- Looking at Total Cases vs Population
-- This shows the percentage of population which contracted Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS contracted_percentage
FROM COVIDProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Which countries have the highest infection rate by population?

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS HighestPercentInfected
FROM COVIDProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY HighestPercentInfected DESC

-- Total Deaths per million sorted by location
SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths, MAX(total_cases_per_million) AS cases_per_million, MAX(CAST(total_deaths_per_million AS float)) AS deaths_per_million
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 5 DESC


-- Showing Countries with highest death count per population

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Sorting by Continent instead

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Sorting by Continent more accurately looks like this

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Sorting by continent the way we do above has drawbacks however, so I will continue to do it the first way
-- Global statistics by date:

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global statistics combined:

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Population vs new vaccincations per day

SELECT covD.continent, covD.location, covD.date, covD.population, covV.new_vaccinations
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date
WHERE covD.continent IS NOT NULL	
ORDER BY 2, 3

-- Adding column to above with sum of new vaccinations per location

SELECT covD.continent, covD.location, covD.date, covD.population, covV.new_vaccinations, 
	SUM(CAST(covV.new_vaccinations AS INT)) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) AS locVaccinationCount
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date
WHERE covD.continent IS NOT NULL	
ORDER BY 2, 3

-- Use CTE to calculate rolling percentage of countries population vaccinated

WITH PopVsVac (continent, location, date, population, newVaccinations, locVaccinationCount)
AS
(
SELECT covD.continent, covD.location, covD.date, covD.population, covV.new_vaccinations, 
	SUM(CAST(covV.new_vaccinations AS INT)) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) AS locVaccinationCount
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date
WHERE covD.continent IS NOT NULL	
)
SELECT *, (locVaccinationCount/population)*100
FROM PopVsVac

-- Use temp table to do the same thing

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT covD.continent, covD.location, covD.date, covD.population, covV.new_vaccinations, 
	SUM(CAST(covV.new_vaccinations AS INT)) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) AS locVaccinationCount
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date
WHERE covD.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating some views to store data for later powerBI project

CREATE VIEW PercentPopulationVaccinated AS
SELECT covD.continent, covD.location, covD.date, covD.population, covV.new_vaccinations, 
	SUM(CAST(covV.new_vaccinations AS INT)) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) AS locVaccinationCount
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date
WHERE covD.continent IS NOT NULL


SELECT *
FROM PercentPopulationVaccinated

-- General view of the data joined together

SELECT *
FROM COVIDProject.dbo.CovidDeaths covD 
JOIN COVIDProject.dbo.CovidVaccinations covV
	ON covD.location = covV.location AND covD.date = covV.date

-- Patient death percentage by country View
DROP VIEW IF EXISTS deathPercentageByLoc
CREATE VIEW deathPercentageByLoc AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Deaths, MAX(total_cases) AS Total_Cases, (MAX(CAST(total_deaths AS INT)) / MAX(total_cases))*100 AS patient_death_percentage
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
-- Orders the view from highest to lowest
SELECT *
FROM deathPercentageByLoc
ORDER BY 4 DESC

-- The same view as above but by continent
DROP VIEW IF EXISTS deathPercentageByLoc
CREATE VIEW deathPercentageByCont AS
SELECT continent, MAX(CAST(total_deaths AS INT)) AS Total_Deaths, MAX(total_cases) AS Total_Cases, (MAX(CAST(total_deaths AS INT)) / MAX(total_cases))*100 AS patient_death_percentage
FROM COVIDProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY continent
-- Orders the view from above highest to lowest
SELECT *
FROM deathPercentageByCont
ORDER BY 4 DESC

-- View of total people fully vaccinated by location

DROP VIEW IF EXISTS deathPercentageByLoc
CREATE VIEW FullyVaccinatedByLoc AS
SELECT location, MAX(CAST(people_fully_vaccinated AS INT)) AS Fully_Vaccinated_People
FROM COVIDProject.dbo.CovidVaccinations
WHERE continent IS NOT NULL AND people_fully_vaccinated IS NOT NULL
GROUP BY location
-- Orders the view from highest to lowest
SELECT *
FROM FullyVaccinatedByLoc
ORDER BY 2 DESC

-- View of total people fully vaccinated by continent

DROP VIEW IF EXISTS deathPercentageByLoc
CREATE VIEW FullyVaccinatedByCont AS
SELECT continent, MAX(CAST(people_fully_vaccinated AS INT)) AS Fully_Vaccinated_People
FROM COVIDProject.dbo.CovidVaccinations
WHERE continent IS NOT NULL AND people_fully_vaccinated IS NOT NULL
GROUP BY continent
-- Orders the view from highest to lowest
SELECT *
FROM FullyVaccinatedByCont
ORDER BY 2 DESC


