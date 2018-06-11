
--Exercise 2
/*Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10
without using a looping construct. You do not need to guarantee any order of the rows in the
output of your solution:*/

SELECT 1 AS n 
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
UNION ALL SELECT 9
UNION ALL SELECT 10 

--Exercise 3
/*Write a query that returns customer and employee pairs that had order activity in January
2016 but not in February 2016:
Table involved: Sales.Orders table*/
USE TSQLV4
SELECT * FROM Sales.Orders

SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160101'
AND orderdate <'20160201'
EXCEPT
SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160201'
AND orderdate <'20160301'

--Exercise 4
/*Write a query that returns customer and employee pairs that had order activity in both January
2016 and February 2016:
Table involved: Sales.Orders*/
SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160101'
AND orderdate <'20160201'
INTERSECT
SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160201'
AND orderdate <'20160301'

--Exercise 5
/*Write a query that returns customer and employee pairs that had order activity in both January
2016 and February 2016 but not in 2015:
Table involved: Sales.Orders*/

SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160101'
AND orderdate <'20160201'
INTERSECT
SELECT custid, empid FROM Sales.Orders
WHERE orderdate >='20160201'
AND orderdate <'20160301'
EXCEPT
SELECT custid, empid FROM Sales.Orders
WHERE YEAR(orderdate) = 2015

/*Exercise 6 (optional, advanced)
You are given the following query:
SELECT country, region, city
FROM HR.Employees
UNION ALL
SELECT country, region, city
FROM Production.Suppliers;
You are asked to add logic to the query so that it guarantees that the rows from Employees
are returned in the output before the rows from Suppliers. Also, within each segment, the
rows should be sorted by country, region, and city:
Tables involved: HR.Employees and Production.Suppliers*/

SELECT country, region, city
FROM HR.Employees
UNION ALL
SELECT country, region, city
FROM Production.Suppliers;

SELECT * FROM HR.Employees
SELECT  * FROM Production.Suppliers;

SELECT country, region, city
FROM (SELECT 1 AS sortcol, country, region, city
FROM HR.Employees
UNION ALL
SELECT 2, country, region, city
FROM Production.Suppliers) AS D
ORDER BY sortcol, country, region, city;

------USING THE NORTHWIND DATABASE
--1. Create a list of every country where we have either a customer or a supplier.
USE Northwind
SELECT * from dbo.Customers;
SELECT * from dbo.suppliers
SELECT country FROM customers
UNION
SELECT country FROM Suppliers

--2. Create a list of every city and country where we have either a customer or a supplier.
SELECT country,city FROM customers
UNION
SELECT country,city FROM Suppliers

--3. Create a list of every country where we have both a customer and a supplier.
SELECT country FROM customers
INTERSECT
SELECT country FROM Suppliers

--4. Create a list of every city and country where we have both a customer and a supplier.
SELECT country,city FROM customers
INTERSECT
SELECT country,city FROM Suppliers

--5. Ceate a list of every country where we have customers but not suppliers.
SELECT country FROM customers
EXCEPT
SELECT country FROM Suppliers

--6. Ceate a list of every country where we have suppliers but not customers.
SELECT country FROM Suppliers
EXCEPT
SELECT country FROM customers
