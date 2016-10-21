CREATE TABLE [Lookups].[GLAccountType]
(
[GLAccountType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[GLAccountTypeDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of GL AccountType', 'SCHEMA', N'Lookups', 'TABLE', N'GLAccountType', NULL, NULL
GO
