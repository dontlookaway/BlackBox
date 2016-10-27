CREATE TABLE [History].[WipInspect]
(
[WID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SignatureDatetime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ProgramName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Ranking] [bigint] NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[BINLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EXPIRYDATE] [datetime] NULL,
[INSPECTIONREFERENCE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOTNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RELEASE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VERSION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WIPINSPECTKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTERNATEWAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTWAREHOUSEFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QUANTITY] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[WipInspect] ADD CONSTRAINT [WipInspect_ID] PRIMARY KEY CLUSTERED  ([SignatureDatetime], [Operator], [ProgramName], [ItemKey], [DatabaseName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
