CREATE DATABASE Retail_orders;
USE Retail_orders;
DROP TABLE sales_data_transactions;

CREATE TABLE df_orders 
(order_id INT PRIMARY KEY, 
order_date VARCHAR(20), 
ship_mode VARCHAR(20), 
segment VARCHAR(20), 
country VARCHAR(20), 
city VARCHAR(20), 
state VARCHAR(20), 
postal_code VARCHAR(20), 
region VARCHAR(20), 
category VARCHAR(20), 
sub_category VARCHAR(20), 
product_id VARCHAR(20), 
quantity INT, 
discount DECIMAL(7,2), 
sale_price DECIMAL(7,2), 
profit DECIMAL(7,2));

LOAD DATA INFILE 'Pytsqlproject.csv' 
INTO TABLE df_orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM df_orders;

UPDATE df_orders SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y');

ALTER TABLE df_orders CHANGE COLUMN order_date order_date DATE;

DESCRIBE df_orders;

-- find the top 10 highest revenue generation products

SELECT product_id, SUM(sale_price) AS sales FROM df_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;

-- find top 5 highest selling product in each region
with cte as
(SELECT region, product_id, SUM(sale_price) AS sales FROM df_orders
GROUP BY region, product_id
ORDER BY region, sales DESC)
SELECT * FROM
(SELECT *, 
ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) AS rn FROM CTE) A
WHERE rn<=5;

-- find month over month comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023

WITH CTE AS
(SELECT YEAR(order_date) AS order_year, month(order_date) AS order_month, 
SUM(sale_price) AS sales FROM df_orders
GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_month, 
SUM(case when order_year=2022 then sales else 0 end) AS sales_2022,
SUM(case when order_year=2023 then sales else 0 end) AS sales_2023
FROM CTE
GROUP BY order_month
ORDER BY order_month;

-- for each category which month had highest sales

WITH CTE AS
(SELECT category, date_format(order_date, '%Y-%m') AS order_year_month, SUM(sale_price) as sales
FROM df_orders
GROUP BY category, date_format(order_date, '%Y-%m')
)
SELECT * FROM 
(SELECT *,
ROW_NUMBER() (OVER PARTITION BY category ORDER BY sales DESC) AS rn
FROM CTE) A 
WHERE rn=1;

-- which sub category had highest growth by profit in 2023 comparing to 2022
WITH CTE AS
(SELECT sub_category, YEAR(order_date) AS order_year, 
SUM(sale_price) AS sales FROM df_orders
GROUP BY sub_category, YEAR(order_date)
)
, CTE2 AS (
SELECT sub_category, 
SUM(case when order_year=2022 then sales else 0 end) AS sales_2022,
SUM(case when order_year=2023 then sales else 0 end) AS sales_2023
FROM CTE
GROUP BY sub_category)
SELECT *
, (sales_2023-sales_2022)*100/sales_2022
FROM CTE2
ORDER BY (sales_2023-sales_2022)*100/sales_2022 DESC;
