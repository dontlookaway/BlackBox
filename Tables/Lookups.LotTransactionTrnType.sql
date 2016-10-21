CREATE TABLE [Lookups].[LotTransactionTrnType]
(
[TrnType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[TrnTypeDescription] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[LotTransactionTrnType] ADD CONSTRAINT [LTTrnType] PRIMARY KEY CLUSTERED  ([TrnType]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'LotTransaction TrnType Description', 'SCHEMA', N'Lookups', 'TABLE', N'LotTransactionTrnType', NULL, NULL
GO
