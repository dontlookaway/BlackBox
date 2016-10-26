SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_OutstandingPurchaseOrders]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015 
Stored procedure set out to bring back purchase orders which do not have receipts
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
            @StoredProcName = 'UspResults_OutstandingPurchaseOrders' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterHdr,ApSupplier,PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35)	Collate Latin1_General_BIN
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            , [OrderStatus] Varchar(35)		Collate Latin1_General_BIN
            , [Supplier] Varchar(15)		Collate Latin1_General_BIN
            , [CancelledFlag] Char(1)		Collate Latin1_General_BIN
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [Supplier] Varchar(15)		Collate Latin1_General_BIN
            , [SupplierName] Varchar(150)	Collate Latin1_General_BIN
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35)	Collate Latin1_General_BIN
            , [Line] Int
            , [MStockCode] Varchar(35)		Collate Latin1_General_BIN
            , [MStockDes] Varchar(150)		Collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 8)
            , [MPrice] Numeric(20 , 3)
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
				Insert #PorMasterHdr
						( DatabaseName
						, PurchaseOrder
						, OrderEntryDate
						, OrderDueDate
						, OrderStatus
						, Supplier
						, CancelledFlag
						)
				SELECT DatabaseName = @DBCode
					 , PurchaseOrder
					 , OrderEntryDate
					 , OrderDueDate
					 , OrderStatus
					 , Supplier
					 , CancelledFlag FROM PorMasterHdr
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
					Insert #ApSupplier
							( DatabaseName
							, Supplier
							, SupplierName
							)
					SELECT DatabaseName = @DBCode
						 , Supplier
						 , SupplierName 
						 FROM ApSupplier
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
				Insert #PorMasterDetail
						( DatabaseName
						, PurchaseOrder
						, Line
						, MStockCode
						, MStockDes
						, MOrderQty
						, MPrice
						)
				SELECT DatabaseName = @DBCode
					 , PurchaseOrder
					 , Line
					 , MStockCode
					 , MStockDes
					 , MOrderQty
					 , MPrice FROM  PorMasterDetail
						End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)			collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35)			collate Latin1_General_BIN
            , [SupplierName] Varchar(150)			collate Latin1_General_BIN
            , [OrderStatusDescription] Varchar(150)	collate Latin1_General_BIN
            , [OrderEntryDate] DateTime2			
            , [OrderDueDate] DateTime2				
            , [Line] Int							
            , [StockCode] Varchar(35)				collate Latin1_General_BIN
            , [StockDesc] Varchar(150)				collate Latin1_General_BIN
            , [OrderQty] Numeric(20 , 6)
            , [Price] Numeric(20 , 3)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [PurchaseOrder]
                , [SupplierName]
                , [OrderStatusDescription]
                , [OrderEntryDate]
                , [OrderDueDate]
                , [Line]
                , [StockCode]
                , [StockDesc]
                , [OrderQty]
                , [Price]
	            )
                Select  [PH].[DatabaseName]
                      , [PH].[PurchaseOrder]
                      , [APS].[SupplierName]
                      , [PS].[OrderStatusDescription]
                      , [PH].[OrderEntryDate]
                      , [PH].[OrderDueDate]
                      , [PMD].[Line]
                      , [PMD].[MStockCode]
                      , [PMD].[MStockDes]
                      , [PMD].[MOrderQty]
                      , [PMD].[MPrice]
                From    [#PorMasterHdr] [PH]
                        Left Join [BlackBox].[Lookups].[PurchaseOrderStatus] [PS] On [PH].[OrderStatus] = [PS].[OrderStatusCode]
                                                              And [PS].[Company] = [PH].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[PurchaseOrderInvoiceMapping] [POI] On [POI].[PurchaseOrder] = [PH].[PurchaseOrder]
                                                              And [POI].[Company] = [PH].[DatabaseName]
                        Left Join [#ApSupplier] [APS] On [APS].[Supplier] = [PH].[Supplier]
                                                         And [APS].[DatabaseName] = [PH].[DatabaseName]
                        Left Join [#PorMasterDetail] [PMD] On [PMD].[PurchaseOrder] = [PH].[PurchaseOrder]
                Where   [POI].[Invoice] Is Null --Where an invoice has not been received
                        And [PH].[CancelledFlag] <> 'Y' --Ignore cancelled flag
		;

--return results
        Select  [DatabaseName]
              , [PurchaseOrder]
              , [SupplierName]
              , [OrderStatusDescription]
              , [OrderEntryDate] = Cast([OrderEntryDate] As Date)
              , [OrderDueDate] = Cast([OrderDueDate] As Date)
              , [Line] = Coalesce([Line] , 0)
              , [StockCode]
              , [StockDesc]
              , [OrderQty] = Coalesce([OrderQty] , 0)
              , [Price] = Coalesce([Price] , 0)
              , [Status] = Case When [OrderDueDate] Is Null
                                Then 'No due date specified'
                                When [OrderDueDate] <= GetDate()
                                Then 'Overdue - nothing received'
                                Else 'Not overdue - nothing received'
                           End
        From    [#Results]
        Where   Coalesce([StockCode] , '') <> ''
                And Coalesce([StockDesc] , '') <> ''
                And Coalesce([OrderQty] , 0) <> 0
                And Coalesce([Price] , 0) <> 0
        Order By [OrderDueDate] Desc
              , [OrderEntryDate] Desc;

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of purchase orders outstanding', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_OutstandingPurchaseOrders', NULL, NULL
GO
