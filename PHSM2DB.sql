-- Student Name: Antonio delle Canne
-- Student Number : K20113110


-- TODO maybe include SOURCE *.sql


-- The dependencies informaitons are obtained from the phsm documents provided with the dataset
-- Table dependencies:
-- lineID uniquely identifies each row
-- (who_id, measure_number) uniquely identifies each row
-- iso <-> iso31661Numeric <-> countryTerritoryArea
-- iso -> who_region
-- who_code -> who_category, who_subcategory, who_measure


-- 1NF
-- eliminate lineID and use of distinct to eliminate duplicated records
-- line ids are reassigned since in the original dataset some rows are duplicates
-- solve incongruences in the data, for instance 
-- Sudan,Israel,Pakistan have different who_regions (2) in different records, so one region will be chosen
-- by observing the dataset is emerged that the who_id indicates the announcment (an act/law) of multiple measures.
-- by observing the data is is emerged that each who_id can contain different measure, so each measure will be identified
-- by the who_id and by a progressive id within the who_id (measure_number)
-- text is converted to date
-- since in the dataset there aren't any null values in date_start and date_ed fields, we assume that meaures are inserted
-- in the database after they made their course and are no longer active

-- TODO unify/see what's up with who_ids
-- TODO see what's up with date start 00000000000 in phsm research queries

drop table if exists phsm_record_1NF;
create table phsm_record_1NF (
  measure_number int not null auto_increment,
  who_id char(80) not null,
  who_region text,
  country_territory_area text,
  iso char(80) not null,
  iso_3166_1_numeric int default null,
  admin_level text,
  area_covered text,
  who_code mediumtext,
  who_category text,
  who_subcategory text,
  who_measure text,
  comments text,
  date_start date,
  measure_stage text,
  prev_measure_number text,
  following_measure_number text,
  date_end date,
  reason_ended text,
  targeted text,
  enforcement text,
  non_compliance_penalty text,
  PRIMARY KEY (measure_number)
);

/*
drop trigger if exists trg_phsm_record_1NF_increment;
DELIMITER //
CREATE TRIGGER trg_phsm_record_1NF_increment
BEFORE INSERT ON phsm_record_1NF
FOR EACH ROW
BEGIN
      DECLARE nseq int;
      SELECT  COALESCE(MAX(measure_number), 0) + 1
      INTO    nseq
      FROM    phsm_record_1NF
      WHERE   who_id = NEW.who_id;
      SET NEW.measure_number = nseq;
END //
DELIMITER ;
*/

insert into phsm_record_1NF (who_id, who_region, country_territory_area, iso, iso_3166_1_numeric, admin_level, area_covered, 
	who_code, who_category, who_subcategory, who_measure, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty)
select distinct who_id, who_region, country_territory_area, iso, iso_3166_1_numeric, admin_level, area_covered, 
	who_code, who_category, who_subcategory, who_measure, comments, STR_TO_DATE(date_start,'%d/%m/%Y'), measure_stage, prev_measure_number, 
    following_measure_number, STR_TO_DATE(date_end,'%d/%m/%Y'), reason_ended, targeted, enforcement, non_compliance_penalty
from phsm;

-- cleaning step
-- in Pakistan records, both PAK and IND iso appear, this field is unified to PAK, updating the related fields who_region, iso, iso_3166_1_numeric
-- the same is done for Sudan and Israel, Sudan will be considered EMRO, Israel will be considered EMRO
-- select distinct country_territory_area, who_region, iso, iso_3166_1_numeric from phsm_record_1NF where country_territory_area = "Pakistan";
update phsm_record_1NF
set who_region='EMRO', iso='PAK', iso_3166_1_numeric=586
where country_territory_area='Pakistan';

-- select distinct country_territory_area, who_region, iso, iso_3166_1_numeric from phsm_record_1NF where country_territory_area = "Israel";
update phsm_record_1NF
set who_region='EMRO', iso='ISR', iso_3166_1_numeric=275
where country_territory_area='Israel';


-- select distinct country_territory_area, who_region, iso, iso_3166_1_numeric from phsm_record_1NF where country_territory_area = "Sudan";
update phsm_record_1NF
set who_region='EMRO', iso='SDN', iso_3166_1_numeric=729
where country_territory_area='Sudan';

-- change '' with NULL
update phsm_record_1NF
set prev_measure_number=NULL
where prev_measure_number='';

update phsm_record_1NF
set following_measure_number=NULL
where following_measure_number='';


-- 2NF
-- A relation schema R is in 2NF if every nonprime attribute A in R is
-- fully functionally dependent on the primary key of R.
--
-- the schema here is the same as the one in 1NF since all the attributes in the table fully depend on the primary key

-- 3NF
-- A relation schema R is in 3NF if it satisfies 2NF and 
-- no nonprime attribute of R is transitively dependent on the primary key
--
-- by observing the table dependencies, we see that who_code -> who_category, who_subcategory, who_measure , aso these are put in a separate table
-- the same is done for iso <-> iso31661Numeric <-> countryTerritoryArea ; iso -> who_region
-- also previous and following measure number are references respectively to previous and following phsm disposition's who_id so this is modeled
-- through the use of foreign keys


drop table if exists phsm_record;
drop table if exists phsm_location;
drop table if exists phsm_who_measure;


create table phsm_who_measure (
	who_code char(80) not null,
	who_category text,
	who_subcategory text,
	who_measure text,
    primary key (who_code)
);


create table phsm_location (
	iso char(80) not null,
	country_territory_area text,
	iso_3166_1_numeric int default null,
    who_region text,
	primary key (iso)
);

create table phsm_dm_record (
  measure_number int not null auto_increment,
  iso char(80) not null,
  who_code char(80) not null,
  date_start date not null,
  date_end text not null,
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

/*
drop trigger if exists trg_phsm_record_increment;
DELIMITER //
CREATE TRIGGER trg_phsm_record_increment
BEFORE INSERT ON phsm_record
FOR EACH ROW
BEGIN
      DECLARE nseq int;
      SELECT  COALESCE(MAX(measure_number), 0) + 1
      INTO    nseq
      FROM    phsm_record_1NF
      WHERE   who_id = NEW.who_id;
      SET NEW.measure_number = nseq;
END //
DELIMITER ;
*/


insert into phsm_who_measure (who_code, who_category, who_subcategory, who_measure)
select distinct  who_code, who_category, who_subcategory, who_measure
from phsm_record_1NF;

insert into phsm_location (who_region, country_territory_area, iso, iso_3166_1_numeric)
select distinct who_region, country_territory_area, iso, iso_3166_1_numeric
from phsm_record_1NF;

insert into phsm_record (who_id, iso, admin_level, area_covered, who_code, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty)
select distinct who_id, iso, admin_level, area_covered, who_code, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty
from phsm_record_1NF;



select * from phsm_record
order by iso, date_start asc;