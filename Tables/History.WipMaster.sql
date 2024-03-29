CREATE TABLE [History].[WipMaster]
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
[BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BINLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTBASIS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTMULTIPLIERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYDATE] [date] NULL,
[CURRENTCOMPANYID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTLABORVALUE] [float] NULL,
[CURRENTMATERIALVALUE] [float] NULL,
[CURRENTOPERATINGSYSTEMDATE] [date] NULL,
[CURRENTOPERATINGSYSTEMTIME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEFAULTBINBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIFO/LIFOCOST] [float] NULL,
[IMPORTFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[INSPECTIONQUANTITY] [float] NULL,
[INSPECTIONREFERENCE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBCOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBTYPE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOURNAL] [float] NULL,
[JOURNALPOSTINGMONTH] [float] NULL,
[JOURNALPOSTINGYEAR] [float] NULL,
[LANGUAGECODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOTNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MASTERJOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MULTIPLEBINFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCURRENTGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATOREMAILADDRESS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORPRIMARYGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OUTSTANDINGQUANTITY] [float] NULL,
[QUANTITY] [float] NULL,
[QUANTITYPLUSINSPECTIONQUANTITY] [float] NULL,
[RECEIPTCOST] [float] NULL,
[RELEASE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDERLINECOMPLETEFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDERLINENUMBER] [float] NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TOTALLABOREXPECTEDVALUE] [float] NULL,
[TOTALLABORISSUEDVALUE] [float] NULL,
[TOTALMATERIALEXPECTEDVALUE] [float] NULL,
[TOTALMATERIALISSUEDVALUE] [float] NULL,
[UPDATESALESORDERLINEORDERQUANTITY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VERSION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[WipMaster] ADD CONSTRAINT [WipMaster_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
