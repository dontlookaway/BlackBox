
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_InvoiceRunVerify]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_InvoiceRunVerify' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(50)
            , [SupplierName] Varchar(255)
            , [Currency] Varchar(5)
            );
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(50)
            , [Invoice] Varchar(50)
            , [EntryNumber] Int
            , [Journal] Int
            , [PaymentNumber] Int
            , [ConvRate] Float
            , [MulDiv] Varchar(5)
            , [MthInvBal1] Numeric(20 , 2)
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [JournalDate] Date
            , [Bank] Varchar(10)
            , [InvoiceDate] Date
            , [DueDate] Date
            , [OrigInvValue] Numeric(20 , 2)
            );
        Create Table [#ApJnlSummary]
            (
              [DatabaseName] Varchar(150)
            , [Invoice] Varchar(50)
            , [EntryNumber] Int
            , [Journal] Int
            , [TransactionCode] Varchar(5)
            , [InvoiceValue] Numeric(20 , 2)
            );
        Create Table [#ApJnlDistrib]
            (
              [DatabaseName] Varchar(150)
            , [Journal] Int
            , [EntryNumber] Int
            , [DistrValue] Numeric(20 , 2)
            , [ExpenseGlCode] Varchar(50)
            , [ExpenseType] Varchar(5)
            );
        Create Table [#ApPayRunDet]
            (
              [DatabaseName] Varchar(150)
            , [Invoice] Varchar(50)
            , [PaymentNumber] Int
            , [Supplier] Varchar(50)
            , [Cheque] Varchar(30)
            , [PostCurrency] Varchar(10)
            , [ChequeDate] Date
            , [PostConvRate] Float
            , [ChRegister] Int
            , [PostMulDiv] Varchar(5)
            );
        Create Table [#ApPayRunHdr]
            (
              [DatabaseName] Varchar(150)
            , [PaymentNumber] Int
            , [PaymentDate] Date
            , [PayYear] Int
            , [PayMonth] Int
            , [Operator] Varchar(250)
            );

--create script to pull data from each db into the tables
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
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
						( [DatabaseName]
						, [Supplier]
						, [SupplierName]
						, [Currency]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AS].[Supplier]
					 , [AS].[SupplierName]
					 , [AS].[Currency]
					  FROM [ApSupplier] As [AS]
			End
	End';
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
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
						( [DatabaseName]
						, [Supplier]
						, [Invoice]
						, [EntryNumber]
						, [Journal]
						, [PaymentNumber]
						, [ConvRate]
						, [MulDiv]
						, [MthInvBal1]
						, [InvoiceYear]
						, [InvoiceMonth]
						, [JournalDate]
						, [Bank]
						, [InvoiceDate]
						, [DueDate]
						, [OrigInvValue]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AI].[Supplier]
					 , [AI].[Invoice]
					 , [AI].[EntryNumber]
					 , [AI].[Journal]
					 , [AI].[PaymentNumber]
					 , [AI].[ConvRate]
					 , [AI].[MulDiv]
					 , [AI].[MthInvBal1]
					 , [AI].[InvoiceYear]
					 , [AI].[InvoiceMonth]
					 , [AI].[JournalDate]
					 , [AI].[Bank]
					 , [AI].[InvoiceDate]
					 , [AI].[DueDate]
					 , [AI].[OrigInvValue] FROM [ApInvoice] As [AI]
			End
	End';
        Declare @SQLApJnlSummary Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
				Insert [#ApJnlSummary]
						( [DatabaseName]
						, [Invoice]
						, [EntryNumber]
						, [Journal]
						, [TransactionCode]
						, [InvoiceValue]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AJS].[Invoice]
					 , [AJS].[EntryNumber]
					 , [AJS].[Journal]
					 , [AJS].[TransactionCode]
					 , [AJS].[InvoiceValue] FROM [ApJnlSummary] As [AJS]
			End
	End';
        Declare @SQLApJnlDistrib Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
				Insert [#ApJnlDistrib]
						( [DatabaseName]
						, [Journal]
						, [EntryNumber]
						, [DistrValue]
						, [ExpenseGlCode]
						, [ExpenseType]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AJD].[Journal]
					 , [AJD].[EntryNumber]
					 , [AJD].[DistrValue]
					 , [AJD].[ExpenseGlCode]
					 , [AJD].[ExpenseType] FROM [ApJnlDistrib] As [AJD]
			End
	End';
        Declare @SQLApPayRunDet Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
				Insert [#ApPayRunDet]
						( [DatabaseName]
						, [Invoice]
						, [PaymentNumber]
						, [Supplier]
						, [Cheque]
						, [PostCurrency]
						, [ChequeDate]
						, [PostConvRate]
						, [ChRegister]
						, [PostMulDiv]
						)
				SELECT [DatabaseName]=@DBCode
					 , [APRD].[Invoice]
					 , [APRD].[PaymentNumber]
					 , [APRD].[Supplier]
					 , [APRD].[Cheque]
					 , [APRD].[PostCurrency]
					 , [APRD].[ChequeDate]
					 , [APRD].[PostConvRate]
					 , [APRD].[ChRegister]
					 , [APRD].[PostMulDiv] FROM [ApPayRunDet] As [APRD]
			End
	End';
        Declare @SQLApPayRunHdr Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
				Insert [#ApPayRunHdr]
						( [DatabaseName]
						, [PaymentNumber]
						, [PaymentDate]
						, [PayYear]
						, [PayMonth]
						, [Operator]
						)
				SELECT [DatabaseName]=@DBCode
					 , [APRH].[PaymentNumber]
					 , [APRH].[PaymentDate]
					 , [APRH].[PayYear]
					 , [APRH].[PayMonth]
					 , [APRH].[Operator] FROM [ApPayRunHdr] As [APRH]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLApSupplier;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApInvoice;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApJnlSummary;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApJnlDistrib;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApPayRunDet;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApPayRunHdr;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [PostCurrency] Char(3)
            , [ConvRate] Float
            , [MulDiv] Char(1)
            , [MthInvBal] Float
            , [CompLocalAmt] Decimal(10 , 2)
            , [DistrValue] Float
            , [Description] Varchar(50)
            , [ExpenseGlCode] Varchar(35)
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [JournalDate] Date
            , [InvoiceDate] Date
            , [PaymentNumber] Int
            , [Bank] Varchar(15)
            , [PaymentDate] Date
            , [PayYear] Int
            , [PayMonth] Int
            , [Operator] Varchar(20)
            , [ChRegister] Float
            , [Cheque] Varchar(15)
            , [ChequeDate] Date
            , [InvNetPayValue] Decimal(15 , 3)
            , [DueDate] Date
            , [InvoiceType] Char(1)
            , [PostValue] Decimal(15 , 3)
            , [PostConvRate] Float
            , [PostMulDiv] Char(1)
            , [SupplierName] Varchar(50)
            , [ExpenseType] Varchar(150)
            , [CompanyName] Varchar(300)
            , [SupplierCurrency] Varchar(5)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Supplier]
                , [Invoice]
                , [PostCurrency]
                , [ConvRate]
                , [MulDiv]
                , [MthInvBal]
                , [CompLocalAmt]
                , [DistrValue]
                , [Description]
                , [ExpenseGlCode]
                , [InvoiceYear]
                , [InvoiceMonth]
                , [JournalDate]
                , [InvoiceDate]
                , [PaymentNumber]
                , [Bank]
                , [PaymentDate]
                , [PayYear]
                , [PayMonth]
                , [Operator]
                , [ChRegister]
                , [Cheque]
                , [ChequeDate]
                , [InvNetPayValue]
                , [DueDate]
                , [InvoiceType]
                , [PostValue]
                , [PostConvRate]
                , [PostMulDiv]
                , [SupplierName]
                , [ExpenseType]
                , [CompanyName]
                , [SupplierCurrency]
                )
                Select  [Company] = [AI].[DatabaseName]
                      , [Supplier] = [AS].[Supplier]
                      , [Invoice] = [AI].[Invoice]
                      , [PostCurrency] = [AD].[PostCurrency]
                      , [ConvRate] = [AI].[ConvRate]
                      , [MulDiv] = [AI].[MulDiv]
                      , [MthInvBal] = [AI].[MthInvBal1]
                      , [CompLocalAmt] = Cast(Case When [AI].[MulDiv] = 'M'
                                                   Then [AI].[MthInvBal1]
                                                        * [AI].[ConvRate]
                                                   Else [AI].[MthInvBal1]
                                                        / [AI].[ConvRate]
                                              End As Numeric(20 , 2))
                      , [DistrValue] = [AJD].[DistrValue]
                      , [Description] = [GM].[Description]
                      , [ExpenseGlCode] = Case When [AJD].[ExpenseGlCode] = ''
                                               Then Null
                                               Else [AJD].[ExpenseGlCode]
                                          End
                      , [InvoiceYear] = [AI].[InvoiceYear]
                      , [InvoiceMonth] = [AI].[InvoiceMonth]
                      , [JournalDate] = [AI].[JournalDate]
                      , [InvoiceDate] = [AI].[InvoiceDate]
                      , [PaymentNumber] = [AI].[PaymentNumber]
                      , [Bank] = [AI].[Bank]
                      , [PaymentDate] = [APH].[PaymentDate]
                      , [PayYear] = [APH].[PayYear]
                      , [PayMonth] = [APH].[PayMonth]
                      , [Operator] = [APH].[Operator]
                      , [ChRegister] = [AD].[ChRegister]
                      , [Cheque] = [AD].[Cheque]
                      , [ChequeDate] = [AD].[ChequeDate]
                      , [InvNetPayValue] = [AJS].[InvoiceValue]
                      , [DueDate] = [AI].[DueDate]
                      , [InvoiceType] = [AJS].[TransactionCode]--[AJS].[InvoiceType]
                      , [PostValue] = [AI].[OrigInvValue]
                      , [PostConvRate] = [AD].[PostConvRate]
                      , [PostMulDiv] = [AD].[PostMulDiv]
                      , [SupplierName] = [AS].[SupplierName]
                      , [ExpenseType] = [AJDE].[ExpenseTypeDesc]
                      , [CompanyName] = [CN].[CompanyName]
                      , [SupplierCurrency] = [AS].[Currency]
                From    [#ApSupplier] As [AS]
                        Left Join [#ApInvoice] As [AI] On [AI].[Supplier] = [AS].[Supplier]
                                                          And [AI].[DatabaseName] = [AS].[DatabaseName]
                        Left Join [#ApJnlSummary] As [AJS] On [AJS].[Invoice] = [AI].[Invoice]
                                                              And [AJS].[EntryNumber] = [AI].[EntryNumber]
                                                              And [AJS].[Journal] = [AI].[Journal]
                                                              And [AJS].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [#ApJnlDistrib] As [AJD] On [AJD].[Journal] = [AI].[Journal]
                                                              And [AJD].[EntryNumber] = [AI].[EntryNumber]
                                                              And [AJD].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[ApJnlDistribExpenseType] [AJDE] On [AJD].[ExpenseType] = [AJDE].[ExpenseType]
                        Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [AJD].[ExpenseGlCode] = [GM].[GlCode]
                                                              And [AJD].[DatabaseName] = [GM].[Company]
                        Left Join [#ApPayRunDet] [AD] On [AD].[Invoice] = [AI].[Invoice]
                                                         And [AD].[PaymentNumber] = [AI].[PaymentNumber]
                                                         And [AD].[Supplier] = [AI].[Supplier]
                                                         And [AD].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [#ApPayRunHdr] [APH] On [APH].[PaymentNumber] = [AI].[PaymentNumber]
                                                          And [APH].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [AI].[DatabaseName]
                Where   [AI].[Invoice] Is Not Null;


--return results
        Select  [CompanyName] = [DatabaseName]
              , [Supplier]
              , [Invoice]
              , [PostCurrency]
              , [ConvRate]
              , [MulDiv]
              , [MthInvBal]
              , [CompLocalAmt]
              , [DistrValue]
              , [Description]
              , [ExpenseGlCode]
              , [InvoiceYear]
              , [InvoiceMonth]
              , [JournalDate]
              , [InvoiceDate]
              , [PaymentNumber]
              , [Bank]
              , [PaymentDate]
              , [PayYear]
              , [PayMonth]
              , [Operator]
              , [ChRegister]
              , [Cheque]
              , [ChequeDate]
              , [InvNetPayValue]
              , [DueDate]
              , [InvoiceType]
              , [PostValue]
              , [PostConvRate]
              , [PostMulDiv]
              , [SupplierName]
              , [ExpenseType]
              , [CompanyName]
              , [SupplierCurrency]
        From    [#Results];

    End;

GO
