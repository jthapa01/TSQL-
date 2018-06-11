

--LAB 4 
--Create a report that shows the product name and supplier id for all products 
--supplied by Exotic Liquids, Grandma Kelly's Homestead, and Tokyo Traders.

USE Northwind

SELECT distinct p.productname,s.supplierID, s.CompanyName  from dbo.Products p
RIGHT OUTER JOiN dbo.Suppliers s
ON p.supplierID = s.SupplierID
where s.companyName 
IN ('Exotic Liquids', 'Grandma Kelly''s Homestead','Tokyo Traders')
And s.supplierID IS not Null
--OR
SELECT ProductName , SupplierID
FROM Products
WHERE SupplierID IN (SELECT SupplierID
FROM Suppliers
WHERE CompanyName IN
( 'Exotic Liquids' , 'Grandma Kelly''s Homestead' , 'Tokyo Traders') ) ;

--2. Create a report that shows all products by name that are in the 
--Seafood category.

SELECT p.ProductID, p.productName FROM dbo.Products p
WHERE p.CategoryID = (SELECT c.categoryID FROM Categories c
				      WHERE CategoryName Like 'Sea%') 

--Create a report that shows all companies by name that sell products in 
--CategoryID 8.

SELECT s.companyName from suppliers s
WHERE s.SupplierID IN (SELECT p.supplierid from Products p
					   WHERE p.CategoryID = (SELECT c.categoryID FROM categories c 
											 WHERE c.CategoryID = p.CategoryID
											 AND c.CategoryID = 8 ))
--OR

 SELECT CompanyName
 FROM Suppliers
 WHERE SupplierID IN (SELECT SupplierID
 FROM Products
 WHERE CategoryID = 8) ;
--select CHARINDEX(' ', 'Barack Hussein Obama',8)

--4. Create a report that shows all companies by name that sell products in the 
--Seafood category.

SELECT * FROM dbo.Products
SELECT * FROM dbo.Categories
SELECT * FROM dbo.Suppliers

SELECT s.companyName from suppliers s
WHERE s.SupplierID IN (SELECT p.supplierid from Products p
					   WHERE p.CategoryID = (SELECT c.categoryID FROM categories c 
											 WHERE c.CategoryID = p.CategoryID
											 AND c.CategoryName = 'Seafood'))

--5. Create a report that lists the ten most expensive products.

SELECT * FROM dbo.Products
order by UnitPrice desc

SELECT productName
      ,unitprice
	  ,[Row Number] 
FROM  (select productName
			 ,unitPrice
			 ,(ROW_NUMBER() OVER (ORDER BY UnitPrice desc))
								AS [Row Number] 
								FROM products) AS newTable  
WHERE [Row Number] < 11

--6. Create a report that shows the date of the last order by all employees.
SELECT employeeid, max(orderdate)AS lastOrder 
FROM dbo.Orders
group by employeeid
order by employeeid

--OR
SELECT * FROM dbo.Categories
SELECT * FROM dbo.Suppliers

SELECT DISTINCT o.orderDate, o.employeeId FROM orders o
WHERE o.orderDate = (SELECT max(orderdate) FROM orders 
						WHERE o.employeeid = employeeid
						)
ORDER BY o.employeeid

--Use the book's database, TSQLV4, and do the exercises 1 through 10, 
--beginning on page 175. The solutions

--1)Write a query that returns all orders placed on the last day of 
--activity that can be found in the Orders table:
use TSQLV4

SELECT orderid, orderdate, custid, empid 
FROM Sales.orders
WHERE orderdate = (SELECT MAX(o.orderdate) 
				   FROM Sales.orders o
				   WHERE orderdate = o.orderdate)

--2)Write a query that returns all orders placed by the 
--customer(s) who placed the highest number of orders. 
--Note that more than one customer might have 
--the same number of orders:

SELECT o.custid
	,o.orderid
	,o.orderdate
	,o.empid 
