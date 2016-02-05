CREATE TABLE [Lookups].[GenJournalType]
(
[TypeCode] [varchar] (5) COLLATE Latin1_General_BIN NOT NULL,
[TypeDetail] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[GenJournalType] ADD CONSTRAINT [PK__GenJourn__3E1CDC7D38993572] PRIMARY KEY CLUSTERED  ([TypeCode]) ON [PRIMARY]
GO
