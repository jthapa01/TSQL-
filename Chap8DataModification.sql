
USE TSQLV4;
--1. INSERT INTO VALUES
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL
		CONSTRAINT PK_Orders PRIMARY KEY,
	orderdate DATE NOT NULL
		CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
	empid INT NOT NULL,
	custid VARCHAR(10) NOT NULL
);

INSERT INTO dbo.Orders(orderid, orderdate, empid,custid)
 VALUES(10001,'20160212',3,'A')

INSERT INTO dbo.Orders(orderid, empid, custid)
VALUES(10002, 5, 'B');

--T-SQL supports an enhanced standard VALUES clause you can use to specify multiple rows separated by commas. IT processes as a transaction
INSERT INTO dbo.Orders
(orderid, orderdate, empid, custid)
VALUES
(10003, '20160213', 4, 'B'),
(10004, '20160214', 1, 'A'),
(10005, '20160213', 1, 'C'),
(10006, '20160215', 3, 'C');

--There’s more to this enhanced VALUES clause. You can use it as a table-value constructor to construct a derived table. Here’s an example:
SELECT * 
FROM(VALUES
		(10003,'20160213',4,'B'),
		(10004,'20160214',1,'A'),
		(10005,'20160213',1,'C'),
		(10006,'20160215',3,'C'))
AS O(orderid, orderdate,empid,custid);

--2. INSERT INTO SELECT 
INSERT INTO dbo.Orders(orderid, orderdate,empid,custid)
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = N'UK';

--3 INSERT EXEC: use to insert a result set returned from a stored procedure or a dynamic SQL batch into a target table

USE TSQLV4
DROP PROC IF EXISTS Sales.GetOrders;
GO
CREATE PROC Sales.GetOrders
	@country AS NVARCHAR(40)
AS

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE shipcountry = @country;
GO

EXEC Sales.GetOrders @country = N'France';

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	EXEC Sales.GetOrders @country = N'France';

--4. SELECT INTO
--You cannot use this statement to insert data into an existing table
--Nonstandard: I mean that it’s not part of the ISO and ANSI SQL standards
DROP TABLE IF EXISTS dbo.Orders

SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders
/*The target table’s structure and data are based on the source table. The SELECT INTO
statement copies from the source the base structure (such as column names, types, nullability,
and identity property) and the data. It does not copy from the source constraints, indexes,
triggers, column properties such as SPARSE and FILESTREAM, and permissions. If you need
those in the target, you’ll need to create them yourself.*/
DROP TABLE IF EXISTS dbo.Locations;
SELECT country, region, city 
INTO dbo.Locations--use INTO clause in first part when with set operators
FROM sales.Customers
EXCEPT
SELECT country,region, city
FROM HR.Employees

--5 BULK INSERT statement
BULK INSERT dbo.Orders FROM 'c:\orders.txt'
	WITH
	(
		DATAFILETYPE = 'char',
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '\n'

	);

--IDENTITY
/*You can define this property for a column with any
numeric type with a scale of zero (no fraction). When defining the property, you can
optionally specify a seed (the first value) and an increment (a step value). If you don’t provide
those, the default is 1 for both*/

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1
(
	keycol INT NOT NULL IDENTITY(1,1)--seed and increment
		CONSTRAINT PK_T1 PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
		CONSTRAINT CHK_T1_datacol CHECK(datacol LIKE '[ABCDEFGHIJKLMNOPQRSTYVWXYZ]%')--data restricted to starting with alphabetical char
);

INSERT INTO dbo.T1(datacol)
VALUES ('AAAAA'),('CCCCC'),('BBBBB1');

select * from dbo.T1
delete from dbo.T1
where keycol in(4,5)

SELECT $identity FROM dbo.T1--generic form

--For example, the following code inserts a new row into the table T1, obtains the newly generated identity value and places it into a variable by querying the SCOPE_IDENTITY function, and queries the variable:
DECLARE @new_key AS INT;
INSERT INTO dbo.T1(datacol) VALUES('AAAAA');
SET @new_key = SCOPE_IDENTITY();
SELECT @new_key AS new_key

