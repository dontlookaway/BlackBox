CREATE TABLE [History].[WipJobAllMat]
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
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QUANTITY] [float] NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WIPJOBALLMATKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [WipJobAllMat_timeItem] ON [History].[WipJobAllMat] ([DatabaseName], [SignatureDateTime], [ItemKey]) ON [PRIMARY]

GO
ALTER TABLE [History].[WipJobAllMat] ADD CONSTRAINT [WipJobAllMat_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
