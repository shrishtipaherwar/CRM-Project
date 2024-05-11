# 1. What is the distribution of account balance across different regions?

USE crm;

WITH cte AS (
SELECT ci.CustomerId, g.geographylocation,bc.Balance
FROM customerinfo ci 
JOIN geography g 
ON ci.GeographyID = g.geographyid
JOIN bank_churn bc 
ON ci.CustomerId = bc.CustomerId
)
SELECT geographylocation, ROUND(SUM(balance),0) AS total_blc
FROM cte 
GROUP BY geographylocation;

# 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
--  since there is no specific information availabe on transactions as such , I have assumed no of products purchased 
-- as num of transaction with each purchase counted as distinct transaction and hence follows for further coding 
-- Also total spend is seen as no of product purchased. 

SELECT surname AS name
FROM customerinfo
WHERE QUARTER(BankDOJ) = 4
ORDER BY estimatedSalary DESC
LIMIT 5;

# 3. Calculate the average number of products used by customers who have a credit card

SELECT AVG(NumOfProducts) AS avg_products
FROM bank_churn
WHERE HasCrCard = 1;

# 4. Determine the churn rate by gender for the most recent year in the dataset
WITH cte AS (
SELECT ci.customerID, ci.genderID, ci.BankDOJ, bc.exited
FROM bank_churn bc
JOIN customerinfo ci
ON bc.customerID = ci.customerID 
),
cte2 AS (
SELECT genderID , COUNT(customerID) AS lost_customers
FROM cte 
WHERE exited = 1
GROUP BY genderID
),
cte3 AS (
SELECT genderID, COUNT(customerID) AS total_customers
FROM cte 
GROUP BY genderID 
)
SELECT c2.genderID, ROUND((c2.lost_customers / c3.total_customers) * 100,2) AS churn_rate
FROM cte2 c2
JOIN cte3 c3
ON c2.genderID = c3.genderID 
ORDER BY churn_rate ASC;

# 5. Compare the average credit score of customers who have exited and those who remain

SELECT exited, ROUND(AVG(creditscore),0) AS avg_credit_score
FROM bank_churn
GROUP BY exited;
# From the table, we can identify that avg_credit_score of customers who are with bank is higher then customers who left the bank.

# 6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? 


SELECT genderID, ROUND(AVG(estimatedsalary),0) AS avg_estimated_salary
FROM customerinfo
GROUP BY genderID
ORDER BY avg_estimated_salary DESC
LIMIT 1;

SELECT COUNT(customerID) AS ttl
FROM bank_churn 
WHERE Isactivemember = 1;

# From both the above queries we can identify that there is no relation between higher_ estimated_salary and active_account.alter

# 7.Segment the customers based on their credit score and identify the segment with the highest exit rate. 
-- As per given segments in ppt file the segmentations are done based on following available information
/*
Excellent: 800–850
Very Good: 740–799
Good: 670–739
Fair: 580–669
Poor: 300–579
*/
-- categoring into different segments and also displaying the Num of customers

select Segment,count(CustomerId) No_of_customers from (
select customerid,creditscore,
case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as Segment,exited
from bank_churn)t 
group by segment;

-- identify the segment with the highest exit rate

with segmented as (
select customerid,creditscore,
case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as segment,exited
from bank_churn)

select Segment,count(case when exited=1 then exited end) as Exit_Count from segmented
group by Segment
order by exit_count desc
limit 1;


# 8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. 

WITH cte AS (
SELECT ci.customerID, ci.geographyID, g.geographylocation, bc.tenure,bc.isactivemember
FROM customerinfo ci
JOIN geography g
ON ci.geographyID = g.geographyID
JOIN bank_churn bc
ON ci.customerID = bc.customerID
)
SELECT geographylocation, COUNT(customerID) AS total_customers
FROM cte 
WHERE isactivemember = 1
AND tenure > 5 
GROUP BY geographylocation 
ORDER BY total_customers DESC
LIMIT 1;


# 10. For customers who have exited, what is the most common number of products they had used?

SELECT numofproducts
FROM bank_churn
WHERE exited = 1
GROUP BY numofproducts
ORDER BY COUNT(*) DESC
LIMIT 1;

# 11. Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). 
# Prepare the data through SQL and then visualize it.

SELECT YEAR(bankDOJ) AS year, MONTH(bankDOJ) AS month, COUNT(customerID) AS total_customers 
FROM customerinfo
GROUP BY YEAR(bankDOJ), MONTH(bankDOJ)
ORDER BY YEAR(bankDOJ), MONTH(bankDOJ);


SELECT YEAR(bankDOJ) AS year,  COUNT(customerID) AS total_customers 
FROM customerinfo
GROUP BY YEAR(bankDOJ)
ORDER BY YEAR(bankDOJ);

# As per the results the no. of customers joining the bank are increasing year over year, 2019 is recorded as a year 
# with highest no.of.customers joining the bank.

# 12. Analyze the relationship between the number of products and the account balance for customers who have exited.

SELECT numofproducts ,ROUND(SUM(balance),0) AS total_blc
FROM bank_churn
WHERE exited = 1
GROUP BY numofproducts ;

# 13. Identify any potential outliers in terms of balance among customers who have remained with the bank.

SELECT customerID, balance 
FROM bank_churn
WHERE exited = 0
ORDER BY balance DESC;


