
CREATE TABLE Inventory
(
	ItemID int NOT NULL PRIMARY KEY,
	ItemsInStore int NOT NULL,
	ItemsInWarehouse int NOT NULL
)
ALTER TABLE Inventory
ADD TotalItems AS SUM(ItemsInStore, ItemsInWarehouse);

SELECT * FROM Inventory
--You develop a Microsoft SQL Server 2012 database. You create a view from the Orders and OrderDetails tables by using the following definition.

--Passing Table to a store Procedure Parameter
USE MSSA;
--Create a table named Students
CREATE TABLE dbo.Students
(
	StudentID int null,
	StudentName varchar(30) NULL,
	StudentFees int NULL
)

--create a user-defined table type in SQL Server
CREATE TYPE dbo.StudentType AS TABLE
(
	StudentID int,
	StudentName varchar(30),
	StudentFees int
);

--ceating a stored procedure in SQL Server
CREATE PROCEDURE dbo.StudentDetailProcedure
	@StudentDetail dbo.StudentType READONLY
	AS 
	BEGIN
		SET NOCOUNT ON
		INSERT INTO dbo.Students(studentID, studentName, StudentFees)
		SELECT studentID, StudentName, StudentFees FROM @StudentDetail

	END

--USing an Exec Command to Execute the Stored Procedure
DECLARE @StudentVariable AS StudentType
INSERT INTO @StudentVariable(StudentID,StudentName, StudentFees)
VALUES(1,'Smith','20000')

EXEC dbo.StudentDetailProcedure @StudentVariable

SELECT StudentID, StudentName, StudentFees
FROM dbo.Students;

--SCALAR UDF
USE TSQLV4;
IF OBJECT_ID('Sales.fn_extension', 'FN') IS NOT NULL
DROP FUNCTION Sales.fn_extension
GO
CREATE FUNCTION Sales.fn_extension
(
	@unitprice AS MONEY,
	@qty AS INT
)
RETURNS MONEY
AS
BEGIN
RETURN @unitprice * @qty
END;
GO

SELECT orderid, unitprice, qty, Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails;

--verify that the stored procedure does not already exist
IF OBJECT_ID('usp_GetErrorInfo', 'P') IS NOT NULL
	DROP PROCEDURE('usp_GetErrorInfo')
GO
--Create procedure to retrieve error information
CREATE PROCEDURE usp_GetErrorInfo
AS
SELECT	
	ERROR_NUMBER() AS ErrorNumber
	,ERROR_SEVERITY() AS ErrorSeverity
	,ERROR_STATE() AS ErrorState
	,ERROR_PROCEDURE() AS ErrorProcedure
	,ERROR_LINE() AS ErrorLine
	,ERROR_MESSAGE() AS ErrorMessage;
GO
BEGIN TRY
	--Generate divide-by-zero error
	SELECT 1/0;
END TRY
BEGIN CATCH
	--Execute error retrieval routine
	EXECUTE usp_GetErrorInfo
END CATCH;

--INDEX
CREATE TABLE dbo.TestStructure
(
	id INT NOT NULL,
	filler1 CHAR(36) NOT NULL,
	filler2 CHAR(216) NOT NULL
)
--The type column stores a value of 0 for heaps, 1 for clustered tables (indexes), and 2 for nonclustered indexes. 
USE MSSA;
SELECT OBJECT_NAME(object_id) AS table_name,
	name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');

SELECT index_type_desc, page_count,
	record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(N'tempdb'), 
				OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');

EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;

INSERT INTO dbo.TestStructure (id, filler1, filler2)
VALUES (1, 'a', 'b');

DECLARE @i AS int = 1;
WHILE @i < 30
BEGIN
	SET @i = @i + 1;
INSERT INTO dbo.TestStructure(id, filler1, filler2)
VALUES(@i, 'a', 'b');
END;

INSERT INTO dbo.TestStructure(id, filler1, filler2)
VALUES(31, 'a', 'b');

--clustered index
TRUNCATE TABLE dbo.TestStructure;
CREATE CLUSTERED INDEX idx_cl_id ON dbo.TestStructure(id);

SELECT OBJECT_NAME(object_id) AS table_name,
name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');

DECLARE @i AS int = 0;
WHILE @i < 18630
  BEGIN
	SET @i = @i + 1;
	INSERT INTO dbo.TestStructure(id, filler1, filler2)
	VALUES(@i, 'a', 'b');
  END;

SELECT index_type_desc, index_depth, index_level, page_count,
	record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(N'tempdb'), 
		OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');

--UDF(user defined function)
--1. Scalar UDF
--2. Table Valued Function(A TVF with a single line of code called Inline TVF UDF)
--Scalar
CREATE FUNCTION dbo.FunctionName
(
	@param1 int,
	@param2 int 
)
RETURNS INT
AS
BEGIN
	RETURN @param1 + @param2
END
--TVF : Returns table instead a single value
--INLINE TVF: Contains a single SELECT code
--Similar to view; can think of it as parametarized view
--no begin and end block
USE TSQL;
IF OBJECT_ID('Sales.fn_FilteredExtension','IF') IS NOT NULL
	DROP FUNCTION Sales.fn_FilteredExtension;
GO 
CREATE FUNCTION Sales.fn_FilteredExtension
(
	@lowqty AS SMALLINT,
	@highqty AS SMALLINT
)
RETURNS TABLE AS RETURN
(
	SELECT orderid, unitprice, qty 
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty and @highqty
);
SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension(10,20);

--Multistatement Table-Valued UDF
--In a table-valued UDF, you must define the table to be returned as
--a table variable and insert data into the table variable. The RETURN statement just --ends the function and is not used to send any data back to the caller.
IF OBJECT_ID('Sales.fn_FilteredExtension2', 'TF') IS NOT NULL
	DROP FUNCTION Sales.fn_FilteredExtension2;
