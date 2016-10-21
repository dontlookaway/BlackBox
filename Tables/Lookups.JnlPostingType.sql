CREATE TABLE [Lookups].[JnlPostingType]
(
[JnlPostingType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[JnlPostingTypeDesc] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[JnlPostingType] ADD CONSTRAINT [PK__JnlPosti__67A396901C72751C] PRIMARY KEY CLUSTERED  ([JnlPostingType]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'JnlPosting Type description', 'SCHEMA', N'Lookups', 'TABLE', N'JnlPostingType', NULL, NULL
GO
