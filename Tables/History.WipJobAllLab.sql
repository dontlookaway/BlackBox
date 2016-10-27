CREATE TABLE [History].[WipJobAllLab]
(
[WID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SignatureDatetime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ProgramName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Ranking] [bigint] NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[EMPLOYEE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ENTRYDATE] [datetime] NULL,
[INSPECTIONFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MACHINE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATION] [float] NULL,
[QUANTITYCOMPLETED] [float] NULL,
[WIPJOBALLLABKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WORKCENTER] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[WipJobAllLab] ADD CONSTRAINT [WipJobAllLab_ID] PRIMARY KEY CLUSTERED  ([SignatureDatetime], [Operator], [ProgramName], [ItemKey], [DatabaseName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
