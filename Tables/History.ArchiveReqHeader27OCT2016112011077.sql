CREATE TABLE [History].[ArchiveReqHeader27OCT2016112011077]
(
[RID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SignatureDatetime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ProgramName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Ranking] [bigint] NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DATEREQUISITIONRAISED] [datetime] NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORIGINATOR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[REQUISITION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[REQUISITIONUSER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ROUTEDTOREQUISITIONUSER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VALUEOFREQUISITION] [float] NULL
) ON [PRIMARY]
GO
