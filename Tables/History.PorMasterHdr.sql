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
[SUPPLIER] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [PorMasterHdr_timeItem] ON [History].[PorMasterHdr] ([DatabaseName], [SignatureDateTime], [ItemKey]) ON [PRIMARY]

GO
ALTER TABLE [History].[PorMasterHdr] ADD CONSTRAINT [PorMasterHdr_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