FROM sales.orders o
WHERE o.custid IN (SELECT TOP (1) WITH TIES custid FROM sales.orders
				  GROUP BY custid
                  ORDER BY COUNT(custid) DESC)

--3 Write a query that returns employees who did not place orders on or after May 1, 2016:

select * from sales.orders
select * from HR.employees

SELECT e.empid, e.firstname, e.lastname FROM HR.Employees e
WHERE e.empid IN (SELECT DISTINCT empid FROM sales.orders
						 WHERE orderdate > ='20160501'
						 AND e.empid = empid)

--OR 
--exists will return true or false, if condition is true return the selected row
SELECT e.empid, e.firstname, e.lastname FROM HR.Employees e
WHERE  EXISTS (SELECT DISTINCT empid FROM sales.orders
						 WHERE orderdate > ='20160501'
						 AND e.empid = empid)


--4 Write a query that returns countries where there are customers but not employees:
select * from HR.Employees
select * from sales.customers

SELECT DISTINCT c.country 
FROM sales.customers c
WHERE NOT EXISTS (SELECT country FROM HR.Employees
				  WHERE c.country = country)

--5 Write a query that returns for each customer all orders placed on the 
--customer’s last day of activity:

SELECT  a.custid 
		,a.orderid 
		,a.orderdate 
		,a.empid 
FROM sales.orders a
where a.orderdate IN (SELECT MAX(o.orderdate) FROM sales.orders o
				   WHERE o.custid = a.custid)
ORDER BY  a.custid

--Write a query that returns customers who ordered product 12:
select * from sales.orders
select * from sales.Customers
select * from Sales.orderDetails

SELECT c.custid, c.companyName 
FROM sales.customers c
WHERE c.custid IN (SELECT o.custid FROM sales.Orders o
				  WHERE c.custid = o.custid
                    AND o.orderid IN (SELECT od.orderid  
										FROM sales.orderdetails od
										WHERE o.orderid = od.orderid 
											AND od.productid = 12))

--8 Write a query that calculates a running-total quantity for each customer and month:
SELECT * FROM sales.custorders
where custid = 1

SELECT custid, ordermonth, qty 
, SUM(qty) OVER ( PARTITION BY custid ORDER BY ordermonth) AS RowNum
FROM sales.custOrders
ORDER BY 1,2,3


--using subquery
SELECT custid, ordermonth, qty,
(SELECT SUM(o2.qty)
FROM Sales.CustOrders AS o2
WHERE o2.custid = O1.custid
AND o2.ordermonth <= O1.ordermonth) AS runqty
FROM Sales.CustOrders AS O1
ORDER BY custid, ordermonth;


--9 Explain the difference between IN and EXISTS.
--In operaor scan all the values inside the IN block where as EXIST quit 
--after 1st occurrence. 

--10 Write a query that returns for each order the number of days that passed 
--since the same customer’s previous order. To determine recency among orders, 
--use orderdate as the primary sort element and orderid as the tiebreaker:

SELECT o1.custid, o1.orderdate, o1.orderid
,DATEDIFF(DAY,
			(SELECT TOP (1) O2.orderdate
			 FROM sales.orders AS o2
			 WHERE o2.custid = o1.custid
				AND (o2.orderdate = o1.orderdate 
				AND o2.orderid < o1.orderid
					OR o2.orderdate < o1.orderdate)
			 ORDER BY o2.orderdate DESC
			         ,o2.orderid DESC)
		   ,o1.orderdate) As diff
FROM sales.orders AS o1
ORDER BY custid, orderdate, orderid

--Handles previous date
SELECT custid, orderdate, orderid,
		(SELECT TOP (1) O2.orderdate
		FROM Sales.Orders AS O2
		WHERE O2.custid = O1.custid
			AND ( O2.orderdate = O1.orderdate 
				AND O2.orderid < O1.orderid
					OR O2.orderdate < O1.orderdate )
		ORDER BY O2.orderdate DESC, O2.orderid DESC) AS prevdate
