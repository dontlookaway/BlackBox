CREATE TABLE [Lookups].[GlExpenseCode]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[GlExpenseCode] [char] (5) COLLATE Latin1_General_BIN NULL,
[GlExpenseDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Gl Expense code descriptions', 'SCHEMA', N'Lookups', 'TABLE', N'GlExpenseCode', NULL, NULL
GO
