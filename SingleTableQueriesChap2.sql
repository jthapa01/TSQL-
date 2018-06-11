USE TSQLV4;

--Logical processing
--FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY
SELECT EMPID, YEAR(orderdate) AS orderyear,
COUNT(*) AS numorders		    --5
FROM Sales.Orders			    --1
WHERE custid = 71			    --2
GROUP BY empid, YEAR(orderdate) --3
HAVING COUNT(*) > 1				--4
ORDER BY empid, orderyear;		--6

SELECT empid, 
	   YEAR(orderdate) AS orderyear,
	   SUM(freight) AS totalfreight,
	   COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

SELECT empid,
	   YEAR(orderdate) AS orderyear,
	   COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY empid, YEAR(orderdate);

--The TOP filter
SELECT TOP(5) orderid, orderdate, custid, empid
FROM Sales.Orders
Order BY orderdate DESC;

--Offset-fetch filter
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY

--window function
SELECT orderid, custid, val,
	ROW_NUMBER() OVER(PARTITION BY custid
					ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;
--(ORDER OF EXECUTION)
--FROM, WHERE, GROUP BY, HAVING, SELECT (EXPRESSION, DISTINCT)
--ORDER BY(TOP/OFFSET_FETCH)

--Predicates and Operators
SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid IN(10248,10249,10250)

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid BETWEEN 10300 AND 10310

--N stands for national denotes
--Unicode data type (NCHAR or NVARCHAR), as opposed
--to a regular character data type (CHAR or VARCHAR).
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%'

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20160101'

--1. Mathematical Operator, 2. Comparision operators
--3. pos, neg, add, concatenation, subtraction --4.Comparison operator
--5. NOT 6. AND 7. BETWEEN, IN, LIKE, OR 8. Assignment
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 1
   AND empid IN (1,3,5)
   OR custid = 85
   AND empid IN(2,4,6)

--CASE expression(Two forms: simple and searched)

--The simple CASE form has a single test value or expression 
--right after the CASE keyword that is compared with a list 
--of possible values in the WHEN clauses.
SELECT productid, productname, categoryid,
	CASE categoryid
		WHEN 1 THEN 'Beverages'
		WHEN 2 THEN 'Condiments'
		WHEN 3 THEN 'Confections'
		WHEN 4 THEN 'Dairy Products'
		WHEN 5 THEN 'Grains/Cereals'
		WHEN 6 THEN 'Meat/Poultry'
		WHEN 7 THEN 'Produce'
		WHEN 8 THEN 'Seafood'
		ELSE 'Unknown Category'
	END AS categoryname
FROM Production.Products
--The searched CASE form is more flexible in the sense you can 
--specify predicates in the WHEN clauses rather than being
--restricted to using equality comparisons.

SELECT orderid, custid, val,
	CASE
		WHEN val < 1000.00 THEN 'Less than 1000'
		WHEN val BETWEEN 1000.00 AND 3000.00 THEN 'Between 1000 and 3000'
		WHEN val > 3000.00 THEN 'More than 3000'
		ELSE 'Unknown'
		END AS valuecategory
FROM Sales.OrderValues;

--Null Does not show off
SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> N'WA';

SELECT Custid, country, region, city
FROM Sales.Customers
WHERE region = NULL; --Evaluates to Unknown

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region is NUll;

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> N'WA'
	OR region IS NULL;

SELECT name, description
FROM sys.fn_helpcollations();

--case insensitive
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'davis'

-- if you want to make the filter case sensitive
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS = N'Davis'

SELECT empid, firstname + N' ' + lastname AS fullName
FROM HR.Employees;

SELECT custid, country, region, city
	,country + N',' + region + N',' + city AS location
FROM Sales.Customers

SELECT custid, country, region, city, country + COALESCE(N',' + region, N'')
  + N', '+ city AS location
FROM Sales.Customers

--CONCAT will treat null automatically
SELECT custid, country, region, city,
   CONCAT(country, N','+ region, N','+ city)AS location
FROM Sales.Customers

--SUBSTRING index starts from 1 
SELECT SUBSTRING('abcde', 1, 4);

--LEFT and RIGHT functions
SELECT RIGHT('abcde', 3)
SELECT LEFT('abcde', 3)

--LEN and DATALENGTH functions
SELECT LEN(N'abcde');
SELECT DATALENGTH(N'abcde');--Unicode has 2 bytes 

--CHARINDEX
SELECT CHARINDEX(' ','Itzik Ben-Gan');
--PATINDEX
--position ofa first occurence of a digit
SELECT PATINDEX('%[0-9]%','abcd123efgh');

--REPLACE function
SELECT REPLACE('1-a 2-b','-',':');

--number of occurence of a character in a string
SELECT empid, lastname, 
	LEN(lastname)-LEN(REPLACE(lastname,'e',''))AS numoccurence
FROM HR.Employees;

--REPLICATE function
SELECT REPLICATE('abc', 3);

--rightmost 10 character
SELECT supplierid, RIGHT(REPLICATE('0',9)+ 
	CAST(supplierid AS VARCHAR(10)), 10) --cast integer to string
	   AS strsupplierid
FROM Production.Suppliers

--STUFF function - STUFF(string, pos, delete_length, insert_string)
SELECT STUFF('xyz', 2, 1, 'abc');

--UPPER and LOWER function
SELECT UPPER('Itzik Ben-Gan');
SELECT LOWER('Itzik Ben-Gan');

--RTRIM and LTRIM functions
SELECT RTRIM(LTRIM('   abc    '));

--FORMAT function
--using FORMAT function instead of REPLICATE and RIGHT
--is more expensive
SELECT FORMAT(1759, '000000000');

--COMPRESS and DECOMPRESS function--use the GZIP algorithm
--COMPRESS function accepts character or binary string as input
--and returns a compressed VARBINARY(MAX) typed value
SELECT COMPRESS(N'This is my cv. Imagine it was much longer.');

--The DECOMPRESS function accepts a binary string as input and 
--returns a decompressed VARBINARY(MAX) typed value.

SELECT DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.'));
--cast to the target string type
SELECT
	CAST(
		DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.')) 
		   AS NVARCHAR(MAX));

--STRING_SPLIT table function
SELECT CAST(value AS INT) AS myvalue
FROM STRING_SPLIT('10248,10249,10250',',') AS S;

--LIKE predicate
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%'

--_(underscore) wildcard -2nd char in lastname is e
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'_e%';

--THe [<list of characters>]wildcard
--where the first character in the last name is A, B, or C:
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[ABC]%';

--The [<character>-<character>] wildcard
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[A-E]%';

--The [^<character list or range>] wildcard
--represent a single character that is not in the 
--specified character list or range.
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[^A-E]%'

--Working with Date and Time
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate = '20160212';

SET LANGUAGE British;
SELECT CAST('02/12/2016' AS DATE);

--CONVERT style number 101
SELECT CONVERT(DATE, '02/12/2016',101);
--PARSE is more expensive 
SELECT PARSE('02/12/2016' AS DATE USING 'en-US');
SELECT PARSE('02/12/2016' AS DATE USING 'en-GB')

--Working with Date and Time Separately
DROP TABLE IF EXISTS Sales.Order2;
SELECT orderid, custid, empid,
   CAST(orderdate AS DATETIME)AS orderdate
INTO Sales.Orders2
FROM Sales.Orders;

SELECT * FROM Sales.Orders2

ALTER TABLE Sales.Orders2
   ADD CONSTRAINT CHK_Orders2_orderdate
   CHECK(CONVERT(CHAR(12), orderdate, 114)='00:00:00:000' );

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2
WHERE orderdate >= '20160212'
	AND orderdate <'20160213';

SELECT CAST('12:30:15.123' AS DATETIME);
DROP TABLE IF EXISTS Sales.Orders2;

--Filtering date ranges
--in most cases, when you apply manipulation on the filtered column,
-- SQL Server cannot use an index in an efficient manner
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate)= 2015;

