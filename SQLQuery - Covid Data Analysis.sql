Select *
from PortfolioProject..CovidDeaths
order by 3, 4

-- Select *
-- from PortfolioProject..CovidVaccinations
-- order by 3, 4

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2


-- Total Cases vs. Total Deaths (chances of dying if contracted)
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like 'Taiwan' or location like 'china'
order by 1, 2

-- Total Cases vs. Population
Select Location, date, total_cases, population, (total_cases/population)*100 as CasePerPopulation
from PortfolioProject..CovidDeaths
where location like 'Taiwan' or location like 'china'
order by 1, 2

-- Country of highest infection rate vs. polulation
Select location, population, MAX(total_cases) as MaxCase, (MAX(total_cases)/population)*100 as MaxCasePerPopulation
from PortfolioProject..CovidDeaths
where population>1000000 and total_cases is not null
Group by location, population
order by MaxCasePerPopulation asc

-- Country with highest death count
Select location, population, MAX(cast(total_deaths as int)) as death_count
from PortfolioProject..CovidDeaths
where population>1000000 and continent is not null and total_deaths is not null
Group by location, population
order by death_count desc

-- by continent highest death count
Select continent, MAX(cast(total_deaths as int)) as death_count
from PortfolioProject..CovidDeaths
where continent is not NULL
Group by continent
order by death_count asc

-- global numbers Total Cases vs. Population (alternative without grouping)
Select date, sum(new_cases)--, total_deaths, (total_deaths/total_cases)*100 as Death_percentage
from PortfolioProject..CovidDeaths
where continent is not null and total_cases is not null and total_deaths is not null
group by date
order by 1, 2 desc

-- global numbers Total Cases vs. Population
Select date, sum(total_cases) as TotalCases, 
			 sum(cast(total_deaths as int)) as TotalDeath,
			 sum(cast(total_deaths as int)) / (sum(total_cases))*100 as Death_percentage
	from PortfolioProject..CovidDeaths
	where continent is not null and total_cases is not null and total_deaths is not null
	group by date
	order by date desc

-- join two databases
-- total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		sum(cast(vac.new_vaccinations as float)) over 
			(partition by dea.location order by dea.date) as RollingVacTotal
	
	from PortfolioProject..CovidDeaths dea
		join PortfolioProject..CovidVaccinations vac
			on dea.location = vac.location
				and dea.date = vac.date
	
	where dea.continent is not null and vac.new_vaccinations is not null
	order by 2, 3

-- use CTE

With PopvsVac (Continent, location, date, population, new_vaccinations, RollingVacTotal) as (
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as float)) over 
				(partition by dea.location order by dea.date) as RollingVacTotal
		from PortfolioProject..CovidDeaths dea
			join PortfolioProject..CovidVaccinations vac
				on dea.location = vac.location and dea.date = vac.date
		where dea.continent is not null and vac.new_vaccinations is not null
		--order by 2, 3
)
Select *, (RollingVacTotal/population) from PopvsVac

-- new table
drop table if exists #PercentPolupationVaccinated
create table #PercentPolupationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingVacTotal numeric
)

insert into #PercentPolupationVaccinated
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as float)) over 
				(partition by dea.location order by dea.date) as RollingVacTotal
		from PortfolioProject..CovidDeaths dea
			join PortfolioProject..CovidVaccinations vac
				on dea.location = vac.location and dea.date = vac.date
		where dea.continent is not null and vac.new_vaccinations is not null
select * from #PercentPolupationVaccinated



-- creating view for future visualization

create view PercentPolupationVaccinated as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			sum(cast(vac.new_vaccinations as float)) over 
				(partition by dea.location order by dea.date) as RollingVacTotal
		from PortfolioProject..CovidDeaths dea
			join PortfolioProject..CovidVaccinations vac
				on dea.location = vac.location and dea.date = vac.date
		where dea.continent is not null and vac.new_vaccinations is not null

select * from PercentPolupationVaccinated