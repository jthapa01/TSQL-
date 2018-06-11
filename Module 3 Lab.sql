--What is the order number and the date of each order sold 
--by each employee?
Go
USE Northwind;
Select * From Orders
Select * From Employees

SELECT o.OrderID
	 , e.EmployeeID
	 , o.OrderDate
	 , e.FirstName
	 , e.LastName
FROM Orders o 
JOIN Employees e
ON o.EmployeeID = e.EmployeeID

--List each territory by region.
SELECT * FROM Territories;
SELECT * FROM Region

SELECT t.TerritoryID, t.TerritoryDescription,r.RegionID,
r.RegionDescription FROM Territories t
JOIN Region r
ON t.RegionID = r.RegionID

--What is the supplier name for each product alphabetically 
--by supplier?
SELECT * FROM Suppliers
SELECT * FROM Products
SELECT p.ProductID, p.ProductName, s.SupplierID, s.CompanyName
FROM Products p JOIN Suppliers s
ON p.SupplierID = s.SupplierID
ORDER BY s.CompanyName

--For every order on May 5, 1998, how many of each item was ordered, 
--and what was the price of the item?
SELECT * FROM [Order Details]
SELECT * FROM Orders

SELECT o.OrderId 
	  ,o.OrderDate 
	  ,od.Quantity
	  ,od.UnitPrice
	  --,SUM(od.Quantity) AS TotalOrder
	  --,SUM(od.UnitPrice) AS TotalPrice 
FROM Orders o
JOIN [Order Details] od
ON o.OrderID = od.OrderID
WHERE o.OrderDate = '1998-05-05'
--GROUP BY o.OrderId 
		--,o.OrderDate 

--For every order on May 5, 1998, how many of each item was ordered 
--giving the name of the item, and what was the price of the item?
SELECT * FROM Products
SELECT o.OrderId 
	  ,o.OrderDate 
	  ,od.Quantity
	  ,od.UnitPrice
	  ,p.ProductID
	  ,p.ProductName
	  --,SUM(od.Quantity) AS TotalOrder
	  --,SUM(od.UnitPrice) AS TotalPrice 
FROM [Order Details]od
JOIN Orders o
ON o.OrderID = od.OrderID
JOIN Products p
ON od.ProductID = p.ProductID
WHERE o.OrderDate = '1998-05-05'
--GROUP BY o.OrderId 
		--,o.OrderDate 

--For every order in May, 1998, what was the customer's name 
--and the shipper's name?
SELECT * FROM Customers
SELECT * FROM Orders
SELECT * FROM Shippers

SELECT o.OrderID, o.OrderDate, c.CustomerID, c.CompanyName, s.CompanyName
FROM Orders o
JOIN Customers c
ON o.CustomerID = c.CustomerID
JOIN Shippers s
ON o.ShipVia = s.ShipperID
WHERE o.OrderDate >= '1998-05-01'
AND o.OrderDate < '1998-06-01'

--WHERE YEAR(o.OrderDate) = 1998
--AND MONTH(o.OrderDate) = 5

--What is the customer's name and the employee's name 
--for every order shipped to France?
SELECT * FROM Customers
SELECT * FROM Employees
SELECT * FROM Orders
SELECT * FROM Shippers

SELECT c.CompanyName
      ,o.ShipCountry
	  ,o.EmployeeID
      ,o.OrderID
	  ,e.FirstName+ ' '+ e.LastName AS [Employee Name]
FROM Customers c
JOIN Orders o
ON c.CustomerID = o.CustomerID
JOIN Employees e
ON o.EmployeeID = e.EmployeeID
WHERE ShipCountry = 'France';

--List the products by name that were shipped to Germany.
SELECT * FROM Products
SELECT * FROM Orders
SELECT * FROM [Order Details]

SELECT distinct p.ProductName
	  ,o.ShipCountry 
FROM Products p
JOIN [Order Details]od
ON p.ProductID = od.ProductID
JOIN Orders o
ON o.OrderID = od.OrderID
WHERE o.ShipCountry = 'Germany';

GO
USE TSQLV4

--Explain what’s wrong in the following query, and provide a 
--correct alternative: -> two different Aliases were added
SELECT Customers.custid 
,Customers.companyname 
,Orders.orderid
,Orders.orderdate
FROM Sales.Customers --AS C
INNER JOIN Sales.Orders --AS O
ON Customers.custid = Orders.custid;