--better 
SELECT orderid, custid, empid, orderdate
FROM sales.Orders
WHERE orderdate >= '20150101'
	AND orderdate <'20160101'; 

--Similarly
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2016 AND MONTH(Orderdate)=2;

--optimized
SELECT orderid, custid, empid, orderdate
FROM Sales.orders
WHERE orderdate >= '20160201' AND orderdate <'20160301';

--DATE and TIME functions
SELECT
   GETDATE()		        AS [GETDATE],
   CURRENT_TIMESTAMP	    AS [CURRENT_TIMESTAMP],
   GETUTCDATE()				AS [GETUTCDATE],
   SYSDATETIME()			AS [SYSDATETIME],
   SYSUTCDATETIME()			AS [SYSUTCDATETIME],
   SYSDATETIME()			AS [SYSDATETIMEOFFSET];

SELECT
	CAST(SYSDATETIME() AS DATE) AS [current_date],
	CAST(SYSDATETIME() AS TIME) AS [current_time];
--CAST is standard
SELECT CAST('20160212' AS DATE);
SELECT CAST(SYSDATETIME () AS DATE);
SELECT CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114);
--base date 1900-01-01
SELECT CONVERT(DATETIME, CONVERT(CHAR(12), CURRENT_TIMESTAMP,114), 114);
SELECT PARSE('02/12/2016' AS DATETIME USING 'en-US');
SELECT PARSE('02/12/2016' AS DATETIME USING 'en-GB');