/*Remember that both @@identity and SCOPE_IDENTITY return the last identity value
produced by the current session. Neither is affected by inserts issued by other sessions.
However, if you want to know the current identity value in a table (the last value produced)
regardless of session, you should use the IDENT_CURRENT function and provide the table
name as input.*/

SELECT 
	SCOPE_IDENTITY() AS [SCOPE IDENTITY],
	@@identity AS [@@identity],
	IDENT_CURRENT(N'dbo.T1') AS [IDENT_CURRENT];

INSERT INTO dbo.T1(datacol) VALUES('12345');
INSERT INTO dbo.T1(datacol) VALUES('EEEEE');
SELECT * FROM dbo.T1
--With SQL Server, you can specify your own explicit values for the identity column when
--you insert rows, as long as you enable a session option called IDENTITY_INSERT against the
--table involved

SET IDENTITY_INSERT dbo.T1 ON;
INSERT INTO dbo.T1(keycol, datacol) VALUES(5,'FFFFF');
SET IDENTITY_INSERT dbo.T1 OFF

INSERT INTO dbo.T1(datacol) VALUES('GGGGG')
SELECT * FROM dbo.T1

/*You need to understand that the identity property itself does not enforce uniqueness in the
column. I already explained that you can provide your own explicit values after setting the
IDENTITY_INSERT option to ON, and those values can be ones that already exist in rows in
the table. Also, you can reseed the current identity value in the table by using the DBCC
CHECKIDENT command*/

--SEQUENCE
/*For example, suppose you want to create a sequence that will help you generate order IDs.
You want it to be of an INT type, have a minimum value of 1 and a maximum value that is the
maximum supported by the type, start with 1, increment by 1, and allow cycling. Here’s the
CREATE SEQUENCE command you would use to create such a sequence:*/
CREATE SEQUENCE dbo.SeqOrderIDs AS INT 
	MINVALUE 1
	CYCLE;

ALTER SEQUENCE dbo.SeqOrderIds
NO CYCLE;

SELECT NEXT VALUE FOR dbo.SeqOrderIds

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1
(
   keycol INT NOT NULL
      CONSTRAINT PK_T1 PRIMARY KEY,
   datacol VARCHAR(10) NOT NULL
);
--variable declaration and assign it from the next value of sequence
DECLARE @neworderid AS INT =  NEXT VALUE for dbo.SeqOrderIds;
INSERT INTO dbo.T1(keycol, datacol) VALUES(@neworderid,'a');

SELECT * FROM dbo.T1
/*If you don’t need to generate the new sequence value before using it, you can specify the
NEXT VALUE FOR function directly as part of your INSERT statement, like this:*/
INSERT INTO dbo.T1(keycol, datacol)
	VALUES(NEXT VALUE FOR dbo.SeqOrderIDs, 'b')

SELECT * FROM dbo.T1;

UPDATE dbo.T1
	SET keycol = NEXT VALUE FOR dbo.SeqOrderIDs

	--To get infor about your sequences query a view called sys.sequences
SELECT current_value FROM sys.sequences
WHERE OBJECT_ID = OBJECT_ID(N'dbo.SeqOrderIDs')

INSERT INTO dbo.T1(keycol,datacol)
  SELECT 
    NEXT VALUE FOR dbo.SeqORderIDs OVER(ORDER BY hiredate),
	LEFT(FIRSTNAME,1) + LEFT(lastname,1)
  FROM HR.Employees;

SELECT firstname, lastname,hiredate FROM HR.Employees
--Another extension to the standard allows the use of the NEXT VALUE FOR function in a default constraint.
ALTER TABLE dbo.T1
  ADD CONSTRAINT DFT_T1_keycol
    DEFAULT(NEXT VALUE FOR dbo.SeqOrderIDs) 
	FOR keyCol;

SELECT * FROM dbo.T1
INSERT INTO dbo.T1(datacol) VALUES('c')

DECLARE @first AS SQL_VARIANT;
EXEC sys.sp_sequence_get_range
	@sequence_name = N'dbo.SeqOrderIDs',
	@range_size = 1000000,
	@range_first_value = @first OUTPUT;

