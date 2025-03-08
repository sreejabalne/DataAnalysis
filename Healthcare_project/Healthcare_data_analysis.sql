
-- Demographic Analysis

-- What is the demographic profile of the patient population, including age and gender distribution?
-- Pediatric: less than 18 years old
-- Adult: Between 18 to 64 years old
-- Senior: Over 65 years old
Select patient_id,gender,date_of_birth,TIMESTAMPDIFF(YEAR, STR_TO_DATE(date_of_birth, '%m/%d/%Y'),CURDATE()) as age
from practice_schema.patients_table where patient_id= '521022' ;

WITH Demographic_Analysis AS(
SELECT patient_id,gender,date_of_birth,
 CASE WHEN TIMESTAMPDIFF(year,STR_TO_DATE(date_of_birth,'%m/%d/%Y'),CURDATE()) < 18 THEN 'Pediatric'
 WHEN TIMESTAMPDIFF(year,STR_TO_DATE(date_of_birth,'%m/%d/%Y'),CURDATE()) BETWEEN 18 AND 64 THEN 'Adult'
 WHEN TIMESTAMPDIFF(year,STR_TO_DATE(date_of_birth,'%m/%d/%Y'),CURDATE()) >65 THEN 'Senior'
 ELSE 'old'
END AS Age
FROM practice_schema.patients_table
)
SELECT gender,Age, count(*) as patient_count
FROM Demographic_Analysis
GROUP BY gender;


-- Which diagnoses are most prevalent among patients and how do they vary across the different demographic groups, including gender and age? 
WITH Diagnosis_Analysis AS(
SELECT pt.patient_id,pt.gender,pt.date_of_birth,
 CASE WHEN TIMESTAMPDIFF(year,STR_TO_DATE(pt.date_of_birth,'%m/%d/%Y'),CURDATE()) < 18 THEN 'Pediatric'
 WHEN TIMESTAMPDIFF(year,STR_TO_DATE(pt.date_of_birth,'%m/%d/%Y'),CURDATE()) BETWEEN 18 AND 64 THEN 'Adult'
 WHEN TIMESTAMPDIFF(year,STR_TO_DATE(pt.date_of_birth,'%m/%d/%Y'),CURDATE()) >65 THEN 'Senior'
 ELSE 'old'
END AS Age, ot.diagnosis
FROM practice_schema.patients_table pt 
INNER JOIN practice_schema.outpatient_visits ot ON pt.patient_id=ot.patient_id
)
SELECT gender,Age,
coalesce(diagnosis,'No Diagnosis')as Diagnosis_a,count(*) AS patient_count
FROM Diagnosis_Analysis
GROUP BY gender,Age,Diagnosis_a;


-- What are the most common appointment times throughout the day, and how does the distribution of appointment times vary across different hours?
SELECT HOUR(admission_time), count(*) AS appointment_counts 
FROM practice_schema.appointment_analysis
GROUP BY HOUR(admission_time)
ORDER BY appointment_counts DESC;
 
-- What are the most commonly ordered lab tests?

SELECT test_name, count(*)as test_results
 FROM practice_schema.lab_results
 GROUP BY test_name;
 
-- Typically, fasting blood sugar levels falls between 70-100 mg/dL. Our goal is to identify patients  whose lab results are outside this normal range to implement early intervention.
-- SELECT result_value FROM practice_schema.lab_results;

SELECT p.patient_id,
	   p.patient_name,
	   l.test_date,
	   l.test_name,
       l.result_value
FROM practice_schema.patients_table AS p
INNER JOIN practice_schema.outpatient_visits AS v
ON p.patient_id = v.patient_id
INNER JOIN practice_schema.lab_results AS l
ON v.visit_id = l.visit_id
WHERE l.test_name = 'Fasting Blood Sugar'
AND (l.result_value > 70 OR l.result_value <100);

-- Assess how many patients are considered High, Medium, and Low Risk.

-- High Risk: patients who are smokers and have been diagnosed with either hypertension or diabetes.
--  Medium Risk: patients who are non-smokers and have been diagnosed with either hypertension or diabetes.
-- Low Risk: patients who do not fall into the High or Medium Risk categories. This includes patients who are not smokers and do not have a diagnosis of hypertension or diabetes.

SELECT 
CASE WHEN smoker_status = 'Y' AND diagnosis IN ('Hypertension','Diabetes') THEN 'High Risk'
	        WHEN smoker_status = 'N' AND diagnosis IN ('Hypertension','Diabetes') THEN 'Medium Risk'
		    ELSE 'Low Risk' END AS Risk_category, COUNT(*) AS Patient_count
FROM practice_schema.outpatient_visits
GROUP BY Risk_category;


-- Find out information about patients who had multiple visits within 30 days of their previous medical visit

-- Identify those patients
-- Date of initial visit
-- Reason of the initial visit
-- Readmission date
-- Reason for readmission
-- Number of days between the initial visit and readmission
-- Readmission visit recorded must have happened after the initial visit 

SELECT visit.patient_id,
visit.visit_date as initial_visit ,visit.reason_for_visit,
revisit.visit_date as readmission_date,revisit.reason_for_visit as readmission_reason,
 DATEDIFF(STR_TO_DATE(revisit.visit_date,'%m/%d/%Y'),STR_TO_DATE(visit.visit_date,'%m/%d/%Y')) AS days_between_initial_and_readmission
FROM practice_schema.outpatient_visits visit
INNER JOIN practice_schema.outpatient_visits revisit
ON visit.patient_id= revisit.patient_id
WHERE  DATEDIFF(STR_TO_DATE(revisit.visit_date,'%m/%d/%Y'),STR_TO_DATE(visit.visit_date,'%m/%d/%Y')) <= 30
	AND STR_TO_DATE(revisit.visit_date,'%m/%d/%Y') > STR_TO_DATE(visit.visit_date,'%m/%d/%Y');
