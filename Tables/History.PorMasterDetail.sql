CREATE TABLE [History].[PorMasterDetail]
(
[PID] [int] NOT NULL IDENTITY(1, 1),
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SignatureDatetime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ProgramName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Ranking] [bigint] NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[1STDISCOUNTPERCENT] [float] NULL,
[ALLOCATIONLINE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BINLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONDITIONDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONTRACTNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTBASIS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTINGMETHOD] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTMULTIPLIER] [float] NULL,
[CREATEDFROM] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYDATE] [datetime] NULL,
[CURRENTCOMPANYID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTCOMPANYNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CURRENTOPERATINGSYSTEMDATE] [datetime] NULL,
[CURRENTOPERATINGSYSTEMTIME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FOREIGNPRICE] [float] NULL,
[GOODSRECEIVEDNUMBER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[IMPORTFUNCTIONREQUESTED] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ISSUETOJOB] [float] NULL,
[JOB] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBALLOCATIONLINE] [float] NULL,
[JOBALLOCATIONSCOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBCOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBCONFIRMED] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBONHOLD] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOURNAL] [float] NULL,
[JOURNALPOSTINGMONTH] [float] NULL,
[JOURNALPOSTINGYEAR] [float] NULL,
[LANGUAGECODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LEDGERCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LINECOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LINEDUEDATE] [datetime] NULL,
[LINEPREVIOUSLYCOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOT] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LOTEXPIRYDATE] [datetime] NULL,
[LOTONFILE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MANYBINSUSEDTOPOST] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NEWINVENTORYUNITCOST] [float] NULL,
[NONSTOCKEDFLAG] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATION] [float] NULL,
[OPERATORCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORCURRENTGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATOREMAILADDRESS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORLOCATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORNAME] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OPERATORPRIMARYGROUPCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORDERUNITOFMEASURE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ORIGINATOR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OUTSTANDINGORDERQUANTITY] [float] NULL,
[PORMASTERDETAILKEY] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PREVIOUSINVENTORYUNITCOST] [float] NULL,
[PREVIOUSLEDGERCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PREVIOUSLINEDUEDATE] [datetime] NULL,
[PREVIOUSOUTSTANDINGORDERQUANTITY] [float] NULL,
[PREVIOUSPRICE] [float] NULL,
[PREVIOUSQUANTITY] [float] NULL,
[PRICE] [float] NULL,
[PRICEORDERRECEIVEDAT] [float] NULL,
[PRICINGUNITOFMEASURE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRODUCTCLASS] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEORDER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PURCHASEORDERLINE] [float] NULL,
[PURCHASEORDERPRICE] [float] NULL,
[QUANTITY] [float] NULL,
[QUANTITYBEINGRECEIVED] [float] NULL,
[REQUISITION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[REQUISITIONLINE] [float] NULL,
[REQUISITIONUSER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDERCOMPLETE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SALESORDERLINE] [float] NULL,
[SOURCEAPPLICATION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKDESCRIPTION] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKINGUNITOFMEASURE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIER] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SYSTEMPRICE] [float] NULL,
[WAREHOUSE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CAPEX] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PREVIOUS1STDISCOUNTPERCENT] [float] NULL,
[PREVIOUSFOREIGNPRICE] [float] NULL,
[QUANTITYADVISED] [float] NULL,
[QUANTITYCOUNTED] [float] NULL,
[QUANTITYINSPECTED] [float] NULL,
[QUANTITYSTILLININSPECTION] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[PorMasterDetail] ADD CONSTRAINT [PorMasterDetail_ID] PRIMARY KEY CLUSTERED  ([SignatureDatetime], [Operator], [ProgramName], [ItemKey], [DatabaseName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
