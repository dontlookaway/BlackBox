CREATE TABLE [Lookups].[AdmTransactionIDs]
(
[TransactionId] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'AdmTransaction Descriptions for use in reports', 'SCHEMA', N'Lookups', 'TABLE', N'AdmTransactionIDs', NULL, NULL
GO
