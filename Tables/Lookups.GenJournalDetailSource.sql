CREATE TABLE [Lookups].[GenJournalDetailSource]
(
[GJSource] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[GJSourceDetail] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [Lookups].[GenJournalDetailSource] ADD 
CONSTRAINT [PK__GenJourn__8DE11BC548C2CC0B] PRIMARY KEY CLUSTERED  ([GJSource]) ON [PRIMARY]
GO
