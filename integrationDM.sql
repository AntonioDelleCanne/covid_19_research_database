-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- SOURCE corona2DM.sql
-- SOURCE PHSM2DM.sql

drop table if exists corona_integration_record;
drop table if exists phsm_integration_record;
drop table if exists integration_iso_region;
drop table if exists integration_iso_iso_3166_1_numeric;
drop table if exists intergation_location;
drop table if exists integration_time;
drop table if exists phsm_integration_who_measure;

-- -----------------------
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

-- ------------ dm implementation begins here ------------------

-- this table corresponds to the phsm_dm_date table
-- and to the corona_dm_tim table, as explained during
-- the data mart creation, contain the same values
create table integration_time like corona_dm_time;
insert into integration_time select * from corona_dm_time;


create table intergation_location(
);

-- The corona record table is preserverd
create table corona_integration_record (
	recordingDate int not null,
    countryterritoryCode char(80) not null,
    cases int DEFAULT NULL,
	deaths int DEFAULT NULL,
    primary key (recordingDate, countryterritoryCode),
    foreign key (countryterritoryCode) references intergation_location(iso),
    foreign key (recordingDate) references integration_time(timeCode)
);

-- The phsm record table is preserverd
create table phsm_integration_record (

);

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

insert into phsm_integration_record
select * from phsm_dm_record;

insert into corona_integration_record
select * from corona_dm_record;

