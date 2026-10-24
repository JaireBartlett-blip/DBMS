-- *****************************************************************************************
-- HW4.sql: Building a Global Space Missions and Launch Operations Relational Model in MySQL
-- *****************************************************************************************
	
use hw4; -- (name of my database)

-- *************************************************************
-- Safe Updates
-- *************************************************************
set SQL_SAFE_UPDATES = 0;
set FOREIGN_KEY_CHECKS = 0;

-- *************************************************************
-- 1. Drop Tables if they exist (for clean re-runs)
-- *************************************************************
drop table if exists payloads;
drop table if exists missions;
drop table if exists rockets;
drop table if exists launch_sites;
drop table if exists organizations;
drop table if exists countries;

-- *************************************************************
-- 2. Create Tables
-- *************************************************************

-- Table: countries
create table countries (
    countrycode     varchar(3) not null, 
    countryname     varchar(50) not null,
    continent       varchar(50) not null,
    
    primary key (countrycode)
);

-- Table: organizations
create table organizations (
    orgid               integer not null,
    orgname             varchar(100) not null,
    headquarterscountry varchar(3) not null,
    orgtype             varchar(20) not null,
    
    foreign key (headquarterscountry) references countries(countrycode) on delete cascade on update cascade,
    primary key (orgid)
);

-- Table: launch_sites
create table launch_sites (
    siteid          integer not null,
    sitename        varchar(100) not null,
    countrycode     varchar(3) not null,
    status          varchar(20) not null,
    
    foreign key (countrycode) references countries(countrycode) on delete cascade on update cascade,
    primary key (siteid)
);

-- Table: rockets
create table rockets (
    rocketid            integer not null,
    rocketname          varchar(50) not null,
    orgid               integer not null,
    payloadcapacitykg   integer not null,
    operationalstatus   varchar(20) not null,
    
    foreign key (orgid) references organizations(orgid) on delete cascade on update cascade,
    primary key (rocketid)
);

-- Table: missions
create table missions (
    missionid       integer not null,
    missionname     varchar(50) not null,
    rocketid        integer not null,
    siteid          integer not null,
    destination     varchar(50) not null,
    launchyear      integer not null,
    outcome         varchar(20) not null,
    
    foreign key (rocketid) references rockets(rocketid) on delete cascade on update cascade,
    foreign key (siteid) references launch_sites(siteid) on delete cascade on update cascade,
    primary key (missionid)
);

-- Table: payloads
create table payloads (
    payloadid       integer not null,
    missionid       integer not null,
    payloadname     varchar(100) not null,
    payloadtype     varchar(50) not null,
    masskg          decimal(15,2),
    
    foreign key (missionid) references missions(missionid) on delete cascade on update cascade,
    primary key (payloadid)
);

-- *************************************************************
-- 2. Queries
-- *************************************************************


/*
-- 1.) Retrieve the mission name, rocket name, organization name, launch site name, 
destination, launch year, and outcome for all space missions without using table aliases. 
Sort the results in descending order by launch year and ascending order by mission name.
*/
select 
    missions.missionname, 
    rockets.rocketname, 
    organizations.orgname, 
    launch_sites.sitename, 
    missions.destination, 
    missions.launchyear, 
    missions.outcome
from 
    missions
join 
    rockets on missions.rocketid = rockets.rocketid
join 
    organizations on rockets.orgid = organizations.orgid
join 
    launch_sites on missions.siteid = launch_sites.siteid
order by 
    missions.launchyear desc, 
    missions.missionname asc;


/*
-- 2.) Retrieve the mission name, rocket name, payload name, payload type, and 
payload mass (in kg) for all payloads launched in 2024 without using table aliases. 
Sort the results in descending order by payload mass.
*/

select 
    missions.missionname, 
    rockets.rocketname, 
    payloads.payloadname, 
    payloads.payloadtype, 
    payloads.masskg
from 
    payloads
join 
    missions on payloads.missionid = missions.missionid
join 
    rockets on missions.rocketid = rockets.rocketid
where 
    missions.launchyear = 2024
order by 
    payloads.masskg desc;


/*
-- 3.) Retrieve all launch sites along with their matching mission names, rockets, 
and launch years for missions that took place in 2024 without using table aliases, 
ensuring that launch sites with no recorded 2024 missions still appear in the results 
with null values for the mission fields. Sort the results in alphabetical order by 
launch site name.
*/
select 
    launch_sites.sitename,
    missions.missionname,
    rockets.rocketname,
    missions.launchyear
from 
    launch_sites
left join 
    missions on launch_sites.siteid = missions.siteid and missions.launchyear = 2024
left join 
    rockets on missions.rocketid = rockets.rocketid
order by 
    launch_sites.sitename asc;


/*
-- 4.) Write a SQL query using a Common Table Expression (CTE) to calculate the 
total payload mass (in kg) deployed by each organization across all missions without 
using table aliases. Retrieve the organization name, headquarters country, organization 
type, and total payload mass, and sort the results in descending order by total payload mass.
*/
with org_payload_totals as (
    select 
        rockets.orgid,
        sum(payloads.masskg) as total_mass
    from 
        payloads
    join 
        missions on payloads.missionid = missions.missionid
    join 
        rockets on missions.rocketid = rockets.rocketid
    group by 
        rockets.orgid
)
select 
    organizations.orgname,
    organizations.headquarterscountry,
    organizations.orgtype,
    coalesce(org_payload_totals.total_mass, 0) as total_payload_mass
from 
    organizations
left join 
    org_payload_totals on organizations.orgid = org_payload_totals.orgid
order by 
    total_payload_mass desc;


/*
-- 5.) Write a SQL query using two separate Common Table Expressions (CTEs)—one to 
calculate total missions by country code and another to calculate total payload mass by 
country code without using table aliases. Then, combine these CTEs with the countries 
table to display the country name, total number of missions, and total payload mass 
(in kg). Sort the results in descending order by total payload mass.
*/
with country_mission_counts as (
    select 
        launch_sites.countrycode,
        count(missions.missionid) as total_missions
    from 
        missions
    join 
        launch_sites on missions.siteid = launch_sites.siteid
    group by 
        launch_sites.countrycode
),
country_payload_mass as (
    select 
        launch_sites.countrycode,
        sum(payloads.masskg) as total_mass
    from 
        payloads
    join 
        missions on payloads.missionid = missions.missionid
    join 
        launch_sites on missions.siteid = launch_sites.siteid
    group by 
        launch_sites.countrycode
)
select 
    countries.countryname,
    coalesce(country_mission_counts.total_missions, 0) as total_missions,
    coalesce(country_payload_mass.total_mass, 0) as total_payload_mass
from 
    countries
left join 
    country_mission_counts on countries.countrycode = country_mission_counts.countrycode
left join 
    country_payload_mass on countries.countrycode = country_payload_mass.countrycode
order by 
    total_payload_mass desc;
