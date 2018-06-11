

---------------------------------------VIEWS---------------------------------------------
-----------------------------------------------------------------------------------------
--create view, why we need check constraint, encryption,and schemabinding
DROP VIEW IF EXISTS Sales.USACusts;
GO
CREATE VIEW Sales.USACusts
AS

SELECT
	custid, companyname, contactname ,contacttitle ,address
	,city ,region ,postalcode ,country ,phone ,fax
FROM Sales.Customers
WHERE country = N'USA'
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

SELECT OBJECT_DEFINITION(OBJECT_ID('HR.Employees'))

--Encryption
ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS
SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
EXEC sp_helptext 'Sales.USACusts';

--The SCHEMABINDING option is available to views and UDFs; it binds the schema of
--referenced objects and columns to the schema of the referencing object
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

--does not allow to drop column : always a good practice
--with schemabinding you are not allowed to drop or create any columns
ALTER TABLE Sales.Customers DROP COLUMN address;

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS
SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO

--The purpose of CHECK OPTION is to prevent modifications through the view that conflict
--with the view’s filter. without the WITH CHECK OPTION you can insert rows that 
--inserts into the customer table, which alters the table.

INSERT INTO Sales.USACusts(
companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax)
VALUES(
N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');
--Inserted into customers table thru views
select * from sales.customers
order by custid desc

--not visible in views because views only has USA customers
select * from sales.usaCusts
where contactname = N'Contact ABCDE'

--clean up the code
DELETE FROM Sales.Customers
WHERE custid > 91;
DROP VIEW IF EXISTS Sales.USACusts;
---------------------------------------------TVF-------------------------------
-----------------------------------------------------------------------------------

--Inline Table Valued Function (Inline TVF)
--Inline TVFs are reusable table expressions that support input parameters;think of it
--as a parametarized views
--T-SQL supports another type of table function called multi-statement TVF, which populates
--and returns a table variable. This type isn’t considered a table expression because 
--it’s not based on a query.

USE TSQLV4
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE --accepts an input parameter '@cid'
AS
RETURN
	SELECT orderid, custid, empid, orderdate, requireddate,
	shippeddate, shipperid, freight, shipname, shipaddress, shipcity,
	shipregion, shippostalcode,shipcountry
	FROM Sales.Orders
	WHERE custid = @cid;
GO

SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS o;

--we can even join Inline TVF against tables
SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
INNER JOIN Sales.OrderDetails AS OD
ON O.orderid = OD.orderid;

--Cleanup
DROP FUNCTION IF EXISTS dbo.GetCustOrders;

-------------------------------------------------------------------
-----------------------------------APPLY Operator-------------
---------------------------------------------------------------
--The APPLY operator operates on two input tables;

--CROSS APPLY: 1 Logical Query proessing phase
-----It applies the right table to each row from the left table and 
---------produces a result table with the unified result sets. functions like a cross join


--OUTER APPLY: 2 Logical Query Processing phase



------------------------------EXAMPLE----------------------------------------------------
--join treats its two inputs as a set, and therefore there’s no order between
--them. This means you cannot refer on one side to elements from the other.

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
CROSS JOIN HR.Employees AS E;

--With APPLY, the left side is evaluated first, and the right side is evaluated 
--per row from the left. So the right side can have references to elements from the left.

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
CROSS APPLY HR.Employees AS E;

--THREE MOST RECENT ORDERS FOR EACH CUSTOMERS


/*In terms of logicalquery
processing, the right table expression (a derived table, in this case) is applied to each
row from the Customers table. Notice in the inner query’s filter the reference to the 
attribute C.custid from the left table. The derived table returns the three most 
recent orders for the current customer from the left row.
*/
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
CROSS APPLY
(SELECT TOP (3) orderid, empid, orderdate, requireddate,custid
FROM Sales.Orders AS O
WHERE O.custid = C.custid
ORDER BY orderdate DESC, orderid DESC) AS A;--Table A as correlated derived table

--OR use OFFSET -- ROWS FETCH NEXT-- ROWS ONLY
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
	(SELECT orderid, empid, orderdate, requireddate
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	ORDER BY orderdate DESC, orderid DESC
	OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A;

/*
If the right table expression returns an empty set, the CROSS APPLY operator does not
return the corresponding left row. For example, customers 22 and 57 did not place orders. 
In both cases, the derived table is an empty set; therefore, those customers are not 
returned in the output. If you want to return rows from the left side even if there are 
no matches on the right side, use OUTER APPLY.
*/
SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	OUTER APPLY
		(SELECT TOP (3) orderid, empid, orderdate, requireddate
		FROM Sales.Orders AS O
		WHERE O.custid = C.custid
		ORDER BY orderdate DESC, orderid DESC) AS A;

/*You might find it more convenient to work with inline TVFs instead of derived tables. 
This way, your code will be simpler to follow and maintain. For example, the following code
creates an inline TVF called TopOrders that accepts as inputs a customer ID (@custid) and a
number (@n), and returns the @n most recent orders for customer @custid:
*/

DROP FUNCTION IF EXISTS dbo.TopOrders;
GO
CREATE FUNCTION dbo.TopOrders
	(@custid AS INT, @n AS INT)
	RETURNS TABLE
AS
RETURN
	SELECT TOP (@n) orderid, empid, orderdate, requireddate
	FROM Sales.Orders
	WHERE custid = @custid
	ORDER BY orderdate DESC, orderid DESC;
GO

SELECT
	C.custid, C.companyname,
	A.orderid, A.empid, A.orderdate, A.requireddate
FROM Sales.Customers AS C
	CROSS APPLY dbo.TopOrders(C.custid, 3) AS A;