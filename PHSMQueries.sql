-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- before executing this script,
-- the file PHSM2DM.sql needs to be executed
-- on the same schema used when executing this file

-- what are the most commonly adopted first measures?
-- execution time on intel core i5 processor 2 sec
select pm.*, count(*) as number_of_times_adopted_as_first_measure
from phsm_dm_record pr
join phsm_dm_measure_details pd
on pr.measure_number = pd.measure_number
join phsm_dm_who_measure pm
on pd.who_code = pm.who_code
join phsm_dm_area rg
on rg.area_code = pr.area_code
where pd.who_code = (
select pd1.who_code
from phsm_dm_record pr1
join phsm_dm_measure_details pd1
on pr1.measure_number = pd1.measure_number
join phsm_dm_area rg1
on rg1.area_code = pr1.area_code
join phsm_dm_time tm1
on tm1.time_code = pr1.time_code
join phsm_dm_date dt1
on tm1.date_start = dt1.timeCode
where rg1.iso = rg.iso
group by pd1.who_code, tm1.date_start
order by dt1.year asc, dt1.month asc, dt1.day asc
limit 1)
group by pd.who_code
order by count(*) desc
limit 5;


-- what is the most adopted level of enforcement for each phsm?
-- when there are ties, both level of enforcement are shown
-- execution time on intel core i5 processor 2 sec
select pm.*, pd.enforcement as most_adopted_level_of_enforcement
from phsm_dm_record pr
join phsm_dm_measure_details pd
on pr.measure_number = pd.measure_number
join phsm_dm_who_measure pm
on pd.who_code = pm.who_code
where enforcement != 'Not known'
group by pd.who_code, pd.enforcement
having count(*) >= all(
select count(*)
from phsm_dm_record pr1
join phsm_dm_measure_details pd1
where pr1.measure_number = pd1.measure_number
and enforcement != 'Not known'
and pd1.who_code = pd.who_code
group by pd1.who_code, pd1.enforcement)
order by pm.who_code;
