CREATE TABLE [Lookups].[LedgerDepts]
(
[Company] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Department] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DepartmentName] [varchar] (250) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [LedgerDeptsCo] ON [Lookups].[LedgerDepts] ([Company], [Department]) ON [PRIMARY]
GO
