
--Module 2 Lab 2C

SELECT tdsc.TerritoryDescription, tdsc.RegionID 
FROM Territories tdsc 
INNER JOIN Region rg
ON tdsc.RegionID = rg.RegionID
AND RegionDescription = 'Southern';  

Select territories.TerritoryDescription 
from territories 
where RegionID = 4;

SELECT ContactName, Phone, City 
FROM Customers;

SELECT ProductID, ProductName, UnitsInStock
FROM Products
Where UnitsInStock = 0;

SELECT ProductID, ProductName, UnitsInStock
FROM Products
Where UnitsInStock = 0;

--To select Top 10 Rows
SELECT TOP 10 ProductID, ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock ! = 0
ORDER BY UnitsInStock

--To select Top 10 Rows
SELECT ProductID, ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock ! = 0
ORDER BY UnitsInStock
OFFSET	0 ROWS
FETCH NEXT 10 ROWS ONLY

 --Alternative way to select Top 10 Rows
 --Ten products on stock with the least amount on hand
SELECT  P.ProductName, P.UnitsInStock,ROW_NUM
FROM (SELECT ProductName,UnitsInStock, ROW_NUMBER()
OVER (ORDER By UnitsInStock) AS ROW_NUM
FROM Products WHERE UnitsInStock ! = 0) P
WHERE ROW_NUM < 11


select DISTINCT productId, ProductName, unitPrice ,UnitsInStock
FROM Products
where UnitsInStock != 0
ORDER BY unitPrice DESC

--Five most expensive products in stock
SELECT p.ProductID, p.ProductName, p.UnitPrice
	  ,p.UnitsInStock, p.RowNumber
FROM (SELECT ProductID, ProductName, 
		     UnitPrice, UnitsInStock,
	         ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS RowNumber
	  FROM Products WHERE UnitsInStock != 0 ) p
WHERE RowNumber <=5;

SELECT  * from products
SELECT  * from customers
SELECT  * from suppliers

--Module 2 Lab 2 D
--Customers in North America?
SELECT * FROM customers
WHERE Country In ('USA', 'Mexico', 'Canada');

--Orders placed in April, 1998?
SELECT * FROM Orders
WHERE YEAR(OrderDate) = 1998 
AND MONTH(OrderDate) = 4

SELECT * FROM Orders 
WHERE OrderDate between '1998-04-01' 
AND '1998-04-30'

--sauces do we sell
SELECT * FROM Products
WHERE ProductName like '%Sauce%'

--some kind of dried fruit that I liked very much. What is its name?
SELECT * FROM Products
WHERE ProductName like '%dried%'

--What employees ship products to Germany in December?

--employees ship products to Germany in December?
SELECT distinct e.EmployeeID, e.LastName, e.FirstName  
FROM Employees e
JOIN Orders o
ON e.EmployeeID = o.EmployeeID
WHERE ShipCountry = 'Germany'
AND MONTH(OrderDate) = 12

SELECT * FROM Employees

--6. We have an issue with product 19. I need to know the total 
--amount and the net amount of all orders for product 19 where the 
--customer took a discount.
SELECT OrderId, ProductId, UnitPrice, Quantity, Discount,
	   (UnitPrice*Quantity) As TotalAmount, 
       (UnitPrice*Quantity-Discount) As NetAmount
FROM [Order Details]
WHERE ProductID = 19
AND Discount > 0;

--I need a list of employees by title, first name, and last name, 
--with the employee's position under their names, and a line
-- separating each employee.
--CHAR(10)-LF Line Feed
--CHAR(13)-CR Carriage Return

SELECT * FROM Employees
SELECT TitleOfCourtesy+ ' ' + FirstName + ' '+ LastName 
	   +  CHAR(13) + CHAR(10) + Title +  CHAR(13) + CHAR(10) + ' '
FROM Employees

--I need a list of our customers and the first name only of the customer representative.

SELECT CompanyName, ContactTitle
	   ,SUBSTRING(ContactName,1,CHARINDEX(' ',ContactName)) AS FirstName 
FROM customers
WHERE ContactTitle LIKE '%Rep%';

--Give me a list of our customer contacts alphabetically by last name.
SELECT * FROM Customers
SELECT Contactname, LEN(LTRIM(SUBSTRING(Contactname,CHARINDEX(' ',Contactname),LEN(Contactname))))
FROM Customers


SELECT Contactname
       ,LTRIM(SUBSTRING(Contactname,CHARINDEX(' ',Contactname)
	   ,LEN(Contactname))) AS [Last Name]
FROM Customers
ORDER BY [Last Name]
SELECT * FROM Customers

--How many days old are you today?
select DATEDIFF(DAY,1985-05-31,SYSDATETIME())

DECLARE @date datetime, 
        @tmpdate datetime, 
		@years int, 
		@months int, 
		@days int
SELECT @date = '05/31/1985'
SELECT @tmpdate = @date
SELECT @years = DATEDIFF(yy, @tmpdate, GETDATE()) 
				- CASE WHEN (MONTH(@date) > MONTH(GETDATE())) 
				OR (MONTH(@date) = MONTH(GETDATE()) AND DAY(@date) 
				> DAY(GETDATE())) THEN 1 ELSE 0 END
SELECT @tmpdate = DATEADD(yy, @years, @tmpdate)
SELECT @months = DATEDIFF(m, @tmpdate, GETDATE()) 
				- CASE WHEN DAY(@date)
			    > DAY(GETDATE()) THEN 1 ELSE 0 END
SELECT @tmpdate = DATEADD(m, @months, @tmpdate)
SELECT @days = DATEDIFF(d, @tmpdate, GETDATE())
SELECT @years, @months, @days