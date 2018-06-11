
--Self-Contained subqueries: independent of the tables in outer query
--Self-contained scalar subquery
--scalar subquery returns the single value
DECLARE @maxid AS INT = (SELECT MAX(orderid) 
						 FROM Sales.Orders);
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid
--you can substitute the vriable with a scalar self-contained subquery
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT max(O.orderid) 
				FROM Sales.Orders AS O);

SELECT orderid
FROM Sales.Orders
WHERE empid = 
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'C%');

--if it tries to return more than one value it will fail
SELECT orderid
FROM Sales.Orders
WHERE empid = 
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'D%')

--If a scalar returns no value, the empty result is converted to
-- a Null. Comparison with NULL yields UNKNOWN 
SELECT orderid
FROM Sales.Orders
WHERE empid = 
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'A%');--returns empty set

--Self-contained multivalued subquery
SELECT orderid
FROM Sales.Orders
WHERE empid IN 
	(SELECT E.empid
	 FROM HR.Employees AS E
	 WHERE E.lastname LIKE N'D%');

-- can be achieved same result with join
SELECT O.orderid
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O
		ON E.empid = O.empid
WHERE E.lastname LIKE N'D%';

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN
	(SELECT C.custid
	 FROM Sales.Customers AS C
	 WHERE C.country = N'USA')

--customers who did not place any orders
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN
	(SELECT O.custid
	 FROM Sales.Orders AS O)

DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL CONSTRAINT PK_ORDERS PRIMARY KEY
);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0;

--To return all missing order IDs, query the Nums table and filter only
--numbers that are between the minimum and maximum ones in the dbo.Orders table,
--and that do not appear as order IDs in the Orders table.
SELECT n
FROM dbo.Nums
WHERE n BETWEEN(SELECT MIN(O.orderid) FROM dbo.Orders AS O)
			AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
  AND n NOT IN(SELECT O.orderid FROM dbo.Orders AS O);

DROP TABLE IF EXISTS dbo.Orders;

--Correlated subqueries: subqueries that refer to attributes from the
--table that appear in the outer query. Logically subquery is evaluated 
--separately for each outer row

