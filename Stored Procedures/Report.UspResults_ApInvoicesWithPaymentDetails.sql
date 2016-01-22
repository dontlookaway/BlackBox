
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ApInvoicesWithPaymentDetails] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--exec [Report].[UspResults_ApInvoicesWithPaymentDetails] @Company =10
*/
        Set NoCount Off;
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApInvoice,ApInvoicePay,ApSupplier'; 
--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(35)
            , [Invoice] Varchar(150)
            , [InvoiceDate] DateTime2
            , [DueDate] DateTime2
            , [OrigInvValue] Numeric(20 , 7)
            , [OrigDiscValue] Numeric(20 , 7)
            , [PaymentNumber] Varchar(150)
            , [MthInvBal1] Numeric(20 , 7)
            , [MthInvBal2] Numeric(20 , 7)
            , [MthInvBal3] Numeric(20 , 7)
            , [ConvRate] Numeric(20 , 7)
            , [Currency] Char(3)
            );
        Create Table [#ApInvoicePay]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(35)
            , [Invoice] Varchar(150)
            , [PaymentReference] Varchar(150)
            , [PostValue] Numeric(20 , 7)
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(50)
            , [SupplierName] Varchar(150)
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
						, [InvoiceDate]
						, [DueDate]
						, [OrigInvValue]
						, [OrigDiscValue]
						, [PaymentNumber]
						, [MthInvBal1]
						, [MthInvBal2]
						, [MthInvBal3]
						, [ConvRate] 
						, [Currency] 
						)
				SELECT [DatabaseName]=@DBCode
					 , [ai].[Supplier]
					 , [ai].[Invoice]
					 , [ai].[InvoiceDate]
					 , [ai].[DueDate]
					 , [ai].[OrigInvValue]
					 , [ai].[OrigDiscValue]
					 , [ai].[PaymentNumber]
					 , [ai].[MthInvBal1]
					 , [ai].[MthInvBal2]
					 , [ai].[MthInvBal3] 
					 , [ai].[ConvRate] 
					 , [ai].[Currency] 
				From [ApInvoice] As [ai]
			End
	End';
        Declare @SQL2 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
				Insert [#ApInvoicePay]
						( [DatabaseName]
						, [Supplier]
						, [Invoice]
						, [PaymentReference]
						, [PostValue]
						)
				SELECT [DatabaseName]=@DBCode
					 , [aip].[Supplier]
					 , [aip].[Invoice]
					 , [aip].[PaymentReference]
					 , [aip].[PostValue] 
				From [ApInvoicePay] As [aip]
			End
	End';
        Declare @SQL3 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
						)
				SELECT [DatabaseName]=@DBCode
					 , [as].[Supplier]
					 , [as].[SupplierName] 
				FROM [ApSupplier] As [as]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        --Print 1
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        --Print 2
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        --Print 3
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
		--Print 4
--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(30)
            , [SupplierName] Varchar(150)
            , [Invoice] Varchar(50)
            , [InvoiceDate] DateTime2
            , [DueDate] DateTime2
            , [OrigInvValue] Numeric(20 , 7)
            , [OrigDiscValue] Numeric(20 , 7)
            , [PaymentReference] Varchar(150)
            , [PaymentNumber] Varchar(150)
            , [PostValue] Numeric(20 , 7)
            , [Value] Numeric(20 , 7)
            , [MthInvBal1] Numeric(20 , 7)
            , [MthInvBal2] Numeric(20 , 7)
            , [MthInvBal3] Numeric(20 , 7)
            , [ConvRate] Numeric(20 , 7)
            , [Currency] Char(3)
            );
        Create Table [#SupplierSummary]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(50)
            , [SupplierValue] Numeric(20 , 7)
            , [Currency] Char(3)
            );


--Placeholder to create indexes as required