SELECT @First;

DROP TABLE IF EXISTS dbo.T1;
DROP SEQUENCE IF EXISTS dbo.SeqOrderIDs;

--DELETING DATA
DROP TABLE IF EXISTS dbo.Orders, dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL,
	companyname NVARCHAR(40) NOT NULL,
	contactname NVARCHAR(30) NOT NULL,
	contacttitle NVARCHAR(60) NOT NULL,
	address NVARCHAR(60) NOT NULL,
	city NVARCHAR(15) NOT NULL,
	region NVARCHAR(15) NULL,
	postalcode NVARCHAR(10) NULL,
	country NVARCHAR(15) NOT NULL,
	phone NVARCHAR(24) NOT NULL,
	fax NVARCHAR(24) NULL,
	CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
custid INT NULL,
empid INT NOT NULL,
orderdate DATE NOT NULL,
requireddate DATE NOT NULL,
shippeddate DATE NULL,
shipperid INT NOT NULL,
freight MONEY NOT NULL
CONSTRAINT DFT_Orders_freight DEFAULT(0),
shipname NVARCHAR(40) NOT NULL,
shipaddress NVARCHAR(60) NOT NULL,
shipcity NVARCHAR(15) NOT NULL,
shipregion NVARCHAR(15) NULL,
shippostalcode NVARCHAR(10) NULL,
shipcountry NVARCHAR(15) NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid),
CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
REFERENCES dbo.Customers(custid)
);
INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
--The DELETE statement tends to be expensive when you delete a large number of rows,mainly because it’s a fully logged operation.

DELETE FROM dbo.Orders
WHERE orderdate < '20150101';

--The TRUNCATE statement
--deletes all rows from a table, TRUNCATE as no filter
--The advantage that TRUNCATE has over DELETE is that the former is minimally logged,whereas the latter is fully logged, resulting in significant performance differences.
--BOTH DELETE and TRUNCATE are transactional
--TRUNCATE resets the identity value back to the original seed, but DELETE doesn’t—even when used without a filter.

/*The TRUNCATE statement is not allowed when the target table is referenced by a foreignkey
constraint, even if the referencing table is empty and even if the foreign key is disabled.
The only way to allow a TRUNCATE statement is to drop all foreign keys referencing the
table with the ALTER TABLE DROP CONSTRAINT command. You can then re-create the
foreign keys after truncating the table with the ALTER TABLE ADD CONSTRAINT command.*/

--As an example, suppose you had a partitioned table called T1 and you wanted to truncate
--partitions 1, 3, 5, and 7 through 10. You would use the following code to achieve this:

TRUNCATE TABLE dbo.T1 WITH(PARTITIONS(1,3,5,7 TO 10));

--DELETE based on a JOIN(non standard but tsql accepts)
DELETE FROM O--FROM is optional here 
FROM dbo.ORDERS AS O
	INNER JOIN dbo.CUSTOMERS AS C
	  ON O.custid = C.custid
WHERE C.country = N'USA';

--As I mentioned earlier, a DELETE statement based on a join is nonstandard. If you want to
--stick to standard code, you can use subqueries instead of joins. For example, the following
--DELETE statement uses a subquery to achieve the same task:

DELETE FROM dbo.Orders
WHERE EXISTS
	(SELECT * 
	 FROM dbo.Customers AS C
	 WHERE Orders.custid  = c.custid
	  AND C.country = N'USA' 
	)
DROP TABLE IF EXISTS dbo.Orders, dbo.Customers;

