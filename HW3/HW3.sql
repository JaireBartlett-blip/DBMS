-- ****************************************************************************
-- HW3.sql: Building a Global Energy and Power Plants Relational Model in MySQL
-- ****************************************************************************
	
 use hw3; -- (name of my database)

-- *************************************************************
-- Safe Updates
-- *************************************************************
set SQL_SAFE_UPDATES = 0;
set FOREIGN_KEY_CHECKS = 0;

-- *************************************************************
-- 1. Create Tables
-- *************************************************************

-- Table: countries
create table countries (
    countrycode     varchar(3) not null, 
    countryname     varchar(50) not null,
    continent		varchar(50) not null,
    
    
    primary key (countrycode)
);

-- Table: operators
create table operators (
    operatorid          integer not null,
    operatorname        varchar (50) not null,
    headquarterscountry varchar (3) not null,
    
	foreign key (headquarterscountry) references countries(countrycode)  on delete cascade on update cascade,
    primary key (operatorid)
    
);

-- Table: fuel_types
create table fuel_types (
    fuelid           integer not null,
    fuelcategory     varchar (20) not null,
    fuelname         varchar (20) not null,
    
    primary key (fuelid)
);

-- Table: power_plants
create table power_plants(
	plantid			 integer not null,
    plantname		 varchar(50) not null,
    countrycode		 varchar (3) not null,
    operatorid		 integer not null,
    fuelid			 integer not null,
    capacitymw		 integer not null,
    commissionyear	 integer not null,
    
	foreign key (countrycode) references countries(countrycode) on delete cascade on update cascade,
	foreign key (operatorid)  references operators(operatorid)   on delete cascade on update cascade,
    foreign key (fuelid) references fuel_types(fuelid)   on delete cascade on update cascade,
    
    primary key (plantid)
);

-- Table: generation_records
create table generation_records (
	plantid integer not null,
    year integer not null,
    generationgwh decimal (15,2), -- wanted to make sure output had two decimals
    
   
    primary key (plantid, year), -- Composite Primary Key
    foreign key (plantid) references power_plants(plantid)   on delete cascade on update cascade

);

-- Table: emission_metrics
create table emission_metrics (
	plantid integer not null,
    year integer not null,
	co2emissionstonnes decimal (15,2), 
    primary key (plantid, year),
    foreign key (plantid) references power_plants(plantid)   on delete cascade on update cascade
    
);


-- *************************************************************
-- 2. Queries
-- *************************************************************

/*
-- 1.) Retrieve the plant name, country name, operator name, fuel category, fuel name, 
capacity (in MW), and commission year for all power plants without using table aliases. 
Sort the results in descending order by capacity.
*/

select
    power_plants.plantname, 
    countries.countryname, 
    operators.operatorname, 
    fuel_types.fuelcategory, 
    fuel_types.fuelname, 
    power_plants.capacitymw, 
    power_plants.commissionyear
from power_plants
inner join countries on power_plants.countrycode = countries.countrycode
inner join operators on power_plants.operatorid = operators.operatorid
inner join fuel_types on power_plants.fuelid = fuel_types.fuelid
order by power_plants.capacitymw desc;


/*
-- 2.) Retrieve the plant name, country code, calendar year, and annual generation (in GWh) for all power
 plants for the year 2024 without using table aliases. Sort the results in descending order by generation.
*/

select 
    power_plants.plantname, 
    power_plants.countrycode, 
    generation_records.year, 
    generation_records.generationgwh
from power_plants
inner join generation_records on power_plants.plantid = generation_records.plantid
where generation_records.year = 2024
order by generation_records.generationgwh desc;



/*
-- 3.) Retrieve the plant name, country code, calendar year, annual generation (in GWh), 
and CO2 emissions (in tonnes) for all power plants for the year 2024 without using table aliases. 
Sort the results in ascending order by CO2 emissions.
*/
select 
    power_plants.plantname, 
    power_plants.countrycode, 
    generation_records.year, 
    generation_records.generationgwh, 
    emission_metrics.co2emissionstonnes
from power_plants
inner join generation_records on power_plants.plantid = generation_records.plantid
inner join emission_metrics on power_plants.plantid = emission_metrics.plantid 
    and generation_records.year = emission_metrics.year
where generation_records.year = 2024
order by emission_metrics.co2emissionstonnes;


/*
-- 4.) Write a SQL query using a Common Table Expression (CTE) to calculate the total cumulative power 
generation (in GWh) for each operator across all available years without using table aliases. 
Retrieve the operator name, headquarters country, and their total generated power, 
and sort the results in descending order by total generation.
*/

with operator_generation_cte as (
    select 
        operators.operatorname, 
        operators.headquarterscountry, 
        generation_records.generationgwh
    from operators
    inner join power_plants on operators.operatorid = power_plants.operatorid
    inner join generation_records on power_plants.plantid = generation_records.plantid
)
select 
    operator_generation_cte.operatorname, 
    operator_generation_cte.headquarterscountry, 
    sum(operator_generation_cte.generationgwh) as total_generation
from operator_generation_cte
group by operator_generation_cte.operatorname, operator_generation_cte.headquarterscountry
order by total_generation;



/*
-- 5.) Write a SQL query using two separate Common Table Expressions (CTEs)--one to calculate total
 power generation by country code and another to calculate total CO2 emissions by 
 country code without using table aliases. Then, join these CTEs with the countries table to display 
 the country name, total generation (in GWh),  and total CO2 emissions (in tonnes). 
 Sort the results in descending order by total generation.
*/

with country_generation_cte as (
    select 
        power_plants.countrycode, 
        generation_records.generationgwh
    from power_plants
    inner join generation_records on power_plants.plantid = generation_records.plantid
),
country_emissions_cte as (
    select
        power_plants.countrycode, 
        emission_metrics.co2emissionstonnes
    from power_plants
    inner join emission_metrics on power_plants.plantid = emission_metrics.plantid
)
select
    countries.countryname, 
    sum(country_generation_cte.generationgwh) as total_generation, 
    sum(country_emissions_cte.co2emissionstonnes) as total_emissions
from countries
inner join country_generation_cte on countries.countrycode = country_generation_cte.countrycode
inner join country_emissions_cte on countries.countrycode = country_emissions_cte.countrycode
group by countries.countryname
order by total_generation desc;


