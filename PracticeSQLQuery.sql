


--select * From mssa.[dbo].[BUYER];
--select * from mssa.dbo.CAR_PURCHASED;

--select buyer.buyer_id, buyer.first_name, buyer.last_name, 
--buyer.phone, concat(car.make, car.model) as 'make and model', 
--car.color, car.purchased_year from mssa.dbo.buyer buyer
--inner join mssa.dbo.car_purchased car on buyer.buyer_id =  car.buyer_id
--where car.color = 'Black'
--order by car.purchased_year desc; 



 
--GO
 
--CREATE TABLE Employees
--(
--EmployeeID int PRIMARY KEY,
--LastName nvarchar(25),
--FirstName nvarchar(25)
--);


--Go
 
--INSERT INTO Employees
--(
--EmployeeID, LastName, FirstName
--)
--VALUES
--(121, 'N’O''Neill', 'N‘Carlene’');

select * from employees;

select len(ltrim(rtrim('    Dave   '))) as 'name';
select CHARINDEX(' ','Barack Hussein Obama',6);
select x = substring('jeevan',2,3);


select x = left('jeevan thapa',charindex(' ','jeevan thapa')) 

select x = dateadd(day,30,sysdatetime());
select dateadd(month, -(10/2), sysdatetime());

select SYSDATETIMEOFFSET();

select convert (date, getdate()); 
DECLARE @days int = 365,
	    @datetime datetime = '2000-01-01 01:01:01.111';
SELECT Date = DATEADD(day, @days, @datetime);

select x = datediff(day, sysdatetime(), '2018-09-07 01:01:01');




DECLARE @currentdate date = convert(date,getdate()),
		@etsdate date = '2018-09-07';
select In_Army  = DATEDIFF(day, @currentdate,@etsdate );

select cast(getdate() as date);

use MSSA
CREATE TABLE student
(
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(50) NOT NULL,
    DOB datetime NOT NULL,
    total_score INT NOT NULL,
    
 )

INSERT INTO student

VALUES (1, 'Jolly', 'Female', '12-JUN-1989', 500), 
(2, 'Jon', 'Male', '02-FEB-1974', 545), 
(3, 'Sara', 'Female', '07-MAR-1988', 600), 
(4, 'Laura', 'Female', '22-DEC-1981', 400), 
(5, 'Alan', 'Male', '29-JUL-1993', 500), 
(6, 'Kate', 'Female', '03-JAN-1985', 500), 
(7, 'Joseph', 'Male', '09-APR-1982', 643), 
(8, 'Mice', 'Male', '16-AUG-1974', 543), 
(9, 'Wise', 'Male', '11-NOV-1987', 499), 
(10, 'Elis', 'Female', '28-OCT-1990', 400);

--Inline table valued Function
CREATE FUNCTION BornBefore
(
@DOB AS DATETIME
)
RETURNS TABLE
AS 
RETURN 
	SELECT * FROM student
	WHERE DOB < @DOB


SELECT 
	name, gender, DOB
FROM
	dbo.BornBefore('1980-01-01')
ORDER BY
	DOB

ALTER FUNCTION BornBefore
 (
 @YearAfter AS DATETIME,
 @YearBefore AS DATETIME
 )
RETURNS TABLE
AS
RETURN
		SELECT * FROM student
		WHERE DOB BETWEEN @YearAfter AND @YearBefore

SELECT 
	name, gender, DOB
FROM
	dbo.BornBefore('1980-01-01', '1990-12-31')
ORDER BY
	DOB


--Multistatement table valued function
CREATE TABLE teacher
(
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(50) NOT NULL,
    DOB datetime NOT NULL,
    
 )
 INSERT INTO teacher

VALUES (1, 'Rick', 'Male', '05-APR-1965'), 
(2, 'Shack', 'Male', '03-JUN-1972'), 
(3, 'Zack', 'Male', '04-MAR-1969'), 
(4, 'Elis', 'Female', '28-NOV-1959'), 
(5, 'Mint', 'Female', '29-DEC-1971')

GO

CREATE FUNCTION GetBornBetween
 (
 @YearAfter AS DATETIME,
 @YearBefore AS DATETIME
 )
RETURNS @People TABLE
(
	Name VARCHAR (MAX),
	Gender VARCHAR(MAX),
	DOB DATETIME,
	Job VARCHAR(10)
)
AS
BEGIN
		INSERT INTO @People
			SELECT name, gender, DOB, 'student'
			FROM student
			WHERE DOB BETWEEN @YearAfter AND @YearBefore

		INSERT INTO @People
			SELECT name, gender, DOB, 'teacher'
			FROM teacher
			WHERE DOB BETWEEN @YearAfter AND @YearBefore

		RETURN
END

SELECT * FROM
	dbo.GetBornBetween('1960-01-01', '1985-12-31')


	use AdventureWorks
	--Running with running total
--SubQuery
SELECT  SalesOrderID ,
        SalesOrderDetailID ,
        LineTotal ,
        ( SELECT    SUM(y.LineTotal)
          FROM      Sales.SalesOrderDetail y
          WHERE     y.SalesOrderID = x.SalesOrderID
                    AND y.SalesOrderDetailID <= x.SalesOrderDetailID
        ) AS RunningTotal
FROM    Sales.SalesOrderDetail x
ORDER BY 1 ,2 ,3;

 
--Self Join
SELECT  x.SalesOrderID ,
        x.SalesOrderDetailID ,
        x.LineTotal ,
        SUM(y.LineTotal) AS RunningTotal
FROM    Sales.SalesOrderDetail x
        JOIN Sales.SalesOrderDetail y ON y.SalesOrderID = x.SalesOrderID
                                        AND y.SalesOrderDetailID <= x.SalesOrderDetailID
GROUP BY x.SalesOrderID ,
        x.SalesOrderDetailID ,
        x.LineTotal
ORDER BY 1, 2, 3;
 
 --using CTE
WITH    CTE
            AS ( SELECT   SalesOrderID ,
                        SalesOrderDetailID ,
                        LineTotal ,
                        RunningTotal = LineTotal
                FROM     Sales.SalesOrderDetail
                WHERE    SalesOrderDetailID IN ( SELECT  MIN(SalesOrderDetailID)
                                                FROM    Sales.SalesOrderDetail
                                                GROUP BY SalesOrderID )
                UNION ALL
                SELECT   y.SalesOrderID ,
                        y.SalesOrderDetailID ,
                        y.LineTotal ,
                        RunningTotal = x.RunningTotal + y.LineTotal
                FROM     CTE x
                        JOIN Sales.SalesOrderDetail y ON y.SalesOrderID = x.SalesOrderID
                                                            AND y.SalesOrderDetailID = x.SalesOrderDetailID + 1
                )
    SELECT  *
    FROM    CTE
    ORDER BY 1 ,
            2 ,
            3
OPTION  ( MAXRECURSION 10000 );

--SQL2012+
SELECT  SalesOrderID ,
        SalesOrderDetailID ,
        LineTotal ,
        SUM(LineTotal) OVER ( PARTITION BY SalesOrderID ORDER BY SalesOrderDetailID ) AS RunningTotal
FROM    Sales.SalesOrderDetail
ORDER BY 1 ,
        2 ,
        3;