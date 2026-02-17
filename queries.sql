/* =========================================================
   Northwind Sales & Revenue Analysis
   Completed by Owen Tran 

   This project explores customer behavior, revenue generation,
   discount impact, and pricing efficiency using SQL.

   The queries below show me using:
   - Filtering and wildcard searches
   - Revenue calculations
   - Conditional logic
   - Joins (INNER and LEFT)
   - Aggregation and grouping
   - Views
   - Business-driven insights
   ========================================================= */


/* ---------------------------------------------------------
   1. Identify customers in key markets
   Business Question:
   Which customers are located in the UK or USA and have 
   “po” in their company name?
   Demonstrates: WHERE, LIKE, logical conditions
---------------------------------------------------------- */

SELECT CompanyName,
       Address,
       Country,
       CustomerID
FROM Customers
WHERE (Country = "UK" OR Country = "USA")
  AND CompanyName LIKE "%po%";


/* ---------------------------------------------------------
   2. Calculate line-level revenue after discounts
   Business Question:
   What is the actual revenue generated per order line 
   after accounting for discounts?
   Demonstrates: Calculated fields, ROUND()
---------------------------------------------------------- */

SELECT OrderID,
       ProductName,
       Discount,
       ROUND(UnitPrice * Quantity * (1 - Discount), 2) AS LineItemRevenue
FROM OrderDetails;


/* ---------------------------------------------------------
   3. Identify high-discount, high-impact sales
   Business Question:
   Which heavily discounted items still generated 
   significant revenue?
   Demonstrates: Complex filtering + calculations
---------------------------------------------------------- */

SELECT OrderID,
       ProductName,
       Discount,
       ROUND(UnitPrice * Quantity * (1 - Discount), 2) AS LineItemRevenue
FROM OrderDetails
WHERE (Discount >= 0.2 
       AND UnitPrice * Quantity * (1 - Discount) > 1000)
ORDER BY LineItemRevenue DESC;


/* ---------------------------------------------------------
   4. Order fulfillment classification
   Business Question:
   Which orders placed in May 1996 were fulfilled 
   and which are still pending?
   Demonstrates: CASE statement + NULL handling
---------------------------------------------------------- */

SELECT CustomerID,
       OrderID,
       OrderDate,
       ShippedDate,
       CASE 
           WHEN ShippedDate IS NULL 
                THEN "Order not yet fulfilled"
           ELSE "Order completed"
       END AS OrderStatus
FROM Orders
WHERE OrderDate BETWEEN '1996-05-01' AND '1996-05-31'
ORDER BY OrderStatus;


/* ---------------------------------------------------------
   5. Revenue per order (Join Example)
   Business Question:
   What is the gross revenue for each order line 
   and which customer placed it?
   Demonstrates: INNER JOIN
---------------------------------------------------------- */

SELECT O.OrderID,
       O.CustomerID,
       D.ProductName,
       D.Quantity * D.UnitPrice AS GrossLineRevenue
FROM Orders O
INNER JOIN OrderDetails D
ON O.OrderID = D.OrderID;


/* ---------------------------------------------------------
   6. Total revenue per order
   Business Question:
   What is the total discounted revenue generated 
   for each order?
   Demonstrates: GROUP BY + Aggregation
---------------------------------------------------------- */

SELECT OrderID,
       ROUND(SUM(UnitPrice * Quantity * (1 - Discount)), 2) 
       AS OrderLineRevenue
FROM OrderDetails
GROUP BY OrderID;


/* ---------------------------------------------------------
   7. Create view for order totals including freight
   Business Question:
   What are the highest-value orders when including 
   both product revenue and freight charges?
   Demonstrates: VIEW + Join + Aggregation
---------------------------------------------------------- */

CREATE VIEW OrderRevenueSummary AS
SELECT OrderID,
       ROUND(SUM(UnitPrice * Quantity * (1 - Discount)), 2)
       AS LineRevenue
FROM OrderDetails
GROUP BY OrderID;

SELECT O.OrderID,
       O.CustomerID,
       O.Freight,
       R.LineRevenue,
       ROUND(O.Freight + R.LineRevenue, 2) AS TotalOrderValue
FROM Orders O
INNER JOIN OrderRevenueSummary R
ON O.OrderID = R.OrderID
ORDER BY TotalOrderValue DESC
LIMIT 8;


/* ---------------------------------------------------------
   8. Pricing efficiency analysis
   Business Question:
   How much lower are realized sale prices compared 
   to listed product prices?
   Demonstrates: View + Join + Percent calculation
---------------------------------------------------------- */

CREATE VIEW AvgPriceReceived AS
SELECT D.ProductID,
       AVG(D.UnitPrice * (1 - D.Discount)) AS AvgSalePrice
FROM Orders O
INNER JOIN OrderDetails D
ON O.OrderID = D.OrderID
WHERE O.OrderDate >= '1996-01-01'
GROUP BY D.ProductID;

SELECT P.ProductID,
       ROUND(P.PricePerUnit - A.AvgSalePrice, 2) 
       AS PriceDifference,
       ROUND(100 * (P.PricePerUnit - A.AvgSalePrice) 
             / A.AvgSalePrice, 2) AS PercentDifference
FROM Products P
INNER JOIN AvgPriceReceived A
ON P.ProductID = A.ProductID
ORDER BY PercentDifference DESC
LIMIT 25;


/* ---------------------------------------------------------
   9. Data quality check using LEFT JOIN
   Business Question:
   Which orders were shipped to addresses that 
   do not exist in the customer records?
   Demonstrates: LEFT JOIN + Data validation
---------------------------------------------------------- */

SELECT O.OrderID,
       O.CustomerID,
       O.OrderDate,
       O.ShipName,
       O.ShipAddress
FROM Orders O
LEFT JOIN Customers C
ON O.ShipAddress = C.Address
WHERE C.CustomerID IS NULL;
