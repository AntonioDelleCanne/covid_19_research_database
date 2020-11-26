-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- the data mart coincides with the 3NF schema in the file corona2DB where the fact table coincides with the corona_record table, and the dimension tables are
-- the corona_location (and the corona_date TO ADD if needed)


drop table if exists corona_dm_record;
drop table if exists corona_dm_location;
drop table if exists corona_dm_time;

create table corona_dm_location (
	geoId varchar(255) not null,
    countriesAndTerritories varchar(255) DEFAULT NULL,
	countryterritoryCode varchar(255) DEFAULT NULL,
	popData2019 int DEFAULT NULL,
	continentExp varchar(255) DEFAULT NULL,
    primary key (geoId)
);

create table corona_dm_time(
	timeCode int NOT NULL AUTO_INCREMENT,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

create table corona_dm_record (
	timeCode date not null,
    geoId varchar(255) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, geoId),
    foreign key (geoId) references corona_location(geoId),
    foreign key (timeCode) references corona_dm_time(timeCode)
);

insert into corona_location (geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp)
SELECT distinct geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp
FROM corona_location;

insert into corona_record (recordingDate, geoId, cases, deaths)
SELECT distinct recordingDate, geoId, cases, deaths
FROM corona_record;

insert into corona_dm_time(day, month, year)
select distinct day(recordingDate), month(recordingDate), year(recordingDate)
from corona_record
order by year, month, day asc;