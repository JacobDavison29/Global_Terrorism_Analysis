
-- Checking out the data 
SELECT *
FROM MasterTable
ORDER BY iyear DESC;

-- Looking at specifics of data
SELECT Date,country_txt,region_txt,provstate,city,attacktype1_txt,targtype1_txt,gname,weaptype1_txt
FROM MasterTable
ORDER BY Date,country_txt;

-- Looking at data specific to my country
SELECT Date,country_txt,region_txt,provstate,city,attacktype1_txt,targtype1_txt,gname,weaptype1_txt
FROM MasterTable
WHERE country_txt like '%states%'
ORDER BY iyear DESC;

-- Looking to see what attack caused most casualties in my country
SELECT Date,country_txt,region_txt,provstate,city,attacktype1_txt,targtype1_txt,gname,weaptype1_txt,nkill
FROM MasterTable
WHERE country_txt like '%states%'
ORDER BY nkill DESC;

-- Looking at Region casualties from terrorism
SELECT region_txt,SUM(nkill) AS TotalDeaths
FROM MasterTable
GROUP BY region_txt
ORDER BY TotalDeaths DESC;

-- Looking at Country casualties from terrorism
SELECT country_txt,SUM(nkill) AS TotalDeaths
FROM MasterTable
GROUP BY country_txt
ORDER BY TotalDeaths DESC;

-- BREAKING THINGS DOWN INTO CONTINENTS

-- Single Query to get total death per continent
SELECT Europe,Asia,Africa,Australia,North_America,South_America 
FROM (SELECT (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Europe%') as Europe ,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Asia%') as Asia,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Africa%') as Africa,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Austral%') as Australia,
			 ((SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%North America%')+(SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Caribbean%'))as North_America,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%South America%') as South_America) AS Continets;
			 
-- Splitting the master table up into sub tables by continent 	
Select * 
INTO North_America
FROM MasterTable
WHERE region_txt like '%North America%' or region_txt like '%Caribbean%';

Select * 
INTO South_America
FROM MasterTable
WHERE region_txt like '%South America%';

Select * 
INTO Europe
FROM MasterTable
WHERE region_txt like '%Europe%';

Select * 
INTO Asia
FROM MasterTable
WHERE region_txt like '%Asia%';

Select * 
INTO Australia
FROM MasterTable
WHERE region_txt like '%Austral%';

Select * 
INTO Africa
FROM MasterTable
WHERE region_txt like '%Africa%';


--Getting the Success Rates of terrorism attack on each continent.
SELECT EuropeSuccessRate,AsiaSuccessRate,AfricaSuccessRate,AustraliaSuccessRate,NorthAmericaSuccessRate,SouthAmericaSuccessRate
FROM (SELECT (SELECT (SUM(success)/COUNT(*)) FROM Europe) as EuropeSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Asia) as AsiaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Africa) as AfricaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Australia) as AustraliaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM North_America) as NorthAmericaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM South_America) as SouthAmericaSuccessRate) AS SuccessRates;

-- Seeing what groups carried out attacks accross all continents
SELECT DISTINCT NA.gname AS NA_Groups, EU.gname AS EU_Groups, AUS.gname AS AUS_Groups, AF.gname AS AF_Groups, AI.gname AS AI_Group, SA.gname AS SA_Groups
FROM North_America AS NA
JOIN Europe AS EU ON NA.gname=EU.gname
JOIN Australia AS AUS ON EU.gname = AUS.gname
JOIN Africa AS AF ON AUS.gname=AF.gname
JOIN Asia AS AI ON AF.gname = AI.gname
JOIN South_America AS SA ON AI.gname=SA.gname
WHERE EU.gname NOT LIKE '%Unknown%' and NA.gname NOT LIKE '%Unknown%' AND AUS.gname NOT LIKE '%Unknown%' and AF.gname NOT LIKE '%Unknown%' AND AI.gname NOT LIKE '%Unknown%' and SA.gname NOT LIKE '%Unknown%';

-- Looking at most popular type of attack in North_America
SELECT NA.attacktype1_txt AS NA_ATT, COUNT(*) AS Total_Count
FROM North_America AS NA
GROUP BY NA.attacktype1_txt
ORDER BY Total_Count DESC;

