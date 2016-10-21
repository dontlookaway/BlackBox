CREATE TABLE [Lookups].[GenJournalCtlJnlSource]
(
[GenJournalCtlJnlSource] [char] (2) COLLATE Latin1_General_BIN NULL,
[GenJournalCtlJnlSourceDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Description of GenJournal CtlJnlSource', 'SCHEMA', N'Lookups', 'TABLE', N'GenJournalCtlJnlSource', NULL, NULL
GO
