CREATE TABLE [Lookups].[LedgerGroupMaps]
(
[GlGroup] [varchar] (500) COLLATE Latin1_General_BIN NOT NULL,
[Map1] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Map2] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Map3] [varchar] (500) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[LedgerGroupMaps] ADD CONSTRAINT [PK__LedgerGr__34CC5B12AF214404] PRIMARY KEY CLUSTERED  ([GlGroup]) ON [PRIMARY]
GO
