-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- SOURCE corona2DM.sql
-- SOURCE PHSM2DM.sql

drop table if exists corona_integration_record;
drop table if exists phsm_integration_record;
drop table if exists integration_iso_region;
drop table if exists integration_iso_iso_3166_1_numeric;
drop table if exists integration_area;
drop table if exists intergation_location;
drop table if exists integration_time_interval;
drop table if exists integration_time;
drop table if exists integration_measure_details;
drop table if exists integration_who_measure;

-- -----------------------
-- this table merges records from  corona_dm_location and phsm_dm_location
-- iso = countryterritoryCode
-- null = geoId
-- null = popData2019
-- country_territory_area = countriesAndTerritories
create table intergation_location (
	iso char(80) not null,
    geoId char(80) default null, -- we don't have geoId of some iso in phsm
    country_territory_area text,
	popData2019 int DEFAULT NULL,
    primary key (iso)
);
insert into intergation_location (iso, geoId, country_territory_area, popData2019)
select pl.iso, cl.geoId, pl.country_territory_area, cl.popData2019
from phsm_dm_location pl
left join corona_dm_location cl
on pl.iso = cl.countryterritoryCode
union all
select cl.countryterritoryCode as iso, cl.geoId, cl.countriesAndTerritories as country_territory_area, cl.popData2019
from phsm_dm_location pl
right join corona_dm_location cl
on pl.iso = cl.countryterritoryCode
where pl.iso is null;

-- this table merges records from  corona_dm_location and phsm_dm_iso_region
-- continentExp = who_region
-- the table phsm_dm_iso_region is preserved
create table integration_iso_region (
	iso char(80) not null,
	who_region char(80) not null,
    primary key (iso, who_region),
    foreign key (iso) references intergation_location(iso)
);
insert into integration_iso_region (iso, who_region)
select pl.iso, pl.who_region
from phsm_dm_iso_region pl
left join corona_dm_location cl
on pl.iso = cl.countryterritoryCode
union all
select cl.countryterritoryCode as iso, cl.continentExp as who_region
from phsm_dm_iso_region pl
right join corona_dm_location cl
on pl.iso = cl.countryterritoryCode
where pl.iso is null;


-- the table phms_dm_iso_iso_3166_1_numeric is preserved
create table integration_iso_iso_3166_1_numeric (
	iso char(80) not null,
	iso_3166_1_numeric int not null,
    primary key (iso, iso_3166_1_numeric),
    foreign key (iso) references intergation_location(iso)
);
insert into integration_iso_iso_3166_1_numeric select * from phms_dm_iso_iso_3166_1_numeric;

-- the table phsm_dm_who_measure is preserved
create table integration_who_measure like phsm_dm_who_measure;
insert into integration_who_measure select * from phsm_dm_who_measure;

-- the table phsm_dm_measure_details is preserved
create table integration_measure_details(
  measure_number int not null,
  who_code char(80) not null,
  who_id char(80) not null,
  admin_level text,
  comments text,
  measure_stage text,
  prev_measure_number char(80),
  following_measure_number char(80),
  reason_ended text,
  targeted text,
  enforcement text,
  non_compliance_penalty text,
  primary key(measure_number),
  foreign key (who_code) references integration_who_measure(who_code)
);
insert into integration_measure_details select * from phsm_dm_measure_details;

-- the table phsm_dm_area is preserved
create table integration_area (
	area_code int not null auto_increment,
    iso char(80) not null,
    area_covered text,
    primary key (area_code),
	foreign key (iso) references phsm_dm_location(iso)
);
insert into integration_area select * from phsm_dm_area;

-- this table corresponds to the phsm_dm_date table
-- and to the corona_dm_tim table, as explained during
-- the data mart creation, contain the same values
create table integration_time like corona_dm_time;
insert into integration_time select * from corona_dm_time;

-- the phsm_dm_time table is preserved
create table integration_time_interval(
	time_code int NOT NULL AUTO_INCREMENT,
	date_start int,
    date_end int,
	PRIMARY KEY (time_code),
    foreign key (date_start) references integration_time(timeCode),
    foreign key (date_end) references integration_time(timeCode)
);
insert into integration_time_interval select * from phsm_dm_time;

-- The corona_dm_record table is preserverd
create table corona_integration_record (
	recordingDate int not null,
    countryterritoryCode char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, countryterritoryCode),
    foreign key (countryterritoryCode) references intergation_location(iso),
    foreign key (recordingDate) references integration_time(timeCode)
);
insert into corona_integration_record select * from corona_dm_record;

-- The phsm_dm_record table is preserverd
create table phsm_integration_record (
	measure_number int not null,
    time_code int not null,
    area_code int not null,
    foreign key (time_code) references integration_time_interval(time_code),
	foreign key (area_code) references integration_area(area_code),
    foreign key (measure_number) references integration_measure_details(measure_number)
);
insert into phsm_integration_record select * from phsm_dm_record;

-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the date_start ad date_end fields of the record table
/*select @min_date := min(recordingDate), @max_date := max(recordingDate)
from (
select distinct day, month, year
from corona_dm_time
union
select distinct distinct day, month, year
from phsm_dm_time);
*/

