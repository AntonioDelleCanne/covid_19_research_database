-- Student Name: Antonio delle Canne
-- Student Number : K20113110

-- By querying the dataset we noticed that frequently the first phsm is adopted before the first case of corona virus:
-- The explanation of this is that many states are adopting preventive measures, like closing the borders, in order to 
-- prevent people coming from infected countries to spread the virus.
-- So we found it interesting to answer this question:
-- how many countries adopted preventive measures and how many didn't, and what is the median delay between the adoption
-- of the preventive measure and the recodring of the first case in the country?


-- what is the number of cases per 100.000 population when countries close schools at national level?
-- by answering this question we are interested in seeing what countries
-- showed the most tollerance to the epidemic
--
-- by looking at the documentation we can see that the measure corresponding
-- to shool closure is '4.1.2'
-- also according to the documentation, in order for the measure to be applied 
-- at national level the admin_level field in the integration_area table is set to 'national'