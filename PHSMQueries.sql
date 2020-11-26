-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- what are the most commonly adopted first measures?

select pl.country_territory_area, pr.iso, pr.date_start, pr.who_id, ps.*
from phsm_record pr
natural join phsm_who_measure ps
natural join phsm_location pl
where pr.date_start <= all (
select pr1.date_start 
from phsm_record pr1
where pr1.iso = pr.iso)
order by pl.country_territory_area;


-- here thefirst measures are ordered by the most popular to least popular