FROM Sales.Orders AS O1
ORDER BY custid, orderdate, orderid;

--Module 4 Lab 4F

use Northwind

--1. List the number of orders by each customer who lives in the United States 
--using a CTE. Sort from highest to lowest.

select * from customers
select * from orders
select * from [Order Details]
-- Define the CTE expression name and column list.
WITH Order_By_USCustomer(CustomerID,Quantity)
AS
--Define the CTE Query
(
	select distinct o.customerID,count(od.quantity)
	FROM orders o 
	JOIN [Order Details] od 
	on o.OrderID = od.orderID
	JOIN Customers c
	ON c.customerID = o.customerID
	WHERE c.country = 'USA'
	group by o.CustomerID


)

select * from Order_By_USCustomer
order by quantity desc

--2. List the product name and the number of each product from a German supplier 
--sold to a customer in Germany using a CTE. Sort from highest to lowest.
select * from products
select * from suppliers
select * from Orders 
select * from [Order Details]



with GERprod (supplierid, country, pid, productname)
AS 
(       select s.supplierid , s.country  , p.productid as pid ,
		p.productname 
		from suppliers s 
		join products p 
		on s.supplierid = p.supplierid
		where s.country like 'Germany'
) 
,
GERord  (pid, quantity, orderid,shipCountry)
AS
(		select d.productid as pid , d.quantity , o.orderid , o.shipcountry
		from orders o 
		join [order details] d 
		on o.orderid = d.orderid
		where o.shipcountry like 'Germany'
)


 SELECT DISTINCT gp.productname , sum(ge.quantity) as TotalSold 
 FROM GERprod gp 
 JOIN GERord ge
 ON gp.pid = ge.pid 
 GROUP BY gp.productname 
 ORDER BY TotalSold desc ;

 --Prepare an employee report showing the name of each employee, 
 --the number of employees they supervise, and the name of their supervisor 
 --using a CTE. Sort by the number of employees supervised.
 WITH Employee_Report_CTE(EmpId, LName, FName, NumOfSubOrdinate ,ReportsTo)
 AS
 (
 SELECT
 EmployeeID , LastName , FirstName , (SELECT COUNT( 1 ) 
											FROM Employees e2
											WHERE e2 . ReportsTo = e . EmployeeID) 
													as NumberOfSubordinates 
									, ReportsTo
 FROM Employees e 
 )

 SELECT erc.EmpId
 , erc.LName
 , erc.FName
 , erc.ReportsTo
 , erc.NumOfSubOrdinate 
 ,manager.LName AS [Manager Last Name]
 ,manager.FName AS [Manager First Name] 
 FROM Employee_Report_CTE erc
 LEFT JOIN Employee_Report_CTE manager 
 ON erc.ReportsTo = manager.EmpId 
 ORDER BY erc.NumOfSubOrdinate desc

 --4
 --(a) Create a query that returns every distinct customer/employee pair.
  select distinct o.CustomerID, o.employeeid from Orders o

--(b) Use that query to write another query turning the customerid, customername, 
--and customercontact, and the employeeid, firstname, and lastname.

  select * from employees
    select * from customers
	select * from orders

  select c.customerID, c.CompanyName, c.ContactName, e.employeeID, e.FirstName
  ,e.LastName from customers c
  join orders o
  on c.CustomerID = o.CustomerID
  join employees e
  ON e.EmployeeID = o.EmployeeID

  --(c) Make sure you drop any view that might exist.
  drop view if exists Cust_Emp_Pairs

  --(d) Create a view based on your query.
