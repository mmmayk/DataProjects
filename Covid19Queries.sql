-- Converting total_cases and total_deaths columns to float as they represent numeric values
Alter Table covid_deaths
Alter Column total_cases float;

Alter Table covid_deaths
Alter Column total_deaths float;


-- Total cases vs total deaths in Poland
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
From covid_deaths
Where location = 'Poland'
Order by 1, 2


-- Total cases vs population (shows what percentage of population in Poland got Covid)
Select location, date, population, total_cases, (total_cases/population)*100 as percentage_of_cases
From covid_deaths
Where location = 'Poland'
Order by 1, 2


-- Countries with highest infection rate
Select location, population, MAX(total_cases) as total_number_cases, MAX((total_cases/population))*100 as
percent_population_infected
From covid_deaths
Group by location, population
Order by percent_population_infected desc


-- Infection count by date per country
Select location, population, date, MAX(total_cases) as total_number_cases, MAX((total_cases/population))*100 as
percent_population_infected
From covid_deaths
Group by location, population, date
Order by percent_population_infected DESC


-- Countries with highest death count
Select location, MAX(total_deaths) as total_death_count
From covid_deaths
Where continent is not null
Group by location
Order by total_death_count desc


-- Breakdown by continent (continents with highest death count; includes data cleaning)
Select location as continent, MAX(total_deaths) as total_death_count
From covid_deaths
Where continent is null
and location not in ('World','High Income', 'Upper Middle Income','Lower Middle Income','Low Income', 'European Union')
Group by location
Order by total_death_count desc


-- Replacing 0 with nulls to perfrom divisions
UPDATE covid_deaths
SET new_cases = NULL
WHERE new_cases = 0


-- Global numbers by date (aggregate function added in order to group by date)
Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
From covid_deaths
Where continent is not null
Group by date
Order by 1, 2


-- Global numbers by country
Select location, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
From covid_deaths
Where continent is not null
Group by location
Order by 1, 2


-- Total cases and deaths worldwide
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths
,SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
From covid_deaths
Where continent is not null
Order by 1, 2


-- HDI and death rate
Select location, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage, human_development_index
From covid_complete
Where continent is not null
Group by location, human_development_index
Order by 4 DESC


-- Number of people fully vaccinated worldwide
Select dea.location, population, MAX(cast(people_fully_vaccinated as float)) as people_fully_vaccinated
, MAX(cast(people_fully_vaccinated as int))/population*100 as percent_people_fully_vaccinated 
From covid_deaths as dea
Join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
	Where dea.continent is not null
Group by dea.location, population
Order by 1


-- Number of people vaccinated by continent
Select dea.location, MAX(cast(people_fully_vaccinated as float)) as people_fully_vaccinated
From covid_deaths as dea
Join covid_vaccinations as vac
	on dea.location = vac.location
	Where dea.continent is null
	and dea.location not in ('World','High income', 'Upper middle income','Lower middle income','Low income', 'European Union')
Group by dea.location


-- CTE, number of vaccinations given in Europe (excluding boosters)
With PopvsVac (continent, location, date, population, new_vaccinations, added_vaccinations)
as
(
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location Order by dea.date)
	as added_vaccinations
From covid_deaths as dea
Join covid_vaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent = 'Europe'
)
Select *, (added_vaccinations/population)*100 as percent_added_vaccinations
From PopvsVac


-- Temp table, number of people fully vaccinated in Europe (drop table to make changes)
Drop table if exists #PopulationVaccinatedEurope;
Create Table #PopulationVaccinatedEurope
(
location nvarchar(255),
population float,
people_fully_vaccinated float
)
Insert into #PopulationVaccinatedEurope
Select dea.location, dea.population, MAX(cast(vac.people_fully_vaccinated as float)) as people_fully_vaccinated
From covid_deaths as dea
Join covid_vaccinations as vac
	on dea.location = vac.location
Where dea.continent = 'Europe'
Group by dea.location, population
Select *, (people_fully_vaccinated/population)*100 as percent_people_fully_vaccinated
From #PopulationVaccinatedEurope


-- Creating Views for data visualizations
-- #1
Create View CountriesHighestInfections as
Select location, population, MAX(total_cases) as total_number_cases, MAX((total_cases/population))*100 as
percent_population_infected
From covid_deaths
Group by location, population


-- #2
Create View InfectionRateDate as
Select location, population, date, MAX(total_cases) as total_number_cases, MAX((total_cases/population))*100 as
percent_population_infected
From covid_deaths
Group by location, population, date


-- #3
Create View DeathCountContinent as
Select location as continent, MAX(total_deaths) as total_death_count
From covid_deaths
Where continent is null
and location not in ('World','High Income', 'Upper Middle Income','Lower Middle Income','Low Income', 'European Union')
Group by location


-- #4
Create View HDIvsDeathRate as
Select location, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage, human_development_index
From covid_complete
Where continent is not null
Group by location, human_development_index