--UPDATING Data
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;
CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
custid INT NULL,
empid INT NOT NULL,
orderdate DATE NOT NULL,
requireddate DATE NOT NULL,
shippeddate DATE NULL,
shipperid INT NOT NULL,
freight MONEY NOT NULL
CONSTRAINT DFT_Orders_freight DEFAULT(0),
shipname NVARCHAR(40) NOT NULL,
shipaddress NVARCHAR(60) NOT NULL,
shipcity NVARCHAR(15) NOT NULL,
shipregion NVARCHAR(15) NULL,
shippostalcode NVARCHAR(10) NULL,
shipcountry NVARCHAR(15) NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
	orderid  INT   NOT NULL,
	productid INT  NOT NULL,
	unitprice MONEY  NOT NULL
	   CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty SMALLINT NOT NULL
		CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount NUMERIC(4,3) NOT NULL
		CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
    CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid,productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
		REFERENCES dbo.Orders(orderid),
    CONSTRAINT CHK_discount CHeCK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHL_qty CHECK (qty>0),
	CONSTRAINT CHK_Unitprice CHECK (unitprice >=0)
);
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

--UPDATE statement
--For example, the following UPDATE statement increases the discount of all order details
--for product 51 by 5 percent:
UPDATE dbo.OrderDetails
  SET discount = discount + .05--SET discount +=.05
WHERE productid = 51;

--UPDATE dbo.T1
--SET col1 = col1 + 10, col2 = col1 + 10;--all at once concept

--UPDATE dbo.T1
--SET col1 = col2, col2 = col1;
--In both assignments, the source column values used are those prior to the update, so you
--don’t need a temporary variable.

--UPDATE based on a JOIN--NOnstandard
UPDATE OD
   SET discount += 0.05
FROM dbo.OrderDetails AS OD
   INNER JOIN dbo.Orders AS O
	 ON OD.orderid = O.orderid
WHERE O.custid = 1;
--LOGICAL PROCESSING: FROM->WHERE->UPDATE first joins based on a match then filters for custid 1 then updates 
--discount in SET clause

UPDATE dbo.OrderDetails--standard version
	SET discount += 0.05
WHERE EXISTS
	(SELECT * FROM dbo.Orders AS O
	WHERE O.orderid = OrderDetails.orderid
	  AND O.custid = 1
	);

UPDATE T1
   SET col1 = T2.col1,
       col2 = T2.col2,
	   col3 = T2.col3
FROM dbo.T1 JOIN dbo.T2
  ON T2.Keycol = T1.Keycol
WHERE T2.col4 = 'ABC';

UPDATE dbo.T1
SET col1 = (SELECT col1
			FROM dbo.T2
			WHERE T2.keycol = T1.keycol),
	col2 = (SELECT col2
			FROM dbo.T2
			WHERE T2.keycol = T1.keycol),
	col3 = (SELECT col3
			FROM dbo.T2
			WHERE T2.keycol = T1.keycol)
WHERE EXISTS
	(SELECT *
	FROM dbo.T2
	WHERE T2.keycol = T1.keycol
		AND T2.col4 = 'ABC');
/*Standard SQL has support for row constructors (also known as vector expressions) that
were only implemented partially in T-SQL. As of SQL Server 2016, many aspects of row
constructors have not yet been implemented, including the ability to use them in the SET
clause of an UPDATE statement like this:*/

UPDATE dbo.T1
 SET(col1, col2, col3) = 
   (SELECT col1, col2, col3
   FROM dbo.T2
   WHERE T2.keycol = T1.keycol)
WHERE EXISTS
(SELECT *
FROM dbo.T2
WHERE T2.keycol = T1.keycol
AND T2.col4 = 'ABC');

--Assignment UPDATE
DROP TABLE IF EXISTS dbo.MySequences;
CREATE TABLE dbo.MySequences
(
	id VARCHAR(10) NOT NULL
	CONSTRAINT PK_MySequences PRIMARY KEY(id),
	val INT NOT NULL
);
INSERT INTO dbo.MySequences VALUES('SEQ1', 0);
select * from dbo.MySequences

DECLARE @nextval AS INT;
UPDATE dbo.MySequences
SET @nextval = val += 1
WHERE id = 'SEQ1';
SELECT @nextval;
DROP TABLE IF EXISTS dbo.MySequences;

