
#1.1

describe customers;


#1.2. Get the time range between which the orders were placed.

select min(order_purchase_timestamp) as first_order,
max(order_purchase_timestamp) as last_order from orders;

#1.3. Count the Cities & States of customers who ordered during the given period.

select count(distinct customer_city) as no_of_cities,count(distinct customer_state) as no_of_states 
from orders as o
left join customers as c
on o.customer_id=c.customer_id;

#2.1 Is there a growing trend in the no. of orders placed over the past years?

select year(order_purchase_timestamp) as year_,count(*) as no_of_orders from orders
group by year_
order by year_;

#2.2 Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

select month(order_purchase_timestamp) as month_no,monthname(order_purchase_timestamp) as month_,
year(order_purchase_timestamp) as year_,count(*) as no_of_orders
from orders
group by month_no,month_,year_
order by no_of_orders desc;

#2.3 During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)

with demo as(
select hour(order_purchase_timestamp) as hrs from orders)
select
case 
when hrs between 0 and 6 then "Dawn"
when hrs between 7 and 12 then "Mornings"
when hrs between 13 and 18	 then "Afternoon"
when hrs between 19 and 23 then "Night"
end as bins,
count(*) as no_of_orders
from demo
group by bins
order by no_of_orders desc;

#3.1 Get the month on month no. of orders placed in each state.

with demo as(
select c.customer_state,month(o.order_purchase_timestamp) as month_no, 
monthname(o.order_purchase_timestamp) as month_,year(o.order_purchase_timestamp) as year_,
count(*) as no_of_orders
from customers as c
join orders as o 
on c.customer_id=o.customer_id
group by customer_state,month_no,month_,year_
order by customer_state,year_,month_no)
select customer_state,month_no,month_,year_,no_of_orders,
sum(no_of_orders) over(partition by customer_state
order by customer_state,year_,month_no
rows between unbounded preceding and current row) as cumm_no_of_orders
from demo;

# 3.2 How are the customers distributed across all the states?

select customer_state, count(*) as no_of_customers,count(*)/
(
select count(customer_id) from customers
)*100 as percent
from customers
group by customer_state
order by no_of_customers desc;

# 4.1 Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only)

with demo2 as(
with demo as(
select year(o.order_purchase_timestamp) as year_, sum(payment_value) as total 
from payments as p
join orders as o
on p.order_id=o.order_id
where year(o.order_purchase_timestamp) between 2017 and 2018 
and month(o.order_purchase_timestamp)between 1 and 8
group by year_
order by year_ desc)
select year_,total,lead(total) over() as lead_ from demo)
select round((total - lead_) / lead_ * 100,2) as percent_increase from demo2
where lead_ is not null;





#4.2 Calculate the Total & Average value of order price for each state.

select c.customer_state,round(sum(p.payment_value),2) as total_payment,
round(avg(p.payment_value),2) as avg_payment
from customers as c
join orders as o
on c.customer_id=o.customer_id 
join payments as p
on o.order_id=p.order_id
group by c.customer_state
order by avg_payment desc;

#4.3 Calculate the Total & Average value of order freight for each state.
#value of order freight 

select c.customer_state,round(sum(oi.freight_value),2) as total_freight_value,round(avg(oi.freight_value),2) as avg_freight_value
from orders as o
join order_items as oi
on o.order_id=oi.order_id 
join customers as c
on c.customer_id=o.customer_id
group by c.customer_state
order by avg_freight_value;

#5.1 Find the no. of days taken to deliver each order from the order’s purchase date as delivery time

select * from orders

select order_id,
datediff(order_delivered_customer_date,order_purchase_timestamp) as time_to_deliver,
datediff(order_delivered_customer_date,order_estimated_delivery_date) as diff_in_estimated_delivery
from orders;

#5.2 Find out the top 5 states with the highest & lowest average freight value.

select c.customer_state,round(avg(freight_value),2) as avg_freight_value
from orders as o
join order_items as oi
on o.order_id=oi.order_id 
join customers as c
on c.customer_id=o.customer_id
group by c.customer_state
order by avg_freight_value desc
limit 5;

select c.customer_state,round(avg(freight_value),2) as avg_freight_value
from orders as o
join order_items as oi
on o.order_id=oi.order_id 
join customers as c
on c.customer_id=o.customer_id
group by c.customer_state
order by avg_freight_value
limit 5;

#5.3 Find out the top 5 states with the highest & lowest average delivery time.

select c.customer_state,
round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp)),2) as avg_delivery_time
from orders as o
join order_items as oi
on o.order_id=oi.order_id 
join customers as c
on c.customer_id=o.customer_id
group by c.customer_state
order by avg_delivery_time desc
limit 5;

select c.customer_state,
round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp)),1) as avg_delivery_time
from orders as o
join order_items as oi
on o.order_id=oi.order_id 
join customers as c
on c.customer_id=o.customer_id
group by c.customer_state
order by avg_delivery_time
limit 5;

#5.4 Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

select c.customer_state,
round(avg(datediff(o.order_delivered_customer_date,o.order_estimated_delivery_date)),1) as avg_diff_in_delivery
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by c.customer_state
order by avg_diff_in_delivery
limit 5;

#6.1 Find the month on month no. of orders placed using different payment types.

with demo as(
select month(o.order_purchase_timestamp) as month_no,monthname(o.order_purchase_timestamp) as month_,
year(o.order_purchase_timestamp) as year_, p.payment_type,
count(*)as no_of_orders
from orders as o
join payments as p
on o.order_id=p.order_id
group by year_,month_no,month_,payment_type
order by payment_type,year_,month_no)
select month_no,month_,year_,payment_type,no_of_orders,
sum(no_of_orders) over (partition by payment_type
order by payment_type,year_,month_no
rows between unbounded preceding and current row) as cumm_no_of_orders
from demo;

#6.2 Find the no. of orders placed on the basis of the payment installments that have been paid.

select count(*) as no_of_orders from payments
where payment_installments>0;



