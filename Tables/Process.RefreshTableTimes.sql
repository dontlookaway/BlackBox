CREATE TABLE [Process].[RefreshTableTimes]
(
[SchemaName] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[TableName] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL,
[OldRowCount] [int] NULL,
[NewRowCount] [int] NULL,
[UpdateStart] [datetime2] NULL,
[UpdateEnd] [datetime2] NULL,
[OldColumnCount] [int] NULL,
[NewColumnCount] [int] NULL,
[SecondsToRun] [int] NULL,
[MinutesToRun] [int] NULL,
[HoursToRun] [int] NULL
) ON [PRIMARY]
GO
