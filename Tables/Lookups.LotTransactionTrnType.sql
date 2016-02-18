CREATE TABLE [Lookups].[LotTransactionTrnType]
(
[TrnType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[TrnTypeDescription] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [Lookups].[LotTransactionTrnType] ADD 
CONSTRAINT [LTTrnType] PRIMARY KEY CLUSTERED  ([TrnType]) ON [PRIMARY]
GO
