CREATE TABLE [Lookups].[GenTransactionSource]
(
[Source] [char] (2) COLLATE Latin1_General_BIN NULL,
[SourceDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of Gen Transaction Source', 'SCHEMA', N'Lookups', 'TABLE', N'GenTransactionSource', NULL, NULL
GO
