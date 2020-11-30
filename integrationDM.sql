-- Student Name: Antonio delle Canne
-- Student Number : K20113110

drop table if exists corona_integration_record;
drop table if exists phsm_integration_record;
drop table if exists integration_iso_region;
drop table if exists integration_iso_iso_3166_1_numeric;
drop table if exists intergation_location;
drop table if exists integration_time;
drop table if exists phsm_integration_who_measure;

-- TODO merge and delete ----------------------

create table corona_dm_location ( 
	geoId char(80) not null,
    countriesAndTerritories varchar(255) DEFAULT NULL,
	countryterritoryCode varchar(255) DEFAULT NULL,
	popData2019 int DEFAULT NULL,
	continentExp varchar(255) DEFAULT NULL,
    primary key (geoId)
);


create table phsm_dm_location like phsm_location;
insert into phsm_dm_location select * from phsm_location;
create table phsm_location (
	iso char(80) not null,
	country_territory_area text,
	primary key (iso)
);

-- -----------------------

-- the corona_dm_location and phsm_dm_location tbales are merged
-- considering that 
-- iso = countryterritoryCode
select count(distinct iso)
from phsm_dm_location;



select count(distinct countryterritoryCode)
from corona_dm_location;


select distinct *
from corona_dm_record
where geoId = 'JPG11668';
select distinct *
from corona_dm_location
where countryterritoryCode = '';
-- TODO country territory core '' = JPN when creating coronaDB and change countryTerritoryArea to Japan
-- TODO change change identifier of corona to countryterritoryCode (and memorize it to iso?)


-- countriesAndTerritories = country_territory_area
select country_territory_area
from phsm_dm_location
where iso = 'JPN';

select count(distinct countriesAndTerritories)
from corona_dm_location;


-- countryterritoryCode = iso_3166_1_numeric ?
-- continentExp = who_region ?


create table intergation_location (
	iso char(80) not null,
    geoId char(80) default null, -- we don't have geoId of some iso in phsm
    country_territory_area text,
	popData2019 int DEFAULT NULL,
    primary key (iso)
);

-- the table phsm_dm_who_measure is preserved
create table phsm_integration_who_measure like phsm_dm_who_measure;
insert into phsm_integration_who_measure select * from phsm_dm_who_measure;

-- the table phsm_dm_iso_region is preserved
create table integration_iso_region (
	iso char(80) not null,
	who_region char(80) not null,
    primary key (iso, who_region),
    foreign key (iso) references intergation_location(iso)
);

-- the table phms_dm_iso_iso_3166_1_numeric is preserved
create table integration_iso_iso_3166_1_numeric (
	iso char(80) not null,
	iso_3166_1_numeric int not null,
    primary key (iso, iso_3166_1_numeric),
    foreign key (iso) references intergation_location(iso)
);

-- -----------------------------

-- to merge the time tables we simply take the min date and max date from both datamarts
-- and fill the table with dates covering this range
create table integration_time(
	timeCode int NOT NULL AUTO_INCREMENT,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

-- The phsm record table is preserverd
create table corona_integration_record (
	recordingDate int not null,
    geoId char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, geoId),
    foreign key (geoId) references intergation_location(geoId), -- TODO change
    foreign key (recordingDate) references integration_time(timeCode)
);

-- The corona record table is preserverd
create table phsm_integration_record (
  measure_number int not null auto_increment,
  iso char(80) not null,
  who_code char(80) not null,
  date_start int default null,
  date_end int default null,
  who_id char(80) not null,
  admin_level text,
  area_covered text,
  comments text,
  measure_stage text,
  prev_measure_number char(80),
  following_measure_number char(80),
  reason_ended text,
  targeted text,
  enforcement text,
  non_compliance_penalty text,
  primary key(measure_number),
  foreign key (who_code) references phsm_dm_who_measure(who_code), -- TODO change
  foreign key (iso) references phsm_dm_location(iso)
);

-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the date_start ad date_end fields of the record table
select @min_date := min(recordingDate), @max_date := max(recordingDate)
from (
select distinct day, month, year
from corona_dm_time
union
select distinct distinct day, month, year
from phsm_dm_time);

-- from https://stackoverflow.com/questions/10132024/how-to-populate-a-table-with-a-range-of-dates
DROP PROCEDURE IF EXISTS filldates;
DELIMITER |
CREATE PROCEDURE filldates(dateStart DATE, dateEnd DATE)
BEGIN
  WHILE dateStart <= dateEnd DO
    INSERT INTO integration_time (day, month, year) VALUES (day(dateStart), month(dateStart), year(dateStart));
    SET dateStart = date_add(dateStart, INTERVAL 1 DAY);
  END WHILE;
END;
|
DELIMITER ;
CALL filldates(@min_date, @max_date);

insert into phsm_integration_record
select * from phsm_dm_record;

insert into corona_integration_record
select * from corona_dm_record;

