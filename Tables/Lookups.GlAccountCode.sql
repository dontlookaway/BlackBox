CREATE TABLE [Lookups].[GlAccountCode]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[GlAccountCode] [char] (5) COLLATE Latin1_General_BIN NULL,
[GlAccountDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of GL AccountCode', 'SCHEMA', N'Lookups', 'TABLE', N'GlAccountCode', NULL, NULL
GO
