
Create Table Customers(
Customer_id Serial Primary key,
first_Name varchar(50) Not Null,
Last_Name varchar(50) Not Null,
email varchar(50) unique Not Null,
Phone varchar(50),
city varchar(50),
State varchar(50),
Signup_Date Date Default current_date
);

Create table Products(
Product_id serial Primary key,
Product_Name varchar(50) Not Null,
Category_id int Not Null,
Price Numeric(10,2) Not Null,
cost_price Numeric(10,2) Not Null,
foreign key(category_id) References categories(category_id)
);

Create table orders(
order_id serial Primary key,
Customer_id int Not Null,
order_status varchar(50) Not Null,
Payment_method varchar(50) Not Null,
order_date date Not Null,
Foreign key(Customer_id) References Customers(Customer_id)
);

Create table order_details(
order_item_id serial Primary key,
order_id int Not Null,
product_id int Not Null,
quantity int Not Null,
selling_price numeric(10,2) Not Null,

Foreign key(order_id) References orders(Order_id),
Foreign key(Product_id) References products(Product_id)
);

Create table categories(
category_id serial ,
category_Name varchar(50) Unique Not Null
);

Alter table categories
add primary key(category_id);

Alter table products
add column category_id int;

alter table products
add constraint fk_category foreign key(category_id)
References categories(category_id);

Alter table orders
add column order_total int;

Create table payments(
payment_id serial primary key,
order_id int Not Null,
payment_method varchar(50) Not Null,
payment_status varchar(50) Not NUll,
payment_date date Not Null,
Payment_amount Numeric(10,2) Not Null,
constraint fk_paymetn_order
foreign key(order_id) References orders(order_id)
);

CREATE TABLE addresses (
address_id SERIAL PRIMARY KEY,
customer_id INT NOT NULL,
address_line TEXT NOT NULL,
city VARCHAR(50),
state VARCHAR(50),
pincode VARCHAR(10),
CONSTRAINT fk_customer_address
FOREIGN KEY(customer_id)
REFERENCES customers(customer_id)
);

ALTER TABLE orders
ADD COLUMN address_id INT,
ADD CONSTRAINT fk_order_address
FOREIGN KEY(address_id)
REFERENCES addresses(address_id);

CREATE TABLE reviews(
review_id SERIAL PRIMARY KEY,
customer_id INT,
product_id INT,
rating INT,
review_text TEXT,
review_date DATE,
CONSTRAINT fk_review_customer
FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
CONSTRAINT fk_review_product
FOREIGN KEY(product_id) REFERENCES products(product_id),
CONSTRAINT unique_review UNIQUE(customer_id, product_id)
);

CREATE TABLE inventory (
inventory_id SERIAL PRIMARY KEY,
product_id INT NOT NULL,
stock_quantity INT NOT NULL,
last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id)
REFERENCES products(product_id)
);


