--T-SQL supports four table operators:JOIN, APPLY, PIVOT, and UNPIVOT.
--ISO/ANSI SQL 93 syntax
--CROSS join
SELECT C.custid, E.empid
FROM Sales.Customers AS C
   CROSS JOIN HR.EMployees AS E;

--ISO/ANSI SQL 89 syntax
SELECT C.custid, E.empid
FROM Sales.Customers AS C, HR.Employees AS E;

--Self cross joins
SELECT 
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
    CROSS JOIN HR.Employees AS E2;

--Producing tables of numbers
DROP TABLE IF EXISTS dbo.Digits;
CREATE TABLE dbo.Digits
(
   digit INT NOT NULL PRIMARY KEY
);
INSERT INTO dbo.Digits(digit)
	VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)
SELECT * FROM dbo.Digits;

SELECT D3.digit*100 + D2.digit*10 + D1.digit + 1 AS n
FROM dbo.Digits AS D1
   CROSS JOIN dbo.Digits AS D2
   CROSS JOIN dbo.Digits AS D3
ORDER BY n;

--INNER JOIN-safety
SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
   INNER JOIN Sales.Orders AS O
      ON E.empid = O.empid;

--Composite joins: inner join on multiple columns
DROP TABLE IF EXISTS Sales.OrderDetailsAudit;
CREATE TABLE Sales.OrderDetailsAudit
(
	lsn		INT NOT NULL IDENTITY,
	orderid INT NOT NULL,
	productid INT NOT NULL,
	dt DATETIME NOT NULL,
	loginname sysname NOT NULL,
	columnname sysname NOT NULL,
	oldval SQL_VARIANT,
	newval SQL_VARIANT,
	CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
	CONSTRAINT FK_OrderDetailsAudit_OrderDetails
		FOREIGN KEY(orderid, productid)
		REFERENCES Sales.OrderDetails(orderid, productid)
);

SELECT OD.orderid, OD.productid, OD.qty,
   ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM Sales.OrderDetails AS OD
   INNER JOIN Sales.OrderDetailsAudit AS ODA
      ON OD.orderid = ODA.orderid
	  AND OD.productid = ODA.productid
WHERE ODA.columnname = N'qty';

--Non-equi joins: join condition involves any operator besides 
--equality, and viceversa is equi join
--join that has an explicit join predicate that is based on a binary operator
--(equality or nequality) is known as theta join. Equi and non-equi are theta joins

SELECT 
	E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
    INNER JOIN HR.Employees AS E2
		ON E1.empid < E2.empid; 

--Multijoin queries
SELECT  
	C.Custid, C.companyname, O.orderid,
	OD.productid, OD.qty
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

--OUTER joins: apply two logical processing(cartesian product and On clause)
-- that inner joins apply plus a third phase called adding outer rows that 
--is unique to this type of join
SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid;
--On clause you specify non final or matching prdicates
--WHERE clause you specify final, or filtering, predicates

--return only customers who didn't place any orders 
--outer joins are identified by theNulls in the attributes from
--the nonpreserved side of the join
SELECT C.custid, C.companyname
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderid IS NULL;

SELECT DATEADD(day, n-1, CAST('20140101' AS DATE)) AS orderdate
FROM dbo.Nums
WHERE n<= DATEDIFF(day, '20140101','20161231') + 1
ORDER BY orderdate;

select DATEDIFF(day, '20140101','20161231') + 1
select * from nums
SELECT DATEADD(day, 0, CAST('20140101' AS DATE)) AS orderdate

SELECT DATEADD(day, Nums.n-1, CAST('20140101' AS DATE)) AS orderdate,
	O.orderid, O.custid, O.empid
FROM dbo.Nums
	LEFT OUTER JOIN Sales.Orders AS O
		ON DATEADD(day, Nums.n-1, CAST('20140101' AS DATE)) = O.orderdate
WHERE Nums.n <= DATEDIFF(day, '20140101', '20161231') + 1
ORDER BY orderdate;

--Filtering attributes from the nonpreserved side of an outer join
/*expression in the form NULL <operator> <value> yields UNKNOWN 
(unless it’s the IS NULL operator explicitly looking for NULLs) 
WHERE clause filters UNKNOWN out. Such a predicate in the WHERE 
clause causes all outer rows to be filtered out, effectively 
nullifying the outer join. Effectively, the join becomes an inner join.*/

/*The query performs a left outer join between the Customers and Orders tables. Prior to
applying the WHERE filter, the join operator returns inner rows for customers who placed
orders and outer rows for customers who didn’t place orders, with NULLs in the order
attributes. The predicate O.orderdate >= ‘20160101’ in the WHERE clause evaluates to
UNKNOWN for all outer rows, because those have a NULL in the O.orderdate attribute. All
outer rows are eliminated by the WHERE filter,*/
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	WHERE O.orderdate >= '20160101';

--using outer joins in a multi-join query

/*Generally, outer rows are dropped whenever any kind of outer join (left, right, or full) is followed by a subsequent inner join or right outer join. That’s assuming, of course, that the join condition compares the NULLs from the left side with something from the right side.*/
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

--several ways to get around the problem if you want to return customers with no
--orders in the output. One option is to use a left outer join in the second join as well
SELECT C.custid, O.orderdate, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	LEFT OUTER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
	RIGHT OUTER JOIN Sales.Customers AS C
		ON O.custid = C.custid;

--A second option
SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN 
		(Sales.Orders AS O
			INNER JOIN Sales.OrderDetails AS OD
			ON O.orderid = OD.orderid)
		ON O.custid = O.custid;

--USing the COUNT(*) aggregare with outer joins-Bug

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
GROUP BY C.custid;

--The COUNT(*) aggregate function cannot detect whether a row really represents an order.
--To fix the problem, you should use COUNT(<column>) instead of COUNT(*) and provide a
--column from the nonpreserved side of the join

SELECT C.custid, COUNT(O.orderid) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
GROUP BY C.custid;