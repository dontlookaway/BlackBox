
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PaymentRunVerify]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure for Payment run verify
--Exec [Report].[UspResults_PaymentRunVerify]  10
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
            @StoredProcName = 'UspResults_PaymentRunVerify' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApInvoice,ApJnlSummary,ApJnlDistrib,ApPayRunDet,ApPayRunHdr'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [PostCurrency] Char(3)
            , [ConvRate] Float
            , [MulDiv] Char(1)
            , [MthInvBal1] Float
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [JournalDate] DateTime2
            , [InvoiceDate] DateTime2
            );
        Create Table [#ApJnlSummary]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Journal] Int
            , [EntryNumber] Int
            );
        Create Table [#ApJnlDistrib]
            (
              [DatabaseName] Varchar(150)
            , [DistrValue] Float
            , [ExpenseGlCode] Varchar(35)
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Journal] Int
            , [EntryNumber] Int
            );
        Create Table [#ApPayRunDet]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [Cheque] Varchar(15)
            , [ChequeDate] DateTime2
            , [InvoiceDate] DateTime2
            , [NetPayValue] Float
            , [DueDate] DateTime2
            , [InvoiceType] Char(1)
            , [PostValue] Float
            , [PostCurrency] Char(3)
            , [PostConvRate] Float
            , [PostMulDiv] Char(1)
            , [SupplierName] Varchar(50)
            , [PaymentNumber] Varchar(15)
            );
        Create Table [#ApPayRunHdr]
            (
              [DatabaseName] Varchar(150)
            , [PaymentNumber] Varchar(15)
            , [Bank] Varchar(15)
            , [PaymentDate] DateTime2
            , [PayYear] Int
            , [PayMonth] Int
            , [Operator] Varchar(20)
            , [ChRegister] Float
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(50)
            , [SupplierName] Varchar(255)
            , [Currency] Varchar(5)
            );
	
--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
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
					Insert #ApInvoice
								( DatabaseName
								, Supplier
								, Invoice
								, PostCurrency
								, ConvRate
								, MulDiv
								, MthInvBal1
								, InvoiceYear
								, InvoiceMonth
								, JournalDate
								, InvoiceDate
								)
					SELECT @DBCode
							  , Supplier
							  , Invoice
							  , PostCurrency
							  , ConvRate
							  , MulDiv
							  , MthInvBal1
							  , InvoiceYear
							  , InvoiceMonth
							  , JournalDate
							  , InvoiceDate	 FROM ApInvoice

					Insert #ApJnlSummary
							( DatabaseName
							, Supplier
							, Invoice
							, TrnYear
							, TrnMonth
							, Journal
							, EntryNumber
							)
					SELECT @DBCode
							,Supplier
							,Invoice
							,TrnYear
							,TrnMonth
							,Journal
							,EntryNumber
					 FROM ApJnlSummary
					 Where [TransactionCode] not in (''X'')
			End
	End';
        Declare @SQL2 Varchar(Max) = '
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
						Insert #ApJnlDistrib
								( DatabaseName
								, DistrValue
								, ExpenseGlCode
								, TrnYear
								, TrnMonth
								, Journal
								, EntryNumber
								)
						SELECT @DBCode
								,DistrValue
								,ExpenseGlCode
								,TrnYear
								,TrnMonth
								,Journal
								,EntryNumber
						 FROM ApJnlDistrib

						 Insert #ApPayRunDet
								( DatabaseName
								, Supplier
								, Invoice
								, Cheque
								, ChequeDate
								, InvoiceDate
								, NetPayValue
								, DueDate
								, InvoiceType
								, PostValue
								, PostCurrency
								, PostConvRate
								, PostMulDiv
								, SupplierName
								, PaymentNumber
								)
						SELECT @DBCode
								,Supplier
								,Invoice
								,Cheque
								,ChequeDate
								,InvoiceDate
								,NetPayValue
								,DueDate
								,InvoiceType
								,PostValue
								,PostCurrency
								,PostConvRate
								,PostMulDiv
								,SupplierName
								,PaymentNumber
						FROM ApPayRunDet
			End
	End';
        Declare @SQL3 Varchar(Max) = '
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
				Insert #ApPayRunHdr
							( DatabaseName
							, PaymentNumber
							, Bank
							, PaymentDate
							, PayYear
							, PayMonth
							, Operator
							, ChRegister
							)
				SELECT @DBCode
							, PaymentNumber
							, Bank
							, PaymentDate
							, PayYear
							, PayMonth
							, Operator
							, ChRegister
				FROM ApPayRunHdr		
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
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQLApSupplier;

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
            , [JournalDate] DateTime2
            , [InvoiceDate] DateTime2
            , [PaymentNumber] Int
            , [Bank] Varchar(15)
            , [PaymentDate] DateTime2
            , [PayYear] Int
            , [PayMonth] Int
            , [Operator] Varchar(20)
            , [ChRegister] Float
            , [Cheque] Varchar(15)
            , [ChequeDate] DateTime2
            --, InvoiceDate DATETIME2
            , [InvNetPayValue] Decimal(15 , 3)
            , [DueDate] DateTime2
            , [InvoiceType] Char(1)
            , [PostValue] Decimal(15 , 3)
            , [PostConvRate] Float
            , [PostMulDiv] Char(1)
            , [SupplierName] Varchar(50)
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
                , [SupplierCurrency] 
	            )
                Select  [AI].[DatabaseName]
                      , [AI].[Supplier]
                      , [AI].[Invoice]
                      , [AI].[PostCurrency]
                      , [AI].[ConvRate]
                      , [AI].[MulDiv]
                      , [MthInvBal] = [AI].[MthInvBal1]
                      , [CompLocalAmt] = Cast(Case When [AI].[MulDiv] = 'M'
                                                   Then [AI].[MthInvBal1]
                                                        * [AI].[ConvRate]
                                                   Else [AI].[MthInvBal1]
                                                        / [AI].[ConvRate]
                                              End As Decimal(10 , 2))
                      , [DistrValue] = Sum([AJD].[DistrValue])
                      , [GM].[Description]
                      , [ExpenseGlCode] = Case When [AJD].[ExpenseGlCode] = ''
                                               Then Null
                                               Else [AJD].[ExpenseGlCode]
                                          End
                      , [AI].[InvoiceYear]
                      , [AI].[InvoiceMonth]
                      , [AI].[JournalDate]
                      , [AI].[InvoiceDate]
                      , [APH].[PaymentNumber]
                      , [APH].[Bank]
                      , [APH].[PaymentDate]
                      , [APH].[PayYear]
                      , [APH].[PayMonth]
                      , [APH].[Operator]
                      , [APH].[ChRegister]
                      , [APD].[Cheque]
                      , [APD].[ChequeDate]
                      , [InvNetPayValue] = [APD].[NetPayValue]
                      , [APD].[DueDate]
                      , [APD].[InvoiceType]
                      , [APD].[PostValue]
                      , [APD].[PostConvRate]
                      , [APD].[PostMulDiv]
                      , [APD].[SupplierName]
                      , [SupplierCurrency] = [AS].[Currency]
                From    [#ApInvoice] [AI]
                        Left Join [#ApJnlSummary] [AJS] With ( NoLock ) On [AI].[Supplier] = [AJS].[Supplier]
                                                              And [AI].[Invoice] = [AJS].[Invoice]
                                                              And [AJS].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [#ApJnlDistrib] [AJD] With ( NoLock ) On [AJD].[TrnYear] = [AJS].[TrnYear]
                                                              And [AJD].[TrnMonth] = [AJS].[TrnMonth]
                                                              And [AJD].[Journal] = [AJS].[Journal]
                                                              And [AJD].[EntryNumber] = [AJS].[EntryNumber]
                                                              And [AJD].[DatabaseName] = [AJS].[DatabaseName]
                        Left Join [SysproCompany40].[dbo].[GenMaster] [GM] On [GM].[GlCode] = [AJD].[ExpenseGlCode] Collate Latin1_General_BIN
                        Inner Join [#ApPayRunDet] [APD] On [APD].[Supplier] = [AI].[Supplier]
                                                           And [APD].[Invoice] = [AI].[Invoice]
                                                           And [APD].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [#ApPayRunHdr] [APH] On [APH].[PaymentNumber] = [APD].[PaymentNumber]
                                                          And [APH].[PaymentNumber] = [APD].[PaymentNumber]
                        Left Join [#ApSupplier] As [AS] On [AS].[Supplier] = [AI].[Supplier]
                                                           And [AS].[DatabaseName] = [AI].[DatabaseName]
                Group By [AI].[DatabaseName]
                      , [AJD].[TrnYear]
                      , [AJD].[TrnMonth]
                      , Case When [AJD].[ExpenseGlCode] = '' Then Null
                             Else [AJD].[ExpenseGlCode]
                        End
                      , [GM].[Description]
                      , [AJS].[Supplier]
                      , [AJS].[Invoice]
                      , [AI].[Supplier]
                      , [AI].[Invoice]
                      , [AI].[PostCurrency]
                      , [AI].[ConvRate]
                      , [AI].[MulDiv]
                      , [AI].[MthInvBal1]
                      , Cast(Case When [AI].[MulDiv] = 'M'
                                  Then [AI].[MthInvBal1] * [AI].[ConvRate]
                                  Else [AI].[MthInvBal1] / [AI].[ConvRate]
                             End As Decimal(10 , 2))
                      , [AI].[InvoiceYear]
                      , [AI].[InvoiceMonth]
                      , [AI].[JournalDate]
                      , [AI].[InvoiceDate]
                      , [APH].[PaymentNumber]
                      , [APH].[Bank]
                      , [APH].[PaymentDate]
                      , [APH].[PayYear]
                      , [APH].[PayMonth]
                      , [APH].[Operator]
                      , [APH].[ChRegister]
                      , [APD].[Cheque]
                      , [APD].[ChequeDate]
                      , [APD].[InvoiceDate]
                      , [APD].[NetPayValue]
                      , [APD].[DueDate]
                      , [APD].[InvoiceType]
                      , [APD].[PostValue]
                      , [APD].[PostCurrency]
                      , [APD].[PostConvRate]
                      , [APD].[PostMulDiv]
                      , [APD].[SupplierName]
                      , [AS].[Currency];

--return results
        Select  [Company] = [R].[DatabaseName]
              , [R].[Supplier]
              , [R].[Invoice]
              , [R].[PostCurrency]
              , [R].[ConvRate]
              , [R].[MulDiv]
              , [R].[MthInvBal]
              , [R].[CompLocalAmt]
              , [R].[DistrValue]
              , [R].[Description]
              , [R].[ExpenseGlCode]
              , [R].[InvoiceYear]
              , [R].[InvoiceMonth]
              , [JournalDate] = Convert(Date , [R].[JournalDate])
              , [R].[PaymentNumber]
              , [R].[Bank]
              , [PaymentDate] = Convert(Date , [R].[PaymentDate])
              , [R].[PayYear]
              , [R].[PayMonth]
              , [R].[Operator]
              , [R].[ChRegister]
              , [R].[Cheque]
              , [ChequeDate] = Convert(Date , [R].[ChequeDate])
              , [InvoiceDate] = Convert(Date , [R].[InvoiceDate])
              , [R].[InvNetPayValue]
              , [DueDate] = Convert(Date , [R].[DueDate])
              , [R].[InvoiceType]
              , [R].[PostValue]
              , [R].[PostConvRate]
              , [R].[PostMulDiv]
              , [R].[SupplierName]
              , [ExpenseType] = Null
              , [cn].[CompanyName]
              , [R].[SupplierCurrency]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company] = [R].[DatabaseName] Collate Latin1_General_BIN;

    End;


GO
