CREATE TABLE [History].[ArchiveWipJobAllLab11JAN2016094727670]
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
[EMPLOYEE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ENTRYDATE] [date] NULL,
[INSPECTIONFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MACHINE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATION] [float] NULL,
[QUANTITYCOMPLETED] [float] NULL,
[WIPJOBALLLABKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WORKCENTER] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
