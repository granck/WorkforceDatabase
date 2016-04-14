-- 1 Runs X
SELECT name
FROM Person NATURAL JOIN Works JOIN Job USING(job_code)
WHERE comp_id= 1234567890 AND status=003;

-- 2 Runs X
SELECT pay_rate
FROM Company NATURAL JOIN Job
WHERE pay_type=001 AND comp_id=1234567890
ORDER BY pay_rate DESC;

-- OR Runs X

SELECT name, works.pay_rate 
FROM Person NATURAL JOIN Works JOIN Job USING(job_code) NATURAL JOIN Company
WHERE status=003 AND works.pay_type=001 AND comp_id=1234567890
ORDER BY works.pay_rate DESC;

-- 3 Runs X
WITH company_salary_total AS (
   SELECT comp_id, SUM(pay_rate) AS total_salary
   FROM Company NATURAL JOIN Job
   WHERE pay_type=001
   GROUP BY comp_id), 
   
  company_wage_total AS (
   SELECT comp_id, SUM(pay_rate * 1920) AS total_wage
   FROM Company NATURAL JOIN Job
   WHERE pay_type=002
   GROUP BY comp_id),
   
  company_salary_all AS(
    SELECT company.comp_id, total_salary
    FROM company LEFT OUTER JOIN 
      company_salary_total ON(company.comp_id = company_salary_total.comp_id)),
      
  company_wage_salary_all AS(
    Select company_salary_all.comp_id, total_salary, total_wage
    From company_salary_all LEFT OUTER JOIN
      company_wage_total ON(company_salary_all.comp_id = company_wage_total.comp_id))

SELECT comp_id, SUM(NVL(total_salary,0) + NVL(total_wage,0))
FROM company_wage_salary_all
GROUP BY comp_id
ORDER BY SUM(NVL(total_salary,0) + NVL(total_wage,0)) DESC;

-- 4 Runs X
SELECT job_code
FROM Works
WHERE status=003 AND per_id=1234567890;

-- 5 Runs X
SELECT ks_code, ks_name
FROM skill_set NATURAL JOIN Knowledge_skill
WHERE per_id=1234567890;

-- 6 Runs X
WITH job_skill_set AS (
   SELECT job_code, ks_code AS job_skills
   FROM Job NATURAL JOIN skills_required),

 persons_jobs AS (
   SELECT per_id, job_code
   FROM Works JOIN Job USING(job_code)
   WHERE per_id=1234567890 and status=003),

 persons_skill_set AS (
   SELECT per_id, ks_code AS person_skills
   FROM Skill_set
   WHERE per_id=1234567890)

SELECT job_code, job_skills
FROM persons_jobs NATURAL JOIN job_skill_set
WHERE job_skills IN ((Select job_skills 
                      From job_skill_set) 
                      MINUS 
                      (Select person_skills 
                      From persons_skill_set))
ORDER BY job_code;

-- 7 Runs X
SELECT pos_code, ks_code AS job_skills, ks_name
FROM skills_required NATURAL JOIN Knowledge_skill
WHERE pos_code=1234567890;

-- 8 Runs X
WITH persons_skill_set AS (
   SELECT per_id, ks_code AS person_skills, ks_name
   FROM skill_set NATURAL JOIN Knowledge_skill
   WHERE per_id=1234567890),

 job_skill_set AS (
   SELECT job_code, ks_code AS job_skills, ks_name
   FROM Job NATURAL JOIN skills_required NATURAL JOIN Knowledge_skill
   WHERE job_code=2309459380) 

SELECT job_skills, ks_name
FROM job_skill_set
WHERE job_skills IN ((SELECT job_skills FROM job_skill_set)
                      MINUS (SELECT person_skills FROM persons_skill_set));

-- 9 
WITH course_skill_set AS (
   SELECT ks_code
   FROM Course NATURAL JOIN Skills_taught)

SELECT skill_set
FROM course_skill_set, skill_set
WHERE skill_set = "Input Skill Set"
AND NOT EXISTS ((SELECT ks_code FROM course_skill_set) 
                MINUS (SELECT ks_code FROM skill_set));

