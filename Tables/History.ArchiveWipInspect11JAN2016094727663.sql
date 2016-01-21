CREATE TABLE [History].[ArchiveWipInspect11JAN2016094727663]
(
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SignatureDateTime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[ComputerName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[ProgramName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ConditionName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[AlreadyEntered] [bit] NULL,
[BINLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EXPIRYDATE] [date] NULL,
[INSPECTIONREFERENCE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOTNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RELEASE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VERSION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WIPINSPECTKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
