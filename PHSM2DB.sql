-- Student Name: Antonio delle Canne
-- Student Number : K20113110


-- before executing this script,
-- the file backupDataset.sql needs to be executed
-- on the same schema used when executing this file

-- The dependencies informaitons are obtained from the phsm documents provided with the dataset
-- Table dependencies:
-- lineID uniquely identifies each row
-- iso <-> iso31661Numeric <-> countryTerritoryArea
-- iso -> who_region
-- who_code -> who_category, who_subcategory, who_measure


-- 1NF

-- * Since we are using the distinct comand to eliminate identical rows (without including the original lineID attribute),
-- the line ids are recreated.
-- * textual date representation is converted to sql date data type
-- * all the empty strings '' are replaced with NULL
-- * as in the documentation, when area_covered is NULL, it means that the measure is applied to the country / territory
-- * when enforcement is null we consider it to be 'Not known' and we replace it as such
-- * by looking at the dataset the measure_stage attribute assumes the values 'new', 'modification', 'extension',
-- 'phase-out', 'introduction / extension of measures', 'finish', NULL.
-- Since since all the measures where the measure_satge attribute assumes the value 'introduction / extension of measures'
-- all have prev_measure_number at null, we assume that they all are are newly introduced measures.
-- Considering this, since the meaning of 'introduction / extension of measures' is redundant
-- with the value 'new' and with the value 'extension' ,where the measure_stage attribute 
-- assumes the value 'introduction / extension of measures', this will be changed to 'new'

drop table if exists phsm_record_1NF;
create table phsm_record_1NF (
  measure_number int not null auto_increment,
  who_code char(80) not null,
  who_id char(80) not null,
  who_region char(80) not null,
  country_territory_area text not null,
  iso char(80) not null,
  iso_3166_1_numeric int not null,
  admin_level text not null,
  who_category text not null,
  who_subcategory text,
  who_measure text,
  area_covered text,
  date_start date,
  date_end date,
  comments text,
  measure_stage text,
  prev_measure_number text,
  following_measure_number text,
  reason_ended text,
  targeted text,
  enforcement text not null,
  non_compliance_penalty text,
  PRIMARY KEY (measure_number)
);

insert into phsm_record_1NF (who_id, who_region, country_territory_area, iso, iso_3166_1_numeric, admin_level, area_covered, 
	who_code, who_category, who_subcategory, who_measure, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty)
select distinct who_id, who_region, country_territory_area, iso, iso_3166_1_numeric, admin_level, if ( area_covered = '', null, area_covered), 
	who_code, who_category, if ( who_subcategory = '' , null , who_subcategory), if ( who_measure = '' , null , who_measure), if ( comments = '', null, comments), 
    if ( date_start = '' , null , STR_TO_DATE(date_start,'%d/%m/%Y')), if ( measure_stage = '' , null , if(measure_stage = 'introduction / extension of measures', 'new', measure_stage)), 
    if ( prev_measure_number = '' , null , prev_measure_number), if ( following_measure_number = '' , null , following_measure_number), 
    if ( date_end = '' , null , STR_TO_DATE(date_end,'%d/%m/%Y')), if ( reason_ended= '' , null , reason_ended), 
    if ( targeted= '' , null , targeted), if ( enforcement= '' , 'Not known' , enforcement), if ( non_compliance_penalty= '' , null , non_compliance_penalty)
from phsm;

-- cleaning step
-- in Pakistan records, both PAK and IND iso appear, since IND only happens two times,
-- we assume this is an error and we correct it by updating
-- the related fields: who_region, iso, iso_3166_1_numeric
-- select distinct country_territory_area, who_region, iso, iso_3166_1_numeric from phsm_record_1NF where country_territory_area = "Pakistan";
update phsm_record_1NF
set who_region='EMRO', iso='PAK', iso_3166_1_numeric=586
where country_territory_area='Pakistan';

-- After cleaning the data we tried to find a combination of attributes that could serve as primary key,
-- and by trial and error, we identified this combination to be:
-- who_code, who_id, targeted, comments
-- this can be verified by running the following (commented) query
-- however we can see that the comments attribute is in it, and it can't be removed from
-- the combination because there are rows that are ientical and the only difference is the comment
-- since the comment can't be part of the primary key because it doesn't have intrinsic meaning
-- and therefore cannot logically identify something, plus is is a text field with very variable length,
-- therefore making it unpractical for this use,
-- we keep using the artificial primary key 'measure_number' generated during the 1NF normalization 
--
-- SELECT *
-- FROM phsm_record_1NF
-- GROUP BY who_code, who_id, targeted, comments
-- HAVING COUNT(*) > 1;
--

-- 2NF
-- A relation schema R is in 2NF if every nonprime attribute A in R is
-- fully functionally dependent on the primary key of R.
--
-- the schema here is the same as the one in 1NF since all the attributes in the table fully depend on the primary key

-- 3NF
-- A relation schema R is in 3NF if it satisfies 2NF and 
-- no nonprime attribute of R is transitively dependent on the primary key
--
-- * By observing the table dependencies, we see that who_code -> who_category, who_subcategory, who_measure.
-- For this reason these are put in a separate table.
-- * The same is done for iso <-> iso31661Numeric <-> countryTerritoryArea ; iso -> who_region
-- * Sudan,Israel,Pakistan have different who_regions (2). To accomodate this this we are creating the table phsm_iso_region
-- * Also the iso with value 'ISR', is associated with two different iso_3166_1_numeric values. 
-- To accomodate this we are creating the table phms_iso_iso_3166_1_numeric


drop table if exists phsm_record;
drop table if exists phms_iso_iso_3166_1_numeric;
drop table if exists phsm_iso_region;
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
	primary key (iso)
);

create table phsm_iso_region(
	iso char(80) not null,
	who_region char(80) not null,
    primary key (iso, who_region),
    foreign key (iso) references phsm_location(iso)
);

create table phms_iso_iso_3166_1_numeric(
	iso char(80) not null,
	iso_3166_1_numeric int not null,
    primary key (iso, iso_3166_1_numeric),
    foreign key (iso) references phsm_location(iso)
);

create table phsm_record (
  measure_number int not null auto_increment,
  iso char(80) not null,
  who_code char(80) not null,
  date_start date,
  date_end date,
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

insert into phsm_who_measure (who_code, who_category, who_subcategory, who_measure)
select distinct  who_code, who_category, who_subcategory, who_measure
from phsm_record_1NF;

insert into phsm_location (country_territory_area, iso)
select distinct country_territory_area, iso
from phsm_record_1NF;

insert into phms_iso_iso_3166_1_numeric (iso, iso_3166_1_numeric)
select distinct iso, iso_3166_1_numeric
from phsm_record_1NF;


insert into phsm_iso_region (who_region, iso)
select distinct who_region, iso
from phsm_record_1NF;

insert into phsm_record (measure_number, who_id, iso, admin_level, area_covered, who_code, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty)
select distinct measure_number, who_id, iso, admin_level, area_covered, who_code, comments, date_start, measure_stage, prev_measure_number, 
    following_measure_number, date_end, reason_ended, targeted, enforcement, non_compliance_penalty
from phsm_record_1NF;