--CTE creation
  with CustEmpPairs(customerID, CompanyName, ContactName, EmployeeID, FirstName, LastName)
  AS
  (
		  select c.customerID, c.CompanyName, c.ContactName, e.employeeID, e.FirstName
		  ,e.LastName from customers c
		  join orders o
		  on c.CustomerID = o.CustomerID
		  join employees e
		  ON e.EmployeeID = o.EmployeeID
  
  )
  select * from CustEmpPairs

  --Use CTE to create Views

  CREATE VIEW Cust_Emp_Pairs
  AS
	  with CustEmpPairs(customerID, CompanyName, 
			ContactName, EmployeeID, FirstName, LastName)
	  AS
	  (
			  select c.customerID, c.CompanyName, c.ContactName, e.employeeID, e.FirstName
			  ,e.LastName from customers c
			  join orders o
			  on c.CustomerID = o.CustomerID
			  join employees e
			  ON e.EmployeeID = o.EmployeeID
	  

	  )
	  			select customerID, CompanyName, ContactName, employeeID, FirstName
			  ,LastName from CustEmpPairs 

--(e) Write a report listing all customers served by employee 7, Robert King.
select * from Cust_Emp_Pairs
where EmployeeID = 7

--f) Write a report listing all employees who served customer CHOPS, Chop-suey Chinese.

select * from Cust_Emp_Pairs
where customerID like 'chops'

--8) Drop the view.
Drop VIEW  if exists Cust_Emp_Pairs;

---------------------------Exercise----------------------
--Page 208-TSQL Fundamentals 3rd Edition
----------------------------------------------------------
--1) The following query attempts to filter orders that were not placed on the 
--last day of the year.It’s supposed to return the order ID, order date, customer ID, 
--employee ID, and respective end-of-year date for each order:

--When you try to run this query, you get the following error:
/* Msg 207, Level 16, State 1, Line 233
Invalid column name 'endofyear'.*/
--Explain what the problem is, and suggest a valid solution.

USE TSQLV4
--Below code didnot understand the alias of a column name 
--given from a DATEFROMPARTS function


SELECT orderid, orderdate, custid, empid,
DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> endofyear;

--DECLARE @endofyear DATETIME;
WITH OrderPlacedEOY
AS
(
	SELECT orderid, orderdate, custid, empid,
	DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
	FROM Sales.Orders
)
SELECT orderid, orderdate, custid, empid, endofyear
from OrderPlacedEOY
where orderdate <> endofyear;

--2-1) Write a query that returns the maximum value in the orderdate column for each employee:
select * from sales.orders

select empid, orderdate from sales.Orders

WITH LatestOrders
AS
(
	Select empid, max(orderdate) AS LatestOrderDt
	from sales.Orders
	GROUP BY empid
)
select * FROM LatestOrders
ORDER BY LatestOrderDt desc

--2-2) Encapsulate the query from Exercise 2-1 in a derived table. Write a join query between 
--the derived table and the Orders table to return the orders with the maximum order date 
--for each employee:

select * from sales.Orders

SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
	INNER JOIN (SELECT empid, MAX(orderdate) AS maxorderdate
	FROM Sales.Orders
	GROUP BY empid) AS D
ON O.empid = D.empid
AND O.orderdate = D.maxorderdate;

--3-1) Write a query that calculates a row number for each order based on orderdate, 
--orderid ordering:

SELECT orderid, 
	orderdate, 
	custid, 
	empid, 
	ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders

--3-2 Write a query that returns rows with row numbers 11 through 20 based on the row-number
--definition in Exercise 3-1. Use a CTE to encapsulate the code from Exercise 3-1:

WITH RowNumOffset
AS
(
	SELECT orderid, 
		orderdate, 
		custid, 
		empid, 
		ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
	FROM Sales.Orders

)
select * FROM RowNUmOffSet
WHERE rownum BETWEEN 11 AND 20

--Write a solution using a recursive CTE that returns the management chain 
--leading to Patricia Doyle (employee ID 9):

select empid, mgrid from HR.Employees
WITH Manager_CTE
AS
(
	SELECT empid,mgrid ,firstname, lastname FROM HR.Employees
	WHERE empid = 9
	UNION ALL
	SELECT e.empid, e.mgrid, e.firstname, e.lastname 
	FROM HR.Employees e
	INNER JOIN Manager_CTE AS C
	ON e.empid = C.mgrid
)
SELECT empid, mgrid, firstname, lastname 
FROM Manager_CTE

