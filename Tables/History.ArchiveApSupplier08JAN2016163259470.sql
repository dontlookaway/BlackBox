CREATE TABLE [History].[ArchiveApSupplier08JAN2016163259470]
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
[APINVOICEDISCOUNT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[APINVOICETERMSCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BANKACCOUNTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BANKBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BANKBRANCHBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BANKBRANCHCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BRANCHBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENCY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYDATE] [date] NULL,
[CURRENTCOMPANYID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTOPERATINGSYSTEMDATE] [date] NULL,
[CURRENTOPERATINGSYSTEMTIME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEFAULTTAXCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DELIVERYTERMSEU] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EFTBANKACCOUNTTYPE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GEOGRAPHICAREA] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GRNMATCHINGALLOWEDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GRNMATCHINGREQUIRED] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LANGUAGECODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LCTREQUIRED] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LCTREQUIREDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOCALCURRENCY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MINPURCHASEORDERMASS] [float] NULL,
[MINPURCHASEORDERVALUELOCAL] [float] NULL,
[MINPURCHASEORDERVOLUME] [float] NULL,
[NATIONALITYCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ONHOLDFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCURRENTGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATOREMAILADDRESS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORPRIMARYGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PAYBYEFT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PAYBYEFTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PAYE1099REFERENCE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[POALLOWEDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEORDERLINEDISCOUNT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEORDERSALLOWED] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERBANK] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERBANKACCOUNT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERBRANCH] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERCHECKNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERCHECKNAMEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERCLASS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERONHOLDFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERSHORTNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERTYPE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TAXREGISTRATIONNUMBEREU] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TERMSCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERDEFINEDFIELD1] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERDEFINEDFIELD2] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WITHHOLDINGTAXCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WITHHOLDINGTAXID] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