CREATE FUNCTION Sales.fn_FilteredExtension2
(
	@lowqty AS SMALLINT,
	@highqty AS SMALLINT
)
RETURNS @returntable TABLE
(
	orderid INT,
	unitprice MONEY,
	qty SMALLINT
)
AS 
BEGIN
	INSERT @returntable
		SELECT orderid, unitprice, qty
		FROM Sales.OrderDetails
		WHERE qty BETWEEN @lowqty AND @highqty
	RETURN 
END;

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension2(10,20);

--STORED PROCEDURE
--Stored procedures take parameters that have a syntax very similar to the DECLARE syntax for variables. Take a look at the CREATE PROCEDURE statement.
--if parameter not inilialized then it is a required parameter
--OUTPUT parameter is an optional parameter
--AS command is requiredd after the list of the parameter
--BEGIN/END is not required
IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
	DROP PROC Sales.GetCustomerOrders;
GO
CREATE PROC Sales.GetCustomerOrders
	@custid AS INT,
	@orderdatefrom AS DATETIME = '19000101',
	@orderdateto AS DATETIME = '99991231',
	@numrows AS INT = 0 OUTPUT
AS 
BEGIN
	SET NOCOUNT ON;
	SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
	FROM Sales.Orders
	WHERE custid = @custid
		AND orderdate >= @orderdatefrom
		AND orderdate < @orderdateto;
	SET @numrows = @@ROWCOUNT;
	RETURN; 
END
GO
--you can pass variable in any order by using a variable name
DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
@custid = 37,
@orderdatefrom = '20070401',
@orderdateto = '20070701',
@numrows = @rowsreturned OUTPUT;

SELECT @rowsreturned AS "Rows Returned"
GO
--you can ignore the optional OUTPUT parameter(it should be optional means already initialized)
EXEC Sales.GetCustomerOrders 37, '20070401', '20070701';

--Return multiple results
IF OBJECT_ID('Sales.ListSampleResultsSets', 'P') IS NOT NULL
DROP PROC Sales.ListSampleResultsSets;
GO
CREATE PROC Sales.ListSampleResultsSets
AS
BEGIN
	SELECT TOP (1) productid, productname, supplierid,
		categoryid, unitprice, discontinued
	FROM Production.Products;
	SELECT TOP (1) orderid, productid, unitprice, qty, discount
	FROM Sales.OrderDetails;
END
GO
EXEC Sales.ListSampleResultsSets

--Statistics(in some cases you can improve performance by using UPDATE STATiSICS)
USE AdventureWorks;  
GO  
UPDATE STATISTICS Sales.SalesOrderDetail;  
GO  

SELECT CONVERT(DATE, GETDATE()); --2018-05-27
SELECT  DATEADD(DAY, 1, CONVERT(DATE, GETDATE()));
SELECT GETDATE();--2018-05-27 16:11:26.230
 SELECT CONVERT(VARCHAR, GETDATE(), 112);--20180527

 --FORMAT
 DECLARE @d DATETIME = '10/01/2011';
SELECT FORMAT ( @d, 'd', 'en-US' ) AS 'US English Result'  
      ,FORMAT ( @d, 'd', 'en-gb' ) AS 'Great Britain English Result'  
      ,FORMAT ( @d, 'd', 'de-de' ) AS 'German Result'  
      ,FORMAT ( @d, 'd', 'zh-cn' ) AS 'Simplified Chinese (PRC) Result';   

SELECT FORMAT ( @d, 'D', 'en-US' ) AS 'US English Result'  
      ,FORMAT ( @d, 'D', 'en-gb' ) AS 'Great Britain English Result'  
      ,FORMAT ( @d, 'D', 'de-de' ) AS 'German Result'  
      ,FORMAT ( @d, 'D', 'zh-cn' ) AS 'Chinese (Simplified PRC) Result';  

USE MSSA;
CREATE TABLE employees
( employee_id INT PRIMARY KEY,
  --employee_id INT,
  last_name VARCHAR(50) NOT NULL,
  first_name VARCHAR(50),
  salary MONEY,
  --CONSTRAINT PK_EMP PRIMARY KEY (employee_id)
);
DROP TABLE dbo.employees

--TRIGGER: DML triggers execute when a user tries to modify data through a data manipulation language (DML) event. DML events are INSERT, UPDATE, or DELETE statements on a table or view.

USE AdventureWorks;
-- Trigger valid for multirow and single row inserts  
-- and optimal for single row inserts.  
USE AdventureWorks;  
GO  
CREATE TRIGGER NewPODetail3  
ON Purchasing.PurchaseOrderDetail  
FOR INSERT AS  
IF @@ROWCOUNT = 1  
BEGIN  
   UPDATE Purchasing.PurchaseOrderHeader  
   SET SubTotal = SubTotal + LineTotal  
   FROM inserted  
   WHERE PurchaseOrderHeader.PurchaseOrderID = inserted.PurchaseOrderID  

END  
ELSE  
BEGIN  
      UPDATE Purchasing.PurchaseOrderHeader  
   SET SubTotal = SubTotal +   
      (SELECT SUM(LineTotal)  
      FROM inserted  
      WHERE PurchaseOrderHeader.PurchaseOrderID  
       = inserted.PurchaseOrderID)  
   WHERE PurchaseOrderHeader.PurchaseOrderID IN  
      (SELECT PurchaseOrderID FROM inserted)  
END; 


USE AdventureWorks;
GO
IF OBJECT_ID ('Purchasing.LowCredit','TR') IS NOT NULL
   DROP TRIGGER Purchasing.LowCredit;
GO
-- This trigger prevents a row from being inserted in the Purchasing.PurchaseOrderHeader table
-- when the credit rating of the specified vendor is set to 5 (below average).

