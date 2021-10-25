-- Had issues with a few data types decided to alter a few using alter table

ALTER TABLE Portfolio_Projects..deaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE Portfolio_Projects..deaths
ALTER COLUMN total_deaths FLOAT;


-- this will appropriately select the data for our continent overview later
SELECT *
FROM Portfolio_Projects..deaths
WHERE continent is not NULL
ORDER BY 3,4;


-- Make sure our table uploaded ok
SELECT *
FROM Portfolio_Projects..vaccinations;

-- Take a peak at our changed data types
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Projects..deaths
ORDER BY 1,2;

-- Looking at total cases vs total deaths
-- shows likelihood of dying of covid based on country added our where clause so we can take a peak specifically at U.S
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Portfolio_Projects..deaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

-- let's take a look at total cases vs population
-- shows us what percentage of population got covid in the us
SELECT location, date, total_cases, population, (total_cases/population)*100 AS population_percentage
FROM Portfolio_Projects..deaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection, MAX((total_cases/population))*100 AS percent_population_infected
FROM Portfolio_Projects..deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC;

-- Let's break total deaths down by continent

SELECT location, MAX(cast(total_deaths as int)) AS death_count
FROM Portfolio_Projects..deaths
WHERE continent is NULL AND location <> 'World'
GROUP BY location
ORDER BY death_count DESC;

-- Shows countries with highest death count per population 

SELECT location, MAX(cast(total_deaths as int)) AS death_count
FROM Portfolio_Projects..deaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY death_count DESC;

-- GLOBAL NUMBERS

SELECT SUM(cast(new_cases AS float)) AS case_numbers, SUM(cast(new_deaths as int)) AS global_deaths, SUM(cast(new_deaths as int))/SUM(cast(new_cases AS float))*100 AS death_percentage
FROM Portfolio_Projects..deaths
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1,2;

-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM Portfolio_Projects..deaths dea
JOIN Portfolio_Projects..vaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE 

With popvsvac (continent, location, date, population, new_vaccinations, rolling_vaccinations) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM Portfolio_Projects..deaths dea
JOIN Portfolio_Projects..vaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (rolling_vaccinations/population)*100
FROM popvsvac
ORDER BY 2,3;

-- TEMP TABLE

DROP TABLE IF EXISTS #percent_population_vaccinated --useful if you need to make alterations to your table
CREATE TABLE #percent_population_vaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_vaccinations NUMERIC
)
INSERT into #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM Portfolio_Projects..deaths dea
JOIN Portfolio_Projects..vaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (rolling_vaccinations/population)*100
FROM #percent_population_vaccinated;

-- creating view to store data for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM Portfolio_Projects..deaths dea
JOIN Portfolio_Projects..vaccinations vac
     ON dea.location = vac.location
     AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *
FROM percent_population_vaccinated