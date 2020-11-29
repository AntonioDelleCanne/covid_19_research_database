-- Student Name: Antonio delle Canne
-- Student Number : K20113110

drop table if exists phsm_dm_record;
drop table if exists phsm_dm_time;
drop table if exists phms_dm_iso_iso_3166_1_numeric;
drop table if exists phsm_dm_iso_region;
drop table if exists phsm_dm_location;
drop table if exists phsm_dm_who_measure;

create table phsm_dm_who_measure like phsm_who_measure;
insert into phsm_dm_who_measure select * from phsm_who_measure;


create table phsm_dm_location like phsm_location;
insert into phsm_dm_location select * from phsm_location;

create table phsm_dm_time(
	timeCode int NOT NULL AUTO_INCREMENT,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

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

create table phsm_dm_record (
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
  foreign key (who_code) references phsm_dm_who_measure(who_code),
  foreign key (iso) references phsm_dm_location(iso)
);

-- fill the time dimension table with dates from the minumum date value to the maximum date value present
-- in the date_start ad date_end fields of the record table

select @min_date := min(dates), @max_date := max(dates) from
(select distinct date_start as dates
from phsm_record
where date_start is not null
union 
select distinct date_end as dates
from phsm_record
where date_end is not null) as dates;

-- from https://stackoverflow.com/questions/10132024/how-to-populate-a-table-with-a-range-of-dates
DROP PROCEDURE IF EXISTS filldates;
DELIMITER |
CREATE PROCEDURE filldates(dateStart DATE, dateEnd DATE)
BEGIN
  WHILE dateStart <= dateEnd DO
    INSERT INTO phsm_dm_time (day, month, year) VALUES (day(dateStart), month(dateStart), year(dateStart));
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


insert into phsm_dm_record (measure_number, who_id, iso, admin_level, area_covered, who_code, comments, measure_stage, prev_measure_number, 
    following_measure_number, reason_ended, targeted, enforcement, non_compliance_penalty, date_start, date_end)
select distinct measure_number, who_id, iso, admin_level, area_covered, who_code, comments, measure_stage, prev_measure_number, 
    following_measure_number, reason_ended, targeted, enforcement, non_compliance_penalty, pt_start.timeCode , pt_end.timeCode
from phsm_record pr
join phsm_dm_time pt_start
on day(pr.date_start) = pt_start.day and month(pr.date_start) = pt_start.month and year(pr.date_start) = pt_start.year
join phsm_dm_time pt_end
on day(pr.date_end) = pt_end.day and month(pr.date_end) = pt_end.month and year(pr.date_end) = pt_end.year;