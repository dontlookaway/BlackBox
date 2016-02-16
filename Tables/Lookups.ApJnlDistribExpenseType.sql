CREATE TABLE [Lookups].[ApJnlDistribExpenseType]
(
[ExpenseType] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ExpenseTypeDesc] [varchar] (150) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [Lookups].[ApJnlDistribExpenseType] ADD 
CONSTRAINT [ExpenseTypeKey] PRIMARY KEY CLUSTERED  ([ExpenseType]) ON [PRIMARY]
GO