--5-1) Create a view that returns the total quantity for each employee and year:

SELECT * FROM Sales.Orders
SELECT * FROM Sales.OrderDetails

GO
DROP VIEW IF EXISTS EmpOrders_VW;
GO

CREATE VIEW EmpOrders_VW
AS
	select o.empid, YEAR(o.Orderdate) AS OrderYear, SUM(od.qty) AS totalQty
	FROM Sales.Orders o
	INNER JOIN Sales.OrderDetails od
	ON o.orderid = od.orderid 
	GROUP BY empid,YEAR(o.Orderdate) 
Go
SELECT * FROM EmpOrders_VW ORDER BY empid, orderyear;


--Write a query against Sales.VEmpOrders that returns the running total quantity
-- for each employee and year:

SELECT * FROM EmpOrders_VW ORDER BY empid, orderyear

SELECT e.empid, e.orderYear, e.totalQty, SUM(e1.totalQty) AS RunQtyTtl
FROM EmpOrders_VW e
INNER JOIN EmpOrders_VW e1
ON e.empid = e1.empid
AND e.OrderYear >= e1.OrderYear
GROUP BY e.empid, e.orderYear, e.totalQty
ORDER BY e.empid, e.OrderYear

--BY USING DERIVED TABLE
SELECT empid, orderyear, totalQty,
(SELECT SUM(totalQty)
FROM EmpOrders_VW AS V2
WHERE V2.empid = V1.empid
AND V2.orderyear <= V1.orderyear) AS runqty
FROM EmpOrders_VW AS V1
ORDER BY empid, orderyear;

--6-1) Create an inline TVF that accepts as inputs a supplier ID (@supid AS INT) and a requested
--number of products (@n AS INT). The function should return @n products with the highest
--unit prices that are supplied by the specified supplier ID:

select * from production.Products

select p.productid, p.productname, p.unitprice 
FROM Production.Products p

DROP FUNCTION IF EXISTS Highest_Unit_Price_TVF;
GO
CREATE FUNCTION Highest_Unit_Price_TVF(@supid AS INT, @n AS INT)
							RETURNS TABLE 
AS
RETURN
	SELECT p.productid, p.productname,p.unitprice
	FROM Production.Products p
	WHERE p.supplierid = @supid
	ORDER BY p.unitprice DESC
	OFFSET 0 ROWS FETCH NEXT @n ROWS ONLY

	SELECT * from Highest_Unit_Price_TVF(5,2);

--6-2) Using the CROSS APPLY operator and the function you created in Exercise 6-1, 
--return the two most expensive products for each supplier:
SELECT s.supplierid, s.companyname, tvf.productid, tvf.productname, tvf.unitprice
FROM Production.Suppliers s
	CROSS APPLY Highest_Unit_Price_TVF(s.supplierid, 2) AS tvf;

	select * from production.Suppliers


--Exercise 4C: USing Set Operators ------------------------
--2) Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10 without using a looping construct. You do not need to guarantee any order of -- the rows in the output of your solution:

SELECT 1 AS n
UNION ALL
SELECT 2
UNION ALL
SELECT 3
UNION ALL
SELECT 4
UNION ALL
SELECT 5
UNION ALL
SELECT 6
UNION ALL
SELECT 7
UNION ALL
SELECT 8
UNION ALL
SELECT 9
UNION ALL
SELECT 10

SELECT n
FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS Nums(n);

--3. Write a query that returns customer and employee pairs that had order activity in January 2016 but not in February 2016:

select * from Sales.Orders

---REMEMBER NOT TO USE ORDER BY IN SET OPERATOR 
select c.custid, c.empid from sales.orders c
where orderdate >= '20160101' 
AND orderdate <'20160201'
EXCEPT
select c.custid, c.empid from sales.orders c
where orderdate >= '20160201' 
AND orderdate <'20160301'


