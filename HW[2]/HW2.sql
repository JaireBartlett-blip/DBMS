-- *************************************************************
-- HW2.sql: Database Schema Creation and Constraints
-- *************************************************************
	
-- use hw1; (name of my database)

-- *************************************************************
-- Safe Updates
-- *************************************************************
set SQL_SAFE_UPDATES = 0;
set FOREIGN_KEY_CHECKS = 0;

-- I had tables beforehhand, this is to let them go

-- DROP TABLE IF EXISTS employs; 
-- DROP TABLE IF EXISTS offers;
-- DROP TABLE IF EXISTS baristas;
-- DROP TABLE IF EXISTS shops;
-- DROP TABLE IF EXISTS pastries;

-- *************************************************************
-- 1. Create Tables for Entity Sets
-- *************************************************************

-- Table: pastries
create table pastries (
    pastryID    integer not null,
    name        varchar (50) not null,
    category    varchar (30),
    price       decimal (5,2),
    primary key (pastryID)
);

-- Table: baristas
create table baristas (
    baristaID        integer not null,
    name             varchar (50) not null,
    experience_level varchar (20),
    primary key (baristaID)
);

-- Table: shops
create table shops (
    shopID   integer not null,
    name     varchar (50),
    city     varchar (30),
    primary key (shopID)
);

-- *************************************************************
-- 2. Create Relationship Tables (Contain Foreign Keys)
-- *************************************************************

-- Table: offers
-- Uses a Composite Primary Key because it is a relationship 
-- by the combination of a specific shop offering a specific pastry.
CREATE TABLE offers (
    shopID     integer not null,
    pastryID   integer not null,
    date_added date,
    primary key (shopID, pastryID), -- Composite Primary Key
    foreign key (shopID) references shops(shopID),
    foreign key (pastryID) references pastries(pastryID)
);

-- Table: employs
-- Uses a Composite Primary Key because it is a relationship
-- by a specific barista working at a specific shop.
create table employs (
    baristaID integer not null,
    shopID    integer not null,
    primary key (baristaID, shopID), -- Composite Primary Key
    foreign key (baristaID) references baristas(baristaID),
    foreign key (shopID) references shops(shopID)
);

-- *************************************************************
-- 3. Queries
-- *************************************************************


-- 1.) Find the average price of pastries for each category from the pastries table


select category, round(avg(price), 2) as 'AvgPrice' -- round makes them stop at two decimals
from pastries
group by category;




-- 2.) Find the total number of baristas at each experience level from the baristas table



select experience_level, count(*) as 'NumOfBaristas'
from baristas
group by experience_level;

-- 3.) Count the total number of shops located in each city from the shops table

select city, count(shopID) as 'NumOfShops'
from shops
group by city;


-- 4.) Find the maximum price among pastries for each category from the pastries table.

select category, max(price) as 'MaxPrice'
from pastries
group by category;

-- 5.) Count how many pastries have been added by each shop using the shopID column from 
-- the offers table.

select shopID, count(pastryID) as 'NumOfPastries'
from offers
group by shopID;


-- 6.) Find the name, category, and price of any pastry whose price matches the maximum price within
-- its category.

select name, category, price
from pastries
where (category, price) in (
    select category, MAX(price)
    from pastries
    group by category
);

-- 7.) Find the unique shop IDs from the offers table that have offered at 
 -- least one pastry whose price is strictly greater than the overall average price of all pastries
 
select distinct shopID
from offers
where pastryID in (
		select pastryID
		from pastries
		where price > (select avg(price) from pastries)
);
	
 
 -- 8.) Find the shop ID and pastry ID for the record in the offers table that have the earliest
 -- date_added (minimum date).
 
 select shopID, pastryID
 from offers
 where date_added = (select min(date_added) from offers);
 
 
 -- 9.) Find the shop ID(s) that offer the highest number of pastries, utilizing a subquery to evaluate
 -- the maximum count per shop.
 
select shopID, count(pastryID) as 'NumOfPastries'
from offers 
group by shopID
having count(pastryID) >= all (
		select count(pastryID)
		from offers 
        group by shopID
);
 
 -- 10.) Find the names of baristas who work at shops in 'Seattle' using nested subqueries.



select name
from baristas
where baristaID in (
	select baristaID
    from employs
    where shopID in (
		select shopID
        from shops
        where city = 'Seattle'
	)
);
