use E_commerce;
select * from customers;
select * from orderdetails;
select * from orders;
select * from products;

--- CUSTOMER INSIGHTS 

--- Checking the top cities where customer concentration is highest for targeted marketing and logistical optimization
select location,count(customer_id) as number_of_customers 
from customers group by location order by number_of_customers desc limit 3;

--- What is the distribution of customer order frequencies across our platform?
with cte as 
(select customer_id as NumberOrders,count(customer_id) as CCount
from Orders group by customer_id order by NumberOrders)
select CCount as NumberOfOrders,count(CCount) as CustomerCount
from cte group by NumberOfOrders order by NumberOfOrders;

--- How successful are our marketing and market expansion campaigns at bringing in entirely new customers month-over-month ?
with cte as
(select distinct(customer_id) as customer,min(date_format(Order_date,'%Y-%m')) as Month from 
orders group by customer_id order by Month asc)
select Month as FirstPurchaseMonth ,count(customer) as TotalNewCustomers 
from cte group by FirstPurchaseMonth;--- as the customer count decreases, this shows the marketing campaign not working as planned.


--- PRODUCT ANALYSIS

--- Which products are generatig more revenue?
select o.product_id as Product_id , p.name as Product_Name , sum(o.quantity*o.price_per_unit) as TotalPrice
from orderdetails as o join products as p on p.product_id = o.product_id group by Product_id, Product_Name 
order by TotalPrice desc ;

--- What products are commonly purchased together?
select od1.product_id as Product1,
		od2.product_id as Product2,
        count(distinct(od1.order_id)) as Times_Bought
        from orderdetails as od1 join orderdetails as od2 
        on od1.order_id = od2.order_id 
        and od1.product_id < od2.product_id
        group by product1,product2
        order by Times_Bought desc
        ; --- this will not only help in inventory management but also in offering discounts to increase the sales.


--- What are our top-grossing products that customers consistently buy in pairs
with cte as 
(select product_id,avg(Quantity) as AvgQuantity,
 sum(price_per_unit*quantity) as TotalRevenue
 from OrderDetails group by product_id )
select product_id,AvgQuantity,TotalRevenue from cte
where AvgQuantity =2  order by TotalRevenue desc; --- Among products with an average purchase quantity of two, product 1 exhibit the highest total revenue.

--- Which of our product categories have the widest appeal across our customer base
select p.category as category, count(distinct(o.customer_id)) as unique_customers
from Orders as o join orderdetails as od on od.order_id=o.order_id
join products as p on p.Product_id=od.Product_id
group by category  order by unique_customers desc;--- Electronics product category needs more focus as it is in high demand among the customers.


--- SALES OPTIMIZATION

--- What does our month-over-month sales growth trajectory look like, and are we picking up momentum?
with cte as 
(select date_format(order_date,'%Y-%m') as 'Month', sum(total_amount) as TotalSales
from orders group by Month order by Month asc)
select Month,TotalSales,
round((((TotalSales - lag(TotalSales) over (order by Month)) / lag(TotalSales) over (order by Month) )* 100),2) as PercentChange
 from cte; --- During feb month of 2024 the sales experience the largest decline.
 
 --- How is our average order value shifting month-over-month, and what does that tell us about our current pricing momentum?
 with monthly_sales as(
    select date_format(order_date, '%Y-%m') as Month,
    round(avg(total_amount),2) as AvgOrderValue
    from orders
    group by date_format(order_date, '%Y-%m') 
)

    select Month, AvgOrderValue,
    Round(AvgOrderValue - lag(AvgOrderValue) over(order by Month) ,2) as ChangeInValue
    from monthly_sales
order by ChangeInValue DESC; --- december month has the highest change in the average order value

--- When do we hit our absolute busiest shopping seasons, and how can we use that data to prepare our inventory and staffing ?
select date_format(order_date,'%Y-%m') as Month,sum(total_amount) as TotalSales
from orders group by Month order by  TotalSales  desc  ;


--- INVENTORY MANAGEMENT

--- Based on sales data, identifing products with the fastest turnover rates, suggesting high demand and the need for frequent restocking.
select product_id,count(product_id) as SalesFrequency
from Orderdetails group by product_id
order by SalesFrequency desc limit 5; --- Digital SLR Camera, Laptop, Bluetooth Headphones, E-Book Reader have the frequently bought by customers.

--- Which items in our inventory are at risk of becoming dead stock due to a lack of customer interest?
with cte as 
(select p.Product_id as Product_id,
p.name as Name,
(select count(customer_id) from customers ) as totalcustomerCount ,
count(distinct(o.customer_id)) as UniqueCustomerCount
from Orderdetails as od join Orders as o on od.Order_id=o.Order_id
join Products as p on p.product_id=od.product_id
join customers as c on c.customer_id=o.customer_id
group by Product_id,name)
select Product_id,Name,UniqueCustomerCount from cte 
where (UniqueCustomerCount/totalcustomerCount)<.4; --- This might be because of poor visibility on platform. so targeted campaign on marketing shall be done to increase the sales.

--- How successful are our marketing and market expansion campaigns at bringing in entirely new customers month-over-month ?
with cte as
(select distinct(customer_id) as customer,min(date_format(Order_date,'%Y-%m')) as Month from 
orders group by customer_id order by Month asc)
select Month as FirstPurchaseMonth ,count(customer) as TotalNewCustomers 
from cte group by FirstPurchaseMonth;--- as the customer count decreases, this shows the marketing campaign not working as planned.


--- STRATEGIC INSIGHTS.

--- Which products drive 'repeat' purchases?
--- select distinct(product_id) as Product_ID , count(distinct order_id) as Count_of_product from orderdetails group by  Product_ID;

WITH repeat_customers AS (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
)

SELECT
    od.product_id,
    COUNT(DISTINCT o.customer_id) AS repeat_customer_count
FROM orderdetails od
JOIN orders o
    ON od.order_id = o.order_id
JOIN repeat_customers rc
    ON o.customer_id = rc.customer_id
GROUP BY od.product_id
ORDER BY repeat_customer_count DESC;

