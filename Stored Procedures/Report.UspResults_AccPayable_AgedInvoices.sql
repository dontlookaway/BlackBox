SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AccPayable_AgedInvoices]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As --Exec [Report].[UspResults_AccPayable_AgedInvoices]  10
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015													
Stored procedure set out to query multiple databases with the same information and return it in a collated format	
Replacement of aged AP analysis																						
*/
        Set NoCount Off;
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
            @StoredProcName = 'UspResults_AccPayable_AgedInvoices' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApSupplier,ApInvoice'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Supplier] Varchar(50)			collate latin1_general_bin
            , [SupplierName] Varchar(200)		collate latin1_general_bin
            );									
        Create Table [#ApInvoice]				
            (									
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Invoice] Varchar(50)				collate latin1_general_bin
            , [InvoiceDate] DateTime2			
            , [OrigInvValue] Numeric(20 , 7)	
            , [OrigDiscValue] Numeric(20 , 7)	
            , [MthInvBal1] Numeric(20 , 7)		
            , [MthInvBal2] Numeric(20 , 7)		
            , [MthInvBal3] Numeric(20 , 7)		
            , [Currency] Char(3)				collate latin1_general_bin
            , [ConvRate] Numeric(20 , 7)		
            , [PostCurrency] Char(3)			collate latin1_general_bin
            , [Supplier] Varchar(50)			collate latin1_general_bin
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
				Insert [#ApInvoice]
						( [DatabaseName]
						, [Invoice]
						, [InvoiceDate]
						, [OrigInvValue]
						, [OrigDiscValue]
						, [MthInvBal1]
						, [MthInvBal2]
						, [MthInvBal3]
						, [Currency]
						, [ConvRate]
						, [PostCurrency]
						, [Supplier]
						)
				SELECT [DatabaseName]=@DBCode
					 , [ai].[Invoice]
					 , [ai].[InvoiceDate]
					 , [ai].[OrigInvValue]
					 , [ai].[OrigDiscValue]
					 , [ai].[MthInvBal1]
					 , [ai].[MthInvBal2]
					 , [ai].[MthInvBal3]
					 , [ai].[Currency]
					 , [ai].[ConvRate]
					 , [ai].[PostCurrency] 
					 , [ai].[Supplier]
				From [ApInvoice] As [ai]
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
				Insert [#ApSupplier]
					( [DatabaseName]
					, [Supplier]
					, [SupplierName]
					)
				SELECT [DatabaseName]=@DBCode
					 , [as].[Supplier]
					 , [as].[SupplierName] 
				From [ApSupplier] As [as]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [sys].[sp_MSforeachdb] @SQL1;
        Exec [sys].[sp_MSforeachdb] @SQL2;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Supplier] Varchar(50)			collate latin1_general_bin
            , [SupplierName] Varchar(150)		collate latin1_general_bin
            , [Invoice] Varchar(50)				collate latin1_general_bin
            , [InvoiceDate] DateTime2			
            , [OrigInvValue] Numeric(20 , 7)	
            , [OrigDiscValue] Numeric(20 , 7)	
            , [MthInvBal1] Numeric(20 , 7)		
            , [MthInvBal2] Numeric(20 , 7)		
            , [MthInvBal3] Numeric(20 , 7)		
            , [Currency] Char(3)				collate latin1_general_bin
            , [ConvRate] Numeric(20 , 7)		
            , [PostCurrency] Char(3)			collate latin1_general_bin
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Supplier]
                , [SupplierName]
                , [Invoice]
                , [InvoiceDate]
                , [OrigInvValue]
                , [OrigDiscValue]
                , [MthInvBal1]
                , [MthInvBal2]
                , [MthInvBal3]
                , [Currency]
                , [ConvRate]
                , [PostCurrency]
	            )
                Select  [asp].[DatabaseName]
                      , [asp].[Supplier]
                      , [asp].[SupplierName]
                      , [ai].[Invoice]
                      , [ai].[InvoiceDate]
                      , [ai].[OrigInvValue]
                      , [ai].[OrigDiscValue]
                      , [ai].[MthInvBal1]
                      , [ai].[MthInvBal2]
                      , [ai].[MthInvBal3]
                      , [ai].[Currency]
                      , [ai].[ConvRate]
                      , [ai].[PostCurrency]
                From    [#ApSupplier] As [asp]
                        Inner Join [#ApInvoice] As [ai]
                            On [ai].[Supplier] = [asp].[Supplier]
                               And [ai].[DatabaseName] = [asp].[DatabaseName];

--return results
        Select  [cn].[CompanyName]
              , [r].[Supplier]
              , [r].[SupplierName]
              , [r].[Invoice]
              , [InvoiceDate] = Cast([r].[InvoiceDate] As Date)
              , [r].[OrigInvValue]
              , [r].[OrigDiscValue]
              , [r].[MthInvBal1]
              , [r].[MthInvBal2]
              , [r].[MthInvBal3]
              , [r].[Currency]
              , [r].[ConvRate]
              , [r].[PostCurrency]
        From    [#Results] As [r]
                Left Join [Lookups].[CompanyNames] As [cn]
                    On [r].[DatabaseName] = [cn].[Company];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'returns details of aged accounts payable invoices', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AccPayable_AgedInvoices', NULL, NULL
GO
