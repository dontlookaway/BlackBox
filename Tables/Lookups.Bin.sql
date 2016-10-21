CREATE TABLE [Lookups].[Bin]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Bin] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'list of bins to be used in reports', 'SCHEMA', N'Lookups', 'TABLE', N'Bin', NULL, NULL
GO
