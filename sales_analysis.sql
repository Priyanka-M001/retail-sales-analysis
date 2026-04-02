-- Date dimension
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    order_date DATE,
    year INT,
    month INT,
    month_name TEXT,
    quarter INT
);


-- Customer dimension
CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id TEXT,
    customer_name TEXT,
    segment TEXT
);


-- Product dimension
CREATE TABLE dim_product (
    product_key INT PRIMARY KEY,
    product_id TEXT,
    category TEXT,
    sub_category TEXT,
    product_name TEXT
);


-- Region dimension
CREATE TABLE dim_region (
    region_key INT PRIMARY KEY,
    country TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    region TEXT
);


-- Fact table
CREATE TABLE fact_sales (
    order_id TEXT,
    date_key INT,
    customer_key INT,
    product_key INT,
    region_key INT,
    sales NUMERIC,

    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (region_key) REFERENCES dim_region(region_key)
);

-- Calculate total company revenue
SELECT ROUND(SUM(sales), 1) AS total_revenue
FROM fact_sales;


-- Revenue by year
SELECT d.year, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;


-- Identify top 10 customers by revenue
SELECT c.customer_name, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 10;


-- Revenue by product category
SELECT p.category, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY revenue DESC;


-- Revenue by region
SELECT r.region, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_region r ON f.region_key = r.region_key
GROUP BY r.region
ORDER BY revenue DESC;


-- Monthly revenue trend
SELECT d.year, d.month, d.month_name, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;


-- Average order value
SELECT ROUND(SUM(sales) / COUNT(DISTINCT order_id), 1) AS avg_order_value
FROM fact_sales;


-- Rank customers based on revenue
SELECT c.customer_name, ROUND(SUM(f.sales), 1) AS revenue, 
	RANK() OVER (ORDER BY SUM(f.sales) DESC) AS revenue_rank
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_name
ORDER BY revenue_rank
LIMIT 10;


-- Top product in each category
SELECT *
FROM (
    SELECT 
        p.product_name,
        p.category,
        ROUND(SUM(f.sales), 1) AS revenue,
        RANK() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(f.sales) DESC
        ) AS category_rank
    FROM fact_sales f
    JOIN dim_product p ON f.product_key = p.product_key
    GROUP BY p.product_name, p.category
) sub
WHERE category_rank = 1;


-- Year-over-Year revenue growth
WITH yearly_sales AS (
    SELECT d.year, SUM(f.sales) AS revenue
    FROM fact_sales f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year
)
SELECT year, revenue, LAG(revenue) OVER (ORDER BY year) AS previous_year,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year)) 
        / LAG(revenue) OVER (ORDER BY year) * 100,
    1) AS yoy_growth_percent
FROM yearly_sales
ORDER BY year;


-- Running total revenue over time
SELECT d.year, d.month, SUM(f.sales) AS monthly_sales,
    SUM(SUM(f.sales)) OVER (ORDER BY d.year, d.month) AS cumulative_sales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


-- Revenue contribution by customer segment
SELECT c.segment, ROUND(SUM(f.sales), 1) AS revenue,
    ROUND(
        SUM(f.sales) * 100.0 / SUM(SUM(f.sales)) OVER (),
    1) AS revenue_percent
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.segment;


-- View for yearly revenue
CREATE VIEW vw_yearly_revenue AS
SELECT d.year, ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year;


-- View for revenue by region
CREATE VIEW vw_region_revenue AS
SELECT r.region, 
    ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_region r ON f.region_key = r.region_key
GROUP BY r.region;


-- View for revenue by category
CREATE VIEW vw_category_revenue AS
SELECT p.category, 
    ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category;


-- View for top customers
CREATE VIEW vw_top_customers AS
SELECT 
    c.customer_name,
    ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_name
ORDER BY revenue DESC;


-- View for monthly sales trend
CREATE VIEW vw_monthly_sales AS
SELECT d.year, d.month, d.month_name,
    ROUND(SUM(f.sales), 1) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name;