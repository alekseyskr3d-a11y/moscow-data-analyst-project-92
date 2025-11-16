
select count (*) as customers_count
from customers c ;
--общее число покупателей
select concat(e.first_name , ' ', e.last_name ) as seller, count(s.sales_id) as operations, floor(sum(p.price * s.quantity)) as income
from  sales s 
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
group by e.employee_id , e.first_name , e.last_name 
order by income desc 
limit 10;
-- топ 10 продавцов
select concat(e.first_name , ' ', e.last_name ) as seller, floor(avg(p.price * s.quantity)) as income
from  sales s 
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
group by e.employee_id , e.first_name , e.last_name 
having floor(avg(p.price * s.quantity)) <  (
    SELECT FLOOR(AVG(s2.quantity * p2.price))
    FROM sales s2
    JOIN products p2 ON s2.product_id = p2.product_id
)
order by income desc ;
-- продавци с выручкой ниже средней
SELECT 
    e.first_name || ' ' || e.last_name AS seller,
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
GROUP BY e.employee_id, e.first_name, e.last_name, EXTRACT(DOW FROM s.sale_date)
ORDER BY EXTRACT(DOW FROM s.sale_date), seller;
--выручка по дням недели