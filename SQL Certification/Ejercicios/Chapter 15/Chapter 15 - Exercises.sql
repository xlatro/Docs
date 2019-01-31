---------------------------------------------------------------------
-- TK 70-461 - Chapter 15 - Implementing Indexes and Statistics
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Implementing Indexes
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Nonclustered Indexes
---------------------------------------------------------------------

-- 3.
USE tempdb;
SET NOCOUNT ON;
GO

-- 4.
CREATE TABLE dbo.TestStructure
(
id      INT       NOT NULL,
filler1 CHAR(36)  NOT NULL,
filler2 CHAR(216) NOT NULL
);
GO

-- 5.
CREATE NONCLUSTERED INDEX idx_nc_filler1 ON dbo.TestStructure(filler1);
GO

-- 6.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- 7.
DECLARE @i AS int = 0;
WHILE @i < 24472
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, FORMAT(@i,'0000'), 'b');
END;
GO

-- 8.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');

-- 9.
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(24473, '24473', 'b');

-- 10.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
GO

-- 12.
TRUNCATE TABLE dbo.TestStructure;
CREATE CLUSTERED INDEX idx_cl_id ON dbo.TestStructure(id);
GO

-- 13.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS index_name, type, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
GO

-- 14.
DECLARE @i AS int = 0;
WHILE @i < 28864
BEGIN
SET @i = @i + 1;
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(@i, FORMAT(@i,'0000'), 'b');
END;
GO

-- 15.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');

-- 16.
INSERT INTO dbo.TestStructure
(id, filler1, filler2)
VALUES
(28865, '28865', 'b');

-- 17.
SELECT index_type_desc, index_depth, index_level,  
 page_count, record_count
FROM sys.dm_db_index_physical_stats
    (DB_ID(N'tempdb'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
GO

-- 18.
DROP TABLE dbo.TestStructure;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using Search Arguments
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the OR and AND Logical Operators
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
CREATE NONCLUSTERED INDEX idx_nc_shipcity ON Sales.Orders(shipcity);
GO

-- 5.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- 6.
SELECT OBJECT_NAME(S.object_id) AS table_name,
 I.name AS index_name, 
 S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
 INNER JOIN sys.indexes AS i
  ON S.object_id = I.object_id
   AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U')
 AND I.name = N'idx_nc_shipcity';

-- 8.
-- Turn on execution plan
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42;

-- 10.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 OR shipcity = N'Vancouver';

-- 13.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 AND shipcity = N'Vancouver';
GO

-- 15.
DROP INDEX idx_nc_shipcity ON Sales.Orders;
GO

-- 16.
CREATE NONCLUSTERED INDEX idx_nc_shipcity_i_custid ON Sales.Orders(shipcity)
INCLUDE (custid);
GO

-- 17.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 OR shipcity = N'Vancouver';

-- 18.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE custid = 42
 AND shipcity = N'Vancouver';
GO

-- 20.
DROP INDEX idx_nc_shipcity_i_custid ON Sales.Orders;
GO

---------------------------------------------------------------------
-- Lesson 03 - Understanding Statistics
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Manually Maintaining Statistics
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
DECLARE @statistics_name AS NVARCHAR(128), @ds AS NVARCHAR(1000);
DECLARE acs_cursor CURSOR FOR 
SELECT name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;
OPEN acs_cursor;
FETCH NEXT FROM acs_cursor INTO @statistics_name;
WHILE @@FETCH_STATUS = 0
BEGIN
 SET @ds = N'DROP STATISTICS Sales.Orders.' + @statistics_name +';';
 EXEC(@ds);
 FETCH NEXT FROM acs_cursor INTO @statistics_name;
END;
CLOSE acs_cursor;
DEALLOCATE acs_cursor;
GO

-- 5.
ALTER DATABASE TSQL2012 
 SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT;
GO

-- 6.
CREATE NONCLUSTERED INDEX idx_nc_custid_shipcity ON Sales.Orders(custid, shipcity);
GO

-- 7.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';

-- 9.
SELECT OBJECT_NAME(object_id) AS table_name,
 name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
  AND auto_created = 1;
GO

-- 10.
CREATE STATISTICS st_shipcity ON Sales.Orders(shipcity);
DBCC FREEPROCCACHE;
GO

-- 11.
SELECT orderid, custid, shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';
GO

-- 13.
ALTER DATABASE TSQL2012 
 SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT;
EXEC sys.sp_updatestats;
DROP STATISTICS sales.Orders.st_shipcity;
DROP INDEX idx_nc_custid_shipcity ON Sales.Orders;
GO
