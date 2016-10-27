CREATE TABLE [History].[WipJobAllMat]
(
[WID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SignatureDatetime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ProgramName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Ranking] [bigint] NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QUANTITY] [float] NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WIPJOBALLMATKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[WipJobAllMat] ADD CONSTRAINT [WipJobAllMat_ID] PRIMARY KEY CLUSTERED  ([SignatureDatetime], [Operator], [ProgramName], [ItemKey], [DatabaseName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
