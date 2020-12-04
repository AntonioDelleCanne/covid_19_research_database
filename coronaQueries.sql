-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- before executing this script,
-- the file corona2DM.sql needs to be executed
-- on the same schema used when executing this file


-- when are the first cases of covid-19 recorded in each country?
-- the caes are also shown to have an idea of what could be the dealy between the real arrival of the virus and the actual recording date
-- execution time on intel core i5 processor 25 sec
select distinct cl.countriesAndTerritories, cl.countryterritoryCode, cr.cases, ct.date
from corona_dm_record as cr
join corona_dm_location cl
on cr.countryterritoryCode = cl.countryterritoryCode
join corona_dm_time ct
on ct.timeCode = cr.recordingDate
where cr.cases > 0
and cr.recordingDate = (select cr1.recordingDate 
from corona_dm_record as cr1
join corona_dm_time ct1
on ct1.timeCode = cr1.recordingDate
where cr1.countryterritoryCode = cr.countryterritoryCode
and cr1.cases > 0
order by year asc, month asc, day asc
limit 1)
order by cl.countriesAndTerritories asc;

-- to allow a more focused vision here with the following quesries we show the 5 countries where covid-19 arrived first
-- execution time on intel core i5 processor 25 sec
select distinct cl.countriesAndTerritories, cl.countryterritoryCode, cr.cases, ct.date
from corona_dm_record as cr
join corona_dm_location cl
on cr.countryterritoryCode = cl.countryterritoryCode
join corona_dm_time ct
on ct.timeCode = cr.recordingDate
where cr.cases > 0
and cr.recordingDate = (select cr1.recordingDate 
from corona_dm_record as cr1
join corona_dm_time ct1
on ct1.timeCode = cr1.recordingDate
where cr1.countryterritoryCode = cr.countryterritoryCode
and cr1.cases > 0
order by year asc, month asc, day asc
limit 1)
order by year asc, month asc, day asc, cl.countriesAndTerritories asc
limit 5;



-- what is the month with the most new cases for each country?
-- here the population data is also displayed in order to put the number of cases in perspective
-- execution time on intel core i5 processor 4 sec
select cl.countriesAndTerritories, cl.countryterritoryCode, ct.year, ct.month, sum(cr.cases) as new_cases, cl.popData2019
from corona_dm_record as cr
join corona_dm_location cl
on cr.countryterritoryCode = cl.countryterritoryCode
join corona_dm_time ct
on ct.timeCode = cr.recordingDate
group by cr.countryterritoryCode, ct.year, ct.month
having new_cases >= all (select sum(cr1.cases) 
from corona_dm_record as cr1
join corona_dm_time ct1
on ct1.timeCode = cr1.recordingDate
where cr1.countryterritoryCode = cr.countryterritoryCode
group by cr1.countryterritoryCode, ct1.year, ct1.month)
order by cl.countriesAndTerritories asc;

-- to allow a more focused vision here with the following quesries we show the 5 months with the most cases
-- execution time on intel core i5 processor 4 sec
select cl.countriesAndTerritories, cl.countryterritoryCode, ct.year, ct.month, sum(cr.cases) as new_cases, cl.popData2019
from corona_dm_record as cr
join corona_dm_location cl
on cr.countryterritoryCode = cl.countryterritoryCode
join corona_dm_time ct
on ct.timeCode = cr.recordingDate
group by cr.countryterritoryCode, ct.year, ct.month
having new_cases >= all (select sum(cr1.cases) 
from corona_dm_record as cr1
join corona_dm_time ct1
on ct1.timeCode = cr1.recordingDate
where cr1.countryterritoryCode = cr.countryterritoryCode
group by cr1.countryterritoryCode, ct1.year, ct1.month)
order by new_cases desc, cl.countriesAndTerritories asc
limit 5;