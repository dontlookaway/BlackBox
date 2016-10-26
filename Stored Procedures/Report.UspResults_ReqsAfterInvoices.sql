SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ReqsAfterInvoices]
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
Proc to return where a requisition was created after an invoice was received
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
            @StoredProcName = 'UspResults_ReqsAfterInvoices' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ReqHeader,ReqDetail,PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ReqHeader]
            (
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [Requisition] Varchar(10)				collate Latin1_General_BIN
            , [DateReqnRaised] Date					
            );										
        Create Table [#ReqDetail]					
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [Requisition] Varchar(10)				collate Latin1_General_BIN
            , [Line] Int							
            , [ApprovedDate] Date					
            , [StockCode] Varchar(30)				collate Latin1_General_BIN
            , [StockDescription] Varchar(50)		collate Latin1_General_BIN
            );										
        Create Table [#PorMasterDetail]				
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [MRequisition] Varchar(10)			collate Latin1_General_BIN
            , [Line] Int							
            , [PurchaseOrder] Varchar(20)			collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 8)			
            , [MPrice] Numeric(20 , 2)				
            , [MForeignPrice] Numeric(20 , 2)		
            );										
        Create Table [#PorMasterHdr]				
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20)			collate Latin1_General_BIN
            , [OrderEntryDate] Date					
            );										
        Create Table [#GrnDetails]					
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20)			collate Latin1_General_BIN
            , [Grn] Varchar(20)						collate Latin1_General_BIN
            , [Supplier] Varchar(15)				collate Latin1_General_BIN
            , [Warehouse] Varchar(10)				collate Latin1_General_BIN
            );										
        Create Table [#GrnMatching]					
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [Grn] Varchar(20)						collate Latin1_General_BIN
            , [Supplier] Varchar(15)				collate Latin1_General_BIN
            , [Invoice] Varchar(20)					collate Latin1_General_BIN
            );										
        Create Table [#ApInvoice]					
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [Supplier] Varchar(15)				collate Latin1_General_BIN
            , [Invoice] Varchar(20)					collate Latin1_General_BIN
            , [InvoiceDate] Date					
            , [PostCurrency] Varchar(10)			collate Latin1_General_BIN
            );										
        Create Table [#ApSupplier]					
            (										
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [Supplier] Varchar(15)				collate Latin1_General_BIN
            , [SupplierName] Varchar(50)			collate Latin1_General_BIN
            );

--create script to pull data from each db into the tables
        Declare @SQLReqs Varchar(Max) = '
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
				Insert [#ReqHeader]
						( [DatabaseName]
						, [Requisition]
						, [DateReqnRaised]
						)
				SELECT [DatabaseName]=@DBCode
					 , [RH].[Requisition]
					 , [RH].[DateReqnRaised] FROM [ReqHeader] As [RH]

				Insert [#ReqDetail]
						( [DatabaseName]
						, [Requisition]
						, [Line]
						, [ApprovedDate]
						, [StockCode]
						, [StockDescription]
						)
				SELECT [DatabaseName]=@DBCode
					 , [RD].[Requisition]
					 , [RD].[Line]
					 , [RD].[ApprovedDate]
					 , [RD].[StockCode]
					 , [RD].[StockDescription] FROM [ReqDetail] As [RD]
			End
	End';
        Declare @SQLPorMasters Varchar(Max) = '
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
				Insert [#PorMasterDetail]
						( [DatabaseName]
						, [MRequisition]
						, [Line]
						, [PurchaseOrder]
						, [MOrderQty]
						, [MPrice]
						, [MForeignPrice]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMD].[MRequisition]
					 , [PMD].[Line]
					 , [PMD].[PurchaseOrder]
					 , [PMD].[MOrderQty]
					 , [PMD].[MPrice]
					 , [PMD].[MForeignPrice] FROM [PorMasterDetail] As [PMD]

				Insert [#PorMasterHdr]
						( [DatabaseName]
						, [PurchaseOrder]
						, [OrderEntryDate]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMH].[PurchaseOrder]
					 , [PMH].[OrderEntryDate] FROM [PorMasterHdr] As [PMH]
			End
	End';
        Declare @SQLGrns Varchar(Max) = '
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
			Insert [#GrnDetails]
					( [DatabaseName]
					, [PurchaseOrder]
					, [Grn]
					, [Supplier]
					, [Warehouse]
					)
			SELECT [DatabaseName]=@DBCode
				 , [GD].[PurchaseOrder]
				 , [GD].[Grn]
				 , [GD].[Supplier]
				 , [GD].[Warehouse] FROM [GrnDetails] As [GD]

			Insert [#GrnMatching]
					( [DatabaseName]
					, [Grn]
					, [Supplier]
					, [Invoice]
					)
			SELECT [DatabaseName]=@DBCode
				 , [GM].[Grn]
				 , [GM].[Supplier]
				 , [GM].[Invoice] FROM [GrnMatching] As [GM]
			End
	End';
        Declare @SQLAps Varchar(Max) = '
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
						, [InvoiceDate]
						, [PostCurrency]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AI].[Supplier]
					 , [AI].[Invoice]
					 , [AI].[InvoiceDate]
					 , [AI].[PostCurrency] FROM [ApInvoice] As [AI]

				Insert [#ApSupplier]
						( [DatabaseName]
						, [Supplier]
						, [SupplierName]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AS].[Supplier]
					 , [AS].[SupplierName] FROM [ApSupplier] As [AS]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLReqs;
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasters;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrns;
        Exec [Process].[ExecForEachDB] @cmd = @SQLAps;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)		collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20)		collate Latin1_General_BIN
            , [Requisition] Varchar(10)			collate Latin1_General_BIN
            , [DateReqnRaised] Date				
            , [OrderEntryDate] Date				
            , [ApprovedDate] Date				
            , [Grn] Varchar(20)					collate Latin1_General_BIN
            , [Invoice] Varchar(20)				collate Latin1_General_BIN
            , [InvoiceDate] Date				
            , [Supplier] Varchar(15)			collate Latin1_General_BIN
            , [SupplierName] Varchar(50)		collate Latin1_General_BIN
            , [StockCode] Varchar(30)			collate Latin1_General_BIN
            , [StockDescription] Varchar(50)	collate Latin1_General_BIN
            , [PostCurrency] Varchar(10)		collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 8)		
            , [MPrice] Numeric(20 , 2)			
            , [MForeignPrice] Numeric(20 , 2)	
            , [Warehouse] Varchar(10)			collate Latin1_General_BIN
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [PurchaseOrder]
                , [Requisition]
                , [DateReqnRaised]
                , [OrderEntryDate]
                , [ApprovedDate]
                , [Grn]
                , [Invoice]
                , [InvoiceDate]
                , [Supplier]
                , [SupplierName]
                , [StockCode]
                , [StockDescription]
                , [PostCurrency]
                , [MOrderQty]
                , [MPrice]
                , [MForeignPrice]
                , [Warehouse]
                )
                Select  Distinct
                        [RH].[DatabaseName]
                      , [PMD].[PurchaseOrder]
                      , [RH].[Requisition]
                      , [RH].[DateReqnRaised]
                      , [PMH].[OrderEntryDate]
                      , [RD].[ApprovedDate]
                      , [GD].[Grn]
                      , [AI].[Invoice]
                      , [AI].[InvoiceDate]
                      , [AI].[Supplier]
                      , [AS].[SupplierName]
                      , [RD].[StockCode]
                      , [RD].[StockDescription]
                      , [AI].[PostCurrency]
                      , [PMD].[MOrderQty]
                      , [PMD].[MPrice]
                      , [PMD].[MForeignPrice]
                      , [GD].[Warehouse]
                From    [#ReqHeader] As [RH]
                        Left Join [#ReqDetail] As [RD] On [RD].[Requisition] = [RH].[Requisition]
                                                          And [RD].[DatabaseName] = [RH].[DatabaseName]
                        Left Join [#PorMasterDetail] As [PMD] On [PMD].[MRequisition] = [RH].[Requisition]
                                                              And [PMD].[Line] = [RD].[Line]
                                                              And [PMD].[DatabaseName] = [RD].[DatabaseName]
                        Left Join [#PorMasterHdr] As [PMH] On [PMH].[PurchaseOrder] = [PMD].[PurchaseOrder]
                                                              And [PMH].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [#GrnDetails] As [GD] On [GD].[PurchaseOrder] = [PMH].[PurchaseOrder]
                                                           And [GD].[DatabaseName] = [PMH].[DatabaseName]
                        Left Join [#GrnMatching] As [GM] On [GM].[Supplier] = [GD].[Supplier]
                                                            And [GM].[Grn] = [GD].[Grn]
                                                            And [GM].[DatabaseName] = [GD].[DatabaseName]
                        Left Join [#ApInvoice] As [AI] On [AI].[Supplier] = [GM].[Supplier]
                                                          And [AI].[Invoice] = [GM].[Invoice]
                                                          And [AI].[DatabaseName] = [GM].[DatabaseName]
                        Left Join [#ApSupplier] As [AS] On [AS].[Supplier] = [AI].[Supplier]
                                                           And [AS].[DatabaseName] = [AI].[DatabaseName]
                Where   [AI].[InvoiceDate] < [RH].[DateReqnRaised];

--return results
        Select  [R].[DatabaseName]
              , [R].[Requisition]
			  , [R].[PurchaseOrder]
              , [R].[DateReqnRaised]
              , [R].[OrderEntryDate]
              , [R].[ApprovedDate]
              , [R].[Grn]
              , [R].[Invoice]
              , [R].[InvoiceDate]
              , [R].[Supplier]
              , [R].[SupplierName]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[PostCurrency]
              , [R].[MOrderQty]
              , [R].[MPrice]
              , [R].[MForeignPrice]
              , [R].[Warehouse]
              , [CN].[CompanyName]
        From    [#Results] As [R]
                Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [R].[DatabaseName];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of requisitions raised post invoices appearing in system', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ReqsAfterInvoices', NULL, NULL
GO
