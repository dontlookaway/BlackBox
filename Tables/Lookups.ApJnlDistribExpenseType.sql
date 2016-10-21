CREATE TABLE [Lookups].[ApJnlDistribExpenseType]
(
[ExpenseType] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ExpenseTypeDesc] [varchar] (150) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[ApJnlDistribExpenseType] ADD CONSTRAINT [ExpenseTypeKey] PRIMARY KEY CLUSTERED  ([ExpenseType]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'ApJnlDistribExpenseType Descriptions for use in reports', 'SCHEMA', N'Lookups', 'TABLE', N'ApJnlDistribExpenseType', NULL, NULL
GO