-- 10 Runs X
WITH persons_skill_set AS (
   SELECT ks_code AS person_skills
   FROM skill_set
   WHERE per_id=1234567890),

 job_skill_set AS (
   SELECT ks_code
   FROM skills_required NATURAL JOIN job
   WHERE job_code=2309459380),

 missing_skill_set AS (
   SELECT ks_code
   FROM job_skill_set
   WHERE ks_code NOT IN ((SELECT ks_code 
                          FROM job_skill_set) 
                          MINUS 
                          (SELECT person_skills 
                          FROM persons_skill_set))),
                          
 missing_skill_count AS (
   SELECT COUNT(ks_code) AS skill_count
   FROM job_skill_set
   WHERE ks_code NOT IN ((SELECT ks_code FROM job_skill_set)
                          MINUS (SELECT person_skills FROM persons_skill_set))),

 course_skill_set AS (
   SELECT c_code, ks_code, course_title
   FROM Course NATURAL JOIN Skills_taught)

SELECT c_code, course_title
FROM course_skill_set RIGHT JOIN missing_skill_set 
ON course_skill_set.ks_code=missing_skill_set.ks_code, missing_skill_count
GROUP BY c_code, course_title
HAVING COUNT(course_skill_set.ks_code)=SUM(skill_count);

-- 11 Runs
WITH persons_skill_set AS (
   SELECT ks_code AS person_skills
   FROM skill_set
   WHERE per_id=1234567890),

 job_skill_set AS (
   SELECT ks_code
   FROM job NATURAL JOIN skills_required
   WHERE job_code=2309459380),

 missing_skill_set AS (
   SELECT ks_code
   FROM job_skill_set
   WHERE ks_code NOT IN ((SELECT ks_code FROM job_skill_set)
                          MINUS (SELECT person_skills FROM persons_skill_set))),
  
 missing_skill_count AS (
   SELECT COUNT(ks_code) AS skill_count
   FROM job_skill_set
   WHERE ks_code NOT IN ((SELECT ks_code FROM job_skill_set)
                          MINUS (SELECT person_skills FROM persons_skill_set))),

 valid_courses AS (
  SELECT c_code
   FROM missing_skill_count,skills_taught RIGHT JOIN missing_skill_set
   ON skills_taught.ks_code=missing_skill_set.ks_code
   GROUP BY c_code
   HAVING COUNT(skills_taught.ks_code)=SUM(skill_count)),

 course_sections AS (
   SELECT c_code, sec_no, year_off, complete_date
   FROM valid_courses NATURAL JOIN Section)

SELECT c1.c_code, c1.sec_no, c1.year_off, c1.complete_date
FROM course_sections c1
WHERE c1.complete_date > '13-APR-16' AND c1.complete_date < ALL (SELECT complete_date
                                                            FROM course_sections
                                                            WHERE complete_date > '13-APR-16');

-- 12
CREATE SEQUENCE CourseSet_seq
START WITH 1
INCREMENT BY 1
MAXVALUE 999999
NOCYCLE;
CREATE OR REPLACE TABLE CourseSet (
csetID NUMBER(8, 0) PRIMARY KEY,
c_code1 NUMBER(5, 0), c_code2 NUMBER(5, 0), c_code3 NUMBER(5, 0),
set_size NUMBER(2, 0) 
);
/* two-course set */
INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, null, 2
FROM Course C1, Course C2
WHERE C1.c_code < C2.code;
/* three-course set */
INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, C3.c_code, 3
FROM Course C1, Course C2, Course C3
WHERE C1.c_code < C2.code AND C2.code < C3.code; 

/* the relationship between course set and its covering skills */
WITH CourseSet_Skill(csetID, ks_code) AS (
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code1=CS.c_code
    UNION
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code2=CS.c_code
    UNION
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code3=CS.c_code), 

  missing_skills AS (
    SELECT R.ks_code
    FROM skills_required R
    WHERE R.ks_code IN (SELECT ks_code
                            FROM skill_input -- where input is ks_code rows
                            MINUS
                            SELECT ks_code
                            FROM skill_set)),

/* use division to find those course sets that cover missing skills */
  Cover_CSet(csetID, num) AS (
    SELECT csetID, num
    FROM CourseSet CSet
    WHERE NOT EXISTS (SELECT ks_code
                      FROM missing_skills
                      MINUS
                      SELECT ks_code
                      FROM CourseSet_Skill CSSk
                      WHERE CSSk.csetID = Cset.csetID))
                      
  /* to find the smallest sets */
