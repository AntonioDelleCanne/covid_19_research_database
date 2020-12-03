-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- Table dependencies:
-- ( recordingDate, geoId ) uniquely identify each records
-- dateRep -> day, month, year
-- geoId <-> countriesAndTerritories <-> countryTerritoryCode <-> popData2019
-- geoId -> continentExp

-- 1NF
-- The date will be memorized in DATE format of MySQL, so  dateResp, day, month, year, will be removed and replaced with date
-- We also have to choose a primary key, here we choose recording date and geografic id, since the records are recorded by day and by location

-- SOURCE backupDataset.sql

drop table if exists corona_record_1NF;
create table corona_record_1NF (
	recordingDate date not null,
    countryterritoryCode char(80) not null,
    geoId char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
	countriesAndTerritories varchar(255) DEFAULT NULL,
	popData2019 int DEFAULT NULL,
	continentExp varchar(255) DEFAULT NULL,
    primary key (recordingDate, countryterritoryCode)
);

insert into corona_record_1NF (recordingDate, geoId, cases, deaths, countriesAndTerritories, countryterritoryCode, popData2019, continentExp)
select distinct STR_TO_DATE(dateRep,'%d/%m/%Y'), geoId, cases, deaths, countriesAndTerritories, countryterritoryCode, popData2019, continentExp
from corona;

-- From the following (commented) query we see that the records with geoId = 'JPG11668' do not have the countryterrytoryCode.
-- Since in order to make the integration with the phsm database more easy, we want the countryterritoryCode
-- to be the primary key (because the values in this field correspond to the values in the iso field in the phsm database)
-- Instead of leaving the countryterrytoryCode empty, we are copying the geoId in it
--
-- select * from corona_record_1NF
-- where countryterritoryCode = '';
--
update corona_record_1NF
set countryterritoryCode = geoId
where countryterritoryCode = '';

-- 2NF
-- A relation schema R is in 2NF if every nonprime attribute A in R is
-- fully functionally dependent on the primary key of R.
--
-- By looking at the dependencies we see that continentExp, countriesAndTerritories, countryTerritoryCode, popData2019
-- are all partilly dependent on the primary key since they depende solely on geoId

drop table if exists corona_record;
drop table if exists corona_location;


create table corona_location (
	countryterritoryCode char(80) not null,
	geoId char(80) not null,
    countriesAndTerritories varchar(255) DEFAULT NULL,
	popData2019 int DEFAULT NULL,
	continentExp varchar(255) DEFAULT NULL,
    primary key (countryterritoryCode)
);


create table corona_record (
	recordingDate date not null,
    countryterritoryCode char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, countryterritoryCode),
    foreign key (countryterritoryCode) references corona_location(countryterritoryCode)
);

insert into corona_location (geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp)
SELECT distinct geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp
FROM corona_record_1NF;

insert into corona_record (recordingDate, countryterritoryCode, cases, deaths)
SELECT distinct recordingDate, countryterritoryCode, cases, deaths
FROM corona_record_1NF;


-- 3NF
-- A relation schema R is in 3NF if it satisfies 2NF and 
-- no nonprime attribute of R is transitively dependent on the primary key
--
-- By looking at the dependencies, we see that there aren't this requirement is already satisfied, therefore
-- the schema is the same as the 2NF one