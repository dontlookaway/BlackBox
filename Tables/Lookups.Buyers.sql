CREATE TABLE [Lookups].[Buyers]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[BuyerName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'list of all buyers', 'SCHEMA', N'Lookups', 'TABLE', N'Buyers', NULL, NULL
GO
