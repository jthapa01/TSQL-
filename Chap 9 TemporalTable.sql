

USE TSQLV4;
--Create Employees table

CREATE TABlE dbo.Employee
(empid INT  NOT NULL
	CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
empname VARCHAR(25) NOT NULL,
department VARCHAR(50) NOT NULL,
salary NUMERIC(10,2) NOT NULL,
sysstart DATETIME2(0)
	GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
sysend DATETIME2(0)
	GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
PERIOD FOR SYSTEM_TIME(sysstart,sysend),
INDEX ix_Employees CLUSTERED(empid, sysstart,sysend)
)
WITH(SYSTEM_VERSIONING = On(HISTORY_TABLE = dbo.EmployeesHistory));

--hidden column not shown
SELECT *
FROM dbo.Employee;

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employee;

ALTER TABLE dbo.Employee
	ADD hiredate DATE NOT NULL
	   CONSTRAINT DFT_Employees_hiredate DEFAULT('19000101');

SELECT *
FROM dbo.EmployeesHistory;

--TO drop hiredate column first drop default constraint then column
ALTER TABLE dbo.Employee
DROP CONSTRAINT DFT_Employees_hiredate;
ALTER TABLE dbo.Employee
DROP COLUMN hiredate;

--Modifying Temporal Table
--currently no support for truncate the temporal table
INSERT INTO dbo.Employee(empid, empname, department, salary)
VALUES(1, 'Sara', 'IT' , 50000.00),
(2, 'Don' , 'HR' , 45000.00),
(3, 'Judy', 'Sales' , 55000.00),
(4, 'Yael', 'Marketing', 55000.00),
(5, 'Sven', 'IT' , 45000.00),
(6, 'Paul', 'Sales' , 40000.00);

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employee;
SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.EmployeesHistory;

DELETE FROM dbo.Employee
Where empid = 6;

UPDATE dbo.Employee
SET salary *= 1.05
WHERE department = 'IT';

BEGIN TRAN;
UPDATE dbo.Employee
SET department = 'Sales'
WHERE empid = 5;

UPDATE dbo.Employee
SET department = 'IT'
WHERE empid = 3;
COMMIT TRAN;


USE TSQLV4;
-- Drop tables if exist
IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );
DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;
GO
-- Create and populate Employees table
CREATE TABLE dbo.Employees
(
empid INT NOT NULL
CONSTRAINT PK_Employees PRIMARY KEY NONCLUSTERED,
empname VARCHAR(25) NOT NULL,
department VARCHAR(50) NOT NULL,
salary NUMERIC(10, 2) NOT NULL,
sysstart DATETIME2(0) NOT NULL,
sysend DATETIME2(0) NOT NULL,
INDEX ix_Employees CLUSTERED(empid, sysstart, sysend)
);
INSERT INTO dbo.Employees(empid, empname, department, salary, sysstart, sysend)
VALUES
(1 , 'Sara', 'IT' , 52500.00, '2016-02-16 17:20:02', '9999-12-31 23:59:59'),
(2 , 'Don' , 'HR' , 45000.00, '2016-02-16 17:08:41', '9999-12-31 23:59:59'),
(3 , 'Judy', 'IT' , 55000.00, '2016-02-16 17:28:10', '9999-12-31 23:59:59'),
(4 , 'Yael', 'Marketing', 55000.00, '2016-02-16 17:08:41', '9999-12-31 23:59:59'),
(5 , 'Sven', 'Sales' , 47250.00, '2016-02-16 17:28:10', '9999-12-31 23:59:59');
-- Create and populate EmployeesHistory table
CREATE TABLE dbo.EmployeesHistory
(
empid INT NOT NULL,
empname VARCHAR(25) NOT NULL,
department VARCHAR(50) NOT NULL,
salary NUMERIC(10, 2) NOT NULL,
sysstart DATETIME2(0) NOT NULL,
sysend DATETIME2(0) NOT NULL,
INDEX ix_EmployeesHistory CLUSTERED(sysend, sysstart)
WITH (DATA_COMPRESSION = PAGE)
);
INSERT INTO dbo.EmployeesHistory(empid, empname, department, salary, sysstart,
sysend) VALUES
(6 , 'Paul', 'Sales' , 40000.00, '2016-02-16 17:08:41', '2016-02-16 17:15:26'),
(1 , 'Sara', 'IT' , 50000.00, '2016-02-16 17:08:41', '2016-02-16 17:20:02'),
(5 , 'Sven', 'IT' , 45000.00, '2016-02-16 17:08:41', '2016-02-16 17:20:02'),
(3 , 'Judy', 'Sales' , 55000.00, '2016-02-16 17:08:41', '2016-02-16 17:28:10'),
(5 , 'Sven', 'IT' , 47250.00, '2016-02-16 17:20:02', '2016-02-16 17:28:10');
-- Enable system versioning
ALTER TABLE dbo.Employees ADD PERIOD FOR SYSTEM_TIME (sysstart, sysend);
ALTER TABLE dbo.Employees ALTER COLUMN sysstart ADD HIDDEN;
ALTER TABLE dbo.Employees ALTER COLUMN sysend ADD HIDDEN;
ALTER TABLE dbo.Employees
SET ( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.EmployeesHistory ) );



SELECT *
FROM dbo.Employees;

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:00:00';

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00';

--the following query returns the percentage of increase 
--of salary of employees who had a salary increase between two
-- different points in time:

SELECT T2.empid, T2.empname,
	CAST ((T2.salary/T1.salary -1.0)*100 AS numeric(10,2)) AS pct
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:10:00' AS T1
	INNER JOIN dbo.Employees FOR SYSTEM_TIME AS OF '2016-02-16 17:25:00' AS T2
		ON T1.empid = T2.empid
	 AND T2.salary > T1.salary;


SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
FOR SYSTEM_TIME FROM '2016-02-16 17:15:26' TO '2016-02-16 17:20:02';

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
FOR SYSTEM_TIME BETWEEN '2016-02-16 17:15:26' AND '2016-02-16 17:20:02';

SELECT empid, empname, department, salary, sysstart, sysend
FROM dbo.Employees
FOR SYSTEM_TIME CONTAINED IN('2016-02-16 17:00:00', '2016-02-16 18:00:00');

SELECT empid, empname, department, salary,
sysstart AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS sysstart,
CASE
WHEN sysend = '9999-12-31 23:59:59'
THEN sysend AT TIME ZONE 'UTC'
ELSE sysend AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
END AS sysend
FROM dbo.Employees FOR SYSTEM_TIME ALL;

IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
ALTER TABLE dbo.Employees SET ( SYSTEM_VERSIONING = OFF );
DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;

------Chapter 9 --Temporal Table Execises---------
--***************************************----------
----------------------------------------------------
/*1)) Create a system-versioned temporal table called Departments with an associated history table called DepartmentsHistory in the database TSQLV4. The table should have the following columns: deptid INT, deptname VARCHAR(25), and mgrid INT, all disallowing NULLs. Also include columns called validfrom and validto that define the validity period of the row. Define those with precision zero (1 second), and make them hidden.*/
CREATE TABLE dbo.Departments
(
	deptid INT NOT NULL
		CONSTRAINT PK_Departments PRIMARY KEY,
	deptname VARCHAR(25) NOT NULL,
	mgrid INT NOT NULL,
	validfrom DATETIME2(0)
	    GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
	validto DATETIME2(0)
		GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
	PERIOD FOR SYSTEM_TIME(validfrom, validto)
)
WITH(SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DepartmentsHistory));

--2))Exercise 2
/*In this exercise, you’ll modify data in the table Departments. Note the point in time in UTC when you submit each statement, and mark those as P1, P2, and so on. You can do so by invoking the SYSUTCDATETIME function in the same batch in which you submit the
modification. Another option is to query the Departments table and its associated history table and to obtain the point in time from the validfrom and validto columns.

Exercise 2-1
Insert four rows to the table Departments with the following details, and note the time when you apply this insert (call it P1):
deptid: 1, deptname: HR, mgrid: 7
deptid: 2, deptname: IT, mgrid: 5
deptid: 3, deptname: Sales, mgrid: 11
deptid: 4, deptname: Marketing, mgrid: 13
*/
select * from dbo.Departments
SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P1;
INSERT INTO dbo.Departments(deptid, deptname, mgrid)
VALUES(1, 'HR' , 7 ),
(2, 'IT' , 5 ),
(3, 'Sales' , 11),
(4, 'marketing', 13);

/*Exercise 2-2
In one transaction, update the name of department 3 to Sales and Marketing and delete
department 4. Call the point in time when the transaction starts P2.*/
SELECT CAST(SYSUTCDATETIME() AS datetime2(0))as p2;

BEGIN TRAN;
UPDATE dbo.Departments
	SET deptname = 'Sales and Marketing'
WHERE deptid = 3;

DELETE FROM dbo.Departments
WHERE deptid = 4;
COMMIT TRAN;

/*Exercise 2-3
Update the manager ID of department 3 to 13. Call the point in time when you apply this
update P2.*/

SELECT CAST(SYSUTCDATETIME() AS DATETIME2(0)) AS P3

UPDATE dbo.Departments
	SET mgrid = 13
WHERE deptid = 3;

select * from [dbo].[DepartmentsHistory]
select deptid, deptname, mgrid,validfrom,validto from dbo.Departments

/*Exercise 3
In this exercise, you’ll query data from the table Departments.
Exercise 3-1
Query the current state of the table Departments:*/
select * from dbo.Departments

/*Exercise 3-2
Query the state of the table Departments at a point in time after P2 and before P3:*/
SELECT *
FROM dbo.Departments
	FOR SYSTEM_TIME AS OF '2018-04-01 00:14:28'

/*Exercise 3-3
Query the state of the table Departments in the period between P2 and P3. Be explicit about the column names in the SELECT list, and include the validfrom and validto columns:*/

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments
	FOR SYSTEM_TIME BETWEEN '2018-04-01 00:20:07'
		AND '2018-04-01 00:20:24'

/*Exercise 4
Drop the table Departments and its associated history table.*/

ALTER TABLE dbo.Departments SET ( SYSTEM_VERSIONING = OFF );
DROP TABLE dbo.DepartmentsHistory, dbo.Departments;