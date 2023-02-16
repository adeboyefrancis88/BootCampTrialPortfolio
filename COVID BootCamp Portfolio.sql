create database portfolioCovidproject

use portfolioCovidproject

-- DATA EXPLORATION

select * from dbo.CovidVaccinations
order  by 3,4

--select * from dbo.CovidDeaths
--order  by 3,4

-- Step 1 following ETL concept - Extract essential data

select location,date,total_cases,new_cases,total_deaths,population 
from dbo.CovidDeaths 
ORDER BY 1,2

-- Total Cases vs Total Deaths ( Death % )

select location,date,total_cases,total_deaths,( total_deaths/total_cases)*100 As DeathRowPercentage
from dbo.CovidDeaths 
WHERE location like '%kingdom%'
ORDER BY 1,2

-- Total Case VS Population ( Infected rate by population )

select location,date,total_cases,population, (total_cases/population)*100 as CasesPercentage
from dbo.CovidDeaths 
WHERE location like '%kingdom%'
ORDER BY 1,2

-- Most Infected Country by population

select location,population,Max(total_cases) AS TopCases,Max((total_cases/population))*100 as PopulationPercentage
from dbo.CovidDeaths 
group by location,population
order by PopulationPercentage desc


-- Mortality rate by Country Population

select location,Max(cast(total_deaths as int)) AS TopMortality
from dbo.CovidDeaths 
where continent is not null
group by location
order by TopMortality desc

-- Continents with Highest Morality by Continent

select continent,Max(cast(total_deaths as int)) AS TopMortality
from dbo.CovidDeaths 
where continent is not null
group by continent
order by TopMortality desc

-- Global Numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathrowPercentage
from dbo.CovidDeaths
--Where location like '%kingdom%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population VS Total Vaccination

Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths  Death
Join dbo.CovidVaccinations Vacc
	On death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null 
order by 2,3

--Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as(Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths  Death
Join dbo.CovidVaccinations Vacc
	On death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths  Death
Join dbo.CovidVaccinations Vacc
	On death.location = vacc.location
	and death.date = vacc.date
--where death.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths  Death
Join dbo.CovidVaccinations Vacc
	On death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null 
--order by 2,3