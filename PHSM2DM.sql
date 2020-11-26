-- Student Name: Antonio delle Canne
-- Student Number : K20113110


drop table if exists phsm_dm_time;
drop table if exists phsm_dm_location;
drop table if exists phsm_dm_who_measure;
drop table if exists phsm_dm_record;


create table phsm_dm_who_measure (
	who_code char(80) not null,
	who_category text,
	who_subcategory text,
	who_measure text,
    primary key (who_code)
);

create table phsm_dm_time(
	timeCode int NOT NULL AUTO_INCREMENT,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);

create table phsm_dm_location (
	iso char(80) not null,
	country_territory_area text,
	iso_3166_1_numeric int default null,
    who_region text,
	primary key (iso)
);

create table phsm_dm_record (
  measure_number int not null auto_increment,
  iso char(80) not null,
  who_code char(80),
  date_start date,
  date_end text,
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
  foreign key (who_code) references phsm_who_measure(who_code),
  foreign key (iso) references phsm_location(iso)
);


insert into phsm_dm_time(day, month, year)
select distinct day(date_start), month(date_start), year(date_start)
from phsm_record
where date_start is not null
union 
select distinct day(date_end), month(date_end), year(date_end)
from phsm_record
where date_end is not null
order by year, month, day asc;