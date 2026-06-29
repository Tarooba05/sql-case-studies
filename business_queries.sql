/*
"What do these two tables have in common?"

orders + customers  → customer_id
orders + payments   → order_id
orders + items      → order_id
items + products    → product_id
items + sellers     → seller_id
*/

/*
1. What columns do I need in the output?
2. Which table(s) contain those columns?
3. How do those tables connect? (JOIN key)
4. Do I need to filter any rows out? (WHERE)
5. Am I calculating something per group? (GROUP BY)
6. Do I need to filter those groups? (HAVING)
7. Do I need to sort? (ORDER BY)
8. Do I need to limit results? (LIMIT)
*/

-- Q1: How many orders were placed each month?
select 
	TO_CHAR(order_purchase_timestamp, 'YYYY-MM') as month,
	count(order_id) as total_orders
from olist_orders_dataset
group by month 
order by month;

-- Q2: Which are the top 5 cities by number of customers?
select customer_city, count(customer_id) as total_customers
from olist_customers_dataset
group by customer_city
order by total_customers desc
limit 5

-- Q3: What is the average order value per product category?
select p.product_category_name, round(avg(oi.price):: numeric, 2) as avg_order_value
from olist_order_items_dataset oi
join olist_products_dataset p on oi.product_id = p.product_id
group by p.product_category_name
order by avg_order_value desc;

-- Q4: How many orders were delivered late vs on time?
select 
	case 
		when order_delivered_customer_date > order_estimated_delivery_date
		then 'Late'
		else 'On time'
	end as deliver_status,
	count(*) as total_orders
from olist_orders_dataset
where order_delivered_customer_date is not null
group by deliver_status;

-- Q5: What percentage of orders were cancelled?
select round(100.0 * count(case when order_status = 'canceled' then 1 end) / count(*) , 2) as cancellation_rate_pct
from olist_orders_dataset;

-- Q6: Which sellers have the highest average review score?
select oi.seller_id, 
	   round(avg(r.review_score)::NUMERIC , 2) as avg_review_score,
	   count(r.review_id) as total_reviews
from olist_order_items_dataset oi
join olist_order_reviews_dataset r on oi.order_id = r.order_id
group by oi.seller_id
having count(r.review_id) >= 10
order by avg_review_score desc
limit 10;

-- Q7: How many customers placed more than one order?
select count(*) as repeat_customers
from (select customer_unique_id
	  from olist_customers_dataset c
	  join olist_orders_dataset o on c.customer_id = o.customer_id
	  group by customer_unique_id
	  having count(o.order_id) > 1
	  ) as repeat_buyers;

-- Q8: What is the revenue trend month over month?
select 
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') as month,
    round(sum(oi.price)::NUMERIC, 2) as total_revenue
from olist_order_items_dataset oi
join olist_orders_dataset o on oi.order_id = o.order_id
group by month
order by month;

-- Q9: Which product categories have the most returns/cancellations?
SELECT 
    p.product_category_name,
    COUNT(*) AS total_cancellations
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_products_dataset p ON oi.product_id = p.product_id
WHERE o.order_status = 'canceled'
GROUP BY p.product_category_name
ORDER BY total_cancellations DESC
LIMIT 10;