--To understand the correlated subqueries focus your attention on a single
--row in the outer table and think about the logical processing that takes
--place in the inner query for that row
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid = 
	(SELECT MAX(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.custid = O1.custid)

/*suppose you need to query the Sales.OrderValues view and return for
each order the percentage of the current order value out of the customer total*/
SELECT * FROM Sales.OrderValues
WHERE custid = 85;

SELECT orderid, custid, val, 
   CAST(100 * val/ (SELECT SUM(O2.val)
				  FROM Sales.OrderValues AS O2
				  WHERE O2.custid = O1.custid)
	   AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY custid, orderid;

--THE EXISTS predicate
--Following query returns customers from Spain who placed orders
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND EXISTS
		(SELECT * FROM Sales.Orders AS O
		 WHERE O.custid = C.custid);

--Even though in most cases the use of star (*) is considered a bad practice, with EXISTS it isn’t. EXISTS uses two valued logic and not three-valued logic
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND NOT EXISTS 
		(SELECT * FROM Sales.Orders AS O
		WHERE O.custid = C.custid);

--Returning previous or next values

/*for each order, information about the current order and also the previous order ID. The tricky part is that the concept of “previous” implies order, and rows in a table have no order.*/
SELECT orderid, orderdate, empid, custid,
   (SELECT MAX(O2.orderid)
    FROM Sales.Orders AS O2
	WHERE O2.orderid< O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;

--Similarly, you can phrase the concept of “next” as “the minimum value that is greater than the current value.”
SELECT orderid, orderdate, empid, custid,
	(SELECT MIN(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;

--USING running aggregates
--Running aggregates are aggregates that accumulate values based on some order
SELECT * FROM Sales.OrderTotalsByYear;
SELECT orderyear, qty,
	(SELECT SUM(OT2.qty)
	 FROM Sales.OrderTotalsByYear AS OT2
	 WHERE OT2.orderyear<=OT1.orderyear) AS RunningTotal
FROM Sales.OrderTotalsByYear AS OT1
Order by orderyear;

--using Window Function: Window partition clause(you can remove partition depending upon the logic), window order clause, window-frame clause
SELECT orderyear, qty, SUM(qty)
					    OVER(
						ORDER BY orderyear
						ROWS BETWEEN UNBOUNDED PRECEDING 
							AND CURRENT ROW) AS runningTotal
FROM Sales.OrderTotalsByYear;



SELECT * FROM Sales.OrderTotalsByYear


--Dealing with misbehaving subqueries
--NULL trouble
--Customers who did not place orders

--Remember that a query filter discards rows that get UNKNOWN in the result of the predicate
/*The IN predicate returns UNKNOWN for a customer such as 22 that does not appear in the
set of known customer IDs in Orders. That’s because when you compare it with known
customer IDs you get FALSE, and when you compare it with a NULL you get UNKNOWN.
FALSE OR UNKNOWN yields UNKNOWN. Consider the expression 22 NOT IN (1, 2, <other
non-22 values>, NULL). This expression can be rephrased as NOT 22 IN (1, 2, ..., NULL). You
can expand this expression to NOT (22 = 1 OR 22 = 2 OR ... OR 22 = NULL). Evaluate each
individual expression in the parentheses to its truth value and you get NOT (FALSE OR FALSE
OR ... OR UNKNOWN), which translates to NOT UNKNOWN, which evaluates to UNKNOWN.*/
Select * from sales.orders
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
					FROM Sales.Orders AS O);

INSERT INTO Sales.Orders
	(custid, empid, orderdate, requireddate, shippeddate, shipperid,
	 freight, shipname, shipaddress, shipcity, shipregion,
	 shippostalcode, shipcountry)
   VALUES(NULL, 1, '20160212', '20160212', '20160212', 1,123.00,
		  N'abc', N'abc', N'abc',N'abc', N'abc', N'abc');

SELECT * FROM Sales.Orders
order by custid

SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN (SELECT O.custid
				     FROM Sales.Orders AS O
					 WHERE O.custid IS NOT NULL);
--You can also exclude the NULLs implicitly by using the NOT EXISTS predicate instead of
--NOT IN, like this:
--Unlike IN, EXISTS uses tow-valued predicated logic.
--EXISTS always returns TRUE or FALSE and never UNKNOWN
--IT is safer to use NOT EXISTS than NOT IN
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
	(SELECT * 
	 FROM Sales.Orders AS O
	 WHERE O.custid = C.custid);

DELETE FROM Sales.Orders WHERE custid IS NULL;

--Substitution errors in subquery column names
DROP TABLE IF EXISTS Sales.MysShippers;
CREATE TABLE Sales.MyShippers
(
	shipper_id INT NOT NULL,
	companyname NVARCHAR(40) NOT NULL,
	phone NVARCHAR(24)	NOT NULL,
	CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, companyname, phone)
	VALUES(1, N'Shipper GVSUA',N'(503) 555-0137'),
		  (2, N'Shipper ETYNR', N'(425) 555-0136'),
		  (3, N'Shipper ZHISN', N'(415) 555-0138');

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
	(SELECT shipper_id
	 FROM Sales.Orders
	 WHERE custid = 43);
/*In our example, SQL Server
first looks for the column shipper_id in the table in the inner query, Orders. Such a column is not found there, so SQL Server looks for it in the table in the outer query, MyShippers. Such a column is found in MyShippers, so that is the one used.*/
SELECT *
	 FROM Sales.Orders
	 WHERE custid = 43

--Running sum 
SELECT empid, ordermonth, val,
	SUM(val) OVER(PARTITION BY empid
				  ORDER BY ordermonth
				  ROWS BETWEEN UNBOUNDED PRECEDING
						AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;