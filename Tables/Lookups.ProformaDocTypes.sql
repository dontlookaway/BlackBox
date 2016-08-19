CREATE TABLE [Lookups].[ProformaDocTypes]
(
[DOCUMENTTYPE] [nvarchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DOCUMENTFORMAT] [nvarchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[DocName] [nvarchar] (150) COLLATE Latin1_General_BIN NULL,
[InsertedDate] [datetime2] NULL CONSTRAINT [DF__ProformaD__Inser__676A338E] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[ProformaDocTypes] ADD CONSTRAINT [PfDType] PRIMARY KEY CLUSTERED  ([DOCUMENTTYPE], [DOCUMENTFORMAT]) ON [PRIMARY]
GO
