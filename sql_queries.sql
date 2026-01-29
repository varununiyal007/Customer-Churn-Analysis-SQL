/* =========================================
   CUSTOMER CHURN & RETENTION ANALYSIS
   ========================================= */

-- 1. Last order date for each customer

select c.customer_id, c.customer_name, max(o.order_date) as last_order_date from customers c
left join sales s
on c.customer_id= s.customer_id
left join orders o
on s.order_id=o.order_id
group by c.customer_id, c.customer_name

-- 2. Churned customers (inactive for last 6 months)

   with last_order as 
(
select c.customer_id, c.customer_name, max(o.order_date) as last_order_date from customers c
left join sales s
on c.customer_id = s.customer_id
left join orders o
on s.order_id= o.order_id
group by c.customer_id, c.customer_name 
)
select customer_id, customer_name, last_order_date, 'churned' as churn_status from last_order
where last_order_date<dateadd(month,-6, getdate())
or last_order_date is null 

   
   
   -- 3. Churn Percentage 

   WITH CustomerAnalysis AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    LEFT JOIN orders o ON s.order_id = o.order_id
    GROUP BY c.customer_id
),
ChurnCounts AS (
    SELECT 
        COUNT(customer_id) AS total_customers,
        SUM(CASE 
            WHEN last_order_date < DATEADD(month, -6, GETDATE()) OR last_order_date IS NULL 
            THEN 1 
            ELSE 0 
        END) AS churned_customers
    FROM CustomerAnalysis
)
SELECT 
    total_customers,
    churned_customers,
    ROUND(
        CAST(churned_customers AS FLOAT) * 100.0 / NULLIF(total_customers, 0), 
        2
    ) AS churn_rate_pct
FROM ChurnCounts;


-- 4. Calculate churn rate by customer segment.


with last_order as 
(
select c.customer_id, c.customer_name,c.segment, max(o.order_date) as last_order_date from customers c
left join sales s
on c.customer_id = s.customer_id
left join orders o
on s.order_id= o.order_id
group by c.segment, c.customer_id, c.customer_name 
),
churned_counts as 
(
select segment,
count( distinct customer_id) as total_customers, 
sum(case when last_order_date<dateadd(month,-6,getdate()) or 
last_order_date is null then 1 else 0 end)as churned_customer from last_order
group by segment
)
select segment, total_customers, churned_customer, round(cast(churned_customer as float)*100/nullif(total_customers,0),2) 
as churn_rate_pct from churned_counts


   -- 5. Revenue Loss due to Churn

   
   WITH last_order AS (
    SELECT
        c.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN sales s
        ON c.customer_id = s.customer_id
    LEFT JOIN orders o
        ON s.order_id = o.order_id
    GROUP BY c.customer_id
),
churned_customers AS (
    SELECT customer_id
    FROM last_order
    WHERE last_order_date < DATEADD(month, -6, GETDATE())
       OR last_order_date IS NULL
)
SELECT
    SUM(s.sales) AS revenue_lost
FROM sales s
JOIN churned_customers c
    ON s.customer_id = c.customer_id;