--Merging data
DROP TABLE IF EXISTS dbo.Customers, dbo.CustomersStage;
GO
CREATE TABLE dbo.Customers
(
custid INT NOT NULL,
companyname VARCHAR(25) NOT NULL,
phone VARCHAR(20) NOT NULL,
address VARCHAR(50) NOT NULL,
CONSTRAINT PK_Customers PRIMARY KEY(custid)
);
INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
(1, 'cust 1', '(111) 111-1111', 'address 1'),
(2, 'cust 2', '(222) 222-2222', 'address 2'),
(3, 'cust 3', '(333) 333-3333', 'address 3'),
(4, 'cust 4', '(444) 444-4444', 'address 4'),
(5, 'cust 5', '(555) 555-5555', 'address 5');
CREATE TABLE dbo.CustomersStage
(
custid INT NOT NULL,
companyname VARCHAR(25) NOT NULL,
phone VARCHAR(20) NOT NULL,
address VARCHAR(50) NOT NULL,
CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);
INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
(2, 'AAAAA', '(222) 222-2222', 'address 2'),
(3, 'cust 3', '(333) 333-3333', 'address 3'),
(5, 'BBBBB', 'CCCCC', 'DDDDD'),
(6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
(7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

SELECT * FROM dbo.Customers;
SELECT * FROM dbo.CustomersStage;

MERGE INTO dbo.Customers AS TGT--target table
USING dbo.CustomersStage AS SRC--source table
   ON TGT.custid = SRC.custid--predicate
WHEN MATCHED THEN -- --what action to take against the against the target when source is not matched by target row
	  UPDATE SET
      TGT.companyname = SRC.companyname,
	  TGT.phone = SRC.phone,
	  TGT.address = SRC.address
WHEN NOT MATCHED THEN
INSERT (custid, companyname, phone, address)
VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);--mandatory to terminate with the semicolon for MERGE 
SELECT * FROM dbo.Customers;

--T-SQL also supports a third clause that defines what action to take when a target row is not matched by a source row;
--this clause is called WHEN NOT MATCHED BY SOURCE.

/*For example, suppose you want to
add logic to the MERGE example to delete rows from the target when there’s no matching
source row. To achieve this, add the WHEN NOT MATCHED BY SOURCE clause with a
DELETE action, like this:*/
MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
	 TGT.companyname = SRC.companyname,
     TGT.phone = SRC.phone,
	 TGT.address = SRC.address
WHEN NOT MATCHED THEN
   INSERT (custid, companyname, phone, address)
   VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN 
DELETE;

SELECT * FROM dbo.Customers;

MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED AND
			( TGT.companyname <> SRC.companyname
			OR TGT.phone <> SRC.phone
			OR TGT.address <> SRC.address) THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);

UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	INNER JOIN dbo.Orders AS O
		ON OD.orderid = O.orderid
WHERE O.custid = 1;
--MODIFYING THRU TABLE EXPRESSION
WITH C AS
(
	SELECT custid, OD.orderid,
		productid, discount, discount+0.05 AS newdiscount
	FROM dbo.OrderDetails AS OD
		INNER JOIN dbo.Orders AS O
		  ON OD. orderid = O.orderid
    WHERE O.custid =1
)
UPDATE C
  SET discount = newdiscount;
--USING DERIVED Table
UPDATE D
  SET discount = newdiscount
FROM ( SELECT custid, OD.orderid,
         productid, discount, discount + 0.05 AS newdiscount
       FROM dbo.OrderDetails AS OD
         INNER JOIN dbo.Orders AS O
           ON OD.orderid = O.orderid
       WHERE O.custid = 1 ) AS D;


DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT, col2 INT);
GO
INSERT INTO dbo.T1(col1) VALUES(20),(10),(30);
SELECT * FROM dbo.T1;

--Suppose you want to update the table, setting col2 to the result of an expression with the
--ROW_NUMBER function. The problem is that the ROW_NUMBER function is not allowed in
--the SET clause of an UPDATE statement. Try running the following code:
UPDATE dbo.T1
SET col2 = ROW_NUMBER() OVER(ORDER BY col1);--set not in row number

WITH C AS
(
	SELECT col1, col2, ROW_NUMBER() OVER(ORDER BY col1) AS rownum
	FROM dbo.T1
) 
UPDATE C
SET col2 = rownum;
SELECT * FROM dbo.T1;

