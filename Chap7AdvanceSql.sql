

USE TSQLV4;
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
orderdate DATE NOT NULL,
empid INT NOT NULL,
custid VARCHAR(5) NOT NULL,
qty INT NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
(30001, '20140802', 3, 'A', 10),
(10001, '20141224', 2, 'A', 12),
(10005, '20141224', 1, 'B', 20),
(40001, '20150109', 2, 'A', 40),
(10006, '20150118', 1, 'C', 14),
(20001, '20150212', 2, 'B', 12),
(40005, '20160212', 3, 'A', 10),
(20002, '20160216', 1, 'C', 20),
(30003, '20160418', 2, 'B', 15),
(30004, '20140418', 3, 'C', 22),
(30007, '20160907', 3, 'D', 30);
SELECT * FROM dbo.Orders;

--Window Function
--There are up to three parts in the definition of a window function, which you specify in -- a clause called OVER: the window-partition clause, window-order clause, and window---frame clause
--the frame is defined with no low boundary point (UNBOUNDED
--PRECEDING) and extends until the current row (CURRENT ROW).clause.

USE TSQLV4;
--For example, to capture all
--rows from two rows before the current row until one row --ahead, you use ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING. Also, if you do not want an upper bound, you can use UNBOUNDED FOLLOWING.
--Running Sum
SELECT empid, ordermonth, val,
SUM(val) OVER(PARTITION BY empid
ORDER BY ordermonth
ROWS BETWEEN UNBOUNDED PRECEDING
AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

SELECT orderid, custid, val,
ROW_NUMBER() OVER(ORDER BY val) AS rownum,
RANK() OVER(ORDER BY val) AS rank,
DENSE_RANK() OVER(ORDER BY val)	AS dense_rank,
NTILE(100) OVER(ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;


--LAG(before) and LEAD(after)
SELECT custid, orderid, val,
LAG(val) OVER(PARTITION BY custid
				ORDER BY orderdate, orderid)AS prevVal,
LEAD(val) OVER(PARTITION BY custid
				ORDER BY orderdate, orderid) AS nextVal
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid

--FIRST_VALUE() and LAST_VALUE()
SELECT custid, orderid, val,
FIRST_VALUE(val) OVER(PARTITION BY custid
					ORDER BY orderdate, orderid
					ROWS BETWEEN UNBOUNDED PRECEDING 
						AND CURRENT ROW) AS firstval,
LAST_VALUE(val) OVER(PARTITION BY custid ORDER BY 
					orderdate, orderid
					ROWS BETWEEN CURRENT ROW 
						AND UNBOUNDED FOLLOWING) AS lastVal
FROM Sales.OrderValues;

--AGGREGATE WINDOW FUNCTION
SELECT orderid, custid, val,
	SUM(val) OVER() AS totalvalue,
	SUM(val) OVER(PARTITION BY custid) AS custTotalValue
	FROM Sales.OrderValues

SELECT orderid, custid, val,
100.*val/SUM(val) OVER() AS pctall,
100*val/SUM(val) OVER(PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;

-------------------------CREATE dbo.Orders table
USE TSQLV4;
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
orderdate DATE NOT NULL,
empid INT NOT NULL,
custid VARCHAR(5) NOT NULL,
qty INT NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
INSERT INTO dbo.Orders(orderid, orderdate, empid, custid, qty)
VALUES
(30001, '20140802', 3, 'A', 10),
(10001, '20141224', 2, 'A', 12),
(10005, '20141224', 1, 'B', 20),
(40001, '20150109', 2, 'A', 40),
(10006, '20150118', 1, 'C', 14),
(20001, '20150212', 2, 'B', 12),
(40005, '20160212', 3, 'A', 10),
(20002, '20160216', 1, 'C', 20),
(30003, '20160418', 2, 'B', 15),
(30004, '20140418', 3, 'C', 22),
(30007, '20160907', 3, 'D', 30);
SELECT * FROM dbo.Orders;
--Default else in case expr is NULL
--pivoting involves grouping, spreading(case statement), and aggregating

--1)Pivoting with a grouped query
SELECT * FROM dbo.Orders;
SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty ENd) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid;

--2)Pivoting with the PIVOT operator
SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty 
	  FROM dbo.Orders) AS D
  PIVOT(SUM(qty)FOR custid IN (A,B,C,D)) AS P;

SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
FROM dbo.Orders) AS D
PIVOT(SUM(qty) FOR empid IN([1], [2], [3])) AS P;

--Unpivoting Data
USE TSQLV4;
DROP TABLE IF EXISTS dbo.EmpCustOrders;

CREATE TABLE EmpCustOrders
(
	empid INT NOT NULL
		CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
		A VARCHAR(5) NULL,
		B VARCHAR(5) NULL,
		C VARCHAR(5) NULL,
		D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders(empid, A,B,C,D)
	SELECT empid, A, B, C, D
	FROM (SELECT empid, custid, qty
			FROM dbo.Orders) AS D
		PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;


	
SELECT * FROM dbo.EmpCustOrders;
--Unpivoting involves three logical processing phases: producing copies, extracting values, and eliminating irrelevant rows.
--UNPIVOTING WITH THE APPLY OPERATOR
SELECT * FROM dbo.EmpCustOrders
   CROSS APPLY(VALUES('A'),('B'),('C'), ('D')) AS C(custid);

SELECT empid, custid, qty
	FROM dbo.EmpCustOrders
		CROSS APPLY (VALUES('A', A),('B', B),('C', C),('D', D)) AS C(custid, qty)
	WHERE qty IS NOT NULL

--UNPIVOTING WITH THE UNPIVOT OPERATOR
--Unpivoting data involves producing two result columns from any number of source columns
SELECT *
FROM dbo.EmpCustOrders  

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN(A,B,C,D)) AS U;

DROP TABLE IF EXISTS dbo.EmpCustOrders;

--GROUPING SETS
--A grouping set is a set of expressions you group the data by in a grouped query (a query
--with a GROUP BY clause).
SELECT empid, custid, SUM(qty) AS sumqty
FROm dbo.Orders
GROUP BY empid, custid;

SELECT empid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid;

SELECT custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY custid;

SELECT SUM(qty) AS sumqty
FROM dbo.Orders;

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid
UNION ALL
SELECT empid, NULL, SUM(qty) AS sumqty
FROM dbo.Orders GROUP BY empid
UNION ALL
SELECT NULL, custid, SUM(qty) AS sumqty
FROM dbo.Orders GROUP BY custid
UNION ALL
SELECT NULL, NULL, SUM(qty) AS sumqty
FROM dbo.Orders;

--GROUPING SETS subclause
--The GROUPING SETS subclause is a powerful enhancement to the GROUP BY clause.
SELECT empid, custid, SUM(qty) AS sumQty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
		(empid, custid),
		(empid),
		(custid),
		()
	);

--CUBE Subclause
--The CUBE subclause of the GROUP BY clause provides an abbreviated way to define 
--multiple grouping sets. For example, CUBE(a, b, c) is equivalent to GROUPING SETS
--( (a, b, c), (a,b), (a, c), (b, c), (a), (b), (c), () ).
--Instead of using the GROUPING SETS subclause in the previous query to define the four
--grouping sets (empid, custid), (empid), (custid), and (), you can simply use 
--CUBE(empid,custid). Here’s the complete query:

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

--ROLLUP Subclause
SELECT 
	YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday,
	SUM(qty) AS sumqty
	FROM dbo.Orders
	GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

--The GROUPING and GROUPING_ID functions
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

SELECT 
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

--GROUPING ID
--GROUPING_ID(a, b, c,d)—and the function returns an integer bitmap in which each bit represents a different input element—the rightmost element represented by the rightmost bit. For example, the grouping
--set (a, b, c, d) is represented by the integer 0 (0×8 + 0×4 + 0×2 + 0×1). The grouping set (a, c)
--is represented by the integer 5 (0×8 + 1×4 + 0×2 + 1×1),

SELECT 
	GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders 
GROUP BY CUBE(empid, custid);

--EXERCISE 5A WINDOW FUNCTION
/*In this exercise, you will use the T-SQL Fundamentals book.
First create the dbo.Orders table from Listing 7-1 on page 224.
Complete and submit exercises 1 and 2 on page 245.*/
USE TSQLV4
SELECT * FROM dbo.Orders

/*Exercise 1
Write a query against the dbo.Orders table that computes both a rank and a dense rank for each
customer order, partitioned by custid and ordered by qty:
Table involved: TSQLV4 database, dbo.Orders table*/

