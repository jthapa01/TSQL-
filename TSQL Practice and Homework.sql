
USE TSQLV4;
GO
--Exercise 2B Single Table Queries
--Exercise 1
SELECT orderid, orderdate, custid, empid FROM Sales.Orders
WHERE orderdate >= '2015-06-01'
AND orderdate < '2015-07-01';

--Exercise 2
--Exercise 2B Single Table Queries
SELECT orderid, orderdate, custid, empid FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

SELECT orderid, orderdate, custid, empid,DATEDIFF
					(month, '19991231', orderdate), DATEADD(month, DATEDIFF
					(month, '19991231', orderdate), '19991231')
FROM Sales.Orders
WHERE orderdate = DATEADD(month, DATEDIFF
					(month, '19991231', orderdate), '19991231');

--Exercise 3
--Employee last name containing e twice or more
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE len(lastname)-len(replace(lastname,'e','')) > 1; 

--Exercise 4
--against Sales.OrderDetails table that returns orders 
--with a total value (quantity * unitprice) greater than 
--10,000, sorted by total value

select orderid, sum(qty * unitprice) AS Totalvalue from Sales.OrderDetails
group by orderid
having sum(qty * unitprice)> 10000
order by Totalvalue desc;

select * from HR.Employees
--where lastname COLLATE Latin1_General_CS_AS LIKE N'[a-z]%';
where lastname COLLATE Latin1_General_CS_AS 
LIKE N'[abcdefghijklmnopqrstuvwxyz]%';

--check collation
SELECT
	description
	,COLLATIONPROPERTY(name, 'CodePage') AS CodePage
	,COLLATIONPROPERTY(name, 'LCID') AS LCID
FROM fn_helpcollations()
WHERE name = N'Latin1_General_CS_AS';


--it returns the order after 20160501 and count them
SELECT empid, count(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20160501'
GROUP BY empid;

--this one groups the order by empid then count the order
--which was after 20160501 as a group, if an employee order
--before and after the 20160501 then this employee will fall out
SELECT empid, count(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';

--that returns the three shipped-to countries with the
--highest average freight in 2015:
SELECT TOP(3) shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE YEAR(orderdate) = 2015
GROUP BY shipcountry
ORDER BY avgfreight DESC;

SELECT TOP(3) shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20150101'
AND orderdate < '20160101'  
GROUP BY shipcountry
ORDER BY avgfreight DESC;

SELECT shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20150101'
AND orderdate < '20160101'  
GROUP BY shipcountry
ORDER BY avgfreight DESC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;

--that calculates row numbers for orders based on
--order date ordering (using the order ID as the tiebreaker) 
--for each customer separately:

SELECT Custid, orderdate, orderid, 
ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) 
AS rownum FROM Sales.Orders

/*that returns for each employee the
gender based on the title of courtesy. For ‘Ms.’ and 
‘Mrs.’ return ‘Female’; for ‘Mr.’ return ‘Male’; and in all
 other cases (for example, ‘Dr.‘) return ‘Unknown’:
*/
SELECT empid, firstname, lastname, 
  CASE titleofcourtesy
	WHEN 'Ms.'  THEN 'Female'
	WHEN 'Mrs.' THEN 'Female'
	WHEN 'Mr.'  THEN 'Male'
	ELSE			 'Unknown'
  END AS gender
FROM HR.Employees

/*Write a query against the Sales.Customers table that returns for
 each customer the customer ID and region. Sort the rows in the 
 output by region, having NULLs sort last (after non-NULL values). 
 Note that the default sort behavior for NULLs in T-SQL is to 
 sort first (before non-NULL values):
 */

 SELECT custid, region ,CASE WHEN region is NULL THEN 1 ELSE 0 END
 FROM Sales.Customers
 ORDER BY
   CASE WHEN region is NULL THEN 1 ELSE 0 END, region







SELECT empid, FirstName, lastname
FROM HR.Employees
WHERE empid NOT IN
(SELECT O.empid
FROM Sales.Orders AS O
WHERE O.orderdate >= '20160501'
);


