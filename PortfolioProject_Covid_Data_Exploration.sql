use portfolioproject


-- TOTAL CASES vs. TOTAL DEATHS in the USA
-- shows what % of people in the USA who got covid died
select location, date, total_cases, total_deaths, round((total_deaths / total_cases)*100, 2) AS MortalityRate
from coviddeaths
where total_deaths is not null and location like '%states%'
order by 1,2;


-- TOTAL CASES vs. POPULATION in the USA
-- shows what % of US population got covid
select location, date, total_cases, population, round((total_cases / population)*100, 2) AS InfectionRate
from coviddeaths 
where total_cases is not null AND location like '%states%'
order by 1,2;


-- WHAT COUNTRY HAS HIGHEST INFECTION RATE vs. POPULATION?
-- shows the countries with the highest % of their population who have had covid 
select location, population, max(total_cases) AS Highest_Number_of_Cases, round(max((total_cases/population))*100, 2) AS Percent_Population_that_got_Covid
from coviddeaths
group by location, population
order by Percent_Population_that_got_Covid desc;


-- WHAT COUNTRY HAS THE HIGHEST DEATH COUNT PER POPULATION?
-- shows the countries (regions are omitted with where statement) with the largest number of covid related fatalities
select location, max(cast(total_deaths as int)) as running_death_total
from coviddeaths
where continent is not null
group by location
order by running_death_total desc;


-- WHAT CONTINENT HAS THE HIGHEST TOTAL DEATHS? 
-- using multiple where clauses with not like and not in to eliminate regions that aren't continents
select location, max(cast(total_deaths as int)) as running_death_total
from coviddeaths
where continent is null and location not like '%income%' and location not in ('world', 'international', 'european union')
group by location
order by running_death_total desc;


-- HOW MANY NEW CASES & NEW DEATHS PER DAY GLOBALLY & WHAT PERCENT OF NEW CASES ARE FATAL? 
select date, sum(new_cases) as total_new_cases, sum(cast(new_deaths as int)) as total_new_deaths, round(sum(cast(new_deaths as int))/sum(new_cases)*100, 2) as Percent_NewDeaths_Per_NewCase
from coviddeaths
where continent is not null and new_cases is not null and new_deaths is not null
group by date
order by 1;


-- ***JOINING THE COVID VACCINATIONS TABLE TO COVID DEATHS TABLE***
Select * from coviddeaths DEA
join covidvaccinations VAC
	on DEA.location = VAC.location
	and DEA.date = VAC.date;


-- GLOBAL: TOTAL POPULATION vs. # OF VACCINATIONS
-- aggregating new vaccinations with a partition to take the running total for each location
select DEA.continent, DEA.location, DEA.date, DEA.population, cast(ISNULL(vac.new_vaccinations, 0) as int) AS NewVaccinations
, SUM(cast(ISNULL(vac.new_vaccinations, 0) as float)) OVER (PARTITION BY DEA.Location ORDER BY dea.location, dea.date) AS Running_Vaccination_Total
From coviddeaths DEA
join covidvaccinations VAC
	on DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null
order by 2,3;


-- USING A CTE (keep # of columns in CTE same as # of columns in select statement & remove order bys)
-- NOTE: normalizing "new_vaccinations" as there are 4 rounds of vaccines I only want to count people who received all 4 rounds as 1 new vaccination more than 1 shot
With CTE_1 (Continent, Location, Date, Population, New_Vaccinations, Running_Vaccination_Total)
as
(
select DEA.continent, DEA.location, DEA.date, DEA.population, cast(ISNULL(vac.new_vaccinations, 0) as int) AS NewVaccinations
, SUM(cast(ISNULL((vac.new_vaccinations/4), 0) as float)) OVER (PARTITION BY DEA.Location ORDER BY dea.location, dea.date) AS Running_Vaccination_Total
From coviddeaths DEA
join covidvaccinations VAC
	on DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null
)
Select *, round((Running_Vaccination_Total / Population)*100, 2) AS Percent_of_Pop_Vaccinated  
From CTE_1;


-- TEMP TABLE TO COMPARE VS. CTE
-- NOTE: normalizing "new_vaccinations" as there are 4 rounds of vaccines I only want to count people who received all 4 rounds as 1 new vaccination
Drop table if exists Temp_1
Create Table Temp_1
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population int,
New_vaccinations int, 
Running_Vaccination_Total float
)
Insert Into Temp_1
select DEA.continent, DEA.location, DEA.date, DEA.population, cast(ISNULL(vac.new_vaccinations, 0) as int) AS NewVaccinations
, SUM(cast(ISNULL((vac.new_vaccinations/4), 0) as float)) OVER (PARTITION BY DEA.Location ORDER BY dea.location, dea.date) AS Running_Vaccination_Total
From coviddeaths DEA
join covidvaccinations VAC
	on DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null

Select *, round((Running_Vaccination_Total / Population)*100, 2) AS Percent_of_Pop_Vaccinated  
From Temp_1
where location like '%states%' and Running_Vaccination_total > 0;


-- CREATE A VIEW TO STORE DATA FOR VISUALIZATIONS 
Create View Percent_Vaccinated AS
select DEA.continent, DEA.location, DEA.date, DEA.population, cast(ISNULL(vac.new_vaccinations, 0) as int) AS NewVaccinations
, SUM(cast(ISNULL(vac.new_vaccinations, 0) as float)) OVER (PARTITION BY DEA.Location ORDER BY dea.location, dea.date) AS Running_Vaccination_Total
From coviddeaths DEA
join covidvaccinations VAC
	on DEA.location = VAC.location
	and DEA.date = VAC.date
where DEA.continent is not null;