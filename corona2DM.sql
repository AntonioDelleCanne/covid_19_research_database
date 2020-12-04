-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- the data mart coincides with the 3NF schema in the file corona2DB where the fact table coincides with the corona_record table, and the dimension tables are
-- the corona_location (and the corona_date TO ADD if needed)

-- SOURCE corona2DB.sql

drop table if exists corona_dm_record;
drop table if exists corona_dm_location;
drop table if exists corona_dm_time;

create table corona_dm_location (
	countryterritoryCode char(80) not null,
	geoId char(80) not null,
    countriesAndTerritories varchar(255) DEFAULT NULL,
	popData2019 int DEFAULT NULL,
	continentExp varchar(255) DEFAULT NULL,
    primary key (countryterritoryCode)
);

create table corona_dm_time(
	timeCode int NOT NULL AUTO_INCREMENT,
    date date DEFAULT NULL,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

create table corona_dm_record (
	recordingDate int not null,
    countryterritoryCode char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, countryterritoryCode),
    foreign key (countryterritoryCode) references corona_dm_location(countryterritoryCode),
    foreign key (recordingDate) references corona_dm_time(timeCode)
);

insert into corona_dm_location (geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp)
SELECT distinct geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp
FROM corona_location;

-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the rcordingDate field of the corona_record table
-- to make the integration easier we are generating the same range of dates for both
-- the corona and the phsm data mart going from '2019-9-30' '2021-12-31'
-- this interval allows to fit the dates contained in both the databases
-- and provides a buffer to insert both older records,
-- in cases, for example, it turns out that the epidemic started earlier
-- and older recorded cases are found,
-- and to add more recent records as the epidemic develops
-- (here the time interval is '2019-12-31' to '2020-07-23')
/*
select @min_date := min(recordingDate), @max_date := max(recordingDate) 
from corona_record;
*/

set @min_date = cast('2019-9-30' as date);
set @max_date = cast('2021-12-31' as date);

-- from https://stackoverflow.com/questions/10132024/how-to-populate-a-table-with-a-range-of-dates
DROP PROCEDURE IF EXISTS filldates;
DELIMITER |
CREATE PROCEDURE filldates(dateStart DATE, dateEnd DATE)
BEGIN
  WHILE dateStart <= dateEnd DO
    INSERT INTO corona_dm_time (date, day, month, year) VALUES (dateStart, day(dateStart), month(dateStart), year(dateStart));
    SET dateStart = date_add(dateStart, INTERVAL 1 DAY);
  END WHILE;
END;
|
DELIMITER ;
CALL filldates(@min_date, @max_date);

insert into corona_dm_record (recordingDate, countryterritoryCode, cases, deaths)
SELECT distinct ct.timeCode, countryterritoryCode, cases, deaths
FROM corona_record cr
join corona_dm_time ct
on day(cr.recordingDate) = ct.day and month(cr.recordingDate) = ct.month and year(cr.recordingDate) = ct.year;