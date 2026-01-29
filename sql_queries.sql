/* =========================================
   CUSTOMER CHURN & RETENTION ANALYSIS
   ========================================= */

-- 1. Last order date for each customer
WITH last_order AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN sales s
        ON c.customer_id = s.customer_id
    LEFT JOIN orders o
        ON s.order_id = o.order_id
    GROUP BY c.customer_id, c.customer_name
)

-- 2. Churned customers (inactive for last 6 months)
SELECT
    customer_id,
    customer_name,
    last_order_date
FROM last_order
WHERE last_order_date < DATEADD(MONTH, -6, GETDATE())
   OR last_order_date IS NULL
ORDER BY last_order_date;

-- 3. Churn count by customer segment
SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id) AS churned_customers
FROM customers c
LEFT JOIN last_order l
    ON c.customer_id = l.customer_id
WHERE l.last_order_date < DATEADD(MONTH, -6, GETDATE())
   OR l.last_order_date IS NULL
GROUP BY c.segment;

-- 4. Revenue lost due to churn
SELECT
    SUM(s.sales) AS revenue_lost
FROM sales s
JOIN last_order l
    ON s.customer_id = l.customer_id
WHERE l.last_order_date < DATEADD(MONTH, -6, GETDATE());

-- 5. Cohort analysis (first order month)
WITH first_order AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders o
    JOIN sales s
        ON o.order_id = s.order_id
    GROUP BY customer_id
)
SELECT
    YEAR(first_order_date) AS cohort_year,
    MONTH(first_order_date) AS cohort_month,
    COUNT(DISTINCT customer_id) AS customers
FROM first_order
GROUP BY YEAR(first_order_date), MONTH(first_order_date)
ORDER BY cohort_year, cohort_month;