--Modifications with TOP and OFFSET-FETCH
/*Unfortunately, unlike with the SELECT statement, you cannot specify an ORDER BY clause for
the TOP filter in modification statements. Essentially, whichever rows SQL Server happens to
access first will be modified.*/
--The OFFSET-FETCH filter is not allowed directly in modifications because this filter
--requires an ORDER BY clause and modification statements don’t support one.

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL,
	requireddate DATE NOT NULL,
	shippeddate DATE NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;

DELETE TOP(50) FROM dbo.Orders;
--Because the statement doesn’t have an ORDER BY clause, it deletes whichever 50 rows it
--stumbles into first. Which rows get chosen is a result of physical data layout and optimization
--choices.
UPDATE TOP(50) dbo.Orders
SET freight += 10.00;--only updates top 50 based on the layout and optimation choices

--Thats why we use Table Expression

WITH C AS
(
	SELECT TOP (50) *
	FROM dbo.Orders
	ORDER BY orderid
)
DELETE FROM C;

WITH C AS
(
	SELECT TOP (50) *
	FROM dbo.Orders
	ORDER BY orderid DESC
) 
UPDATE C
SET freight += 10.00;

--Similarly OFFSET FETCH
WITH C AS
(
	SELECT *
	FROM dbo.Orders
	ORDER BY orderid
	OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
) 
DELETE FROM C;

WITH C AS
(
	SELECT *
	FROM dbo.Orders
	ORDER BY orderid DESC
	OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
) 
UPDATE C
SET freight += 10.00;

--THE OUTPUT CLAUSE
--INSERT WITH OUTPUT

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1
(
	keycol INT NOT NULL IDENTITY(1, 1) CONSTRAINT PK_T1 PRIMARY KEY,
	datacol NVARCHAR(40) NOT NULL
);
/*Suppose you want to insert into T1 the result of a query against the HR.Employees table and
return all newly generated identity values. To achieve this, add the OUTPUT clause to the
INSERT statement and specify the attributes you want to return:*/

INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol--return all newly generated identity values:does two statement once
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'USA';

/*As mentioned, you can also direct the result set into a table. The table can be a real table,
temporary table, or table variable. When the result set is stored in the target table, you can
manipulate the data by querying that table. For example, the following code declares a table
variable called @NewRows, inserts another result set into T1, and directs the result set
returned by the OUTPUT clause into the table variable. The code then queries the table
variable just to show the data that was stored in it:*/

DECLARE @NewRows TABLE(keycol INT, datacol NVARCHAR(40));
INSERT INTO dbo.T1(datacol)
	OUTPUT inserted.keycol, inserted.datacol--inserts first to the T1 and output to the variale then insert var 
	--to the table var
	INTO @NewRows(keycol, datacol)
		SELECT lastname
		FROM HR.Employees
		WHERE country = N'UK';
SELECT * FROM @NewRows;

