CREATE TABLE [History].[InvMaster]
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
[ABCANALYSISREQBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ABCCOSTINGREQBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTERNATEKEY1BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTERNATEKEY2BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTERNATEUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTMETHODFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTREDUCTIONFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ALTSISOFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BASISBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BATCHBILLBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BULKISSUEFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYINGRULEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CLEARINGFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONVFACTALTUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONVFACTOTHUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CONVMULDIVBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COSTUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[COUNTRYOFORIGINBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CYCLECOUNTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DECIMALSBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DEMANDTIMEFENCEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DESCRIPTIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DISTWAREHOUSETOUSEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DOCKTOSTOCKBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DRAWOFFICENUMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EBQBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EBQPANBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ECCFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ECCUSERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIXOVERHEADBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIXTIMEPERIODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GROSSREQRULEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GSTTAXCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[INCLINSTRVALIDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[INSPECTIONFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ISSMULTLOTSFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JOBCLASSIFICATIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[KITTYPEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LABOURCOSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LCTREQUIREDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LEADTIMEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LISTPRICEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LONGDESCBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MAKETOORDERFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MANUALCOSTFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MANUFACTUREUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MANUFLEADTIMEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MASSBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MATERIALCOSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MINPRICEPCTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MPSFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MULDIVBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MUMMULDIVBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NOALTUNITBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ONHOLDREASONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OTHERTAXCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OTHERUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OUTPUTMASSFLAGBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PANSIZEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PARTCATEGORYBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PERCENTAGEYIELDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PHANTOMIFCOMPBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PLANNERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRCINCLGSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRICECATEGORYBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRICEMETHODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRICETYPEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRODUCTCLASSBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PRODUCTGROUPBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RELEASEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RESOURCECODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[RETURNABLEITEMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SERENTRYATSALEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SERIALMETHODBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SHELFLIFEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SPECIFICGRAVITYBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKANDALTUMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKMOVEMENTREQBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKONHOLDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STOCKUOMBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUBCONTRACTCOSTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPERCESSIONDATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLEMENTARYCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLEMENTARYUNITBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SUPPLIERBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TARIFFCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TAXCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TRACEABLETYPEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UNITQTYBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERFIELD1BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERFIELD2BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERFIELD3BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERFIELD4BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[USERFIELD5BEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VARIABLEOVERHEADBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VERSIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VOLUMEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WAREHOUSETOUSEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WIPCTLGLCODEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[WITHHOLDINGTAXEXPENSETYPEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[InvMaster] ADD CONSTRAINT [InvMaster_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