CREATE TRIGGER Purchasing.LowCredit ON Purchasing.PurchaseOrderHeader
AFTER INSERT
AS
IF EXISTS (SELECT *
           FROM Purchasing.PurchaseOrderHeader p 
           JOIN inserted AS i 
           ON p.PurchaseOrderID = i.PurchaseOrderID 
           JOIN Purchasing.Vendor AS v 
           ON v.BusinessEntityID = p.VendorID
           WHERE v.CreditRating = 5
          )
BEGIN
RAISERROR ('A vendor''s credit rating is too low to accept new
purchase orders.', 16, 1);
ROLLBACK TRANSACTION;
RETURN 
END;
GO

-- This statement attempts to insert a row into the PurchaseOrderHeader table
-- for a vendor that has a below average credit rating.
-- The AFTER INSERT trigger is fired and the INSERT transaction is rolled back.

INSERT INTO Purchasing.PurchaseOrderHeader (RevisionNumber, Status, EmployeeID,
VendorID, ShipMethodID, OrderDate, ShipDate, SubTotal, TaxAmt, Freight)
VALUES (
2
,3
,261	
,1652	
,4	
,GETDATE()
,GETDATE()
,44594.55	
,3567.564	
,1114.8638 );
GO

SELECT * FROM INSERTED -- show data in Inserted logical table

--LAG(previous without the need of join)
USE AdventureWorks;
GO
SELECT TerritoryName, BusinessEntityID, SalesYTD,
	   LAG(SalesYTD, 1,0) OVER (PARTITION BY TerritoryName ORDER BY SalesYTD) 
	   AS PrevRepSales
FROM Sales.vSalesPerson
WHERE TerritoryName IN(N'Northwest',N'Canada')
ORDER BY TerritoryName;

--SOME, ANY, ALL
USE NORTHWIND;
SELECT ProductName
FROM Products
WHERE ProductID = ANY(SELECT ProductID
					  FROM [Order Details] 
					  WHERE Quantity = 10)

SELECT ProductName
FROM Products
WHERE ProductID = ALL(SELECT ProductID 
					  FROM [Order Details] 
                      WHERE Quantity = 10)
--GROUPING SET
USE MSSA;
CREATE TABLE tbl_Employee
(
	Employee_Name varchar (25),
	Region varchar(50),
	Department varchar(50),
	sal int
)
INSERT into tbl_Employee( 
                              Employee_Name, 
                              Region, 
                              Department, 
                              sal 
                        ) 

VALUES 

('Shujaat', 'North America', 'Information Technology', 9999), 
('Andrew', 'Asia Pacific', 'Information Technology',  5555), 
('Maria', 'North America', 'Human Resources', 4444), 
('Stephen', 'Middle East & Africa', 'Information Technology', 8888), 
('Stephen', 'Middle East & Africa', 'Human Resources', 8888)

SELECT * FROM tbl_Employee;

SELECT Region, Department, avg(sal) Average_Salary
FROM tbl_Employee
GROUP BY 
	GROUPING SETS
	(
		(Region, Department), --average by the group
		(Region),	--Department null; average by region
		(Department),--Region null; average by Department
		()		--Total average by of the table
	)

--ROLLUP subclause for grouping
SELECT Region, Department, avg(sal) Average_salary
FROM tbl_Employee
GROUP BY
	ROLLUP(Region, Department) 

--which is equivalent to 
SELECT Region, Department, avg(sal) Average_Salary 
from tbl_Employee 

Group BY 
      Grouping Sets 
      ( 
            (Region, Department), --n+1 of grouping set
            (Region), 
            () 
      )

--CUBE subclause for grouping

SELECT Region, Department, avg(sal) Average_Salary
FROM tbl_Employee
GROUP BY 
	CUBE(Region, Department);

-- which is equivalent to 
SELECT Region, Department, avg(sal) Average_Salary 
from tbl_Employee 
GROUP BY
	  GROUPING SETS 
      ( 
            (Region, Department), 
            (Region), 
            (Department) , 
            ()          
      )

--Table Expression
--1. Derived Tables 2. Common Table Expression(CTEs) 3. Views 4. Inline table-valued fn
--DERiVED TABLE
--You define the derived table’s inner query in parentheses in the FROM clause of the --outer query, and specify the name of the derived table after the parentheses.
USE TSQL;
--window function only allowed in SELECT and ORDERBY
SELECT ROW_NUMBER() OVER(PARTITION BY categoryid
						 ORDER BY unitprice, productid) AS rownum,
		categoryid, productid, productname, unitprice
FROM Production.Products

SELECT categoryid, productid, productname, unitprice
FROM(SELECT 
		ROW_NUMBER() OVER(PARTITION BY categoryid
						  ORDER BY unitprice, productid) AS rownum,
	     categoryid, productid, productname, unitprice	
		FROM Production.Products)AS D
WHERE rownum <=2;

--CTE(Common Table Expression)
WITH C 
AS
(
	SELECT
		ROW_NUMBER() OVER (PARTITION BY categoryid
						   ORDER BY unitprice, productid) AS rownum,
		categoryid, productid, productname, unitprice
	FROM Production.Products
)

SELECT categoryid, productid, productname, unitprice
FROM C
WHERE rownum <= 2;

--As an example, the following code uses a recursive CTE to return the management chain
--leading all the way up to the CEO for a specified employee.
WITH EmpsCTE AS
(
	SELECT empid, mgrid, firstname, lastname, 0 AS distance
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL

	SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance +1 AS distance
	FROM EmpsCTE AS S
		JOIN HR.Employees AS M
			ON S.mgrid = M.empid
)
SELECt empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;

USE TSQL;

--Querying and Managing XML Data
USE TSQL;
SELECT Customer.custid, Customer.companyname,
	[Order].orderid, [Order].orderdate
FROM Sales.Customers AS Customer
	INNER JOIN Sales.Orders AS [Order]
		ON Customer.custid = [Order].custid
ORDER BY Customer.custid,[Order].orderid
FOR XML AUTO;
--FOR XML AUTO, ELEMENTS;
--FOR XML RAW;
--FOR XML RAW, ELEMENTS;
--FOR XML PATH('Customers')

/*Improve the XML created with the previous query by changing from RAW to AUTO
mode. Make the result element-centric by using TK461-CustomersOrders as the
namespace and CustomersOrders as the root element. You can use the following code.*/

WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid],
	[co:Customer].companyname AS [co:companyname],
	[co:Order].orderid AS [co:orderid],
	[co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
   INNER JOIN Sales.Orders AS [co:Order]
      ON [co:Customer].custid = [co:Order].custid
ORDER BY [co:Customer].custid,[co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');

--
USE MSSA;
CREATE TABLE ProductCatalog
(
	CatID INT,
	CatName VARCHAR(100),
	ProductID INT,
	ProductName VARCHAR(100),
	UnitPrice DECIMAL(7,2)
)
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(1,'CatOne',10,'Prod10',1.11);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(2,'CatTwo',20,'Prod20',2.22);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(3,'CatThree',30,'Prod30',3.33);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(4,'CatFour',40,'Prod40',4.44);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(5,'CatFive',50,'Prod50',5.55);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(6,'CatSix',60,'Prod60',6.66);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(7,'CatSeven',70,'Prod70',7.77);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(8,'CatEight',80,'Prod80',8.88);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(9,'CatNine',90,'Prod90',9.99);
INSERT INTO ProductCatalog (CatID,CatName,ProductID,ProductName,UnitPrice)
VALUES(31,'CatThreeA',31,'Prod31',3.33);

SELECT * FROM ProductCatalog;
SELECT ProductCatalog.CatID,ProductCatalog.CatName,ProductCatalog.ProductID
	   ,ProductCatalog.ProductName,ProductCatalog.UnitPrice
	   ,Rank() OVER(ORDER BY ProductCatalog.UnitPrice DESC ) AS PriceRank
	   ,ROW_NUMBER()OVER( ORDER BY ProductCatalog.UnitPrice DESC) AS RowNum
	   ,DENSE_RANK()OVER(ORDER BY ProductCatalog.UnitPrice DESC) AS DenseRank
	   ,NTILE(2)OVER(ORDER BY ProductCatalog.UnitPrice DESC) AS Half
FROM ProductCatalog
ORDER BY  ProductCatalog.UnitPrice DESC

--WRITE IN UPDATE STATEMENT
CREATE TABLE BlogEntry
(
	Id BIGINT,
	EntryDateTime DATETIME,
	Summary NVARCHAR(MAX)
)
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(1,GETDATE()-11,'One');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(2,GETDATE()-10,'Two');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(3,GETDATE()-9,'Three');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(4,GETDATE()-8,'Four');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(5,GETDATE()-7,'Five');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(6,GETDATE()-6,'Six');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(7,GETDATE()-5,'Seven');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(8,GETDATE()-4,'Eight');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(9,GETDATE()-3,'Nine');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(10,GETDATE()-2,'Ten');
INSERT INTO BlogEntry(Id,EntryDateTime,Summary)
VALUES(11,GETDATE()-1,'Eleven');

SELECT * FROM BlogEntry;

UPDATE BlogEntry
	SET Summary.WRITE(N'This is in draft stage',NULL,0) 
	FROM (SELECT TOP(10) Id FROM BlogEntry
		  ORDER BY EntryDateTime DESC) AS s
WHERE BlogEntry.Id = s.Id;

--TRY_PARSE
SELECT IIF(TRY_PARSE('01/01/2011' AS datetime2) IS NULL, 'True','False') AS RESULT;

DECLARE @var as decimal;
set @var = 12;
SELECT 
	IIF(TRY_PARSE(@var AS decimal(36,9))IS NULL, 'True','False') AS BadCast

DECLARE @fakeDate AS VARCHAR(10);   
SET @fakeDate = 'iamnotadate';  
SELECT TRY_PARSE(@fakeDate AS DATE); 

DECLARE @var1 AS varchar;
SET @var1 = 12;
SELECT TRY_PARSE(@var1 AS DECIMAL)

--Controlling the XML output
--RAW,AUTO,EXPLICIT,PATH
USE TSQL
SELECT orderid,custid, orderdate FROM Sales.Orders
--If we want the resultset to be XML, we add the FOR XML AUTO statement:
SELECT orderid,custid, orderdate FROM Sales.Orders FOR XML AUTO
--above sql Produces Fields as attributes, and table as elements

-- Most of the time, you will want them as elements. To do this, you add the ELEMENTS parameter:
SELECT orderid,custid, orderdate FROM Sales.Orders FOR XML AUTO,ELEMENTS

--INSTEAD OF TRIGGERS
USE MSSA;

-- Create simple base table
CREATE TABLE dbo.Ari_People_Tbl
   (
    PersonID         INT IDENTITY(1,1) NOT FOR REPLICATION PRIMARY KEY,
    PersonName        nvarchar(100) UNIQUE,
    PersonAddress     nvarchar(100),
    PersonBirthdate   datetime
   )
GO
 
-- Create simple table with FOREIGN KEY
CREATE TABLE dbo.Ari_Employees_Tbl
   (
    EmployeeID       INT IDENTITY PRIMARY KEY,
    PersonID         INT UNIQUE,
    Department       nvarchar(100),
    Salary           money,
    CONSTRAINT Employee_People_fk FOREIGN KEY (PersonID) REFERENCES Ari_People_Tbl (PersonID)
   )
GO
 
-- create simple view from one table
CREATE VIEW dbo.Ari_People_v AS
SELECT
    P.PersonID, P.PersonName, P.PersonBirthdate, P.PersonAddress
FROM Ari_People_Tbl P
GO
 
-- Create complex view based on several tables
CREATE VIEW dbo.Ari_Employees_v AS
SELECT
    P.PersonID, P.PersonName, P.PersonBirthdate, P.PersonAddress,
    E.EmployeeID, E.Department, E.Salary
FROM dbo.Ari_Employees_Tbl E
left join dbo.Ari_People_Tbl P on E.PersonID = P.PersonID
GO

-- Create INSTEAD of trigger on table
CREATE TRIGGER dbo.Ari_People_ioTrig 
	ON dbo.Ari_People_Tbl
	INSTEAD OF INSERT 
AS
BEGIN
    SET NOCOUNT ON
    -- Here we can impliment any logic that we need to execute INSTEAD of the insert stetement
    -- In this example we just print information and do the simple insert statement
    declare @C NVARCHAR(10) = CONVERT(NVARCHAR(10), (select count(*) from inserted))
    Print 'Trigger Ari_People_ioTrig: Insert started, trying to insert ' + @C
    insert dbo.Ari_People_Tbl (PersonName, PersonAddress, PersonBirthdate) 
    select I.PersonName, I.PersonAddress, I.PersonBirthdate
    from inserted I
END
GO
 
-- Create INSTEAD of trigger on view
CREATE TRIGGER dbo.Ari_People_v_ioTrig ON dbo.Ari_People_v
INSTEAD OF INSERT AS BEGIN
    SET NOCOUNT ON
    -- Here we can impliment any logic that we need to execute INSTEAD of the insert stetement
    -- In this example we just print information and do the simple insert statement
    declare @C NVARCHAR(10) = CONVERT(NVARCHAR(10), (select count(*) from inserted))
    Print 'Trigger Ari_People_v_ioTrig: Insert started, trying to insert ' + @C
     
    insert dbo.Ari_People_Tbl (PersonName, PersonAddress, PersonBirthdate) 
    select I.PersonName, I.PersonAddress, I.PersonBirthdate
    from inserted I
END

-- Test 01: insert one row to table
insert dbo.Ari_People_Tbl (PersonName, PersonAddress, PersonBirthdate)
values ('Ronen', 'Israel', '2014-02-27')
GO
/*************************************************************** Output:
 Trigger Ari_People_ioTrig: Insert started, trying to insert 1
 (1 row(s) affected)
*/
 
SELECT * from dbo.Ari_People_Tbl
GO
/*************************************************************** Result:
PersonID    PersonName    PersonAddress   PersonBirthdate
----------- -----------   -------------- -----------------------
1           Ronen         Israel         2014-02-27 00:00:00.000
(1 row(s) affected)
*/

-- Test 02: insert one row to view
insert dbo.Ari_People_v (PersonName, PersonAddress, PersonBirthdate)
values ('Ariely', 'Israel', '2014-02-27')
GO
/*************************************************************** Result:
Trigger Ari_People_ioTrig: Insert started, trying to insert 1
Trigger Ari_People_ioTrig: Insert started, trying to insert 1
(1 row(s) affected)
*/
SELECT * from dbo.Ari_People_Tbl
GO
/*************************************************************** Result:
PersonID    PersonName  PersonAddress  PersonBirthdate
----------- ----------- -------------- -----------------------
1           Ronen       Israel         2014-02-27 00:00:00.000
2           Ariely      Israel         2014-02-27 00:00:00.000
(2 row(s) affected)
*/

--SOME EXAMPLE
create table Employee
(
	ID int primary key,
	Name varchar(20),
	Salary float,
	Department varchar(20)
)
create table Logs
(
	Activity varchar(20),
	Activity_date datetime
) 
--AFTER trigger(only insert log table after the main table is inserted)
CREATE TRIGGER trigger_example ON Employee 
AFTER INSERT
AS 
Insert into Logs values('Data is inserted',getdate())

Insert into Employee values(1,'Rahul',20000,'Finance')

select * from Employee
select * from Logs

DELETE from EMPLOYEE
DELETE from logs
drop trigger trigger_example

--INSTEAD OF TRigger
Alter TRIGGER trigger_example ON Employee 
Instead of INSERT
AS 
Insert into Logs values('Data is inserted',getdate())

Insert into Employee values(2,'Bansal',10000,'IT')
select * from Employee
select * from Logs

--inserted table
Alter TRIGGER trigger_example ON Employee 
After INSERT
AS 
begin 
	Insert into Employee select * from inserted
	Insert into Logs values('Data is inserted',getdate()) 
End

-- Inserting the new data will generate an error because the action query will fire and wants to insert the data whereas the "inserted" virtual table also wants to insert the same row.
Insert into Employee values(3,'ABC',50000,'IT')
select * from Employee
select * from Logs

--If I create an instead of trigger using the "inserted" virtual table then the data will be inserted.
Alter TRIGGER trigger_example ON Employee 
INSTEAD OF INSERT
AS 
BEGIN 
	INSERT INTO Employee SELECT * FROM inserted
	INSERT INTO Logs VALUES('Data is inserted',getdate()) 
END

Insert into Employee values(3,'ABC',50000,'IT')
select * from Employee
select * from Logs

--INDEXED VIEW: We can use this Indexed views while writing query with a complex join on large amount of data. There will be good performance while retrieving the data because it exists on the disk and joins and aggregations are already defined in advance of running the query.
USE AdventureWorks;
SELECT  CUST.CustomerID ,
        PER.FirstName ,
        PER.LastName ,
        SOH.SalesOrderID ,
        SOH.OrderDate ,
        SOH.[Status] ,
        SOD.ProductID ,
        PROD.Name ,
        SOD.OrderQty
FROM    Sales.SalesOrderHeader SOH
        INNER JOIN Sales.SalesOrderDetail SOD 
               ON SOH.SalesOrderID = SOD.SalesOrderID
        INNER JOIN Production.Product PROD
               ON PROD.ProductID = SOD.ProductID
        INNER JOIN Sales.Customer CUST
               ON SOH.CustomerID = CUST.CustomerID
        INNER JOIN Person.Person PER
               ON PER.BusinessEntityID = CUST.PersonID;

CREATE VIEW Sales.vCustomerOrders
WITH SCHEMABINDING
AS
	SELECT  CUST.CustomerID ,
        PER.FirstName ,
        PER.LastName ,
        SOH.SalesOrderID ,
        SOH.OrderDate ,
        SOH.[Status] ,
        SOD.ProductID ,
        PROD.Name ,
        SOD.OrderQty
FROM    Sales.SalesOrderHeader SOH
        INNER JOIN Sales.SalesOrderDetail SOD 
               ON SOH.SalesOrderID = SOD.SalesOrderID
        INNER JOIN Production.Product PROD
               ON PROD.ProductID = SOD.ProductID
        INNER JOIN Sales.Customer CUST
               ON SOH.CustomerID = CUST.CustomerID
        INNER JOIN Person.Person PER
               ON PER.BusinessEntityID = CUST.PersonID;

SELECT  CustomerID ,
        FirstName ,
        LastName ,
        SalesOrderID ,
        OrderDate ,
        Status ,
        ProductID ,
        Name ,
        OrderQty
FROM    Sales.vCustomerOrders CO; 

--Simple view has the same execution plan as the select statement 
--In order to turn our normal Sales.vCustomerOrders view into an indexed view, we need to add a unique clustered index
CREATE UNIQUE CLUSTERED INDEX CIX_vCustomerOrders
	ON Sales.vCustomerOrders(CustomerID, SalesOrderID, ProductID);

--When we add a unique clustered index to a view, we ‘materialize’ it. In other words, the ‘virtual table’ persists to disk, with its own page structure, and we can treat it just like a normal table. 

SELECT  CUST.CustomerID ,
        SOH.SalesOrderID ,
        SOH.OrderDate ,
        SOD.ProductID ,
        PROD.Name ,
        SUM(SOD.OrderQty) AS TotalSpent
FROM    Sales.SalesOrderHeader SOH
        INNER JOIN Sales.SalesOrderDetail SOD
               ON SOH.SalesOrderID = SOD.SalesOrderID
        INNER JOIN Production.Product PROD
               ON PROD.ProductID = SOD.ProductID
        INNER JOIN Sales.Customer CUST
               ON SOH.CustomerID = CUST.CustomerID
        INNER JOIN Person.Person PER
               ON PER.BusinessEntityID = CUST.PersonID
GROUP BY CUST.CustomerID ,
        SOH.SalesOrderID ,
        SOH.OrderDate ,
        SOD.ProductID ,
		PROD.Name;

--SET STATISTICS IO ON;
SET STATISTICS IO OFF;

SELECT  CUST.CustomerID ,
        SOH.SalesOrderID ,
        SOD.ProductID ,
        SUM(SOD.OrderQty) AS TotalOrderQty ,
        SUM(LineTotal) AS TotalValue
FROM    Sales.SalesOrderHeader SOH
        INNER JOIN Sales.SalesOrderDetail SOD
               ON SOH.SalesOrderID = SOD.SalesOrderID
        INNER JOIN Production.Product PROD ON PROD.ProductID = SOD.ProductID
        INNER JOIN Sales.Customer CUST ON SOH.CustomerID = CUST.CustomerID
        INNER JOIN Person.Person PER ON PER.BusinessEntityID = CUST.PersonID
GROUP BY CUST.CustomerID ,
        SOH.SalesOrderID ,
        SOD.ProductID; 

--creates an indexed view, vSalesSummaryCustomerProduct, to help reduce the cost of this and similar queries.
CREATE VIEW Sales.vSalesSummaryCustomerProduct
WITH SCHEMABINDING
AS
    SELECT  CUST.CustomerID ,
            SOH.SalesOrderID ,
            SOD.ProductID ,
            SUM(SOD.OrderQty) AS TotalOrderQty ,
            SUM(LineTotal) AS TotalValue ,
            COUNT_BIG(*) AS CountLines
    FROM    Sales.SalesOrderHeader SOH
            INNER JOIN Sales.SalesOrderDetail SOD
                   ON SOH.SalesOrderID = SOD.SalesOrderID
            INNER JOIN Production.Product PROD
                   ON PROD.ProductID = SOD.ProductID
            INNER JOIN Sales.Customer CUST
                   ON SOH.CustomerID = CUST.CustomerID
            INNER JOIN Person.Person PER
                   ON PER.BusinessEntityID = CUST.PersonID
    GROUP BY CUST.CustomerID ,
            SOH.SalesOrderID ,
            SOD.ProductID; 
GO
CREATE UNIQUE CLUSTERED INDEX CX_vSalesSummaryCustomerProduct
  ON Sales.vSalesSummaryCustomerProduct(CustomerID, SalesOrderID, ProductID); 
GO

SELECT  CustomerID ,
        SalesOrderID ,
        TotalOrderQty ,
        TotalValue
FROM    Sales.vSalesSummaryCustomerProduct; 

--Again, notice the yellow exclamation mark; hovering over the index scan icon reveals that it is a “Columns with no statistics” warning on the SalesOrderID column, the second column in the clustered index key. We can see that SQL Server has created a statistics object for this clustered index

--However, if we run the query using the WITH (NOEXPAND) hint, as shown in Figure 14, we will no longer see the warning.
SELECT CustomerID,
	   SalesOrderID,
	   TotalOrderQty,
	   TotalValue
FROM	Sales.vSalesSummaryCustomerProduct WITH (NOEXPAND)

--Below execution plan shows that the plan references the underlying tables and ignores our view and its index
SELECT  CustomerID ,
        COUNT(SalesOrderID) AS OrderCount ,
        SUM(TotalValue) AS OrderValue
FROM    Sales.vSalesSummaryCustomerProduct
WHERE   CustomerID = 30103
GROUP BY CustomerID; 

--To make the query optimizer use the unique clustered index I created on vSalesSummaryCustomerProduct, we can use the NOEXPAND hint.

-- indexed views (also called materialized views) it tells the optimizer to just use the index defined and to not look at the underlying tables that define the view that has been indexed.
--It's the opposite of NOEXPAND. It will force all statements within the query defined to not use indexed views and instead to expand them out. This is the opposite situation where expanding the views may work faster than letting the optimizer choose to access the materialized view.
SELECT    CustomerID ,
          COUNT(SalesOrderID) AS OrderCount ,
          SUM(TotalValue) AS OrderValue
FROM      Sales.vSalesSummaryCustomerProduct WITH ( NOEXPAND )
WHERE     CustomerID = 30103
GROUP BY  CustomerID; 

--OUTPUT clause The OUTPUT clause is a part of the query that will return data from before or after the operations is completed.  Let’s say that you inserted data in to a table and you wanted the ID column values (which are auto-numbers).  The OUTPUT clause gives you this information!  It can work on INSERT, DELETE, UPDATE, and MERGE statements.
USE AdventureWorks;
IF OBJECT_ID ('Books', 'U') IS NOT NULL
DROP TABLE dbo.Books;
 
CREATE TABLE dbo.Books
(
  BookID int NOT NULL PRIMARY KEY,
  BookTitle nvarchar(50) NOT NULL,
  ModifiedDate datetime NOT NULL
);

-- declare @InsertOutput1 table variable 
DECLARE @InsertOutput1 table
(
  BookID int,
  BookTitle nvarchar(50),
  ModifiedDate datetime
);
 
-- insert new row into Books table
INSERT INTO Books
OUTPUT INSERTED.*
  INTO @InsertOutput1
VALUES(101, 'One Hundred Years of Solitude', GETDATE());
 
-- view inserted row in Books table
SELECT * FROM Books;

-- view output row in @InsertOutput1 variable
SELECT * FROM @InsertOutput1;

--The OUTPUT clause takes two basic forms: OUTPUT and OUTPUT INTO. Use the OUTPUT form if you want to return the data to the calling application. Use the OUTPUT INTO form if you want to return the data to a table or a table variable.

--declare @InsertOutput2 table variable
DECLARE @InsertOutput2 table
(
	BookID int,
	BookTitle nvarchar(50),
	ModifiedDate datetime
)

--inert into row into Books table
INSERT INTO Books
OUTPUT 
	INSERTED.BOOKID,
	INSERTED.BookTitle,
	INSERTED.ModifiedDate
   INTO @InsertOutput2
VALUES(102, 'Pride and Prejudice', GETDATE());

--view inserted row in Books table
SELECT * FROM Books;

--view output row in @InsertOutput2 variable
SELECT * FROM @InsertOutput2

--In some cases, you don’t want to output all inserted values, so you must define your OUTPUT clause accordingly. In the next example, I output only the BookID and BookTitle columns:
-- declare @InsertOutput2 table variable 
DECLARE @InsertOutput3 table
(
  BookID int,
  BookTitle nvarchar(50)
);
 
-- insert new row into Books table
INSERT INTO Books
OUTPUT 
    INSERTED.BookID, 
    INSERTED.BookTitle
  INTO @InsertOutput3
VALUES(103, 'The Great Gatsby', GETDATE());
 
-- view inserted row in Books table
SELECT * FROM Books;
 
-- view output row in @InsertOutput3 variable
SELECT * FROM @InsertOutput3;

--Now let’s look at another variation on the OUTPUT clause. Once more, I define a table variable (@InsertOutput4) that includes three columns, but this time the columns have different names and are in a different order:

-- declare @InsertOutput4 table variable 
DECLARE @InsertOutput4 table
(
  Title nvarchar(50),
  TitleID int,
  TitleAddDate datetime
);
 
-- insert new row into Books table
INSERT INTO Books
OUTPUT 
    INSERTED.BookID, 
    INSERTED.BookTitle, 
    INSERTED.ModifiedDate
  INTO @InsertOutput4
  (TitleID, Title, TitleAddDate)
VALUES(104, 'Mrs. Dalloway', GETDATE());
 
-- view inserted row in Books table
SELECT * FROM Books;
 
-- view output row in @InsertOutput4 variable
SELECT * FROM @InsertOutput4;

--IN UPDATE CLAUSE
SELECT* FROM Books
--USING OUTPUT clause in an UPDATE Statement 
-- declare @UpdateOutput1 table variable  
DECLARE @UpdateOutput1 table
(
  OldBookID int,
  NewBookID int,
  BookTitle nvarchar(50),
  OldModifiedDate datetime,
  NewModifiedDate datetime
);
 
-- update row in Books table
UPDATE Books
SET 
  BookID = 105,
  ModifiedDate = GETDATE()
OUTPUT
    DELETED.BookID,
    INSERTED.BookID,
    INSERTED.BookTitle,
    DELETED.ModifiedDate,
    INSERTED.ModifiedDate
  INTO @UpdateOutput1
WHERE BookTitle = 'Mrs. Dalloway';
 
-- view updated row in Books table
SELECT * FROM Books;
 
-- view output row in @UpdateOutput1 variable
SELECT * FROM @UpdateOutput1;
 
 
 
 --SEQUENCE
USE MSSA;
CREATE SEQUENCE DecSeq  
    AS decimal(3,0)   
    START WITH 125  
    INCREMENT BY 25  
    MINVALUE 100  
    MAXVALUE 200  
    CYCLE  
    CACHE 3  
; 

SELECT NEXT VALUE FOR DecSeq;   

SELECT * FROM sys.dm_db_index_usage_stats
SELECT * FROM sys.dm_db_missing_index_details DMV


--CURSORS
USE AdventureWorks;
SELECT BusinessEntityID, Name
FROM Sales.Store;

--1. Declare variables to hold the output from the cursor
DECLARE @BusinessEntityID as INT;
DECLARE @BusinessName as NVARCHAR(50);

--2. Declare the cursor object
DECLARE @BusinessCursor as CURSOR;

--3. Assignt the query to the cursor
SET @BusinessCursor = CURSOR FOR
SELECT BusinessENtityID, Name
FROM Sales.Store

--4.Open the cursor
OPEN @BusinessCursor;

--5. Fetch the first row
FETCH NEXT FROM @BusinessCursor INTO @BusinessEntityID, @BusinessName;

--6. Loop until there are no more results. In the loop print out the ID and the name from the result set and fetch the net row 
WHILE @@FETCH_STATUS = 0
BEGIN 
	PRINT CAST(@BusinessEntityID as VARCHAR(50)) + ' '+ @BusinessName;
	FETCH NEXT FROM @BusinessCursor INTO @BusinessEntityID, @BusinessName;
END

--7: Close the cursor
CLOSE @BusinessCursor;

--8: Deallocate the cursor to free up any memory or open result sets
DEALLOCATE @BusinessCursor;


USE AdventureWorks;
GO  
SET SHOWPLAN_XML ON ;  
GO  
-- First query.  
SELECT BusinessEntityID   
FROM HumanResources.Employee  
WHERE NationalIDNumber = '509647174';  
GO  
-- Second query.  
SELECT BusinessEntityID, JobTitle  
FROM HumanResources.Employee  
WHERE JobTitle LIKE 'Production%';  
GO  
SET SHOWPLAN_XML ON;

USE TSQL;
SELECT * FROM Sales.Orders

SELECT orderdate, 
	   GETDATE() AS CurrentDate, 
	   EOMONTH(GETDATE()) AS EOM,
	   EOMONTH(GETDATE(),-1) AS PreviousEOM,
	   DATEADD(day,1,EOMONTH(GETDATE(),-1))
FROM Sales.Orders

USE MSSA;
CREATE TABLE PurchasingOrder
(
	purchase_id int,
	purchase_dt datetime2,
	item NVARCHAR(25),
	constraint purchase_id_fk PRIMARY KEY (purchase_id)
)
INSERT INTO PurchasingOrder(purchase_id, purchase_dt, item)
Values (1,getdate(), N'soccer ball'),
		(2, getdate()+1, N'Shoes'),
		(3, getdate()+2, N'Pad'),
		(4, getdate()+3, N'Jersey'),
		(5, getdate()+4, N'Shorts'),
		(6, getdate()+5, N'Band'),
		(7, getdate()+6, N'Shocks'),
		(8, getdate()+7, N'Mask'),
		(9, getdate()+8, N'Water'),
		(10,getdate()-31, N'soccer ball'),
		(11, getdate()-30, N'Shoes'),
		(12, getdate()-40, N'Pad'),
		(13, getdate()-60, N'Jersey'),
		(14, getdate()-35, N'Shorts'),
		(15, getdate()-45, N'Band'),
		(16, getdate()-46, N'Shocks'),
		(17, getdate()-57, N'Mask'),
		(18, getdate()-58, N'Water')


		
SELECT * FROM PurchasingOrder

SELECT * FROM PurchasingOrder
WHERE purchase_dt >= DATEADD(d,1,EOMONTH(GETDATE(),-2))
AND purchase_dt<DATEADD(d,1,EOMONTH(GETDATE(),-1))
ORDER BY purchase_dt

--Below sql will not count the date after 04/30/2018 00:00:00
--if the order is placed on 04/30/2018 00:04:00 the the order will
--be dropped therefore compare against the second date to the beginning
--of next day 
SELECT * FROM PurchasingOrder
WHERE purchase_dt >= DATEADD(d,1,EOMONTH(GETDATE(),-2))
AND purchase_dt<= EOMONTH(GETDATE(),-1)
ORDER BY purchase_dt


USE AdventureWorks;
IF OBJECT_ID(N'ufnGetInventoryStock',N'FN') IS NOT NULl
	DROP FUNCTION ufnGetInventoryStock
GO
CREATE FUNCTION ufnGetInventoryStock(@ProductID int)
RETURNS INT
AS
--Returns the stock level for the prodcut
BEGIN
	DECLARE @ret int
	SELECT @ret = SUM(p.Quantity)
	FROM Production.ProductInventory p
	WHERE p.ProductID = @ProductID
		AND p.LocationID = '6'
	IF(@ret IS NULL)
		SET @ret = 0
	RETURN @ret
END

SELECT ProductModelID, Name, dbo.ufnGetInventoryStock(ProductID)AS CurrentSupply
FROM Production.Product
WHERE ProductModelID BETWEEN 75 AND 80;

--decimal money data types
DECLARE @mymoney_sm smallmoney = 3148.29,  
        @mymoney    money = 3148.29;  
SELECT  CAST(@mymoney_sm AS varchar) AS 'SM_MONEY varchar',  
        CAST(@mymoney AS decimal(6,2))    AS 'MONEY DECIMAL';  

--OFFSET FETCH
--OFFSET means how many rows to skip
USE TSQL;
SELECT firstname + ' ' + lastname  AS fullname
FROM HR.Employees 
ORDER BY empid 
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

