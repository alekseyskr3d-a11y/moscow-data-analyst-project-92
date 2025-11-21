-- общее число покупателей
select
    count(*) as customers_count
from customers;

-- топ 10 продавцов
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_id) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales s
join employees e on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
order by income desc
limit 10;

-- продавцы с выручкой ниже средней
select
    concat(e.first_name, ' ', e.last_name) as seller,
    floor(avg(p.price * s.quantity)) as average_income
from sales s
join employees e on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
having
    floor(avg(p.price * s.quantity)) < (
        select
            floor(avg(s2.quantity * p2.price))
        from sales s2
        join products p2 on s2.product_id = p2.product_id
    )
order by average_income;

-- выручка по дням недели
select
    e.first_name || ' ' || e.last_name as seller,
    case extract(dow from s.sale_date)
        when 0 then 'sunday'
        when 1 then 'monday'
        when 2 then 'tuesday'
        when 3 then 'wednesday'
        when 4 then 'thursday'
        when 5 then 'friday'
        when 6 then 'saturday'
    end as day_of_week,
    floor(sum(s.quantity * p.price)) as income
from sales s
join employees e on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name,
    extract(dow from s.sale_date)
order by
    seller,
    case
        when day_of_week = 'monday' then 1
        when day_of_week = 'tuesday' then 2
        when day_of_week = 'wednesday' then 3
        when day_of_week = 'thursday' then 4
        when day_of_week = 'friday' then 5
        when day_of_week = 'saturday' then 6
        when day_of_week = 'sunday' then 7
    end;

-- покупатели по разным возрастным группам
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(*) as age_count
from customers
group by age_category
order by age_category;

-- число покупателей в месяц
select
    to_char(s.sale_date, 'yyyy-mm') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(s.quantity * p.price)) as income
from sales s
join products p on s.product_id = p.product_id
group by to_char(s.sale_date, 'yyyy-mm')
order by selling_month;

-- покупатели с первой покупкой по акции
with first_purchases as (
    select
        customer_id,
        min(sale_date) as first_sale_date
    from sales
    group by customer_id
),
first_purchase_details as (
    select distinct on (fp.customer_id)
        fp.customer_id,
        fp.first_sale_date,
        s.sales_person_id,
        s.sales_id
    from first_purchases fp
    join sales s
        on fp.customer_id = s.customer_id
        and fp.first_sale_date = s.sale_date
    join products p on s.product_id = p.product_id
    where p.price = 0
)
select
    concat(c.first_name, ' ', c.last_name) as customer,
    fpd.first_sale_date as sale_date,
    concat(e.first_name, ' ', e.last_name) as seller
from first_purchase_details fpd
join customers c on fpd.customer_id = c.customer_id
join employees e on fpd.sales_person_id = e.employee_id
order by c.customer_id;