--Return US customers, and for each customer return the total 
--number of orders and total quantities:
--select * from sales.Orders
--select * from sales.OrderDetails
--select * from sales.Customers


SELECT c.custid, 
	   count(od.orderID) AS numorders
	   ,SUM(od.qty) 
FROM Sales.Customers c
INNER JOIN sales.Orders o
ON c.custid = o.custid
INNER JOIN sales.OrderDetails od
ON o.orderid = od.orderid
WHERE c.country = 'USA'
GROUP BY c.custid

--Return customers and their orders, including customers who 
--placed no orders:

--select * from sales.OrderDetails
--select * from sales.Customers

SELECT c.custid, c.companyname, o.orderid, o.orderdate
FROM Sales.Customers c LEFT JOIN sales.Orders o
ON o.custid = c.custid

--Return customers who placed no orders:
--select * from sales.Customers
--select * from sales.Orders

SELECT c.custid , c.companyname
FROM sales.Customers c
WHERE NOT EXISTS (SELECT o.custid FROM sales.Orders o
				  WHERE c.custid = o.custid )

--Return customers with orders placed on February 12, 2016, 
--along with their orders:
--SELECT c.custid , c.companyname, o.orderid, o.orderdate
--FROM sales.Customers c
--INNER JOIN sales.Orders o
--ON c.custid = o.custid
--WHERE o.orderdate = '2016-02-12';--Do not work as expected 
--use on clause instead of where

--Write a query that returns all customers in the output, 
--but matches them with their respective orders only if they 
--were placed on February 12, 2016:

SELECT c.custid, c.companyname, o.orderid, o.orderdate
FROM Sales.Customers c
LEFT OUTER JOIN   Sales.Orders o
ON o.custid = c.custid
AND  o.orderdate = '20160212';

--AND Clause and WHERE clause are different in OUTER JOIN 
--whereas they are same for inner join.
--WHERE clause in outer join will return the all rows from
--outer table and apply the condition on WHERE clause

--Second, the predicate based on the order date is a nonfinal 
--matching predicate; as such it must appear in the ON clause 
--and not the WHERE clause. Remember that the WHERE clause is 
--a final filter that is applied after outer rows are added.
SELECT c.custid, c.companyname, o.orderid, o.orderdate
FROM Sales.Customers c
LEFT OUTER JOIN   Sales.Orders o
ON o.custid = c.custid
WHERE  o.orderdate = '20160212';

--Explain why the following query isn’t a correct solution 
--query for Exercise 7:

--Below query will pull out the customers who did not place
--an order at all but who has the orderdate other than 20160212
--and NULL
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
LEFT OUTER JOIN Sales.Orders AS O
ON O.custid = C.custid
WHERE O.orderdate = '20160212'
OR O.orderid IS NULL;

--Return all customers, and for each return a Yes/No value 
--depending on whether the customer placed orders on 
--February 12, 2016:
--Use this form of switch for null value
--here each boolean_expression is evaluated sequentially 
--and the first to return true is executed. 
SELECT c.custid
	  ,o.custid 
	  ,c.companyname
	  ,o.orderid 
	  ,o.orderdate,
CASE  WHEN o.orderid is NULL THEN 'No' 
			   ELSE 'Yes' 
END AS isOrdered
FROM sales.Customers c 
LEFT OUTER JOIN sales.orders o 
ON c.custid = o.custid
AND o.orderdate = '20160212'; 

--Write a query that generates five copies of each 
--employee row:
--select * from dbo.nums
SELECT e.empid
      ,e.firstname
      ,e.lastname
	  ,n.n
FROM dbo.nums n 
CROSS JOIN HR.Employees e
WHERE n<=5
ORDER BY n

--Write a query that returns a row for each employee and day 
--in the range June 12, 2016 through June 16, 2016:
--select * from dbo.nums
--select * from HR.Employees
--Only use this when value is not null
SELECT e.empid
	  ,CASE n.n WHEN 1 THEN '20160612'
				WHEN 2 THEN '20160613'
				WHEN 3 THEN '20160614'
				WHEN 4 THEN '20160615'
				WHEN 5 THEN '20160616'
       END AS dayInRange
FROM dbo.nums n 
CROSS JOIN HR.Employees e
WHERE n<=5
order by empid




use tsqlv4

