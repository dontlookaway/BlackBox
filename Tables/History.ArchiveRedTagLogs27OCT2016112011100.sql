CREATE TABLE [History].[ArchiveRedTagLogs27OCT2016112011100]
(
[TagID] [int] NOT NULL IDENTITY(1, 1),
[TagDatetime] [datetime2] NULL CONSTRAINT [DF__RedTagLog__TagDa__39836D4D] DEFAULT (getdate()),
[StoredProcDb] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[StoredProcSchema] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[StoredProcName] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UsedByType] [char] (1) COLLATE Latin1_General_BIN NULL,
[UsedByName] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[UsedByDb] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RedTagLogs_StoredProcName] ON [History].[ArchiveRedTagLogs27OCT2016112011100] ([StoredProcName]) INCLUDE ([UsedByName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RedTagLogs_StoredProcSchema] ON [History].[ArchiveRedTagLogs27OCT2016112011100] ([StoredProcSchema]) INCLUDE ([StoredProcName], [TagID], [UsedByName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RedTagLogs_UsedByName] ON [History].[ArchiveRedTagLogs27OCT2016112011100] ([UsedByName]) INCLUDE ([TagDatetime], [UsedByType]) ON [PRIMARY]
GO
ALTER TABLE [History].[ArchiveRedTagLogs27OCT2016112011100] ADD CONSTRAINT [FK__RedTagLog__UsedB__3A779186] FOREIGN KEY ([UsedByType]) REFERENCES [Lookups].[RedTagsUsedByType] ([UsedByType])
GO
EXEC sp_addextendedproperty N'MS_Description', N'history of reports run', 'SCHEMA', N'History', 'TABLE', N'ArchiveRedTagLogs27OCT2016112011100', NULL, NULL
GO