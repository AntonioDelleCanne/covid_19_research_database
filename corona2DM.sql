-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- the data mart coincides with the 3NF schema in the file corona2DB where the fact table coincides with the corona_record table, and the dimension tables are
-- the corona_location (and the corona_date TO ADD if needed)


drop table if exists corona_dm_record;
drop table if exists corona_dm_location;
drop table if exists corona_dm_time;

create table corona_dm_location (
	geoId char(80) not null,
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
	recordingDate int not null,
    geoId char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, geoId),
    foreign key (geoId) references corona_dm_location(geoId),
    foreign key (recordingDate) references corona_dm_time(timeCode)
);

insert into corona_dm_location (geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp)
SELECT distinct geoId, countriesAndTerritories, countryterritoryCode, popData2019, continentExp
FROM corona_location;

-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the date_start ad date_end fields of the record table

select @min_date := min(recordingDate), @max_date := max(recordingDate) 
from corona_record;

-- from https://stackoverflow.com/questions/10132024/how-to-populate-a-table-with-a-range-of-dates
DROP PROCEDURE IF EXISTS filldates;
DELIMITER |
CREATE PROCEDURE filldates(dateStart DATE, dateEnd DATE)
BEGIN
  WHILE dateStart <= dateEnd DO
    INSERT INTO corona_dm_time (day, month, year) VALUES (day(dateStart), month(dateStart), year(dateStart));
    SET dateStart = date_add(dateStart, INTERVAL 1 DAY);
  END WHILE;
END;
|
DELIMITER ;
CALL filldates(@min_date, @max_date);

insert into corona_dm_record (recordingDate, geoId, cases, deaths)
SELECT distinct ct.timeCode, geoId, cases, deaths
FROM corona_record cr
join corona_dm_time ct
on day(cr.recordingDate) = ct.day and month(cr.recordingDate) = ct.month and year(cr.recordingDate) = ct.year;