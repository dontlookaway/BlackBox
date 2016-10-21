CREATE TABLE [Lookups].[GenJournalDetailSource]
(
[GJSource] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[GJSourceDetail] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[GenJournalDetailSource] ADD CONSTRAINT [PK__GenJourn__8DE11BC548C2CC0B] PRIMARY KEY CLUSTERED  ([GJSource]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of GenJournal DetailSource', 'SCHEMA', N'Lookups', 'TABLE', N'GenJournalDetailSource', NULL, NULL
GO
