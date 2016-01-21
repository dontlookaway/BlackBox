SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ApInvoicesWithPaymentDetails]
( @Company VARCHAR(Max))--, @DueDateEnd VARCHAR(Max))
As --exec [Report].[UspResults_ApInvoicesWithPaymentDetails] @Company =10
Begin
/*
#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			9/10/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'ApInvoice,ApInvoicePay,ApSupplier'; 
--create temporary tables to be pulled from different databases, including a column to id
        Create Table #ApInvoice
            (
              DatabaseName VARCHAR(150)
            , [Supplier] VARCHAR(35)
            , [Invoice] VARCHAR(150)
            , [InvoiceDate] DATETIME2
            , [DueDate] DATETIME2
            , [OrigInvValue] NUMERIC(20, 7)
            , [OrigDiscValue] NUMERIC(20, 7)
            , [PaymentNumber] VARCHAR(150)
            , [MthInvBal1] NUMERIC(20, 7)
            , [MthInvBal2] NUMERIC(20, 7)
            , [MthInvBal3] NUMERIC(20, 7)
			, [ConvRate] NUMERIC(20, 7)
			, [Currency] char(3)
            );
        Create Table #ApInvoicePay
            (
              DatabaseName VARCHAR(150)
            , [Supplier] VARCHAR(35)
            , [Invoice] VARCHAR(150)
            , [PaymentReference] VARCHAR(150)
            , [PostValue] NUMERIC(20, 7)
            );
        Create Table #ApSupplier
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(50)
            , SupplierName VARCHAR(150)
            );

--create script to pull data from each db into the tables
        Declare @SQL1 VARCHAR(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
            + UPPER(@Company) + ''' = ''ALL''
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
        Declare @SQL2 VARCHAR(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
            + UPPER(@Company) + ''' = ''ALL''
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
        Declare @SQL3 VARCHAR(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
            + UPPER(@Company) + ''' = ''ALL''
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
        Print 1
		Exec sp_MSforeachdb
            @SQL1;
        Print 2
		Exec sp_MSforeachdb
            @SQL2;
        Print 3
		Exec sp_MSforeachdb
            @SQL3;
		Print 4
--define the results you want to return
        Create Table #Results
            (
              DatabaseName		 VARCHAR(150) Collate Latin1_General_BIN
            , [Supplier]		 VARCHAR(30)
            , [SupplierName]	 VARCHAR(150)
            , [Invoice]			 VARCHAR(50)
            , [InvoiceDate]		 DATETIME2
            , [DueDate]			 DATETIME2
            , [OrigInvValue]	 NUMERIC(20, 7)
            , [OrigDiscValue]	 NUMERIC(20, 7)
            , [PaymentReference] VARCHAR(150)
            , [PaymentNumber]	 VARCHAR(150)
            , [PostValue]		 NUMERIC(20, 7)
            , [Value]			 NUMERIC(20, 7)
            , [MthInvBal1]		 NUMERIC(20, 7)
            , [MthInvBal2]		 NUMERIC(20, 7)
            , [MthInvBal3]		 NUMERIC(20, 7)
			, [ConvRate]		 NUMERIC(20, 7) 
			, [Currency]		 CHAR(3)
            );
        Create Table #SupplierSummary
            (
              DatabaseName		 VARCHAR(150) Collate Latin1_General_BIN
            , [Supplier]		 VARCHAR(50)
            , SupplierValue		 NUMERIC(20, 7)
			, Currency			Char(3)
            );


--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table

		--Determine end limiter
		--Declare @EndDate DATE
		--If @DueDateEnd = 'Today'
		--BEGIN
		--    Select @EndDate = GETDATE()
		--End
  --      If @DueDateEnd = 'End of this Month'
		--BEGIN
		--    Select @EndDate = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0))
		--End
  --      If @DueDateEnd = 'Start of this Month'
		--BEGIN
		--    Select @EndDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
		--End
  --      If @DueDateEnd = 'End of Next Month'
		--BEGIN
		--    Select @EndDate = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+2,0))
		--End

		Print 5
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
                Select
                    [ai].[DatabaseName]
                  , [ai].[Supplier]
                  , [ai].[Invoice]
                  , [ai].[InvoiceDate]
                  , [ai].[DueDate]
                  , [ai].[OrigInvValue]
                  , [ai].[OrigDiscValue]
                  , [PaymentReference] = MIN([aip].[PaymentReference])
                  , [PaymentNumber] = MAX([ai].[PaymentNumber])
                  , [PostValue] = SUM([aip].[PostValue])
                  , Value = [ai].[OrigInvValue] + SUM([aip].[PostValue])
                  , [ai].[MthInvBal1]
                  , [ai].[MthInvBal2]
                  , [ai].[MthInvBal3]
                  , [SupplierName]
				  , [ai].[ConvRate]
				  , [ai].[Currency]
                From
                    [#ApInvoice] As [ai]
                Left Join [#ApInvoicePay] As [aip]
                    On [aip].[Supplier] = [ai].[Supplier]
                       And [aip].[Invoice] = [ai].[Invoice]
                       And [aip].[DatabaseName] = [ai].[DatabaseName]
                Left Join [#ApSupplier] As [as]
                    On [as].[Supplier] = [ai].[Supplier]
                       And [as].[DatabaseName] = [ai].[DatabaseName]
				Where [ai].[DueDate]<=GETDATE()

                Group By
                    [ai].[DatabaseName]
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
		
		Print 6
        Insert  [#SupplierSummary]
                ( [DatabaseName]
                , [Supplier]
                , [SupplierValue]
				, [Currency]
                )
                Select
                    [r].[DatabaseName]
                  , [r].[Supplier]
				  , SupplierValue = SUM(case when [r].[Value]>= 0 then r.Value else 0 end)
				  , [r].[Currency]
                From
                    [#Results] As [r]
                Group By
                    [r].[DatabaseName], [r].[Currency]
                  , [r].[Supplier];

--return results
        Select
            [cn].[CompanyName]
          , [r].[Supplier]
          , [r].[SupplierName]
		  , [SupplierValue]			= coalesce([ss].[SupplierValue],0)
          , [r].[Invoice]
          , [InvoiceDate]			= Cast([InvoiceDate] As date)
          , [DueDate]				= Cast([DueDate] As date)
          , [r].[OrigInvValue]
          , [r].[OrigDiscValue]
          , [r].[PaymentReference]
          , [r].[PaymentNumber]
          , [PostValue]				= COALESCE([r].[PostValue], 0)
          , [Value]					= COALESCE([r].[Value], 0)
          , [r].[MthInvBal1]
          , [r].[MthInvBal2]
          , [r].[MthInvBal3]
		  , [r].[Currency]
		  , [r].[ConvRate]
        From
            #Results r
        Left Join [Lookups].[CompanyNames] As [cn]
            On [cn].[Company] = [r].[DatabaseName] Collate Latin1_General_BIN
		Left Join [#SupplierSummary] As [ss] 
			On [ss].[Supplier] = [r].[Supplier] 
			And [ss].Currency = r.Currency
			And [ss].[DatabaseName] = [r].[DatabaseName]
		Order By [DueDate]
        
		--Print @EndDate
    End;

GO
