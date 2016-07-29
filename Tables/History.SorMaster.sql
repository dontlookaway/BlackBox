CREATE TABLE [History].[SorMaster]
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
[CURRENTCOMPANYDATE] [date] NULL,
[CURRENTCOMPANYID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTOPERATINGSYSTEMDATE] [date] NULL,
[CURRENTOPERATINGSYSTEMTIME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CUSTOMERCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[INVOICEDATEDAYSDIFFERENT] [float] NULL,
[INVOICEDATEENTERED] [date] NULL,
[LANGUAGECODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NEWORDERSTATUS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCURRENTGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATOREMAILADDRESS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORPRIMARYGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORDERSTATUS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORDERVALUE] [float] NULL,
[SALESORDER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDERNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[SorMaster] ADD CONSTRAINT [SorMaster_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO