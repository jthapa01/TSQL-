

--CTE and variables

USE TSQLV4
DECLARE @empID int =3;

WITH Emp_Hire_Year
AS
(
	SELECT empid, lastname, firstname, YEAR(hiredate) AS HireYear
	FROM HR.Employees
	WHERE empid = @empID

)

Select empid, lastname, firstname, hireYear
FROM Emp_Hire_Year
WHERE empid = @empID