-- Q10: What is the average delivery time in days per state?
select c.customer_state, round(avg(extract(epoch from(o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400) :: numeric, 1) as avg_delivery_days
from olist_orders_dataset o 
join olist_customers_dataset c on o.customer_id = c.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_days;

--SELECT + WHERE
-- 1. Show all orders that are currently 'shipped' (not delivered yet)
select * 
from olist_orders_dataset 
where order_status = 'shipped';

-- 2. Show all customers from the state of 'RJ' (Rio de Janeiro)
select *
from olist_customers_dataset 
where customer_state = 'RJ';

-- 3. Show all payments made by 'credit_card' over 500 in value
select *
from olist_order_payments_dataset
where payment_type = 'credit_card' AND payment_value >= 500;

-- 4. Show all products that have more than 5 photos
select *
from olist_products_dataset
where product_photos_qty > 5;

-- 5. Show orders that were NOT delivered (all statuses except 'delivered')
select * 
from olist_orders_dataset 
where order_status != 'delivered';

-- 6. Show all sellers from the city of 'sao paulo'
select *
from olist_sellers_dataset 
where seller_city = 'sao paulo';

-- 7. Show all reviews with a score of 1 (worst rating)
select * 
from olist_order_reviews_dataset
where review_score = 1;

-- 8. Show orders placed in January 2018 only
select *
from olist_orders_dataset
where order_purchase_timestamp >= '2018-01-01' and order_purchase_timestamp < '2018-02-01';


--Joins
-- 1. Show each order with the customer's city and state
select o.order_id , c.customer_city , c.customer_state
from olist_orders_dataset o
join olist_customers_dataset c
on o.customer_id = c.customer_id;

-- 2. Show each order item with the product category name
SELECT oi.order_id,oi.product_id,p.product_category_name
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LIMIT 100;

-- 3. Show each order with its review score and review comment
select o.order_id , r.review_score , r.review_comment_message
from olist_orders_dataset o
join olist_order_reviews_dataset r
on o.order_id = r.order_id
limit 100

-- 4. Show each seller with the number of items they've sold
--    (hint: JOIN sellers to order_items)
select seller_id , count(*) as item_sold
from olist_order_items_dataset
group by seller_id
order by item_sold desc;

-- 5. Show orders with both payment info AND customer city in one query
--    (hint: you need 3 tables)
select o.order_id , p.payment_type , p.payment_value , c.customer_city
from olist_orders_dataset o
join olist_order_payments_dataset p
on o.order_id = p.order_id
join olist_customers_dataset c
on o.customer_id = c.customer_id
limit 100;

-- 6. Show all products that have NEVER been ordered
--    (hint: anti-join using LEFT JOIN + WHERE IS NULL)
SELECT p.product_id, p.product_category_name
FROM olist_products_dataset p
LEFT JOIN olist_order_items_dataset oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL

-- 7. Show each order with the seller's city who fulfilled it
select o.order_id , s.seller_id , s.seller_city
from olist_orders_dataset o
join olist_order_items_dataset oi on o.order_id = oi.order_id 
join olist_sellers_dataset s on oi.seller_id = s.seller_id 
limit 100 


-- GROUP BY + HAVING
-- 1. How many orders does each customer state have?
select c.customer_state , count(o.order_id) as total_orders
from olist_orders_dataset o
join olist_customers_dataset c on o.customer_id = c.customer_id
group by c.customer_state;

-- 2. What is the total revenue per payment type?
select p.payment_type, round(sum(p.payment_value):: NUMERIC, 2) as total_revenue
from olist_order_payments_dataset p
group by p.payment_type;

-- 3. Which product categories have more than 500 orders?
select p.product_category_name, count(*) as total_orders
from olist_order_items_dataset oi
join olist_products_dataset p
on oi.product_id = p.product_id
group by p.product_category_name 
having count(*) > 500
order by total_orders desc;

-- 4. What is the average review score per product category?
select p.product_category_name , round(avg(r.review_score):: numeric, 2) as avg_review_score
from olist_order_reviews_dataset r
join olist_order_items_dataset oi on r.order_id = oi.order_id 
join olist_products_dataset p on oi.product_id = p.product_id
group by p.product_category_name;

-- 5. Which states have an average delivery payment over 200?
select c.customer_state , round(avg(p.payment_value):: numeric , 2) as avg_delivery_payment
from olist_orders_dataset o
join olist_order_payments_dataset p on o.order_id = p.order_id
join olist_customers_dataset c on o.customer_id = c.customer_id 
group by c.customer_state 
having avg(p.payment_value) > 200;

-- 6. How many orders were placed per order status per month?
--    (hint: GROUP BY two columns)
select order_status, count(order_id) as total_orders, TO_CHAR(order_purchase_timestamp, 'YYYY-MM') as month
from olist_orders_dataset 
group by month, order_status 
order by month , order_status;

-- 7. Which sellers have sold more than 100 items?
select seller_id , count(*) as items_sold
from olist_order_items_dataset 
group by seller_id 
having count(*) > 100
order by items_sold desc;

-- 8. What is the min, max and average price per product category?
select p.product_category_name , round(min(oi.price):: numeric, 2) as min_price, round(max(oi.price):: numeric, 2) as max_price, round(avg(oi.price):: numeric, 2) as avg_price
from olist_order_items_dataset oi
join olist_products_dataset p on oi.product_id = p.product_id
group by p.product_category_name;
