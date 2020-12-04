-- Student Name: Antonio delle Canne
-- Student Number : K20113110


-- before executing this script,
-- the file PHSM2DB.sql needs to be executed
-- on the same schema used when executing this file

-- We are creating a new table indicating the area where the measure is applied, in which we are including the
-- admin_level, area_covered, and the location information we had in the DB
-- we do this because the fields admin_level and area_covered 
-- contain information about the location where the measure is applied.
-- For insatcne when the area_covered field is null and admin_level is 'national', 
-- this means that the measure is applied to the iso area.
-- We didn't do this in the normalization step since this isn't a functional 
-- dependency and since the iso and the area_covered were both in the phsms_record table.

drop table if exists phsm_dm_record;
drop table if exists phsm_dm_time;
drop table if exists phsm_dm_date;
drop table if exists phms_dm_iso_iso_3166_1_numeric;
drop table if exists phsm_dm_iso_region;
drop table if exists phsm_dm_area;
drop table if exists phsm_dm_location;
drop table if exists phsm_dm_measure_details;
drop table if exists phsm_dm_who_measure;

create table phsm_dm_location like phsm_location;
insert into phsm_dm_location select * from phsm_location;

create table phsm_dm_iso_region (
	iso char(80) not null,
	who_region char(80) not null,
    primary key (iso, who_region),
    foreign key (iso) references phsm_dm_location(iso)
);

create table phms_dm_iso_iso_3166_1_numeric (
	iso char(80) not null,
	iso_3166_1_numeric int not null,
    primary key (iso, iso_3166_1_numeric),
    foreign key (iso) references phsm_dm_location(iso)
);

create table phsm_dm_area (
	area_code int not null auto_increment,
    iso char(80) not null,
    admin_level text,
    area_covered text,
    primary key (area_code),
	foreign key (iso) references phsm_dm_location(iso)
);

create table phsm_dm_who_measure like phsm_who_measure;
insert into phsm_dm_who_measure select * from phsm_who_measure;

-- since this table contains all of the attributes (see comments in PHSM2DB.sql file)
-- necessary to uniquely identify each record, each row will correspond to a record
-- therefore we can use the pk of the phsm_record table as an identifier
create table phsm_dm_measure_details(
  measure_number int not null,
  who_code char(80) not null,
  who_id char(80) not null,
  comments text,
  measure_stage text,
  prev_measure_number char(80),
  following_measure_number char(80),
  reason_ended text,
  targeted text,
  enforcement text,
  non_compliance_penalty text,
  primary key(measure_number),
  foreign key (who_code) references phsm_dm_who_measure(who_code)
);

create table phsm_dm_date(
	timeCode int NOT NULL AUTO_INCREMENT,
    date date default null,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

create table phsm_dm_time(
	time_code int NOT NULL AUTO_INCREMENT,
	date_start int,
    date_end int,
	PRIMARY KEY (time_code),
    foreign key (date_start) references phsm_dm_date(timeCode),
    foreign key (date_end) references phsm_dm_date(timeCode)
);

create table phsm_dm_record (
	measure_number int not null,
    time_code int not null,
    area_code int not null,
    foreign key (time_code) references phsm_dm_time(time_code),
	foreign key (area_code) references phsm_dm_area(area_code),
    foreign key (measure_number) references phsm_dm_measure_details(measure_number)
);

-- ---
-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the date_start ad date_end fields of the phsm_record table
-- to make the integration easier we are generating the same range of dates for both
-- the corona and the phsm data mart going from '2019-9-30' '2021-12-31'
-- this interval allows to fit the dates contained in both the databases
-- and provides a buffer to insert both older records,
-- in cases, for example, it turns out that the epidemic started earlier
-- and older recorded cases are found,
-- and to add more recent records as the epidemic develops
-- (here the time interval is '2019-12-31' to '2020-10-01')


set @min_date = cast('2019-9-30' as date);
set @max_date = cast('2021-12-31' as date);

-- from https://stackoverflow.com/questions/10132024/how-to-populate-a-table-with-a-range-of-dates
DROP PROCEDURE IF EXISTS filldates;
DELIMITER |
CREATE PROCEDURE filldates(dateStart DATE, dateEnd DATE)
BEGIN
  WHILE dateStart <= dateEnd DO
    INSERT INTO phsm_dm_date (date, day, month, year) VALUES (dateStart, day(dateStart), month(dateStart), year(dateStart));
    SET dateStart = date_add(dateStart, INTERVAL 1 DAY);
  END WHILE;
END;
|
DELIMITER ;
CALL filldates(@min_date, @max_date);
--

insert into phms_dm_iso_iso_3166_1_numeric (iso, iso_3166_1_numeric)
select distinct iso, iso_3166_1_numeric
from phms_iso_iso_3166_1_numeric;

insert into phsm_dm_iso_region (who_region, iso)
select distinct who_region, iso
from phsm_iso_region;


insert into phsm_dm_area (iso, admin_level, area_covered)
select distinct iso, admin_level, area_covered
from phsm_record;

insert into phsm_dm_measure_details (
  measure_number, who_code, who_id, comments,
  measure_stage, prev_measure_number,
  following_measure_number, reason_ended,
  targeted, enforcement, non_compliance_penalty)
select distinct measure_number, who_code, who_id, comments,
  measure_stage, prev_measure_number,
  following_measure_number, reason_ended,
  targeted, enforcement, non_compliance_penalty
from phsm_record;

insert into phsm_dm_time (date_start, date_end)
select distinct t1.timeCode, t2.timeCode
from phsm_record pr1
left join phsm_dm_date t1
on day(pr1.date_start) = t1.day and month(pr1.date_start) = t1.month and year(pr1.date_start) = t1.year
left join phsm_dm_date t2
on day(pr1.date_end) = t2.day and month(pr1.date_end) = t2.month and year(pr1.date_end) = t2.year;

insert into phsm_dm_record (measure_number, time_code, area_code)
select pmd.measure_number, tm.time_code, ar.area_code
from phsm_record pr1
join phsm_dm_area ar
on pr1.iso <=> ar.iso and pr1.area_covered <=> ar.area_covered
join phsm_dm_measure_details pmd
on pr1.measure_number <=> pmd.measure_number
left join phsm_dm_date t1
on day(pr1.date_start) <=> t1.day and month(pr1.date_start) <=> t1.month and year(pr1.date_start) <=> t1.year
left join phsm_dm_date t2
on day(pr1.date_end) <=> t2.day and month(pr1.date_end) <=> t2.month and year(pr1.date_end) <=> t2.year
join phsm_dm_time tm
on tm.date_start <=> t1.timeCode and tm.date_end <=> t2.timeCode;