SELECT c_code1, c_code2, c_code3
FROM Cover_CSet NATURAL JOIN CourseSet
WHERE num =(SELECT MIN(num) 
            FROM Cover_CSet); 

-- 13 Runs
CREATE SEQUENCE CourseSet_seq
START WITH 1
INCREMENT BY 1
MAXVALUE 999999
NOCYCLE;
CREATE OR REPLACE TABLE CourseSet (
csetID NUMBER(8, 0) PRIMARY KEY,
c_code1 NUMBER(5, 0), c_code2 NUMBER(5, 0), c_code3 NUMBER(5, 0),
set_size NUMBER(2, 0) 
);
/* two-course set */
INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, null, 2
FROM Course C1, Course C2
WHERE C1.c_code < C2.code;
/* three-course set */
INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, C3.c_code, 3
FROM Course C1, Course C2, Course C3
WHERE C1.c_code < C2.code AND C2.code < C3.code; 

/* the relationship between course set and its covering skills */
WITH CourseSet_Skill(csetID, ks_code) AS (
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code1=CS.c_code
    UNION
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code2=CS.c_code
    UNION
    SELECT csetID, ks_code
    FROM CourseSet CSet JOIN skills_taught CS ON CSet.c_code3=CS.c_code), 

  missing_skills AS (
    SELECT R.ks_code
    FROM skills_required R
    WHERE R.ks_code IN (SELECT ks_code
                            FROM skills_required NATURAL JOIN job
                            WHERE job_code=4758692431
                            MINUS
                            SELECT ks_code
                            FROM skill_set)),

/* use division to find those course sets that cover missing skills */
  Cover_CSet(csetID, num) AS (
    SELECT csetID, num
    FROM CourseSet CSet
    WHERE NOT EXISTS (SELECT ks_code
                      FROM missing_skills
                      MINUS
                      SELECT ks_code
                      FROM CourseSet_Skill CSSk
                      WHERE CSSk.csetID = Cset.csetID))
                      
  /* to find the smallest sets */
SELECT c_code1, c_code2, c_code3
FROM Cover_CSet NATURAL JOIN CourseSet
WHERE num =(SELECT MIN(num) 
            FROM Cover_CSet); 
-- 14 No can skip

-- 15 Runs X
SELECT pos_code
FROM skills_required --skill_set table or view does not exist? 
WHERE skills_required.ks_code NOT IN((SELECT ks_code
                                    FROM skills_required)
                                    MINUS 
                                    (SELECT ks_code
                                    FROM skill_set
                                    WHERE per_id = 1234567890));

-- 16 Runs X
SELECT DISTINCT j1.job_code
FROM job j1 NATURAL JOIN skills_required j1
WHERE j1.ks_code NOT IN((SELECT ks_code
                      FROM skills_required)
                      MINUS
                      (SELECT ks_code
                      FROM skill_set
                      WHERE per_id = 1234567890))
AND j1.pay_rate >= ALL (SELECT pay_rate
                    FROM job j2 NATURAL JOIN skills_required j2
                    WHERE j2.ks_code NOT IN((SELECT ks_code
                                              FROM skills_required)
                                              MINUS
                                              (SELECT ks_code
                                              FROM skill_set
                                              WHERE per_id = 1234567890)));
-- Unless we want to get fancy and account for salary vs. wage...

-- 17 -- runs X
SELECT DISTINCT name, email
FROM person, skills_required
WHERE skills_required.ks_code NOT IN((SELECT ks_code
                           FROM skills_required
                           WHERE pos_code=1234567890)
                           MINUS -- Officially confused about minus vs - now,
                           (SELECT ks_code -- takes this with no complaint, no
                           FROM skill_set)); -- right paranthesis error either

-- 18 -- runs
WITH skill_count AS(
    SELECT per_id, COUNT(skills_required.ks_code - skill_set.ks_code) AS missing_skill_count
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    GROUP BY per_id)
    
SELECT per_id
FROM skill_count
WHERE missing_skill_count < 2;

-- 19 Runs
WITH skill_count AS(
    SELECT per_id, COUNT(skills_required.ks_code - skill_set.ks_code) AS missing_skill_count
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    GROUP BY per_id),
    
  person_missing_skill AS(
    SELECT per_id, skills_required.ks_code
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    AND skills_required.ks_code NOT IN((SELECT ks_code
                                    FROM skills_required)
                                    MINUS
                                    (SELECT ks_code
                                    FROM skill_set)))
    
