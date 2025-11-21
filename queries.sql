--общее число покупателей
SELECT COUNT(*) AS customers_count
FROM customers;

--топ 10 продавцов
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    COUNT(sales.sales_id) AS operations,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees
    ON sales.sales_person_id = employees.employee_id
INNER JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
    employees.first_name,
    employees.last_name
ORDER BY income DESC
LIMIT 10;

--продавцы с выручкой ниже средней
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    FLOOR(AVG(products.price * sales.quantity)) AS average_income
FROM sales
INNER JOIN employees
    ON sales.sales_person_id = employees.employee_id
INNER JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    employees.employee_id,
    employees.first_name,
    employees.last_name
HAVING FLOOR(AVG(products.price * sales.quantity)) < (
    SELECT
        FLOOR(AVG(sales_inner.quantity * products_inner.price))
    FROM sales AS sales_inner
    INNER JOIN products AS products_inner
        ON sales_inner.product_id = products_inner.product_id
)
ORDER BY average_income;

--выручка по дням недели
SELECT
    seller,
    day_of_week,
    income
FROM (
    SELECT
        employees.first_name || ' ' || employees.last_name AS seller,
        CASE EXTRACT(DOW FROM sales.sale_date)
            WHEN 0 THEN 'sunday'
            WHEN 1 THEN 'monday'
            WHEN 2 THEN 'tuesday'
            WHEN 3 THEN 'wednesday'
            WHEN 4 THEN 'thursday'
            WHEN 5 THEN 'friday'
            WHEN 6 THEN 'saturday'
        END AS day_of_week,
        FLOOR(SUM(sales.quantity * products.price)) AS income
    FROM sales
    INNER JOIN employees
        ON sales.sales_person_id = employees.employee_id
    INNER JOIN products
        ON sales.product_id = products.product_id
    GROUP BY
        employees.employee_id,
        employees.first_name,
        employees.last_name,
        EXTRACT(DOW FROM sales.sale_date)
) AS subquery
ORDER BY
    seller,
    CASE day_of_week
        WHEN 'monday' THEN 1
        WHEN 'tuesday' THEN 2
        WHEN 'wednesday' THEN 3
        WHEN 'thursday' THEN 4
        WHEN 'friday' THEN 5
        WHEN 'saturday' THEN 6
        WHEN 'sunday' THEN 7
    END;

--покупатели по разным возраснтым группам
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

--число покупателей в месяц
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(sales.quantity * products.price)) AS income
FROM sales
INNER JOIN products
    ON sales.product_id = products.product_id
GROUP BY TO_CHAR(sales.sale_date, 'YYYY-MM')
ORDER BY selling_month;

--покупатели с первой покупкой по акции
WITH first_purchases AS (
    SELECT
        customer_id,
        MIN(sale_date) AS first_sale_date
    FROM sales
    GROUP BY customer_id
),

first_purchase_details AS (
    SELECT DISTINCT ON (first_purchases.customer_id)
        first_purchases.customer_id,
        first_purchases.first_sale_date,
        sales.sales_person_id,
        sales.sales_id
    FROM
        first_purchases
    INNER JOIN sales
        ON first_purchases.customer_id = sales.customer_id
        AND first_purchases.first_sale_date = sales.sale_date
    INNER JOIN products
        ON sales.product_id = products.product_id
    WHERE products.price = 0
)

SELECT
    customer,
    sale_date,
    seller
FROM (
    SELECT
        CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
        first_purchase_details.first_sale_date AS sale_date,
        CONCAT(employees.first_name, ' ', employees.last_name) AS seller
    FROM first_purchase_details
    INNER JOIN customers
        ON first_purchase_details.customer_id = customers.customer_id
    INNER JOIN employees
        ON first_purchase_details.sales_person_id = employees.employee_id
) AS final_results
ORDER BY customer;