--DELETE with OUTPUT
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders
(
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL,
	requireddate DATE NOT NULL,
	shippeddate DATE NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
	CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
GO
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
--Deletes from the table and select the output.
DELETE FROM dbo.Orders
	OUTPUT
		deleted.orderid,
		deleted.orderdate,
		deleted.empid,
		deleted.custid
WHERE orderdate < '20160101';
--UPDATE with OUTPUT

DROP TABLE IF EXISTS dbo.OrderDetails;
CREATE TABLE dbo.OrderDetails
(
	orderid INT NOT NULL,
	productid INT NOT NULL,
	unitprice MONEY NOT NULL
	CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty SMALLINT NOT NULL
	CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount NUMERIC(4, 3) NOT NULL
	CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

--THis will get the data before the change apply and after the changes : both states
UPDATE dbo.OrderDetails
   SET discount +=0.05
OUTPUT
   inserted.orderid,
   inserted.productid,
   deleted.discount AS olddiscount,
   inserted.discount AS newdiscount
WHERE productid = 51;

--MERGE with OUTPUT
--The following code merges the contents of CustomersStage into Customers, updating the attributes
--of customers who already exist in the target and adding customers who don’t:
/*You can also use the OUTPUT clause with the MERGE statement, but remember that a single
MERGE statement can invoke multiple different DML actions. To identify which DML action
produced each output row, you can invoke a function called $action in the OUTPUT clause,
which will return a string representing the action (INSERT, UPDATE, or DELETE).*/
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
	TGT.companyname = SRC.companyname,
	TGT.phone = SRC.phone,
	TGT.address = SRC.address
WHEN NOT MATCHED THEN--when target didnt match against source
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT $action AS theaction, inserted.custid,--sction tells the action produces the output
	deleted.companyname AS oldcompanyname,
	inserted.companyname AS newcompanyname,
	deleted.phone AS oldphone,
	inserted.phone AS newphone,
	deleted.address AS oldaddress,
	inserted.address AS newaddress;

--Nested DML
DROP TABLE IF EXISTS dbo.ProductsAudit, dbo.Products;
CREATE TABLE dbo.Products
(
	productid INT NOT NULL,
	productname NVARCHAR(40) NOT NULL,
	supplierid INT NOT NULL,
	categoryid INT NOT NULL,
	unitprice MONEY NOT NULL
	CONSTRAINT DFT_Products_unitprice DEFAULT(0),
	discontinued BIT NOT NULL
	CONSTRAINT DFT_Products_discontinued DEFAULT(0),
	CONSTRAINT PK_Products PRIMARY KEY(productid),
	CONSTRAINT CHK_Products_unitprice CHECK(unitprice >= 0)
	);
	INSERT INTO dbo.Products SELECT * FROM Production.Products;
	CREATE TABLE dbo.ProductsAudit
	(
		LSN INT NOT NULL IDENTITY PRIMARY KEY,
		TS DATETIME2 NOT NULL DEFAULT(SYSDATETIME()),
		productid INT NOT NULL,
		colname SYSNAME NOT NULL,
		oldval SQL_VARIANT NOT NULL,
		newval SQL_VARIANT NOT NULL
);

--Suppose you now need to update all products supplied by supplier 1, increasing their price
--by 15 percent. You also need to audit the old and new values of updated products, but only
--those with an old price that was less than 20 and a new price that is greater than or equal to 20.

INSERT INTO dbo.ProductsAudit(productid, colname, oldval, newval)
   SELECT productid, N'unitprice', oldval, newval
   FROM (UPDATE dbo.Products
		SET unitprice *=1.15
	 OUTPUT
	    inserted.productid,
		deleted.unitprice AS oldval,
		inserted.unitprice As newval
	 WHERE supplierid = 1) AS D
  WHERE oldval<20.0 AND newval>=20.0
SELECT * FROM dbo.ProductsAudit;

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.ProductsAudit, dbo.Products,
dbo.Orders, dbo.Customers, dbo.T1, dbo.MySequences, dbo.CustomersStage;

/*Exercises
This section provides exercises so that you can practice the subjects discussed in this chapter.
The database assumed in the exercise is TSQLV4.
Exercise 1
Run the following code to create the dbo.Customers table in the TSQLV4 database:*/

USE TSQLV4
DROP TABLE IF EXISTS dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL PRIMARY KEY,
	companyname NVARCHAR(40) NOT NULL,
	country NVARCHAR(15) NOT NULL,
	region NVARCHAR(15) NULL,
	city NVARCHAR(15) NOT NULL
)

/*Exercise 1-1
Insert into the dbo.Customers table a row with the following information:
custid: 100
companyname: Coho Winery
country: USA
region: WA
city: Redmond */

INSERT INTO dbo.Customers(custid, companyname, country, region, city)
VALUES(100, N'Coho Winery',N'USA',N'WA', N'Redmond' )

/*Exercise 1-2
Insert into the dbo.Customers table all customers from Sales.Customers who placed orders.*/
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
SELECT custid, companyname, country, region, city
FROM Sales.Customers AS C
WHERE EXISTS	
  (SELECT * FROM Sales.Orders AS O
  WHERE O.custid = C.custid)

  /*Exercise 1-3
Use a SELECT INTO statement to create and populate the dbo.Orders table with orders from
the Sales.Orders table that were placed in the years 2014 through 2016.*/
USE TSQLV4;
DROP TABLE IF EXISTS dbo.Orders;

SELECT *
INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate >= '20140101'
   AND orderdate < '20170101'

/*Exercise 2
Delete from the dbo.Orders table orders that were placed before August 2014. Use the
OUTPUT clause to return the orderid and orderdate values of the deleted orders:*/

DELETE FROM dbo.Orders
   OUTPUT deleted.orderid, deleted.orderdate
WHERE orderdate <'20140801';

/*Exercise 3
Delete from the dbo.Orders table orders placed by customers from Brazil.*/

SELECT * FROM dbo.Orders
DELETE FROM dbo.Orders
WHERE EXISTS
	(SELECT * FROM dbo.Customers AS C
	WHERE Orders.custid = C.custid
		AND C.country = N'Brazil');

MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'Brazil') AS C
	ON O.custid = C.custid
