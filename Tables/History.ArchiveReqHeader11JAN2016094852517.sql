CREATE TABLE [History].[ArchiveReqHeader11JAN2016094852517]
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
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DATEREQUISITIONRAISED] [date] NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORIGINATOR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[REQUISITION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[REQUISITIONUSER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ROUTEDTOREQUISITIONUSER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VALUEOFREQUISITION] [float] NULL
) ON [PRIMARY]
GO
