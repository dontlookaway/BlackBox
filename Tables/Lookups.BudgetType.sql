CREATE TABLE [Lookups].[BudgetType]
(
[BudgetType] [char] (1) COLLATE Latin1_General_BIN NULL,
[BudgetTypeDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'list of budget types to be used in reports', 'SCHEMA', N'Lookups', 'TABLE', N'BudgetType', NULL, NULL
GO