CREATE TABLE order_status_history (
status_id SERIAL PRIMARY KEY,
order_id INT NOT NULL,
status VARCHAR(50) NOT NULL,
status_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

CONSTRAINT fk_status_order
FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TYPE order_status_enum AS ENUM (
'Pending',
'Shipped',
'Delivered',
'Cancelled',
'Returned'
);

ALTER TABLE order_status_history
DROP COLUMN IF EXISTS status,
ADD COLUMN status order_status_enum;

select table_name
from information_schema.tables
where table_schema = 'public';

--Entering the values into customers table

COPY customers(customer_id, first_name, last_name, email, phone, city, state, signup_date)
FROM '/C:\Users\tharun tharun\OneDrive\Desktop\K.Tharun\IT\Data analyst\SQL\Project-1\Data Files/customers'
DELIMITER ','
CSV HEADER;

--Inserting the data into "Order_table using Sql query"

Insert into orders (customer_id,order_status,payment_method,order_date,order_total,address_id)
select c.customer_id,Case when random() < 0.65 then 'Delivered'
                          When random() < 0.80 then 'shipped'
						  when random() < 0.95 then 'pending'
						  else 'cancelled'
					 End,
					 (Array['UPI','Credit card','Debit card','COD'])[floor(random()*4)+1],
					 current_date - (random()*365)::int, 
                      0, -- tempory, Update later
					  a.address_id
From customers c
join addresses a on c.customer_id = a.customer_id
join generate_series(1,(random()*4+1)::int) g on true;

-- Query Completed

-- Inserting data into order_details table 

Insert into Order_details(order_id,product_id,quantity,selling_price)
select o.order_id,p.product_id, case when random() < 0.6 Then 1
                                     when random() < 0.85 Then 2
									 else 3
								end,
Round((p.price * (0.85 + random()*0.15))::numeric, 2)
From orders o
Join lateral(select Product_id, price from products
order by random()
Limit (floor(random()*5)+1)) p on true;


--Quesry Completed

--Updating the order_total in order table

update orders o
set order_total = sub.total
from ( select order_id,sum(quantity * selling_price) as total
from order_details
group by order_id) sub 
where o.order_id = sub.order_id;

--query completed

-- Inserting data into payments table
Insert into Payments(order_id,payment_method,payment_status,payment_date,payment_amount)
select order_id,payment_method,case when order_status = 'Cancelled' Then 'Failed'
                               else 'Success'
							   End,
order_Date,order_total From orders;

--Query completed

--Inserting the data into order_status_history

Insert Into order_status_history(order_id,status,status_date)
Select o.order_id,s.status::order_status_enum,o.order_date + (s.step * Interval '1 day') from orders o
join lateral(Values ('Pending',0),
             ('Shipped',2),
			 ('Delivered',5)) as s(status,step) on true
Where o.order_status In ('Shipped','Delivered');

--Query Completed

--Inserting data into Inventory table

Insert into inventory(Product_id, Stock_quantity)
Select Product_id,(random()*200)::int from products;

--Query completed

--Inserting Data into review table
Insert Into reviews(customer_id,Product_id, rating,review_text,review_date)
select Distinct o.Customer_id, od.Product_id,(floor(random()*5)+1)::int,'Sample review',
o.order_date + interval '10 days' from orders o
join order_details od on o.order_id = od.order_id
where o.order_status = 'Delivered'
on conflict do nothing;

Select * from customers;
Select * from categories;
Select * from Addresses;
Select * from products;
Select * from orders;
Select * from order_details;
Select * from payments;
Select * from order_status_history;
Select * from inventory;
Select * from reviews;

select * from order_details
where order_id = 1;

select sum(selling_price) from order_details
where order_id = 1;
--Total revenue
Select coalesce(sum(order_total),0) As Revenue from orders
where order_status = 'Delivered';

--Total number of orders
Select coalesce(count(order_id),0) AS Total_Number_orders from orders;

--Count of unique customers who placed atlest one orders
Select count(Distinct customer_id) As Unique_custmer from orders;

--count of unique customers who place successful orders.
select count(distinct customer_id) as Total_customers from orders
where order_status !='cancelled';

--Average order value
select coalesce(avg(order_total),0) as Average_order_value from orders
where order_status ='Delivered';

--Top 5 customers generating revenue
select customer_id, coalesce(sum(order_total),0) as Revenue from orders
where order_status = 'Delivered'
Group by customer_id
order by Revenue desc
limit 5;

--Top 5 products by Revenue
Select P.Product_id, p.product_Name, sum(od.quantity * od.selling_price) as Revenue from order_details od 
join products p on od.product_id = p.product_id join orders o on o.order_id = od.order_id
where o.order_status = 'Delivered'
Group by P.Product_Name,P.Product_id
order by Revenue Desc
limit 5;

--Top 5 categories by Revenue

Select c.Category_id, c.Category_Name, sum(od.quantity * od.selling_price) as Revenue from order_details od 
join products p on od.product_id = p.product_id join orders o on o.order_id = od.order_id
join categories c on c.category_id = p.category_id
where o.order_status = 'Delivered'
Group by c.Category_Name,c.Category_id
order by Revenue Desc;

--Selecting the products category where 0order_status is Delivered

Select Distinct c.Category_Name from categories c
join products p on p.category_id = c.category_id join order_details od on od.product_id = p.product_id
join orders o on o.order_id = od.order_id
where order_status = 'Delivered';

--Revenue change month by month


Select Date_Trunc('month',o.order_date) as Month, sum(od.quantity * od.selling_price) as Revenue from order_details od 
join products p on od.product_id = p.product_id join orders o on o.order_id = od.order_id
where o.order_status = 'Delivered'
Group by Month
order by Month;

--Counting total customers who placed more than one order

Select Count(*) as Total_count from(Select Customer_id, count(order_id) as Total_order from orders
Group by Customer_id
having count(order_id) > 1
order by Total_order desc) sub;

--Percentage of the customers who placed more than the one order
With CTE AS(
Select Count(*) as Total_count from(Select Customer_id, count(order_id) as Total_order from orders
Group by Customer_id
having count(order_id) > 1) AS SUB),
CTE2 as (select Count(Distinct Customer_id) as Unique_count from orders)

Select (c1.Total_count*100)/c2.Unique_count As percentage from CTE c1,CTE2 c2;

--Average Revenue Generated per customer
SELECT 
    AVG(customer_revenue) AS avg_customer_lifetime_value
FROM (
    SELECT 
        o.customer_id,
        SUM(od.quantity * od.selling_price) AS customer_revenue
    FROM order_details od
    JOIN orders o ON o.order_id = od.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
) sub;

Select count(Distinct Customer_id)  from orders;

--Which 3months generated the highest revenue
Select Date_Trunc('month',o.order_date) as Month, sum(od.quantity*od.selling_price) as Revenue from order_details od
join orders o on o.order_id = od.order_id
where o.order_status = 'Delivered'
Group by Month
order by Month,Revenue; 
--limit 3;

--Running total Revenue
With Monthly_Revenue AS(Select Date_Trunc('month',o.order_date) as Month, sum(od.quantity*od.selling_price) As Revenue from order_details od
join orders o on o.order_id = od.order_id
where o.order_status = 'Delivered'
Group by Month)
Select Month,Revenue,sum(Revenue)over(order by Month) as Running_Total From Monthly_Revenue;


--For Each Category, Which product Generate the Highest Revenue
With  Category_Revenue As (Select p.Category_id,p.product_id,p.Product_name,sum(od.Quantity*od.Selling_price) As Revenue from order_details od
join products p on p.product_id = od.product_id join orders o on o.order_id = od.order_id
where order_status = 'Delivered'
Group by p.Category_id,p.product_id,p.Product_Name),
Rank_for_Revenue AS (Select Category_id,product_id,Product_Name,Revenue,Dense_rank() over(Partition by Category_id order by Revenue Desc) As rn
From Category_Revenue)
Select Category_id,Product_id,Product_Name,Revenue,rn from Rank_for_Revenue
where rn = 1;

--Selecting the customers who are not placed any orders
Select Customer_id from Customers
where Customer_id not In(select Distinct Customer_id from orders);


--Customer Segmentation

With Customer_Revenue AS (Select Customer_id, sum(order_total) As Revenue from orders
Where order_status = 'Delivered'
Group by Customer_id)
Select Customer_id, Revenue, Case
                                  When Revenue > 30000 Then 'High'
								  when Revenue > 10000 Then 'Medium'
								  else 'Low'
							  end As Customer_Segmentation from Customer_Revenue;

-- Creating one table and storing all essential data in it for Dashboard purpose
SELECT 
    c.customer_id, 
    c.first_name, 
    c.city, 
    
    o.order_id,
    o.order_date,
    o.order_status,
    
    p.product_id,
    p.product_name,
	P.cost_price,
    
    ca.category_name,
    
    od.quantity,
    od.selling_price,
    
    (od.quantity * od.selling_price) AS Revenue

FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
JOIN categories ca ON ca.category_id = p.category_id;

Select * from orders;

Select * from products;
select * from order_details;
select * from inventory;
select * from reviews;

delete from reviews;
Delete from order_details;
Delete from inventory;
delete from products;
Drop table analysis;
create temp table analysis as
SELECT 
    c.customer_id, 
    c.first_name, 
    c.city, 
    
    o.order_id,
    o.order_date,
    o.order_status,
    
    p.product_id,
    p.product_name,
	p.cost_price,
    
    ca.category_name,
    
    od.quantity,
    od.selling_price,
    
    (od.quantity * od.selling_price) AS Revenue

FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
JOIN categories ca ON ca.category_id = p.category_id;

-- Changing the sequence of the order_item_id

select column_default
from information_schema.columns
where table_name = 'order_details'
and column_name = 'order_item_id';

alter sequence order_details_order_item_id_seq restart with 1;

Select * from order_details;

truncate table order_details restart identity cascade;


--MOM Revenue Percentage

WITH monthly_revenue AS (
SELECT
DATE_TRUNC('month', order_date) AS month,
SUM(revenue) AS total_revenue
FROM Analysis
GROUP BY month
)

SELECT
month,
total_revenue,
LAG(total_revenue) OVER(ORDER BY month) AS previous_month_revenue,

ROUND(
(
(total_revenue - LAG(total_revenue) OVER(ORDER BY month))
/
LAG(total_revenue) OVER(ORDER BY month)
) * 100,
2
) AS mom_growth_percentage

FROM monthly_revenue;


--Profit Percentage

WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(revenue) AS total_revenue,
		sum(Cost_price) as Total_cost_price,
        -- Calculates total profit (Revenue - Cost)
        SUM(revenue - cost_price) AS total_profit 
    FROM Analysis
    GROUP BY month
)

