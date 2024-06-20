--- data ranges
DECLARE @BirthDateGT AS datetime = '1960-01-01'
DECLARE @BirthDateLT AS datetime = '1961-01-01'
SELECT [EmployeeID]
      ,[LastName]
      ,[FirstName]
      ,[Title]
      ,[BirthDate]
  FROM [dbo].[Employees]
  WHERE [BirthDate] <= @BirthDateLT
    AND [BirthDate] >= @BirthDateGT

--- wildcard
DECLARE @LastName AS nvarchar(30) = 'B%'
SELECT [EmployeeID]
      ,[LastName]
      ,[FirstName]
      ,[Title]
      ,[BirthDate]
  FROM [dbo].[Employees]
  WHERE [LastName] LIKE @LastName

--- data type conversion
DECLARE @LastNameVarchar AS varchar(60) = 'Buchanan'
SELECT [EmployeeID]
      ,[LastName]
      ,[FirstName]
      ,[Title]
      ,[BirthDate]
  FROM [dbo].[Employees]
  WHERE [LastName] = @LastNameVarchar

--- functions
DECLARE @BirthDateYear AS varchar(4) = '1960'
SELECT [EmployeeID]
      ,[LastName]
      ,[FirstName]
      ,[Title]
      ,[BirthDate]
  FROM [dbo].[Employees]
  WHERE YEAR([BirthDate]) = @BirthDateYear

--- stored procedures
DECLARE @RC AS int
DECLARE @Beginning_Date AS datetime = '1960-01-01'
DECLARE @Ending_Date AS datetime = '2024-01-01'

EXECUTE @RC = [dbo].[Employee Sales by Country] 
   @Beginning_Date
  ,@Ending_Date
GO

--- views
SELECT TOP 20 * 
FROM [dbo].[Invoices]

--- refresh Always Encrypted metadata
DECLARE @name AS NVARCHAR(255) = '[dbo].[Invoices]'
EXECUTE sp_refresh_parameter_encryption @name