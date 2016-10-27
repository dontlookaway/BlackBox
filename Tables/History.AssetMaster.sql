CREATE TABLE [History].[AssetMaster]
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
[ASSETCOSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ASSETGROUPCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BOOKVALDEPBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BRANCHBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BVASSETCOSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BVCURRENTVALUEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BVDEPNTHISPERIODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BVDEPNTHISYRBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEPNSTARTPERIODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEPNSTARTYEARBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DESCRIPTIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIRSTINSTALDATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[IDCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOCATIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NUMBEROFPERIODSBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEDATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEPERIODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEYEARBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RESIDUALVALUEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOLDDATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOLDPERIODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOLDYEARBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STARTDEPDATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STATGLBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUSPENDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TOTALPERIODSTDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERDEF3BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERDEF4BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VARYINGANNIVERSARYBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[AssetMaster] ADD CONSTRAINT [AssetMaster_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