SELECT per_id, ks_code
FROM skill_count NATURAL JOIN person_missing_skill
WHERE missing_skill_count < 2;

-- 20 Runs
WITH skill_count AS(
    SELECT per_id, COUNT(skills_required.ks_code - skill_set.ks_code) AS missing_skill_count
    FROM skill_set, skills_required
    WHERE pos_code=0987654321 -- new job profile
    GROUP BY per_id)
    
SELECT s1.per_id, missing_skill_count
FROM skill_count s1, skill_count s2
WHERE s1.missing_skill_count <= s2.missing_skill_count;

-- 21 Runs
WITH skill_count AS(
    SELECT per_id, COUNT(skills_required.ks_code - skill_set.ks_code) AS missing_skill_count
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    GROUP BY per_id)
    
SELECT per_id, missing_skill_count
FROM skill_count 
WHERE missing_skill_count < 5 -- 5 being a fill in for k
ORDER BY missing_skill_count ASC;

-- 22 Runs
WITH skill_count AS(
    SELECT per_id, COUNT(skills_required.ks_code - skill_set.ks_code) AS missing_skill_count
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    GROUP BY per_id),
    
  person_missing_skill AS(
    SELECT per_id, skills_required.ks_code
    FROM skill_set, skills_required
    WHERE pos_code=1234567890 
    AND skills_required.ks_code NOT IN((SELECT ks_code
                                    FROM skills_required)
                                    MINUS
                                    (SELECT ks_code
                                    FROM skill_set)))
    
SELECT ks_code, COUNT(per_id)
FROM skill_count NATURAL JOIN person_missing_skill
WHERE missing_skill_count < 5 -- being k
GROUP BY ks_code
ORDER BY COUNT(per_id) DESC;

-- 23 Runs
SELECT per_id, name, address, zip_code, email, gender, phone
FROM person NATURAL JOIN works JOIN job USING(job_code)
WHERE pos_code=0911911911

-- 24 Runs
WITH unemployeed AS(
  SELECT per_id, name, address, zip_code, email, gender, phone, job_code
  FROM person NATURAL JOIN works
  WHERE NOT EXISTS(SELECT status
                    FROM works
                    WHERE status=003))
  
SELECT per_id, name, address, zip_code, email, gender, phone
FROM unemployeed NATURAL JOIN job
WHERE pos_code=0008675309;

--25 individual selects work, need to find a way to combine them
WITH company_employees AS(
  SELECT comp_id, COUNT(per_id) AS employee_count
  FROM works JOIN job USING(job_code)
  WHERE status=003
  GROUP BY comp_id),
  
  company_salary_total AS (
   SELECT comp_id, SUM(pay_rate) AS total_salary
   FROM Company NATURAL JOIN Job
   WHERE pay_type=001
   GROUP BY comp_id), 
   
  company_wage_total AS (
   SELECT comp_id, SUM(pay_rate * 1920) AS total_wage
   FROM Company NATURAL JOIN Job
   WHERE pay_type=002
   GROUP BY comp_id),
   
  company_total_pay AS(
    SELECT comp_id, SUM(total_salary + total_wage) AS pay
    FROM company_wage_total JOIN company_salary_total USING(comp_id)
    GROUP BY comp_id)

SELECT c1.comp_id
FROM company_employees c1, company_employees c2
WHERE c1.employee_count > c2.employee_count;

SELECT p1.comp_id
FROM company_total_pay p1, company_total_pay p2
WHERE p1.pay > p2.pay;

-- 26 27 are grad questions
-- 28 29 can skip

-- 30 Runs
WITH job_skills AS (
    SELECT ks_code
    FROM job NATURAL JOIN skills_required
    WHERE pos_code=1234567890),
  
  missing_skills AS(
    SELECT job_skills.ks_code
    FROM job_skills, skill_set
    WHERE per_id=1234567890 
    AND job_skills.ks_code NOT IN((SELECT ks_code
                                FROM job_skills)
                                MINUS
                                (SELECT ks_code
                                FROM skill_set)))
                                
SELECT c_code
FROM skills_taught, missing_skills
WHERE missing_skills.ks_code NOT IN((SELECT ks_code
                                    FROM missing_skills)
                                    MINUS
                                    (SELECT ks_code
                                    FROM skills_taught));
