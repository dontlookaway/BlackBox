SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ApAgingInvoices]
    (
      @RunDate Date
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016
*/

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ApAgingInvoices' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--If no rundate defined, use todays date
        Select  @RunDate = Coalesce(@RunDate , GetDate());

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DB] Varchar(50) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [Invoice] Varchar(20) Collate Latin1_General_BIN
            , [NextPaymEntry] Int
            , [JournalDate] Date
            , [Journal] Int
            , [Branch] Varchar(10) Collate Latin1_General_BIN
            , [InvoiceDate] Date
            , [DiscountDate] Date
            , [DueDate] Date
            , [Reference] Varchar(30) Collate Latin1_General_BIN
            , [OrigInvValue] Numeric(20 , 2)
            , [OrigDiscValue] Numeric(20 , 2)
            , [MthInvBal1] Numeric(20 , 2)
            , [MthInvBal2] Numeric(20 , 2)
            , [MthInvBal3] Numeric(20 , 2)
            , [ManualChqDate] Date
            , [ManualChqNum] BigInt
            , [DiscActiveFlag] Char(1) Collate Latin1_General_BIN
            , [InvoiceStatus] Char(1) Collate Latin1_General_BIN
            , [Currency] Varchar(10) Collate Latin1_General_BIN
            , [Bank] Varchar(20) Collate Latin1_General_BIN
            , [PaymGrossValue] Numeric(20 , 2)
            , [PaymDiscValue] Numeric(20 , 2)
            , [TaxPortionDisc] Numeric(20 , 2)
            , [NotificationDate] Date
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [YearInvBalZero] Int
            , [MonthInvBalZero] Int
            , [ExchangeRate] Float
            , [FirstTaxCode] Char(3) Collate Latin1_General_BIN
            , [WithTaxValue] Numeric(20 , 2)
            , [WithTaxRate] Float
            , [CurrencyValue] Numeric(20 , 2)
            , [PostCurrency] Varchar(10) Collate Latin1_General_BIN
            , [ConvRate] Float
            , [MulDiv] Char(1) Collate Latin1_General_BIN
            , [AccountCur] Varchar(10) Collate Latin1_General_BIN
            , [AccConvRate] Float
            , [AccMulDiv] Char(1) Collate Latin1_General_BIN
            , [TriangCurrency] Varchar(10) Collate Latin1_General_BIN
            , [TriangRate] Float
            , [TriangMulDiv] Char(1) Collate Latin1_General_BIN
            , [Tax2Value] Numeric(20 , 2)
            , [VatInvalid] Char(1) Collate Latin1_General_BIN
            , [EntryNumber] Int
            , [PaymentChkType] Char(1) Collate Latin1_General_BIN
            , [ManualChRef] Varchar(30)
            , [PaymentNumber] Varchar(15) Collate Latin1_General_BIN
            , [InvoiceTakeOn] Char(1) Collate Latin1_General_BIN
            , [FixExchangeRate] Char(1) Collate Latin1_General_BIN
            , [NextRevalNo] Int
            , [TaxReverse] Char(1) Collate Latin1_General_BIN
            , [Tax2Reverse] Char(1) Collate Latin1_General_BIN
            , [NationalitySource] Char(3) Collate Latin1_General_BIN
            , [NationalityDest] Char(3) Collate Latin1_General_BIN
            , [AutoVoucherCreated] Char(1) Collate Latin1_General_BIN
            , [AutoVoucherPrinted] Char(1) Collate Latin1_General_BIN
            , [SecondTaxCode] Char(3) Collate Latin1_General_BIN
            , [WithTaxCode] Char(3) Collate Latin1_General_BIN
            );
        Create Table [#ApSupplier]
            (
              [DB] Varchar(50) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [SupplierName] Varchar(255) Collate Latin1_General_BIN
            , [TermsCode] Char(2) Collate Latin1_General_BIN
            );
        Create Table [#TblApTerms]
            (
              [DB] Varchar(50) Collate Latin1_General_BIN
            , [TermsCode] Char(2) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            );



--create script to pull data from each db into the tables
        Declare @SQLApInvoice Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF isnumeric(@DBCode)=1
			begin
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
            '
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Insert [#ApInvoice]
        ( [DB], [Supplier], [Invoice], [NextPaymEntry], [JournalDate]
        , [Journal], [Branch], [InvoiceDate], [DiscountDate], [DueDate]
        , [Reference], [OrigInvValue], [OrigDiscValue], [MthInvBal1], [MthInvBal2]
        , [MthInvBal3], [ManualChqDate], [ManualChqNum], [DiscActiveFlag], [InvoiceStatus]
        , [Currency], [Bank], [PaymGrossValue], [PaymDiscValue], [TaxPortionDisc], [NotificationDate]
        , [InvoiceYear], [InvoiceMonth], [YearInvBalZero], [MonthInvBalZero], [ExchangeRate]
        , [FirstTaxCode], [WithTaxValue], [WithTaxRate], [CurrencyValue], [PostCurrency], [ConvRate]
        , [MulDiv], [AccountCur], [AccConvRate], [AccMulDiv], [TriangCurrency], [TriangRate]
        , [TriangMulDiv], [Tax2Value], [VatInvalid], [EntryNumber], [PaymentChkType], [ManualChRef]
        , [PaymentNumber], [InvoiceTakeOn], [FixExchangeRate], [NextRevalNo], [TaxReverse]
        , [Tax2Reverse], [NationalitySource], [NationalityDest], [AutoVoucherCreated]
        , [AutoVoucherPrinted], [SecondTaxCode], [WithTaxCode]
        )
SELECT [DB]=@DBCode, [AI].[Supplier], [AI].[Invoice], [AI].[NextPaymEntry], [AI].[JournalDate]
     , [AI].[Journal], [AI].[Branch], [AI].[InvoiceDate], [AI].[DiscountDate], [AI].[DueDate]
     , [AI].[Reference], [AI].[OrigInvValue], [AI].[OrigDiscValue], [AI].[MthInvBal1], [AI].[MthInvBal2]
     , [AI].[MthInvBal3], [AI].[ManualChqDate], [AI].[ManualChqNum], [AI].[DiscActiveFlag], [AI].[InvoiceStatus]
     , [AI].[Currency], [AI].[Bank], [AI].[PaymGrossValue], [AI].[PaymDiscValue], [AI].[TaxPortionDisc], [AI].[NotificationDate]
     , [AI].[InvoiceYear], [AI].[InvoiceMonth], [AI].[YearInvBalZero], [AI].[MonthInvBalZero], [AI].[ExchangeRate]
     , [AI].[FirstTaxCode], [AI].[WithTaxValue], [AI].[WithTaxRate], [AI].[CurrencyValue], [AI].[PostCurrency], [AI].[ConvRate]
     , [AI].[MulDiv], [AI].[AccountCur], [AI].[AccConvRate], [AI].[AccMulDiv], [AI].[TriangCurrency], [AI].[TriangRate]
     , [AI].[TriangMulDiv], [AI].[Tax2Value], [AI].[VatInvalid], [AI].[EntryNumber], [AI].[PaymentChkType], [AI].[ManualChRef]
     , [AI].[PaymentNumber], [AI].[InvoiceTakeOn], [AI].[FixExchangeRate], [AI].[NextRevalNo], [AI].[TaxReverse]
	 , [AI].[Tax2Reverse], [AI].[NationalitySource], [AI].[NationalityDest], [AI].[AutoVoucherCreated]
     , [AI].[AutoVoucherPrinted], [AI].[SecondTaxCode], [AI].[WithTaxCode] 
	 FROM [ApInvoice] As [AI]
	 where [AI].[MthInvBal1]<>0
			End
		End
	End';
        Declare @SQLApSupplier Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF isnumeric(@DBCode)=1
			begin
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
            '
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
						Insert [#ApSupplier]
			        ( [DB] , [Supplier] , [SupplierName], [TermsCode]  )
			SELECT [DB]=@DBCode
                 , [AS].[Supplier]
                 , [AS].[SupplierName]
				 , [TermsCode]  FROM [ApSupplier] As [AS]
			End
		End
	End';
        Declare @SQLTblApTerms Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF isnumeric(@DBCode)=1
			begin
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
            '
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert [#TblApTerms]
						( [DB] , [TermsCode] , [Description] )
				SELECT [DB]=@DBCode
					 , [TAT].[TermsCode]
					 , [TAT].[Description] FROM [TblApTerms] As [TAT]
			End
		End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLApInvoice;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApSupplier;
        Exec [Process].[ExecForEachDB] @cmd = @SQLTblApTerms;
		

--define the results you want to return
        Create Table [#ApData]
            (
              [Company] Varchar(50) Collate Latin1_General_BIN
            , [Supplier] Varchar(255) Collate Latin1_General_BIN
            , [Invoice] Varchar(20) Collate Latin1_General_BIN
            , [NextPaymEntry] Int
            , [JournalDate] Date
            , [Journal] Int
            , [Branch] Varchar(10) Collate Latin1_General_BIN
            , [InvoiceDate] Date
            , [DiscountDate] Date
            , [DueDate] Date
            , [Reference] Varchar(30) Collate Latin1_General_BIN
            , [OrigInvValue] Numeric(20 , 2)
            , [OrigDiscValue] Numeric(20 , 2)
            , [MthInvBal1] Numeric(20 , 2)
            , [MthInvBal2] Numeric(20 , 2)
            , [MthInvBal3] Numeric(20 , 2)
            , [ManualChqDate] Date
            , [ManualChqNum] BigInt
            , [DiscActiveFlag] Char(1) Collate Latin1_General_BIN
            , [InvoiceStatus] Char(1) Collate Latin1_General_BIN
            , [Currency] Varchar(10) Collate Latin1_General_BIN
            , [Bank] Varchar(20) Collate Latin1_General_BIN
            , [PaymGrossValue] Numeric(20 , 2)
            , [PaymDiscValue] Numeric(20 , 2)
            , [TaxPortionDisc] Numeric(20 , 2)
            , [NotificationDate] Date
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [YearInvBalZero] Int
            , [MonthInvBalZero] Int
            , [ExchangeRate] Float
            , [FirstTaxCode] Char(3) Collate Latin1_General_BIN
            , [WithTaxValue] Numeric(20 , 2)
            , [WithTaxRate] Float
            , [CurrencyValue] Numeric(20 , 2)
            , [PostCurrency] Varchar(10) Collate Latin1_General_BIN
            , [ConvRate] Float
            , [MulDiv] Char(1) Collate Latin1_General_BIN
            , [AccountCur] Varchar(10) Collate Latin1_General_BIN
            , [AccConvRate] Float
            , [AccMulDiv] Char(1) Collate Latin1_General_BIN
            , [TriangCurrency] Varchar(10) Collate Latin1_General_BIN
            , [TriangRate] Float
            , [TriangMulDiv] Char(1) Collate Latin1_General_BIN
            , [Tax2Value] Numeric(20 , 2)
            , [VatInvalid] Char(1) Collate Latin1_General_BIN
            , [EntryNumber] Int
            , [PaymentChkType] Char(1) Collate Latin1_General_BIN
            , [ManualChRef] Varchar(30) Collate Latin1_General_BIN
            , [PaymentNumber] Varchar(15) Collate Latin1_General_BIN
            , [InvoiceTakeOn] Char(1) Collate Latin1_General_BIN
            , [FixExchangeRate] Char(1) Collate Latin1_General_BIN
            , [NextRevalNo] Int
            , [TaxReverse] Char(1) Collate Latin1_General_BIN
            , [Tax2Reverse] Char(1) Collate Latin1_General_BIN
            , [NationalitySource] Char(3) Collate Latin1_General_BIN
            , [NationalityDest] Char(3) Collate Latin1_General_BIN
            , [AutoVoucherCreated] Char(1) Collate Latin1_General_BIN
            , [AutoVoucherPrinted] Char(1) Collate Latin1_General_BIN
            , [SecondTaxCode] Char(3) Collate Latin1_General_BIN
            , [WithTaxCode] Char(3) Collate Latin1_General_BIN
            , [30Days] Numeric(20 , 2)
            , [45Days] Numeric(20 , 2)
            , [60Days] Numeric(20 , 2)
            , [90Days] Numeric(20 , 2)
            , [120Days] Numeric(20 , 2)
            , [121DaysPlus] Numeric(20 , 2)
            , [LocalCurrency] Numeric(20 , 2)
            , [SupplierTerms] Varchar(50)
            , [RunDate] Date
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#ApData]
                ( [Company]
                , [Supplier]
                , [Invoice]
                , [NextPaymEntry]
                , [JournalDate]
                , [Journal]
                , [Branch]
                , [InvoiceDate]
                , [DiscountDate]
                , [DueDate]
                , [Reference]
                , [OrigInvValue]
                , [OrigDiscValue]
                , [MthInvBal1]
                , [MthInvBal2]
                , [MthInvBal3]
                , [ManualChqDate]
                , [ManualChqNum]
                , [DiscActiveFlag]
                , [InvoiceStatus]
                , [Currency]
                , [Bank]
                , [PaymGrossValue]
                , [PaymDiscValue]
                , [TaxPortionDisc]
                , [NotificationDate]
                , [InvoiceYear]
                , [InvoiceMonth]
                , [YearInvBalZero]
                , [MonthInvBalZero]
                , [ExchangeRate]
                , [FirstTaxCode]
                , [WithTaxValue]
                , [WithTaxRate]
                , [CurrencyValue]
                , [PostCurrency]
                , [ConvRate]
                , [MulDiv]
                , [AccountCur]
                , [AccConvRate]
                , [AccMulDiv]
                , [TriangCurrency]
                , [TriangRate]
                , [TriangMulDiv]
                , [Tax2Value]
                , [VatInvalid]
                , [EntryNumber]
                , [PaymentChkType]
                , [ManualChRef]
                , [PaymentNumber]
                , [InvoiceTakeOn]
                , [FixExchangeRate]
                , [NextRevalNo]
                , [TaxReverse]
                , [Tax2Reverse]
                , [NationalitySource]
                , [NationalityDest]
                , [AutoVoucherCreated]
                , [AutoVoucherPrinted]
                , [SecondTaxCode]
                , [WithTaxCode]
                , [30Days]
                , [45Days]
                , [60Days]
                , [90Days]
                , [120Days]
                , [121DaysPlus]
                , [LocalCurrency]
                , [SupplierTerms]
                , [RunDate]
                )
                Select  [Company] = [API].[DB]
                      , [Supplier] = LTrim(RTrim([API].[Supplier])) + ' - '
                        + LTrim(RTrim([APS].[SupplierName]))
                      , [API].[Invoice]
                      , [API].[NextPaymEntry]
                      , [API].[JournalDate]
                      , [API].[Journal]
                      , [API].[Branch]
                      , [API].[InvoiceDate]
                      , [API].[DiscountDate]
                      , [API].[DueDate]
                      , [API].[Reference]
                      , [API].[OrigInvValue]
                      , [API].[OrigDiscValue]
                      , [API].[MthInvBal1]
                      , [API].[MthInvBal2]
                      , [API].[MthInvBal3]
                      , [API].[ManualChqDate]
                      , [API].[ManualChqNum]
                      , [API].[DiscActiveFlag]
                      , [API].[InvoiceStatus]
                      , [API].[Currency]
                      , [API].[Bank]
                      , [API].[PaymGrossValue]
                      , [API].[PaymDiscValue]
                      , [API].[TaxPortionDisc]
                      , [API].[NotificationDate]
                      , [API].[InvoiceYear]
                      , [API].[InvoiceMonth]
                      , [API].[YearInvBalZero]
                      , [API].[MonthInvBalZero]
                      , [API].[ExchangeRate]
                      , [API].[FirstTaxCode]
                      , [API].[WithTaxValue]
                      , [API].[WithTaxRate]
                      , [API].[CurrencyValue]
                      , [API].[PostCurrency]
                      , [API].[ConvRate]
                      , [API].[MulDiv]
                      , [API].[AccountCur]
                      , [API].[AccConvRate]
                      , [API].[AccMulDiv]
                      , [API].[TriangCurrency]
                      , [API].[TriangRate]
                      , [API].[TriangMulDiv]
                      , [API].[Tax2Value]
                      , [API].[VatInvalid]
                      , [API].[EntryNumber]
                      , [API].[PaymentChkType]
                      , [API].[ManualChRef]
                      , [API].[PaymentNumber]
                      , [API].[InvoiceTakeOn]
                      , [API].[FixExchangeRate]
                      , [API].[NextRevalNo]
                      , [API].[TaxReverse]
                      , [API].[Tax2Reverse]
                      , [API].[NationalitySource]
                      , [API].[NationalityDest]
                      , [API].[AutoVoucherCreated]
                      , [API].[AutoVoucherPrinted]
                      , [API].[SecondTaxCode]
                      , [API].[WithTaxCode]
                      , [30Days] = Case When DateDiff(dd , [API].[InvoiceDate] ,
                                                      @RunDate) <= 30
                                        Then [API].[MthInvBal1]
                                        Else 0
                                   End
                      , [45Days] = Case When DateDiff(dd , [API].[InvoiceDate] ,
                                                      @RunDate) Between 31
                                                              And
                                                              45
                                        Then [API].[MthInvBal1]
                                        Else 0
                                   End
                      , [60Days] = Case When DateDiff(dd , [API].[InvoiceDate] ,
                                                      @RunDate) Between 46
                                                              And
                                                              60
                                        Then [API].[MthInvBal1]
                                        Else 0
                                   End
                      , [90Days] = Case When DateDiff(dd , [API].[InvoiceDate] ,
                                                      @RunDate) Between 61
                                                              And
                                                              90
                                        Then [API].[MthInvBal1]
                                        Else 0
                                   End
                      , [120Days] = Case When DateDiff(dd ,
                                                       [API].[InvoiceDate] ,
                                                       @RunDate) Between 91
                                                              And
                                                              120
                                         Then [API].[MthInvBal1]
                                         Else 0
                                    End
                      , [121DaysPlus] = Case When DateDiff(dd ,
                                                           [API].[InvoiceDate] ,
                                                           @RunDate) > 120
                                             Then [API].[MthInvBal1]
                                             Else 0
                                        End
                      , [LocalCurrency] = Cast(Case When [API].[MulDiv] = 'M'
                                                    Then [API].[MthInvBal1]
                                                         * [API].[ConvRate]
                                                    Else [API].[MthInvBal1]
                                                         / [API].[ConvRate]
                                               End As Decimal(20 , 2))
                      , [SupplierTerms] = [TAT].[Description]
                      , @RunDate
                From    [#ApInvoice] As [API]
                        Left Outer Join [#ApSupplier] As [APS] On [API].[Supplier] = [APS].[Supplier]
                                                              And [APS].[DB] = [API].[DB]
                        Left Join [#TblApTerms] As [TAT] On [TAT].[TermsCode] = [APS].[TermsCode]
                                                            And [TAT].[DB] = [APS].[DB];


--return results
        Select  [AD].[Company]
              , [AD].[Supplier]
              , [AD].[Invoice]
              , [AD].[NextPaymEntry]
              , [AD].[JournalDate]
              , [AD].[Journal]
              , [AD].[Branch]
              , [AD].[InvoiceDate]
              , [AD].[DiscountDate]
              , [AD].[DueDate]
              , [AD].[Reference]
              , [AD].[OrigInvValue]
              , [AD].[OrigDiscValue]
              , [AD].[MthInvBal1]
              , [AD].[MthInvBal2]
              , [AD].[MthInvBal3]
              , [AD].[ManualChqDate]
              , [AD].[ManualChqNum]
              , [AD].[DiscActiveFlag]
              , [AD].[InvoiceStatus]
              , [AD].[Currency]
              , [AD].[Bank]
              , [AD].[PaymGrossValue]
              , [AD].[PaymDiscValue]
              , [AD].[TaxPortionDisc]
              , [AD].[NotificationDate]
              , [AD].[InvoiceYear]
              , [AD].[InvoiceMonth]
              , [AD].[YearInvBalZero]
              , [AD].[MonthInvBalZero]
              , [AD].[ExchangeRate]
              , [AD].[FirstTaxCode]
              , [AD].[WithTaxValue]
              , [AD].[WithTaxRate]
              , [AD].[CurrencyValue]
              , [AD].[PostCurrency]
              , [AD].[ConvRate]
              , [AD].[MulDiv]
              , [AD].[AccountCur]
              , [AD].[AccConvRate]
              , [AD].[AccMulDiv]
              , [AD].[TriangCurrency]
              , [AD].[TriangRate]
              , [AD].[TriangMulDiv]
              , [AD].[Tax2Value]
              , [AD].[VatInvalid]
              , [AD].[EntryNumber]
              , [AD].[PaymentChkType]
              , [AD].[ManualChRef]
              , [AD].[PaymentNumber]
              , [AD].[InvoiceTakeOn]
              , [AD].[FixExchangeRate]
              , [AD].[NextRevalNo]
              , [AD].[TaxReverse]
              , [AD].[Tax2Reverse]
              , [AD].[NationalitySource]
              , [AD].[NationalityDest]
              , [AD].[AutoVoucherCreated]
              , [AD].[AutoVoucherPrinted]
              , [AD].[SecondTaxCode]
              , [AD].[WithTaxCode]
              , [AD].[30Days]
              , [AD].[45Days]
              , [AD].[60Days]
              , [AD].[90Days]
              , [AD].[120Days]
              , [AD].[121DaysPlus]
              , [AD].[LocalCurrency]
              , [CN].[CompanyName]
              , [AD].[SupplierTerms]
              , [AD].[RunDate]
        From    [#ApData] As [AD]
                Left Join [Lookups].[CompanyNames] As [CN] On [CN].[Company] = [AD].[Company];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'replaced by UspResults_AccPayable_AgedInvoices', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ApAgingInvoices', NULL, NULL
GO
