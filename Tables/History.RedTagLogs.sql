CREATE TABLE [History].[RedTagLogs]
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
CREATE NONCLUSTERED INDEX [IX_RedTagLogs_StoredProcName] ON [History].[RedTagLogs] ([StoredProcName]) INCLUDE ([UsedByName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RedTagLogs_StoredProcSchema] ON [History].[RedTagLogs] ([StoredProcSchema]) INCLUDE ([StoredProcName], [TagID], [UsedByName]) ON [PRIMARY]
GO
ALTER TABLE [History].[RedTagLogs] ADD CONSTRAINT [FK__RedTagLog__UsedB__3A779186] FOREIGN KEY ([UsedByType]) REFERENCES [Lookups].[RedTagsUsedByType] ([UsedByType])
GO
