CREATE TABLE [History].[PorMasterHdr]
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
[ORDERVALUEAFTERCHANGE] [float] NULL,
[ORDERVALUEBEFORECHANGE] [float] NULL,
[PURCHASEORDER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[1STDISCOUNTPERCENT] [float] NULL,
[BUYER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYDATE] [date] NULL,
[CURRENTCOMPANYID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTOPERATINGSYSTEMDATE] [date] NULL,
[CURRENTOPERATINGSYSTEMTIME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CUSTOMER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LANGUAGECODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MINIMUMORDERMASS] [float] NULL,
[MINIMUMORDERVALUE] [float] NULL,
[MINIMUMORDERVOLUME] [float] NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCURRENTGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATOREMAILADDRESS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORPRIMARYGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORDERDUEDATE] [date] NULL,
[ORDERMASS] [float] NULL,
[ORDERVALUE] [float] NULL,
[ORDERVOLUME] [float] NULL,
[REQUISITIONFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[PorMasterHdr] ADD CONSTRAINT [PorMasterHdr_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Logs from PorMasterHdr change logs', 'SCHEMA', N'History', 'TABLE', N'PorMasterHdr', NULL, NULL
GO
