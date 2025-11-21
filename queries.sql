-- общее число покупателей
select
    count(*) as customers_count
from
    customers;

-- топ 10 продавцов
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    count(sales.sales_id) as operations,
    floor(sum(products.price * sales.quantity)) as income
from
    sales
inner join
    employees
    on sales.sales_person_id = employees.employee_id
inner join
    products
    on sales.product_id = products.product_id
group by
    employees.employee_id,
    employees.first_name,
    employees.last_name
order by
    income desc
limit 10;

-- продавцы с выручкой ниже средней
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    floor(avg(products.price * sales.quantity)) as average_income
from
    sales
inner join
    employees
    on sales.sales_person_id = employees.employee_id
inner join
    products
    on sales.product_id = products.product_id
group by
    employees.employee_id,
    employees.first_name,
    employees.last_name
having
    floor(avg(products.price * sales.quantity)) < (
        select
            floor(avg(sales_inner.quantity * products_inner.price))
        from
            sales as sales_inner
        inner join
            products as products_inner
            on sales_inner.product_id = products_inner.product_id
    )
order by
    average_income;

-- выручка по дням недели
select
    employees.first_name || ' ' || employees.last_name as seller,
    case extract(dow from sales.sale_date)
        when 0 then 'sunday'
        when 1 then 'monday'
        when 2 then 'tuesday'
        when 3 then 'wednesday'
        when 4 then 'thursday'
        when 5 then 'friday'
        when 6 then 'saturday'
    end as day_of_week,
    floor(sum(sales.quantity * products.price)) as income
from
    sales
inner join
    employees
    on sales.sales_person_id = employees.employee_id
inner join
    products
    on sales.product_id = products.product_id
group by
    employees.employee_id,
    employees.first_name,
    employees.last_name,
    extract(dow from sales.sale_date)
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
from
    customers
group by
    age_category
order by
    age_category;

-- число покупателей в месяц
select
    to_char(sales.sale_date, 'yyyy-mm') as selling_month,
    count(distinct sales.customer_id) as total_customers,
    floor(sum(sales.quantity * products.price)) as income
from
    sales
inner join
    products
    on sales.product_id = products.product_id
group by
    to_char(sales.sale_date, 'yyyy-mm')
order by
    selling_month;

-- покупатели с первой покупкой по акции
with first_purchases as (
    select
        customer_id,
        min(sale_date) as first_sale_date
    from
        sales
    group by
        customer_id
),

first_purchase_details as (
    select distinct on (first_purchases.customer_id)
        first_purchases.customer_id,
        first_purchases.first_sale_date,
        sales.sales_person_id,
        sales.sales_id
    from
        first_purchases
    inner join
        sales
        on first_purchases.customer_id = sales.customer_id
        and first_purchases.first_sale_date = sales.sale_date
    inner join
        products
        on sales.product_id = products.product_id
    where
        products.price = 0
)

select
    concat(customers.first_name, ' ', customers.last_name) as customer,
    first_purchase_details.first_sale_date as sale_date,
    concat(employees.first_name, ' ', employees.last_name) as seller
from
    first_purchase_details
inner join
    customers
    on first_purchase_details.customer_id = customers.customer_id
inner join
    employees
    on first_purchase_details.sales_person_id = employees.employee_id
order by
    customers.customer_id;