--SWITCHOFFSET function
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(),'-05:00');
SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00');

--The TODATETIMEOFFSET function
--DST(daylightsaving)
--TODATETIMEOFFSET(local_date_and_time_value, UTC_offset)
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info;

SELECT
   CAST('20160212 12:00:00.0000000' AS DATETIME2)
      AT TIME ZONE 'Pacific Standard Time' AS val1,
   CAST('20160812 12:00:00.0000000' AS DATETIME2)
      AT TIME ZONE 'Pacific Standard Time' AS val2;

SELECT
   CAST('20160212 12:00:00.0000000 -05:00' AS DATETIMEOFFSET)
      AT TIME ZONE 'Pacific Standard Time' AS val1,
   CAST('20160812 12:00:00.0000000 -04:00' AS DATETIMEOFFSET)
   AT TIME ZONE 'Pacific Standard Time' AS val2;

--DATEADD function
SELECT DATEADD(year, 1,'20160212');
--DATEDIFF and DATEDIFF_BIG Functions
SELECT DATEDIFF(day, '20150212', '20160212');
SELECT DATEDIFF_BIG(MILLISECOND, '00010101','20160212');

SELECT DATEDIFF(day, '19000101', SYSDATETIME());
--current date
SELECT 
   DATEADD(
   day, 
   DATEDIFF(day, '19000101', SYSDATETIME()), '19000101');

SELECT DATEDIFF(month, '19000101', SYSDATETIME());
--First day of the current month
SELECT 
	DATEADD(
		month, DATEDIFF(month, '19000101', SYSDATETIME()),'19000101');
--first day of the current year
SELECT 
	DATEADD(
		year, DATEDIFF(year, '19000101', SYSDATETIME()),'19000101');

--Last day of the current year 
SELECT
	DATEADD(
	   YEAR, DATEDIFF(year, '18991231', SYSDATETIME()),'18991231');

--DATEPART(part, dt_val)
SELECT DATEPART(month, '20160212')

SELECT
   DAY('20160212') AS theday,
   MONTH('20160212') AS themonth,
   YEAR('20160212') AS theyear;

--DATENAME - DATENAME(dt_val, part)
SELECT DATENAME(month, '20160212');
SELECT DATENAME(year, '20160212');

--ISDATE function
SELECT ISDATE('20160212'); --1
SELECT ISDATE('20160230');--0

--FROMPARTS
SELECT
  DATEFROMPARTS(2016,02,12),
  DATETIME2FROMPARTS(2016,02,12,13,30,5,1,7),
  DATETIMEFROMPARTS(2016, 02, 12, 13, 30, 5, 997),
  DATETIMEOFFSETFROMPARTS(2016, 02, 12, 13, 30, 5, 1, -8, 0, 7),
  SMALLDATETIMEFROMPARTS(2016, 02, 12, 13, 30),
  TIMEFROMPARTS(13, 30, 5, 1, 7);

--EOMONTH
SELECT EOMONTH(SYSDATETIME());
SELECT EOMONTH(SYSDATETIME(), 1);

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);


--QUERYING metadata
--The SCHEMA_NAME function is used to convert the schema ID integer to its name
SELECT SCHEMA_NAME(schema_id) AS table_schema_name, name AS table_name
FROM sys.tables

SELECT 
   name AS column_name,
   TYPE_NAME(system_type_id) AS column_type,
   max_length,
   collation_name,
   is_nullable
FROM sys.columns
WHERE object_id = OBJECT_ID(N'Sales.Orders');

--INFORMATION SCHEMA views
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE';

SELECT
	COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
	COLLATION_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'Sales'
   AND TABLE_NAME = N'Orders';

--SYSTEM Stored procedure and Functions
EXEC sys.sp_tables;
EXEC sys.sp_help
   @objname = N'Sales.Orders';

EXEC sys.sp_columns
@table_name = N'Orders',
@table_owner = N'Sales';

EXEC sys.sp_helpconstraint
@objname = N'Sales.Orders';

SELECT
SERVERPROPERTY('ProductLevel');

SELECT DATABASEPROPERTYEX(N'TSQLV4', 'Collation');

SELECT OBJECTPROPERTY(OBJECT_ID(N'Sales.Orders'), 'TableHasPrimaryKey');
SELECT COLUMNPROPERTY(OBJECT_ID(N'Sales.Orders'), N'shipcountry', 'AllowsNull');