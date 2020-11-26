-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- what are the most commonly adopted first measures?

-- what is the medium delay between changes in measures?


-- (what measures need enforcement the most?)



select pl.country_territory_area, pr.iso, pr.date_start, pr.who_id, ps.*
from phsm_record pr
natural join phsm_who_measure ps
natural join phsm_location pl
where pr.date_start <= all (
select pr1.date_start 
from phsm_record pr1
where pr1.iso = pr.iso)
order by pl.country_territory_area;

select * from phsm_record
where who_id in (
select ps.who_id
from phsm_record ps
group by who_id
having count(*) > 1)
order by who_id;









WITH RECURSIVE measure_chain AS (
	SELECT measure_number, who_id, following_measure_number, prev_measure_number, 1 lvl
	FROM (select * from phsm_record limit 1000) psm
	WHERE prev_measure_number IS NULL and iso = 'AFG'-- who_id = 'ACAPS_4258'
	UNION ALL
	select pr.measure_number, pr.who_id, pr.following_measure_number, pr.prev_measure_number, lvl + 1
	from phsm_record pr, measure_chain mc
    where pr.prev_measure_number = mc.who_id)
    -- inner join on measure_chain mc on mc.who_id = pr.following_measure_number)
select *
from phsm_record ps
where ps.measure_number in (select measure_number from measure_chain)
order by date_start;

		