WHEN MATCHED THEN DELETE;

/*Exercise 4
Run the following query against dbo.Customers, and notice that some rows have a NULL in
the region column: Update the dbo.Customers table, and change all NULL region values to <None>. Use the OUTPUT clause to show the custid, oldregion, and newregion:
*/
SELECT * FROM dbo.Customers;
UPDATE dbo.Customers
	SET region = '<None>'
OUTPUT
	deleted.custid,
	deleted.region AS oldregion,
	inserted.region AS newregion
WHERE region IS NULL

/*Exercise 5
Update all orders in the dbo.Orders table that were placed by United Kingdom customers, and set their shipcountry, shipregion, and shipcity values to the country, region, and city values of the corresponding customers.*/
UPDATE O
	SET shipcountry = C.country,
		shipregion = C.region,
		shipcity = C.city
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'UK';

WITH CTE_UPD AS
(
	SELECT 
		O.shipcountry AS ocountry, C.country AS ccountry,
		O.shipregion AS oregion, C.region as cregion,
		O.Shipcity AS ocity, c.city AS ccity
	FROM dbo.Orders AS O
		INNER JOIN dbo.Customers AS C
			ON O.custid = C.custid
	WHERE C.country = N'UK'
)
UPDATE CTE_UPD
	SET ocountry = ccountry, oregion = cregion, ocity=ccity;

MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'UK') AS C
	ON O.custid = C.custid
WHEN MATCHED THEN
	UPDATE SET shipcountry = C.country,
			   shipregion = C.region,
			   shipcity = C.city;

/*Exercise 6
Run the following code to create the tables Orders and OrderDetails and populate them with
data:*/
USE TSQLV4;
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;
CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
custid INT NULL,
empid INT NOT NULL,
orderdate DATE NOT NULL,
requireddate DATE NOT NULL,
shippeddate DATE NULL,
shipperid INT NOT NULL,
freight MONEY NOT NULL
CONSTRAINT DFT_Orders_freight DEFAULT(0),
shipname NVARCHAR(40) NOT NULL,
shipaddress NVARCHAR(60) NOT NULL,
shipcity NVARCHAR(15) NOT NULL,
shipregion NVARCHAR(15) NULL,
shippostalcode NVARCHAR(10) NULL,
shipcountry NVARCHAR(15) NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);
CREATE TABLE dbo.OrderDetails
(
orderid INT NOT NULL,
productid INT NOT NULL,
unitprice MONEY NOT NULL
CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
qty SMALLINT NOT NULL
CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
discount NUMERIC(4, 3) NOT NULL
CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
REFERENCES dbo.Orders(orderid),
CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
CONSTRAINT CHK_qty CHECK (qty > 0),
CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

/*Write and test the T-SQL code that is required to truncate both tables, and make sure your code runs successfully.When you’re done, run the following code for cleanup:*/

ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;
TRUNCATE TABLE dbo.OrderDetails;
TRUNCATE TABLE dbo.Orders;

ALTER TABLE dbo.OrderDetails ADD CONSTRAINT FK_OrderDetails_Orders
FOREIGN KEY(orderid) REFERENCES dbo.Orders(orderid);


DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders, dbo.Customers;

