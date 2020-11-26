-- Student Name: Antonio delle Canne
-- Student Number : K20113110



-- when are the first cases of covid-19 recorded in each country?
-- the caes are also shown to have an idea of what could be the dealy between the real arrival of the virus and the actual recording date
select distinct cl.countriesAndTerritories, cl.geoId, cr.recordingDate as firstCases, cr.cases
from corona_record as cr
natural join corona_location cl
where cr.cases > 0
and cr.recordingDate <= all (select cr1.recordingDate 
from corona_record as cr1
where cr1.geoId = cr.geoId
and cr1.cases > 0)
order by cl.countriesAndTerritories;




-- what is the month with the most new cases for each country?
-- here the population data is also displayed in order to put the number of cases in perspective

select cl.countriesAndTerritories, cl.geoId, year(cr.recordingDate) as recYear, month(cr.recordingDate) as recMonth, sum(cr.cases) as cases_sum, popData2019
from corona_record as cr
natural join corona_location cl
group by cr.geoId, recYear, recMonth
having cases_sum >= all (select sum(cr1.cases) 
from corona_record as cr1
where cr1.geoId = cr.geoId
group by cr1.geoId, year(cr1.recordingDate), month(cr1.recordingDate))
order by cl.countriesAndTerritories;