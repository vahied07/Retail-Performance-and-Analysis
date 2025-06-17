-- (1) What is the total revenue generated in the last 12 months? 

SELECT 
    SUM(total_amount) AS total_revenue_last_12_months
FROM 
    sales_data_cleaned
WHERE 
    order_date >= CURDATE() - INTERVAL 12 MONTH;
    

-- (2) Which are the top 5 best-selling products by quantity? 

SELECT 
    p.product_name,
    s.product_id,
    SUM(s.quantity) AS total_quantity_sold
FROM 
    sales_data_cleaned s
JOIN 
    products_cleaned p ON s.product_id = p.product_id
GROUP BY 
    s.product_id, p.product_name
ORDER BY 
    total_quantity_sold DESC
LIMIT 5;


-- (3) How many customers are from each region? 

SELECT 
    region,
    COUNT(*) AS customer_count
FROM 
    customers_cleaned
GROUP BY 
    region
ORDER BY 
    customer_count DESC;
    

-- (4) Which store has the highest profit in the past year?

SELECT 
    st.store_id,
    st.store_name,
    st.city,
    st.region,
    SUM(s.total_amount) - st.operating_cost AS profit
FROM 
    sales_data_cleaned s
JOIN 
    stores_cleaned st ON s.store_id = st.store_id
WHERE 
    s.order_date >= CURDATE() - INTERVAL 12 MONTH
GROUP BY 
    st.store_id, st.store_name, st.city, st.region, st.operating_cost
ORDER BY 
    profit DESC
LIMIT 1;


-- (5) What is the return rate by product category? 

SELECT 
    p.category,
    COUNT(DISTINCT r.order_id) AS total_returns,
    COUNT(DISTINCT s.order_id) AS total_sales,
    ROUND(
        (COUNT(DISTINCT r.order_id) / COUNT(DISTINCT s.order_id)) * 100, 
        2
    ) AS return_rate_percent
FROM 
    sales_data_cleaned s
JOIN 
    products_cleaned p ON s.product_id = p.product_id
LEFT JOIN 
    returns_cleaned r ON s.order_id = r.order_id
GROUP BY 
    p.category
ORDER BY 
    return_rate_percent DESC;


-- (6) What is the average revenue per customer by age group? 

SELECT 
    CASE
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
        WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS age_group,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    ROUND(SUM(s.total_amount) / COUNT(DISTINCT c.customer_id), 2) AS avg_revenue_per_customer
FROM 
    customers_cleaned c
JOIN 
    sales_data_cleaned s ON c.customer_id = s.customer_id
GROUP BY 
    age_group
ORDER BY 
    age_group;
    

-- (7) Which sales channel (Online vs In-Store) is more profitable on average? 

SELECT 
    s.sales_channel,
    ROUND(AVG((s.unit_price * s.quantity * (1 - s.discount_pct)) - (p.cost_price * s.quantity)), 2) AS avg_profit_per_order
FROM 
    sales_data_cleaned s
JOIN 
    products_cleaned p ON s.product_id = p.product_id
GROUP BY 
    s.sales_channel
ORDER BY 
    avg_profit_per_order DESC;
    

-- (8) How has monthly profit changed over the last 2 years by region? 

WITH ranked_returns AS (
  SELECT 
    p.category,
    p.product_id,
    p.product_name,
    COUNT(s.order_id) AS total_sales,
    COUNT(r.return_id) AS total_returns,
    ROUND(COUNT(r.return_id) / COUNT(s.order_id) * 100, 2) AS return_rate,
    ROW_NUMBER() OVER (
      PARTITION BY p.category
      ORDER BY COUNT(r.return_id) / COUNT(s.order_id) DESC
    ) AS rn
  FROM sales_data_cleaned s
  JOIN products_cleaned p ON s.product_id = p.product_id
  LEFT JOIN returns_cleaned r ON s.order_id = r.order_id
  GROUP BY p.category, p.product_id, p.product_name
  HAVING total_sales > 0
)

SELECT 
  category, product_id, product_name, total_sales, total_returns, return_rate
FROM ranked_returns
WHERE rn <= 3
ORDER BY category, rn;


-- (10) . Which 5 customers have contributed the most to total profit, and what is their tenure with the company? 

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ROUND(SUM((s.unit_price * s.quantity * (1 - s.discount_pct)) - (p.cost_price * s.quantity)), 2) AS total_profit,
    DATEDIFF(CURDATE(), c.signup_date) AS tenure_days,
    ROUND(DATEDIFF(CURDATE(), c.signup_date) / 365, 1) AS tenure_years
FROM 
    sales_data_cleaned s
JOIN 
    products_cleaned p ON s.product_id = p.product_id
JOIN 
    customers_cleaned c ON s.customer_id = c.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.signup_date
ORDER BY 
    total_profit DESC
LIMIT 5;
