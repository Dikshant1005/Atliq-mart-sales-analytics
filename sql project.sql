
-- Generate a report that provides an overview of the number of stores in each city
SELECT city, COUNT(*) AS no_of_stores
FROM dim_stores
GROUP BY city
ORDER BY no_of_stores DESC;


-- Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free).     
SELECT distinct(product_code), base_price, promo_type 
FROM fact_events
WHERE base_price > 500 AND promo_type = 'BOGOF';


-- Generate a report that displays each campaign along with the total revenue generated before and after the campaign?

SELECT
    fe.campaign_id,
    ROUND(SUM(fe.base_price * fe.`quantity_sold(before_promo)`)/1000000,2) AS revenue_before_promo,
    ROUND(SUM(
        CASE
            WHEN fe.promo_type = '33% OFF' THEN (1 - 0.33) * fe.base_price
            WHEN fe.promo_type = '50% OFF' THEN fe.base_price / 2
            WHEN fe.promo_type = '25% OFF' THEN (1 - 0.25) * fe.base_price
            WHEN fe.promo_type = 'BOGOF' THEN fe.base_price / 2
            WHEN fe.promo_type = '500 Cashback' THEN fe.base_price - 500
            ELSE fe.base_price
        END * fe.`quantity_sold(after_promo)`
    )/1000000,2) AS revenue_after_promo
FROM
    fact_events fe
GROUP BY
    fe.campaign_id;


-- Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 

WITH revenue_bf_af_promo AS (
    SELECT
        fe.*,
        (fe.base_price * fe.`quantity_sold(before_promo)` / 1000000) AS revenue_before_promo,
        (
            CASE
                WHEN fe.promo_type = '33% OFF' THEN (1 - 0.33) * fe.base_price
                WHEN fe.promo_type = '50% OFF' THEN fe.base_price / 2
                WHEN fe.promo_type = '25% OFF' THEN (1 - 0.25) * fe.base_price
                WHEN fe.promo_type = 'BOGOF' THEN fe.base_price / 2
                WHEN fe.promo_type = '500 Cashback' THEN fe.base_price - 500
                ELSE fe.base_price
            END * fe.`quantity_sold(after_promo)` / 1000000
        ) AS revenue_after_promo
    FROM
        fact_events fe
)

SELECT
    p.product_code,
    p.product_name,
    ROUND((SUM(revenue_after_promo) - SUM(revenue_before_promo)) / SUM(revenue_before_promo) * 100, 2) AS `IR%`
FROM
    revenue_bf_af_promo r
JOIN
    dim_products p ON r.product_code = p.product_code
GROUP BY
    p.product_code,
    p.product_name
ORDER BY
    `IR%` DESC
LIMIT 5;


-- Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. Additionally, provide rankings for the categories based on their ISU%.

WITH isu_pct AS (
    SELECT
        p.category,
        (SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`)) / SUM(`quantity_sold(before_promo)`) * 100 AS `ISU%`
    FROM
        fact_events fe
    JOIN
        dim_products p ON fe.product_code = p.product_code
    WHERE
        fe.campaign_id = 'CAMP_DIW_01'
    GROUP BY
        p.category
)

SELECT
    category,
    `ISU%`,
    RANK() OVER (ORDER BY `ISU%` DESC) AS category_rank
FROM
    isu_pct;

