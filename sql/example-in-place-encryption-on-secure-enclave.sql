--- Errors since lots of restrictions with Always Encrypted
--- https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/always-encrypted-database-engine?view=sql-server-ver16#limitations

-- Msg 5074, Level 16, State 1, Line 1
-- The index 'PostalCode' is dependent on column 'PostalCode'.
-- Msg 4922, Level 16, State 9, Line 1
-- ALTER TABLE ALTER COLUMN PostalCode failed because one or more objects access this column.
--- Error Index exists on column being converted
DROP INDEX [LastName] ON [dbo].[Employees]
GO

-- Msg 5074, Level 16, State 1, Line 1
-- The index 'PostalCode' is dependent on column 'PostalCode'.
-- Msg 4922, Level 16, State 9, Line 1
-- ALTER TABLE ALTER COLUMN PostalCode failed because one or more objects access this column.
--- Error Index exists on column being converted
DROP INDEX [PostalCode] ON [dbo].[Employees]
GO

-- Msg 5074, Level 16, State 1, Line 1
-- The object 'CK_Birthdate' is dependent on column 'BirthDate'.
-- Msg 4922, Level 16, State 9, Line 1
-- ALTER TABLE ALTER COLUMN BirthDate failed because one or more objects access this column.
--- Always Encrypted columns can't have check constraints... now check of date being less than today needs to be in the application
--- ALTER TABLE [dbo].[Employees] WITH NOCHECK ADD CONSTRAINT [CK_Birthdate] CHECK (([BirthDate]<getdate()))
ALTER TABLE [dbo].[Employees]
DROP CONSTRAINT [CK_Birthdate]

-- Msg 11427, Level 16, State 1, Line 1
-- The online ALTER COLUMN operation cannot be performed for table 'Employees' because column 'Notes' currently has or is getting altered into an unsupported datatype: text, ntext, image, CLR type or FILESTREAM. The operation must be performed offline.
--- needed to convert from ntext datatype existing on table not compatible with AE convert
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Notes] [nvarchar](max);
GO

-- Msg 11427, Level 16, State 1, Line 1
-- The online ALTER COLUMN operation cannot be performed for table 'Employees' because column 'Photo' currently has or is getting altered into an unsupported datatype: text, ntext, image, CLR type or FILESTREAM. The operation must be performed offline.
--- needed to move Photo to new table since image datatype existing on table not compatible with AE convert
SELECT [EmployeeID], [Photo] INTO [EmployeePhotos]
FROM [Employees]
WHERE [Photo] IS NOT NULL;
GO

ALTER TABLE [dbo].[Employees]
DROP COLUMN [Photo];
GO

ALTER TABLE [dbo].[EmployeePhotos] ADD  CONSTRAINT [PK_EmployeePhotos] PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[EmployeePhotos]  WITH NOCHECK ADD  CONSTRAINT [FK_EmployeePhotos_Employees] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employees] ([EmployeeID]);
GO
ALTER TABLE [dbo].[EmployeePhotos] CHECK CONSTRAINT [FK_EmployeePhotos_Employees];
GO

--- now do the inplace conversion
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

ALTER TABLE [dbo].[Employees]
ALTER COLUMN [LastName] [nvarchar](20) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NOT NULL
WITH
(ONLINE = ON);
GO

ALTER TABLE [dbo].[Employees]
ALTER COLUMN [FirstName] [nvarchar](10) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NOT NULL
WITH
(ONLINE = ON);
GO

-- can't set collation on datetime column
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [BirthDate] [datetime] 
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
WITH
(ONLINE = ON);
GO

ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Address] [nvarchar](60) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
WITH
(ONLINE = ON);
GO

ALTER TABLE [dbo].[Employees]
ALTER COLUMN [PostalCode] [nvarchar](10) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Deterministic, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
WITH
(ONLINE = ON);
GO

ALTER TABLE [dbo].[Employees]
ALTER COLUMN [HomePhone] [nvarchar](24) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
WITH
(ONLINE = ON);
GO

--- need to encrypt notes as well since names are used
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Notes] [nvarchar](max) COLLATE Latin1_General_BIN2
ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [CEK1Enclaves], ENCRYPTION_TYPE = Randomized, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
WITH
(ONLINE = ON);
GO


CREATE NONCLUSTERED INDEX [LastName] ON [dbo].[Employees]
(
	[LastName] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [PostalCode] ON [dbo].[Employees]
(
	[PostalCode] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