SELECT custid, orderid, qty
, RANK() OVER(PARTITION BY custid order by qty) AS ranknum
, DENSE_RANK() OVER(PARTITION BY custid ORDER BY qty) AS denseRanknum
FROM dbo.Orders

--2) Earlier in the chapter in the section “Ranking window functions,” I provided the following
--query against the Sales.OrderValues view to return distinct values and their associated row
--numbers:
SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;
--Can you think of an alternative way to achieve the same task?
--Table involved: TSQLV4 database, Sales.OrderValues view

WITH orderVal
AS
(
	SELECT val FROM Sales.OrderValues

)
SELECT val,ROW_NUMBER() OVER(ORDER BY val) AS rownum FROM orderval

--Exercise 3
--Write a query against the dbo.Orders table that computes for each customer order both the difference between the current order quantity and the customer ’s previous order quantity and the difference between the current order quantity and the customer ’s next order quantity:Table involved: TSQLV4 database, dbo.Orders table
USE TSQLV4

SELECT * FROM dbo.Orders

order by orderdate, orderid

SELECT custid, orderid, qty,
	qty - LAG(qty) OVER(PARTITION BY custid
		ORDER BY orderdate, orderid) AS diffprev,
	qty - LEAD(qty) OVER(PARTITION BY custid
		ORDER BY orderdate, orderid) AS diffnext
FROM dbo.Orders;

--Exercise 4
--Write a query against the dbo.Orders table that returns a row for each employee, a column for each order year, and the count of orders for each employee and order year:
--Table involved: TSQLV4 database, dbo.Orders table

SELECT empid,
	COUNT(CASE WHEN orderyear = 2014 THEN orderyear END) AS cnt2014,
	COUNT(CASE WHEN orderyear = 2015 THEN orderyear END) AS cnt2015,
	COUNT(CASE WHEN orderyear = 2016 THEN orderyear END) AS cnt2016
FROM (SELECT empid, YEAR(orderdate) AS orderyear
	FROM dbo.Orders) AS D
GROUP BY empid;

SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016
FROM (SELECT empid, YEAR(orderdate) AS orderyear
	FROM dbo.Orders) AS D
  PIVOT(COUNT(orderyear)
		FOR orderyear IN([2014], [2015], [2016])) AS P;

--Exercise 5
--Run the following code to create and populate the EmpYearOrders table:
USE TSQLV4;
DROP TABLE IF EXISTS dbo.EmpYearOrders;
CREATE TABLE dbo.EmpYearOrders
(
	empid INT NOT NULL
	CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
	cnt2014 INT NULL,
	cnt2015 INT NULL,
	cnt2016 INT NULL
);
INSERT INTO dbo.EmpYearOrders(empid, cnt2014, cnt2015, cnt2016)
SELECT empid, [2014] AS cnt2014, [2015] AS cnt2015, [2016] AS cnt2016
FROM (SELECT empid, YEAR(orderdate) AS orderyear
		FROM dbo.Orders) AS D
PIVOT(COUNT(orderyear)
FOR orderyear IN([2014], [2015], [2016])) AS P;
SELECT * FROM dbo.EmpYearOrders;

--Write a query against the EmpYearOrders table that unpivots the data, returning a row for each employee and order year with the number of orders. Exclude rows in which the number of orders is 0 (in this example, employee 3 in the year 2015).

SELECT empid, orderyear, numorders
FROM dbo.EmpYearOrders
	CROSS APPLY (VALUES(2014, cnt2014),
						(2015, cnt2015),
						(2016, cnt2016)) AS A(orderyear, numorders)
WHERE numorders <> 0;

SELECT empid, CAST(RIGHT(orderyear, 4) AS INT) AS orderyear, numorders
FROM dbo.EmpYearOrders
	UNPIVOT(numorders FOR orderyear IN(cnt2014, cnt2015, cnt2016)) AS U
WHERE numorders <> 0;

--Exercise 6
--Write a query against the dbo.Orders table that returns the total quantities for each of the following: (employee, customer, and order year), (employee and order year), and (customer and order year). Include a result column in the output that uniquely identifies the grouping set with which the current row is associated:
--Table involved: TSQLV4 database, dbo.Orders table

SELECT 
   GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
   empid, custid, YEAR(Orderdate) AS orderyear, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY 
	GROUPING SETS
	(
		(empid, custid, YEAR(orderdate)),
		(empid, YEAR(orderdate)),
		(custid, YEAR(orderdate))

	);