SELECT
    month,
    total_revenue,
	Total_cost_price,
    LAG(total_revenue) OVER(ORDER BY month) AS previous_month_revenue,
    
    -- Month-over-Month Revenue Growth %
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER(ORDER BY month)) / 
        LAG(total_revenue) OVER(ORDER BY month)) * 100, 
        2
    ) AS mom_growth_percentage,
    
    total_profit,
    
    -- Profit Margin % (Profit / Revenue)
    ROUND(
        (total_profit / total_revenue) * 100, 
        2
    ) AS profit_margin_percentage,
    
    -- Month-over-Month Profit Growth %
    ROUND(
        ((total_profit - LAG(total_profit) OVER(ORDER BY month)) / 
        LAG(total_profit) OVER(ORDER BY month)) * 100, 
        2
    ) AS mom_profit_growth_percentage

FROM monthly_metrics;

--Query Ends

Select o.customer_id, sum(od.quantity*od.selling_price) as Revenue from orders o
join order_details od on o.order_id = od.order_id
group by o.customer_id;

--Finding the category which generating the highest revenue

Select c.Category_id, c.category_name, sum(od.quantity * od.selling_price) as Revenue from categories c
join products p on c.category_id = p.category_id
join order_details od on p.product_id = od.product_id
group by c.category_id, c.category_name
order by Revenue Desc;


Select c.Category_id, c.category_name, sum(od.quantity * od.selling_price) as Revenue from categories c
join products p on c.category_id = p.category_id
join order_details od on p.product_id = od.product_id
group by c.category_id, c.category_name
order by Revenue Desc;


Select * from order_details;

--finding the total quantity sold in each category

Select p.category, p.category_id,sum(od.quantity) as total, sum(quantity*selling_price) as Revenue from products p
join order_details od on p.product_id = od.product_id
--where p.category = 'Books'
group by p.category,p.category_id
order by total DESC;