# 14. How many different tables are given in the dataset, out of these tables which table only consist of categorical variables?

 # Ans- There are 7 different tables given in the dataset. Out of these tables, Gender, Geography, ActiveCustomers, 
 #      CreditCard, ExitCustomer are the tables which consist of categorical variables.
 
 # 15. Using SQL, write a query to find out the gender wise average income of male and female in each geography id. 
 #    Also rank the gender according to the average value. 
 
 WITH cte AS ( 
 SELECT g.gendercategory, ge.geographylocation, ROUND(AVG(ci.estimatedsalary),0) AS avg_income
 FROM Customerinfo ci 
 JOIN gender g
 ON ci.genderID = g.genderID
 JOIN  geography ge
 ON ci.geographyID = ge.geographyID
 GROUP BY g.gendercategory, ge.geographylocation
 )
 SELECT *,
 DENSE_RANK() OVER( ORDER BY avg_income DESC) AS 'rank'
 FROM cte; 
 
 # 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

WITH cte AS (
SELECT ci.customerID, bc.tenure,ci.age
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID 
WHERE bc.exited = 1 
 ),
 cte2 AS (
 SELECT * ,
 CASE 
 WHEN age BETWEEN 18 AND 30 THEN '18-30'
  WHEN age BETWEEN 31 AND 50 THEN '31-50'
 ELSE '50+'
 END AS age_bracket
 FROM cte
 ) 
 SELECT age_bracket, ROUND(AVG(tenure),0) AS avg_tenure
 FROM cte2
 GROUP BY age_bracket;
 
 # 17. Is there any direct correlation between salary and balance of the customers? And is it different for people who have exited or not?

SELECT ci.customerID, ci.estimatedsalary, bc.balance
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID;

SELECT ci.customerID, ci.estimatedsalary, bc.balance
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID
WHERE bc.exited = 1;

# - There is no relation between estimatedsalary and balance of customers. Same applies who exited the bank.

# 18. . Is there any correlation between salary and Credit score of customers?

SELECT ci.customerID, ci.estimatedsalary, bc.creditscore
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID
ORDER  BY ci.estimatedsalary DESC;

 # - There is no relation between estimatedsalary and creditscore of customers. CreditScore depends on repayment history,
 #    types of loans, credit history, debt utilisation. 
 
 # 19. . Rank each bucket of credit score as per the number of customers who have churned the bank.

WITH cte AS (
SELECT creditscore, COUNT(*) AS churned_customers 
FROM bank_churn
WHERE exited = 1
GROUP BY creditscore
)
SELECT *,
DENSE_RANK() OVER(ORDER BY churned_customers DESC) AS 'rank'
FROM cte;

# 20. According to the age buckets find the number of customers who have a credit card. 
# Also retrieve those buckets who have lesser than average number of credit cards per bucket.

WITH cte AS (
SELECT ci.customerID, ci.age, bc.hascrcard
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID
WHERE hascrcard = 1 
),
cte2 AS (
SELECT * ,
 CASE 
 WHEN age BETWEEN 18 AND 30 THEN '18-30'
  WHEN age BETWEEN 31 AND 50 THEN '31-50'
 ELSE '50+'
 END AS age_bucket
FROM cte
)
SELECT age_bucket, COUNT(customerID) AS total_customers
FROM cte2
 GROUP BY age_bucket;
 
 
 WITH cte AS (
SELECT ci.customerID, ci.age, bc.hascrcard
FROM customerinfo ci 
JOIN bank_churn bc 
ON ci.customerID = bc.customerID
WHERE hascrcard = 1 
),
cte2 AS (
SELECT * ,
 CASE 
 WHEN age BETWEEN 18 AND 30 THEN '18-30'
  WHEN age BETWEEN 31 AND 50 THEN '31-50'
 ELSE '50+'
 END AS age_bucket
FROM cte
),
cte3 AS (
SELECT age_bucket, COUNT(customerID) AS total_customers
FROM cte2
 GROUP BY age_bucket
 )
 SELECT * FROM cte3
 WHERE total_customers < (
							SELECT AVG(total_customers) 
								FROM cte3
                                )
ORDER BY total_customers DESC;

# - The age bucket that have total_customers less than average_customers are 18-30 and 50+.

#. 21. Rank the Locations as per the number of people who have churned the bank and average balance of the customers.

WITH cte AS (
SELECT customerID, balance
FROM bank_churn
WHERE exited = 1
),
cte2 AS (
SELECT c.customerID, c.balance, ci.geographyID, g.geographylocation
FROM cte c 
JOIN customerInfo ci 
ON c.customerID = ci.customerID 
JOIN geography g 
ON ci.geographyid = g.geographyid
),
cte3 AS (
SELECT geographylocation, COUNT(customerID) AS ttl_churned, ROUND(AVG(balance),0) AS avg_blc
FROM cte2
GROUP BY geographylocation
)
SELECT *,
DENSE_RANK() OVER(ORDER BY ttl_churned DESC, avg_blc DESC) AS 'rank'
FROM cte3;

 # 22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now 
 #  if we have to join it with a table where the primary key is also a combination of CustomerID and Surname,
 # come up with a column where the format is “CustomerID_Surname”.
 # Ans. In bank_churn table, primary key is customerId and there is no surname column. Therefore, we can't join on the
 # basis of ustomerId and surname. 
 
 # 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
# Ans. No, we can't join without using JOIN clause.

#24. Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?
# Ans. There were no missing values in dataset.

#25. Write the query to get the customer ids, their last name and whether they are active or not for the customers whose surname  
#    ends with “on”.

SELECT c.customerid, c.surname, b.IsActiveMember
FROM customerinfo c 
JOIN bank_churn b 
ON c.customerid = b.CustomerId
WHERE surname LIKE '%on';


 
  
 
 
 