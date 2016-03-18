CREATE TABLE [Lookups].[GenJournalCtlSource]
(
[Source] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SourceDescription] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[GenJournalCtlSource] ADD CONSTRAINT [PK__GenJourn__09FAC3774842BCD4] PRIMARY KEY CLUSTERED  ([Source]) ON [PRIMARY]
GO
