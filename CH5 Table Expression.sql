USE TSQLV4;
--Chapter 5: Table Expression

--1. DERIVED TABLES------Single Statement scope: not reusable
SELECT * 
FROM (SELECT custid, companyname
	  FROM Sales.Customers
	  WHERE country = N'USA') AS USACusts;

--Inline aliasing form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
	  FROM Sales.Orders) AS D
GROUP BY orderyear;

--second aliasing form
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate), custid
	  FROM Sales.Orders) AS D(orderyear, custid)
GROUP BY orderyear;

--Using Arguments
DECLARE @empid AS INT = 3;
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM(SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
	WHERE empid = @empid) AS D
GROUP BY orderyear;

--Nesting
SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	  FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders) AS D1
      GROUP BY orderyear) AS D2
WHERE numcusts > 70;

--Multiple references
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear,
	     COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
      GROUP BY YEAR(orderdate)) AS Cur
  LEFT OUTER JOIN
      (SELECT YEAR(orderdate) AS orderyear,
         COUNT(DISTINCT custid) AS numcusts
       FROM Sales.Orders
       GROUP BY YEAR(orderdate)) AS Prv
   ON Cur.orderyear = Prv.orderyear + 1;

--2. Common Table Expression (CTE)-Single Statement scope(not reusable)
WITH USACusts AS
(
	SELECT custid, companyname
	FROM Sales.Customers
	WHERE country = N'USA'
)
SELECT * FROM USACusts;

--Assigning column aliases in CTE
--a) Inline Form
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

--b)External Form
WITH C(orderyear, custid) AS
(
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT orderyear,COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

--Using arguments in CTEs
DECLARE @emplid AS INT = 3;
WITH C AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
	WHERE empid = @emplid
)
SELECT orderyear, COUNT(DISTINCT(custid)) AS numcusts
FROM C 
GROUP BY orderyear;
--Defining multiple CTEs
WITH C1 AS 
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
),
C2 AS
(
	SELECT orderyear, count(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;

--Multiple references in CTEs
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear,
		COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)
SELECT Cur.orderyear, 
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
	LEFT OUTER JOIN YearlyCount AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

--Recursive CTEs
WITH EmpsCTE AS
(
	--anchor table
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2
	UNION ALL
	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		INNER JOIN HR.Employees AS C
			ON C.mgrid = P.empid
)
SELECT empid, mgrid,firstname, lastname
FROM EmpsCTE;

--3. Views: permanent object in db
DROP VIEW IF EXISTS Sales.USACusts;
Go
CREATE VIEW Sales.USACusts
AS
SELECT 
	custid, companyname, contactname, contacttitle,address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
GO
SELECT custid, companyname
FROM Sales.USACusts
--Views and the order by clause: Orderby clause not permitted
--inside the views like other table unless TOP, FETCH are used
ALTER VIEW Sales.USACusts
AS
SELECT TOP(100) PERCENT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO
SELECT custid, companyname, region
FROM Sales.USACusts; --rows not sorted always use orderby against outer queries

--however optimizer does not yet optimize out the combination when the --inner query uses OFFSET clause with 0 ROWS
--still do not assume the presentation is guaranteed
ALTER VIEW Sales.USACusts
AS
SELECT
	custid,companyname,contactname,contacttitle,address,
	city,region,postalcode,country,phone,fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region
OFFSET 0 ROWS;
GO
SELECT custid, companyname, region
FROM Sales.USACusts;

--View Options
--a) The ENCRYPTION option: available to create or alter views,
-- stored procedures,triggers, and user-defined functions (UDFs).

ALTER VIEW Sales.USACusts
AS
SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS
SELECT 
	custid, companyname,contactname,contacttitle,address,
	city,region,postalcode,country,phone,fax
FROM Sales.Customers
WHERE country = N'USA';
Go

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));--NULL
--Alternatively
EXEC sp_helptext 'Sales.USACusts';

--b)The SCHEMABINDING option: is available to views and UDFs;
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
	custid, companyname,contactname,contacttitle,address,city,region,
	postalcode,country,phone,fax
FROM Sales.Customers
WHERE country = N'USA'
GO
--referenced objects, columns cant be altered or dropped
ALTER TABLE Sales.Customers DROP COLUMN address;

--c)The CHECK option: prevent modification thru the view that conflict with the views filter 
INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax)
VALUES(
	N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE',N'Address ABCDE', N'London', NULL, N'12345',N'UK', N'012-3456789',N'012-3456789');

SELECT custid, companyname, country
FROM Sales.USACusts
WHERE companyname = N'Customer ABCDE'

SELECT custid, companyname, country
FROM Sales.Customers
WHERE companyname = N'Customer ABCDE';

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT 
	custid, companyname,contactname,contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO

--now try to insert a code
INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax)
VALUES(
N'Customer FGHIJ', N'Contact FGHIJ', N'Title FGHIJ', N'Address FGHIJ',
N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

DELETE FROM Sales.Customers
WHERE custid > 91;

DROP VIEW IF EXISTS Sales.USACusts

--INLINE table-Valued functions
USE TSQLV4
DROP FUNCTION IF EXISTS dbo.GetCustOrders
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE
AS
RETURN 
	SELECT orderid, custid, empid, orderdate, requireddate,
		shippeddate, shipperid, freight, shipname, shipaddress, shipcity
	FROM Sales.Orders
	WHERE custid = @cid;
GO
SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;

SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

DROP FUNCTION IF EXISTS dbo.GetCustOrders;

--APPLY operator
--CROSS APPLY and OUTER APPLY
--CROSS APPLY-> implements one logical-query processing phase it applies the right table to each row from the left table and produces a result table with the unified result sets.
SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
	CROSS JOIN HR.Employees AS E

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
	CROSS APPLY HR.Employees AS E;
--With APPLY, the left side is evaluated first, and the right side is evaluated per row from the left. So the right side can have references to elements from the left; logical query processing
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
		(SELECT TOP(3) orderid, empid, orderdate, requireddate
		FROM Sales.Orders AS O
		WHERE O.custid = C.custid
		ORDER BY orderdate DESC, orderid DESC) AS A;

--Using standard OFFSET-FETCH 
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
		(SELECT orderid, empid, orderdate, requireddate
		FROM Sales.Orders AS O
		WHERE O.custid = C.custid
		ORDER BY orderdate DESC, orderid DESC
		OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A; 
		
--OUTER APPLY: return rows from left if no matches on  the right side. Second 
--logical phase that preserves all left rows(with derived tables)
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	OUTER APPLY
		(SELECT TOP (3) orderid, empid, orderdate, requireddate
		FROM Sales.Orders AS O
		WHERE O.custid = C.custid
		ORDER BY orderdate DESC, orderid DESC) AS A;

--using inline Table Value Function with outer apply much cleaner code

DROP FUNCTION IF EXISTS TopOrders
GO
CREATE FUNCTION TopOrders
	(@custid AS INT, @n AS INT)
	RETURNS TABLE
AS
RETURN
	SELECT TOP(@n) orderid, empid, orderdate, requireddate
	FROM Sales.Orders AS O
	WHERE custid = @custid
	ORDER BY orderdate DESC, orderid DESC;
GO

SELECT 
	C.custid, C.companyname,
	A.orderid, A.empid, A.orderdate, A.requireddate
FROM Sales.Customers AS C
	CROSS APPLY dbo.TopOrders(C.custid, 3) AS A 