--script to combine base data and insert into results table

		--Print 5
        Insert  [#Results]
                ( [DatabaseName]
                , [Supplier]
                , [Invoice]
                , [InvoiceDate]
                , [DueDate]
                , [OrigInvValue]
                , [OrigDiscValue]
                , [PaymentReference]
                , [PaymentNumber]
                , [PostValue]
                , [Value]
                , [MthInvBal1]
                , [MthInvBal2]
                , [MthInvBal3]
                , [SupplierName]
                , [ConvRate]
                , [Currency]
                )
                Select  [ai].[DatabaseName]
                      , [ai].[Supplier]
                      , [ai].[Invoice]
                      , [ai].[InvoiceDate]
                      , [ai].[DueDate]
                      , [ai].[OrigInvValue]
                      , [ai].[OrigDiscValue]
                      , [PaymentReference] = Min([aip].[PaymentReference])
                      , [PaymentNumber] = Max([ai].[PaymentNumber])
                      , [PostValue] = Sum([aip].[PostValue])
                      , [Value] = [ai].[OrigInvValue] + Sum([aip].[PostValue])
                      , [ai].[MthInvBal1]
                      , [ai].[MthInvBal2]
                      , [ai].[MthInvBal3]
                      , [as].[SupplierName]
                      , [ai].[ConvRate]
                      , [ai].[Currency]
                From    [#ApInvoice] As [ai]
                        Left Join [#ApInvoicePay] As [aip] On [aip].[Supplier] = [ai].[Supplier]
                                                              And [aip].[Invoice] = [ai].[Invoice]
                                                              And [aip].[DatabaseName] = [ai].[DatabaseName]
                        Left Join [#ApSupplier] As [as] On [as].[Supplier] = [ai].[Supplier]
                                                           And [as].[DatabaseName] = [ai].[DatabaseName]
                Where   [ai].[DueDate] <= GetDate()
                Group By [ai].[DatabaseName]
                      , [ai].[Supplier]
                      , [ai].[Invoice]
                      , [ai].[InvoiceDate]
                      , [ai].[DueDate]
                      , [ai].[OrigInvValue]
                      , [ai].[OrigDiscValue]
                      , [ai].[MthInvBal1]
                      , [ai].[MthInvBal2]
                      , [ai].[MthInvBal3]
                      , [as].[SupplierName]
                      , [ai].[ConvRate]
                      , [ai].[Currency];
		
		--Print 6
        Insert  [#SupplierSummary]
                ( [DatabaseName]
                , [Supplier]
                , [SupplierValue]
                , [Currency]
                )
                Select  [r].[DatabaseName]
                      , [r].[Supplier]
                      , [SupplierValue] = Sum(Case When [r].[Value] >= 0
                                                 Then [r].[Value]
                                                 Else 0
                                            End)
                      , [r].[Currency]
                From    [#Results] As [r]
                Group By [r].[DatabaseName]
                      , [r].[Currency]
                      , [r].[Supplier];

--return results
        Select  [cn].[CompanyName]
              , [r].[Supplier]
              , [r].[SupplierName]
              , [SupplierValue] = Coalesce([ss].[SupplierValue] , 0)
              , [r].[Invoice]
              , [InvoiceDate] = Cast([r].[InvoiceDate] As Date)
              , [DueDate] = Cast([r].[DueDate] As Date)
              , [r].[OrigInvValue]
              , [r].[OrigDiscValue]
              , [r].[PaymentReference]
              , [r].[PaymentNumber]
              , [PostValue] = Coalesce([r].[PostValue] , 0)
              , [Value] = Coalesce([r].[Value] , 0)
              , [r].[MthInvBal1]
              , [r].[MthInvBal2]
              , [r].[MthInvBal3]
              , [r].[Currency]
              , [r].[ConvRate]
        From    [#Results] [r]
                Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company] = [r].[DatabaseName] Collate Latin1_General_BIN
                Left Join [#SupplierSummary] As [ss] On [ss].[Supplier] = [r].[Supplier]
                                                        And [ss].[Currency] = [r].[Currency]
                                                        And [ss].[DatabaseName] = [r].[DatabaseName]
        Order By [DueDate];

    End;

GO
