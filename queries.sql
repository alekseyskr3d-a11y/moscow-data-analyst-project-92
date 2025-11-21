--общее число покупателей
SELECT COUNT(*) AS customers_count
FROM customers;

--топ 10 продавцов
SELECT CONCAT(e.first_name, ' ', e.last_name) AS seller,
       COUNT(s.sales_id) AS operations,
       FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY e.employee_id,
         e.first_name,
         e.last_name
ORDER BY income DESC
LIMIT 10;

--продавцы с выручкой ниже средней
SELECT CONCAT(e.first_name, ' ', e.last_name) AS seller,
       FLOOR(AVG(p.price * s.quantity)) AS average_income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY e.employee_id,
         e.first_name,
         e.last_name
HAVING FLOOR(AVG(p.price * s.quantity)) <
  (SELECT FLOOR(AVG(s2.quantity * p2.price))
   FROM sales s2
   JOIN products p2 ON s2.product_id = p2.product_id)
ORDER BY average_income;

--выручка по дням недели
SELECT seller,
       day_of_week,
       income
FROM
  (SELECT e.first_name || ' ' || e.last_name AS seller,
          CASE EXTRACT(DOW FROM s.sale_date)
              WHEN 0 THEN 'sunday'
              WHEN 1 THEN 'monday'
              WHEN 2 THEN 'tuesday'
              WHEN 3 THEN 'wednesday'
              WHEN 4 THEN 'thursday'
              WHEN 5 THEN 'friday'
              WHEN 6 THEN 'saturday'
          END AS day_of_week,
          FLOOR(SUM(s.quantity * p.price)) AS income
   FROM sales s
   JOIN employees e ON s.sales_person_id = e.employee_id
   JOIN products p ON s.product_id = p.product_id
   GROUP BY e.employee_id,
            e.first_name,
            e.last_name,
            EXTRACT(DOW FROM s.sale_date)) AS subquery
ORDER BY seller,
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
SELECT CASE
           WHEN age BETWEEN 16 AND 25 THEN '16-25'
           WHEN age BETWEEN 26 AND 40 THEN '26-40'
           ELSE '40+'
       END AS age_category,
       COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;

--число покупателей в месяц
SELECT TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
       COUNT(DISTINCT s.customer_id) AS total_customers,
       FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;

--покупатели с первой покупкой по акции
WITH first_purchases AS
  (SELECT customer_id,
          MIN(sale_date) AS first_sale_date
   FROM sales
   GROUP BY customer_id),
     first_purchase_details AS
  (SELECT DISTINCT ON (fp.customer_id) fp.customer_id,
                      fp.first_sale_date,
                      s.sales_person_id,
                      s.sales_id
   FROM first_purchases fp
   JOIN sales s ON fp.customer_id = s.customer_id
   AND fp.first_sale_date = s.sale_date
   JOIN products p ON s.product_id = p.product_id
   WHERE p.price = 0)
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer,
       fpd.first_sale_date AS sale_date,
       CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchase_details fpd
JOIN customers c ON fpd.customer_id = c.customer_id
JOIN employees e ON fpd.sales_person_id = e.employee_id
ORDER BY c.customer_id;
