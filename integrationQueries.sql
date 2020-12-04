-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- By querying the dataset we noticed that frequently the first phsm is adopted before the first case of corona virus:
-- The explanation of this is that many states are adopting preventive measures, like closing the borders, in order to 
-- prevent people coming from infected countries to spread the virus.
-- So we found it interesting to answer this question:
-- how many countries adopted preventive measures and how many didn't, and what is the median delay between the adoption
-- of the preventive measure and the recodring of the first case in the country?

select sum(if(fm.first_measure_date - fc.first_recorded_case < 0, 1, 0)) as states_that_adopted_preventive_measures, sum(if(fm.first_measure_date - fc.first_recorded_case >= 0, 1, 0)) states_that_did_not_adopt_preventive_measures,
round(avg(if(fc.first_recorded_case  - fm.first_measure_date > 0, fc.first_recorded_case  - fm.first_measure_date , null))) as avg_delay_preventive_measure_and_first_case 
from (
select distinct cr.countryterritoryCode as iso, tm.date as first_recorded_case
from corona_integration_record cr
join integration_time tm
on cr.recordingDate = tm.timeCode
where tm.timeCode = (
select tm1.timeCode
from corona_integration_record cr1
join integration_time tm1
on cr1.recordingDate = tm1.timeCode
where cr1.countryterritoryCode = cr.countryterritoryCode
and cr1.cases > 0
order by tm1.date asc
limit 1)
) fc
join (
select distinct ar.iso, tm.date as first_measure_date
from phsm_integration_record pr
join integration_area ar
on ar.area_code = pr.area_code
join integration_time_interval tmi
on tmi.time_code = pr.time_code
join integration_time tm
on tmi.date_start = tm.timeCode
where tm.timeCode = (
select tm1.timeCode
from phsm_integration_record pr1
join integration_area ar1
on ar1.area_code = pr1.area_code
join integration_time_interval tmi1
on tmi1.time_code = pr1.time_code
join integration_time tm1
on tmi1.date_start = tm1.timeCode
where ar1.iso = ar.iso
order by tm1.date asc
limit 1)
) fm
on fc.iso = fm.iso;

-- what is the number of new cases per 100.000 population when countries close schools at national levels?
-- by answering this question we are interested in seeing what countries
-- showed the most tollerance to the epidemic
--
-- by looking at the documentation we can see that the measure corresponding
-- to shool closure is '4.1.2'
-- also according to the documentation, in order for the measure to be applied 
-- at national level the admin_level field in the integration_area table is set to 'national'

select cl.iso, cl.country_territory_area, cr.cases, cl.popData2019, cr.cases * 100000 / cl.popData2019 as cases_100000_pop_school_closure
from corona_integration_record cr
join integration_location cl
on cr.countryterritoryCode = cl.iso
join (
select distinct tm.timeCode, ar.iso
from phsm_integration_record pr
join integration_area ar
on ar.area_code = pr.area_code
join integration_time_interval tmi
on tmi.time_code = pr.time_code

join integration_time tm
on tmi.date_start = tm.timeCode
where tm.timeCode = (
select tm1.timeCode
from phsm_integration_record pr1
join integration_measure_details dt1
on pr1.measure_number = dt1.measure_number
join integration_area ar1
on ar1.area_code = pr1.area_code
join integration_time_interval tmi1
on tmi1.time_code = pr1.time_code
join integration_time tm1
on tmi1.date_start = tm1.timeCode
where ar1.iso = ar.iso
and dt1.who_code = '4.1.2'
and ar1.admin_level = 'national'
order by tm1.date asc
limit 1
)) scls
on cr.recordingDate = scls.timeCode 
and cr.countryterritoryCode = scls.iso
where cl.popData2019 is not null
order by cases_100000_pop_school_closure desc
limit 10;