-- Creating temp table to house data for attack type occurences globally per continent
DROP TABLE IF EXISTS #ATTACK_OCCURRENCES
SELECT DISTINCT MS.attacktype1_txt,
	(SELECT count(*) FROM North_America AS NA WHERE NA.attacktype1=MS.attacktype1) NA_Totals,
	(SELECT count(*) FROM Europe AS EU WHERE EU.attacktype1=MS.attacktype1) EU_Totals,
	(SELECT count(*) FROM Australia AS AUS WHERE AUS.attacktype1=MS.attacktype1) AUS_Totals,
	(SELECT count(*) FROM Africa AS AF WHERE AF.attacktype1=MS.attacktype1) AF_Totals,
	(SELECT count(*) FROM Asia AS AI WHERE AI.attacktype1=MS.attacktype1) AI_Totals,
	(SELECT count(*) FROM South_America AS SA WHERE SA.attacktype1=MS.attacktype1) SA_Totals
INTO #ATTACK_OCCURRENCES
FROM MasterTable AS MS;

-- Creating a new column to hold the global totals for each attack type
ALTER TABLE #ATTACK_OCCURRENCES
ADD Global_Totals INT null;

-- Updating the temp table to hold the global totals for each attack
UPDATE #ATTACK_OCCURRENCES
SET Global_Totals = NA_Totals+EU_Totals+AUS_Totals+AF_Totals+AI_Totals+SA_Totals;

-- Taking a look at the most common kind of terrorist attack globally
SELECT * FROM #ATTACK_OCCURRENCES ORDER BY Global_Totals DESC;

-- Checking the Percentages of each type off attack Per continent
SELECT attacktype1_txt, CAST(NA_Totals AS FLOAT)/Global_Totals AS NA_Percentage, CAST(EU_Totals AS FLOAT)/Global_Totals AS EU_Percentage, CAST(AUS_Totals AS FLOAT)/Global_Totals AS AUS_Percentage,
		CAST(AF_Totals AS FLOAT)/Global_Totals AS AF_Percentage,  CAST(AI_Totals AS FLOAT)/Global_Totals AS AI_Percentage, CAST(SA_Totals AS FLOAT)/Global_Totals AS SA_Percentage
FROM #ATTACK_OCCURRENCES
ORDER BY attacktype1_txt;

-- CREATING VIEWS TO SROTE DATA FOR LATER VISUALIZATION

-- Total number of deaths per continent
CREATE VIEW CONTINENT_DEATHS AS
SELECT Europe,Asia,Africa,Australia,North_America,South_America 
FROM (SELECT (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Europe%') as Europe ,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Asia%') as Asia,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Africa%') as Africa,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Austral%') as Australia,
			 ((SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%North America%')+(SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%Caribbean%'))as North_America,
			 (SELECT SUM(nkill) FROM MasterTable WHERE region_txt Like '%South America%') as South_America) AS Continets;

-- Success rate per continent of terrorist attacks
CREATE VIEW TERRORISM_SUCCESS_RATE AS
SELECT EuropeSuccessRate,AsiaSuccessRate,AfricaSuccessRate,AustraliaSuccessRate,NorthAmericaSuccessRate,SouthAmericaSuccessRate
FROM (SELECT (SELECT (SUM(success)/COUNT(*)) FROM Europe) as EuropeSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Asia) as AsiaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Africa) as AfricaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM Australia) as AustraliaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM North_America) as NorthAmericaSuccessRate,
			 (SELECT (SUM(success)/COUNT(*)) FROM South_America) as SouthAmericaSuccessRate) AS SuccessRates;


--Attack type occurences per Continent
CREATE VIEW ATTACK_OCCURRENCES AS
SELECT DISTINCT MS.attacktype1_txt,
	(SELECT count(*) FROM North_America AS NA WHERE NA.attacktype1=MS.attacktype1) NA_Totals,
	(SELECT count(*) FROM Europe AS EU WHERE EU.attacktype1=MS.attacktype1) EU_Totals,
	(SELECT count(*) FROM Australia AS AUS WHERE AUS.attacktype1=MS.attacktype1) AUS_Totals,
	(SELECT count(*) FROM Africa AS AF WHERE AF.attacktype1=MS.attacktype1) AF_Totals,
	(SELECT count(*) FROM Asia AS AI WHERE AI.attacktype1=MS.attacktype1) AI_Totals,
	(SELECT count(*) FROM South_America AS SA WHERE SA.attacktype1=MS.attacktype1) SA_Totals
FROM MasterTable AS MS;

