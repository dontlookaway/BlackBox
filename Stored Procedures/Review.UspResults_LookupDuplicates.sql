SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Review].[UspResults_LookupDuplicates]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_LookupDuplicates' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#DupeCheck]
            (
              [TableName] Varchar(150)
            , [Company] Varchar(150)
            , [ID] Varchar(500)
            , [DescriptionField] Varchar(1000)
            , [DupeCount] Int
            );

        Insert  [#DupeCheck]
                ( [TableName]
                , [Company]
                , [ID]
                , [DescriptionField]
                , [DupeCount]
                )
                Select  [t].[TableName]
                      , [t].[Company]
                      , [t].[ID]
                      , [t].[DescriptionField]
                      , [t].[EntryCount]
                From    ( Select    [TableName] = '[Lookups].[AdmTransactionIDs]'
                                  , [Company] = 'All'
                                  , [ID] = Convert(Varchar(150) , [ATID].[TransactionId])
                                  , [DescriptionField] = Convert(Varchar(500) , [ATID].[TransactionDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[AdmTransactionIDs] [ATID]
                          Group By  Convert(Varchar(150) , [ATID].[TransactionId])
                                  , [ATID].[TransactionDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[ApJnlDistribExpenseType]'
                                  , [Company] = 'All'
                                  , [ID] = Convert(Varchar(150) , [AJDET].[ExpenseType])
                                  , [DescriptionField] = Convert(Varchar(500) , [AJDET].[ExpenseTypeDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[ApJnlDistribExpenseType] [AJDET]
                          Group By  Convert(Varchar(150) , [AJDET].[ExpenseType])
                                  , [AJDET].[ExpenseTypeDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[ArInvoicePayTrnType]'
                                  , [Company] = 'All'
                                  , [ID] = Convert(Varchar(150) , [AIPTT].[TrnType])
                                  , [DescriptionField] = Convert(Varchar(500) , [AIPTT].[TrnTypeDesc])
                                  , Count(1)
                          From      [Lookups].[ArInvoicePayTrnType] [AIPTT]
                          Group By  Convert(Varchar(150) , [AIPTT].[TrnType])
                                  , [AIPTT].[TrnTypeDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[BankBalances]'
                                  , [Company] = [BB].[DatabaseName]
                                  , [ID] = Convert(Varchar(150) , [BB].[Bank])
                                    + Convert(Varchar(150) , [BB].[DateTimeOfBalance])
                                  , [DescriptionField] = Convert(Varchar(500) , [BB].[BankDescription])
                                  , Count(1)
                          From      [Lookups].[BankBalances] [BB]
                          Group By  Convert(Varchar(150) , [BB].[Bank])
                                    + Convert(Varchar(150) , [BB].[DateTimeOfBalance])
                                  , [BB].[DatabaseName]
                                  , Convert(Varchar(500) , [BB].[BankDescription])
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[Bin]'
                                  , [Company] = [B].[Company]
                                  , [B].[Bin]
                                  , [DescriptionField] = Convert(Varchar(500) , Null)
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[Bin] [B]
                          Group By  [B].[Company]
                                  , [B].[Bin]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[BudgetType]'
                                  , [Company] = 'All'
                                  , [ID] = Convert(Varchar(150) , [BT].[BudgetType])
                                  , [DescriptionField] = Convert(Varchar(500) , [BT].[BudgetTypeDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[BudgetType] [BT]
                          Group By  [BT].[BudgetType]
                                  , [BT].[BudgetTypeDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[CompanyNames]'
                                  , [Company] = [CN].[Company]
                                  , [ID] = [CN].[Company]
                                  , [DescriptionField] = Convert(Varchar(500) , ( [CN].[ShortName]
                                                              + ' - '
                                                              + [CN].[CompanyName]
                                                              + ' - '
                                                              + [CN].[Currency] ))
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[CompanyNames] [CN]
                          Group By  [CN].[ShortName] + ' - '
                                    + [CN].[CompanyName] + ' - '
                                    + [CN].[Currency]
                                  , [CN].[Company]
                                  , [CN].[Company]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[CurrencyRates]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [CR].[StartDateTime])
                                    + ' - '
                                    + Convert(Varchar(150) , [CR].[EndDateTime])
                                    + ' ' + [CR].[Currency]
                                  , [DescriptionField] = Convert(Varchar(500) , Null)
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[CurrencyRates] [CR]
                          Group By  Convert(Varchar(150) , [CR].[StartDateTime])
                                    + ' - '
                                    + Convert(Varchar(150) , [CR].[EndDateTime])
                                    + ' ' + [CR].[Currency]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GenJournalCtlJnlSource]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [GJCJS].[GenJournalCtlJnlSource])
                                  , [DescriptionField] = Convert(Varchar(500) , [GJCJS].[GenJournalCtlJnlSourceDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GenJournalCtlJnlSource] [GJCJS]
                          Group By  [GJCJS].[GenJournalCtlJnlSource]
                                  , [GJCJS].[GenJournalCtlJnlSourceDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GenJournalCtlSource]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [GJCS].[Source])
                                  , [DescriptionField] = Convert(Varchar(500) , [GJCS].[SourceDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GenJournalCtlSource] [GJCS]
                          Group By  [GJCS].[Source]
                                  , [GJCS].[SourceDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GenJournalDetailSource]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [GJDS].[GJSource])
                                  , [DescriptionField] = Convert(Varchar(500) , [GJDS].[GJSourceDetail])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GenJournalDetailSource] [GJDS]
                          Group By  [GJDS].[GJSource]
                                  , [GJDS].[GJSourceDetail]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GenJournalType]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [GJT].[TypeCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [GJT].[TypeDetail])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GenJournalType] [GJT]
                          Group By  [GJT].[TypeCode]
                                  , [GJT].[TypeDetail]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GenTransactionSource]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [GTS].[Source])
                                  , [DescriptionField] = Convert(Varchar(500) , [GTS].[SourceDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GenTransactionSource] [GTS]
                          Group By  [GTS].[Source]
                                  , [GTS].[SourceDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GlAnalysisCategory]'
                                  , [Company] = [GAC].[Company]
                                  , [ID] = Convert(Varchar(150) , [GAC].[GlAnalysisCategory])
                                  , [DescriptionField] = Convert(Varchar(500) , Null)
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GlAnalysisCategory] [GAC]
                          Group By  [GAC].[Company]
                                  , [GAC].[GlAnalysisCategory]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[GlExpenseCode]'
                                  , [Company] = [GEC].[Company]
                                  , [ID] = Convert(Varchar(150) , [GEC].[GlExpenseCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [GEC].[GlExpenseDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[GlExpenseCode] [GEC]
                          Group By  [GEC].[Company]
                                  , [GEC].[GlExpenseCode]
                                  , [GEC].[GlExpenseDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[HolidayDays]'
                                  , [Company] = 'ALL'
                                  , [ID] = [HD].[Country] + ' - '
                                    + Convert(Varchar(150) , [HD].[HolidayDate])
                                  , [DescriptionField] = Convert(Varchar(500) , [HD].[HolidayDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[HolidayDays] [HD]
                          Group By  [HD].[Country] + ' - '
                                    + Convert(Varchar(150) , [HD].[HolidayDate])
                                  , [HD].[HolidayDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[InvMaster_PartCategory]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [IMPC].[PartCategoryCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [IMPC].[PartCategoryDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[InvMaster_PartCategory] [IMPC]
                          Group By  [IMPC].[PartCategoryCode]
                                  , [IMPC].[PartCategoryDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[JnlPostingType]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [JPT].[JnlPostingType])
                                  , [DescriptionField] = Convert(Varchar(500) , [JPT].[JnlPostingTypeDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[JnlPostingType] [JPT]
                          Group By  [JPT].[JnlPostingType]
                                  , [JPT].[JnlPostingTypeDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[JnlStatus]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [JS].[JnlStatus])
                                  , [DescriptionField] = Convert(Varchar(500) , [JS].[JnlStatusDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[JnlStatus] [JS]
                          Group By  [JS].[JnlStatus]
                                  , [JS].[JnlStatusDesc]
                          Having    Count(1) > 1
                          Union
                  /*Select    [TableName] = '[Lookups].[LedgerDepts]'
                          , [Company] = [LD].[Company]
                          , [ID] = Convert(Varchar(150) , [LD].[Department])
                          , [DescriptionField] = Convert(Varchar(500) , [LD].[DepartmentName])
                          , [EntryCount] = Count(1)
                  From      [Lookups].[LedgerDepts] [LD]
                  Group By  [LD].[Company]
                          , [LD].[Department]
                          , [LD].[DepartmentName]
                  Having    Count(1) > 1
                  Union*/
                          Select    [TableName] = '[Lookups].[LotTransactionTrnType]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [LTTT].[TrnType])
                                  , [DescriptionField] = Convert(Varchar(500) , [LTTT].[TrnTypeDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[LotTransactionTrnType] [LTTT]
                          Group By  [LTTT].[TrnType]
                                  , [LTTT].[TrnTypeDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[MCompleteFlag]'
                                  , [Company] = [MCF].[Company]
                                  , [ID] = Convert(Varchar(150) , [MCF].[MCompleteFlagCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [MCF].[MCompleteFlagDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[MCompleteFlag] [MCF]
                          Group By  [MCF].[Company]
                                  , [MCF].[MCompleteFlagCode]
                                  , [MCF].[MCompleteFlagDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[PorLineType]'
                                  , [Company] = 'ALL'
                                  , [ID] = Convert(Varchar(150) , [PLT].[PorLineType])
                                  , [DescriptionField] = Convert(Varchar(500) , [PLT].[PorLineTypeDesc])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[PorLineType] [PLT]
                          Group By  [PLT].[PorLineType]
                                  , [PLT].[PorLineTypeDesc]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[ProductClass]'
                                  , [Company] = [PC].[Company]
                                  , [ID] = Convert(Varchar(150) , [PC].[ProductClass])
                                  , [DescriptionField] = Convert(Varchar(500) , [PC].[ProductClassDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[ProductClass] [PC]
                          Group By  [PC].[Company]
                                  , [PC].[ProductClass]
                                  , [PC].[ProductClassDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[PurchaseOrderStatus]'
                                  , [Company] = [POS].[Company]
                                  , [ID] = Convert(Varchar(150) , [POS].[OrderStatusCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [POS].[OrderStatusDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[PurchaseOrderStatus] [POS]
                          Group By  [POS].[Company]
                                  , [POS].[OrderStatusCode]
                                  , [POS].[OrderStatusDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[PurchaseOrderTaxStatus]'
                                  , [Company] = [POTS].[Company]
                                  , [ID] = Convert(Varchar(150) , [POTS].[TaxStatusCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [POTS].[TaxStatusDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[PurchaseOrderTaxStatus] [POTS]
                          Group By  [POTS].[Company]
                                  , [POTS].[TaxStatusCode]
                                  , [POTS].[TaxStatusDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[PurchaseOrderType]'
                                  , [Company] = [POT].[Company]
                                  , [ID] = Convert(Varchar(150) , [POT].[OrderTypeCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [POT].[OrderTypeDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[PurchaseOrderType] [POT]
                          Group By  [POT].[Company]
                                  , [POT].[OrderTypeCode]
                                  , [POT].[OrderTypeDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[ReqnStatus]'
                                  , [Company] = [RS].[Company]
                                  , [ID] = Convert(Varchar(150) , [RS].[ReqnStatusCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [RS].[ReqnStatusDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[ReqnStatus] [RS]
                          Group By  [RS].[Company]
                                  , [RS].[ReqnStatusCode]
                                  , [RS].[ReqnStatusDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[SalesOrderLineType]'
                                  , [Company] = [SOLT].[Company]
                                  , [ID] = Convert(Varchar(150) , [SOLT].[LineTypeCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [SOLT].[LineTypeDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[SalesOrderLineType] [SOLT]
                          Group By  [SOLT].[Company]
                                  , [SOLT].[LineTypeCode]
                                  , [SOLT].[LineTypeDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[SalesOrderStatus]'
                                  , [Company] = [SOS].[Company]
                                  , [ID] = Convert(Varchar(150) , [SOS].[OrderStatusCode])
                                  , [DescriptionField] = Convert(Varchar(500) , [SOS].[OrderStatusDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[SalesOrderStatus] [SOS]
                          Group By  [SOS].[Company]
                                  , [SOS].[OrderStatusCode]
                                  , [SOS].[OrderStatusDescription]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[TrnTypeAmountModifier]'
                                  , [Company] = [TTAM].[Company]
                                  , [ID] = Convert(Varchar(150) , [TTAM].[TrnType])
                                  , [DescriptionField] = Convert(Varchar(500) , [TTAM].[AmountModifier])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[TrnTypeAmountModifier] [TTAM]
                          Group By  [TTAM].[Company]
                                  , [TTAM].[TrnType]
                                  , [TTAM].[AmountModifier]
                          Having    Count(1) > 1
                          Union
                          Select    [TableName] = '[Lookups].[Warehouse]'
                                  , [Company] = [W].[Company]
                                  , [ID] = [W].[Warehouse]
                                  , [DescriptionField] = Convert(Varchar(500) , [W].[WarehouseDescription])
                                  , [EntryCount] = Count(1)
                          From      [Lookups].[Warehouse] [W]
                          Group By  [W].[Company]
                                  , [W].[Warehouse]
                                  , [W].[WarehouseDescription]
                          Having    Count(1) > 1
                        ) [t];

        Set NoCount Off;
        Select  [DC].[TableName]
              , [DC].[Company]
              , [DC].[ID]
              , [DC].[DescriptionField]
              , [DC].[DupeCount]
        From    [#DupeCheck] [DC];

        Set NoCount On;
        Drop Table [#DupeCheck];
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'check lookup tables for duplicates (indicates that refresh failed)', 'SCHEMA', N'Review', 'PROCEDURE', N'UspResults_LookupDuplicates', NULL, NULL
GO
