-- Student Name: Antonio delle Canne
-- Student Number : K20113110

drop table if exists integration_time;


create table integration_time(
	timeCode int NOT NULL AUTO_INCREMENT,
	day int DEFAULT NULL,
	month int DEFAULT NULL,
	year int DEFAULT NULL,
	PRIMARY KEY (timeCode)
);


insert into integration_time(day, month, year)
select distinct day, month, year
from corona_dm_time
union
select distinct distinct day, month, year
from phsm_dm_time
order by year, month, day asc;