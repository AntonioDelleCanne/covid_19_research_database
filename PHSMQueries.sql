-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- what are the most commonly adopted first measures?

select pl.country_territory_area, pr.iso, pr.date_start, pr.who_id, ps.*, pr.enforcement, ts.day as day_start, 
ts.month as month_start, ts.year as year_start, te.day as day_end, te.month as month_end, te.year as year_end
from phsm_dm_record pr
natural join phsm_dm_who_measure ps
natural join phsm_dm_location pl
join phsm_dm_time ts
on ts.timeCode = pr.date_start
join phsm_dm_time te
on te.timeCode = pr.date_end
where pr.date_start = (
select pr1.date_start
from phsm_dm_record pr1
join phsm_dm_time t1
on t1.timeCode = pr1.date_start
where pr1.iso = pr.iso
order by t1.year, t1.month, t1.day asc
limit 1)
order by pl.country_territory_area;


-- what is the most adopted level of enforcement for each measure?

select ps.*, pr.enforcement as most_applied_level_of_enforcement
from phsm_dm_record pr
natural join phsm_dm_who_measure ps
where enforcement != 'Not known'
group by pr.who_code, pr.enforcement
having count(*) >= all(
select count(*)
from phsm_dm_record pr1
natural join phsm_dm_who_measure ps1
where ps1.who_code = ps.who_code
and enforcement != 'Not known'
group by ps1.who_code, pr1.enforcement)
order by who_code;

-- TODO understand why some who_codes are not in the record table
-- -------------------------------

select * from phsm_dm_who_measure
where who_code not in (
select pr.who_code
from phsm_dm_record pr
natural join phsm_dm_who_measure ps
-- where enforcement != 'Not known'
group by pr.who_code, pr.enforcement
having count(*) >= all(
select count(*)
from phsm_dm_record pr1
natural join phsm_dm_who_measure ps1
where ps1.who_code = pr.who_code
and enforcement != 'Not known'
group by ps1.who_code, pr1.enforcement)
order by who_code)
order by who_code;

select who_code, enforcement, count(*)
from phsm_dm_record pr1
natural join phsm_dm_who_measure ps1
group by ps1.who_code, pr1.enforcement
order by who_code;

select distinct * 
from phsm_dm_record
where who_code = '1.3';
