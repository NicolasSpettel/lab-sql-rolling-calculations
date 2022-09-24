-- Lab | SQL Rolling calculations

USE sakila;

-- 1. Get number of monthly active customers.
CREATE OR REPLACE VIEW user_activity AS
	SELECT 
		customer_id, 
        DATE(rental_date) AS activity_date, 
        DATE_FORMAT(rental_date, '%m') AS activity_month,
        DATE_FORMAT(rental_date, '%y') AS activity_year
	FROM rental; 
SELECT * FROM user_activity;

CREATE OR REPLACE VIEW monthly_active_users AS
SELECT 
	activity_month, 
    activity_year, 
    COUNT(DISTINCT customer_id) AS active_users
FROM 
	user_activity
GROUP BY 
	activity_year, 
    activity_month
ORDER BY
	activity_year,
    activity_month;
    
SELECT * FROM monthly_active_users;

-- 2. Active users in the previous month.
CREATE OR REPLACE VIEW last_month_customers AS
SELECT 
	*,
    lag(active_users) over(partition by activity_year order by activity_month) as last_month
FROM 
	monthly_active_users;
    
SELECT * FROM last_month_customers;    

-- 3. Percentage change in the number of active customers.
CREATE OR REPLACE VIEW percentage_customers AS
SELECT 
	*, 
	active_users/last_month AS percentage_change 
FROM last_month_customers;

SELECT * FROM percentage_customers;

-- 4. Retained customers every month.
select * from rental;
WITH sub AS (
  SELECT YEAR(c.rental_date) AS activity_year, 
         MONTH(c.rental_date) AS activity_month,
         COUNT(DISTINCT c.customer_id) AS unq_customers
  FROM rental c
  GROUP BY activity_year, 
           activity_month
)

SELECT activity_year,
       activity_month,
       unq_customers,
       IFNULL(
         unq_customers /
         (SUM(unq_customers) OVER(ORDER BY activity_month) -
          unq_customers),
         1
       ) * 100 AS retention_rate
FROM sub;