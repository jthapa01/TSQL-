--Chapter 10 Transaction and Concurrency
--Transaction: is a unit of work that might include multiple activities that query and modify data and that can also change the data definition.
--Transactions have four properties—atomicity, consistency, isolation, and durability— ACID:
USE TSQLV4;
--start a new transaction
BEGIN TRAN;

	--Declare a variable
	DECLARE @neworderid AS INT;

	--Insert a new order into the sales.orders table
	INSERT INTO Sales.Orders
		(custid, empid, orderdate, requireddate, shippeddate,
		shipperid, freight, shipname, shipaddress, shipcity,
		shippostalcode, shipcountry)
	VALUES
		(85, 5, '20090212', '20090301', '20090216',
			3, 32.38, N'Ship to 85-B', N'6789 rue de l''Abbaye',   N'Reims', N'10345', N'France');

--Save the new order ID in a variable
SET @neworderid = SCOPE_IDENTITY();

--Return the new order ID
SELECT @neworderid AS neworderid;

--Inswert order lines for the new order into Sales.OrderDetails
INSERT INTO Sales.OrderDetails
	(orderid, productid, unitprice, qty, discount)
	VALUES(@neworderid, 11, 14.00, 12, 0.000),
		(@neworderid, 42, 9.80, 10, 0.000),
		(@neworderid, 72, 34.80, 5, 0.000);

--Commit the transaction
COMMIT TRAN;

--cleanup
DELETE FROM Sales.OrderDetails
WHERE orderid > 11077;
DELETE FROM Sales.Orders
WHERE orderid > 11077;

--Locks and blocking
--Locks modes and compatibility
--Lock modes: exclusive and shared
--shared: because multiple transactions can hold shared locks on the same data resource simultaneously.

/*In Azure SQL Database, the default isolation level is called READ COMMITTED SNAPSHOT. Instead of relying only on locking, this isolation level relies on a combination of locking and row versioning. Under this isolation level, readers do not require shared locks,and therefore they never wait; they rely on the row-versioning technology to provide the expected isolation. In practical terms, this means that under the READ COMMITTED isolation level, if a transaction modifies rows, until the transaction completes, another transaction can’t read the same rows. This approach to concurrency control is known as the pessimistic concurrency approach. Under the READ COMMITTED SNAPSHOT isolation level, if a transaction modifies rows, another transaction trying to read the data will get the last
committed state of the rows that was available when the statement started. This approach to concurrency control is known as the optimistic concurrency approach.*/

SELECT--use * to explore other available attributes
	request_session_id		AS sid,
	resource_type			As restype,
	resource_database_id	AS dbid,
	DB_Name(resource_database_id) AS dbname,
	resource_description	AS res,
	resource_associated_entity_id AS resid,
	request_mode			AS mode,
	request_status			AS status
FROm sys.dm_tran_locks

--block chaining
SELECT --USE * to explore
	session_id AS sid,
	connect_time,
	last_read,
	last_write,
	most_recent_sql_handle
	FROM sys.dm_exec_connections
	WHERE session_id IN(52,53);