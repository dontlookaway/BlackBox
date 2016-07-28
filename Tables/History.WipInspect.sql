CREATE TABLE [History].[WipInspect]
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
[WIPINSPECTKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTERNATEWAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QUANTITY] [float] NULL,
[ALTWAREHOUSEFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[WipInspect] ADD CONSTRAINT [WipInspect_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
