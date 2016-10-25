SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Procedure [Report].[UspResults_PurchaseOrdersOpen]
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
Returns details of all open (non cancelled & non fulfilled) PO's
--Exec [Report].[UspResults_PurchaseOrdersOpen]  10
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount Off;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_PurchaseOrdersOpen' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterHdr,PorMasterDetail,ApSupplier,PorMasterDetail+'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35) Collate Latin1_General_BIN
            , [Buyer] Varchar(35) Collate Latin1_General_BIN
            , [Supplier] Varchar(35) Collate Latin1_General_BIN
            , [OrderStatus] Varchar(35) Collate Latin1_General_BIN
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35) Collate Latin1_General_BIN
            , [Line] Varchar(15) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [StockDes] Varchar(150) Collate Latin1_General_BIN
            , [SupCatalogue] Varchar(50) Collate Latin1_General_BIN
            , [OrderQty] Numeric(20 , 7)
            , [ReceivedQty] Numeric(20 , 7)
            , [MPrice] Numeric(20 , 3)
            , [OrderUom] Varchar(10) Collate Latin1_General_BIN
            , [Warehouse] Varchar(35) Collate Latin1_General_BIN
            , [LatestDueDate] DateTime2
            , [CompleteFlag] Char(5)
            , [MForeignPrice] Numeric(20 , 3)
            , [MGlCode] Varchar(35) Collate Latin1_General_BIN
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(35) Collate Latin1_General_BIN
            , [SupplierName] Varchar(150) Collate Latin1_General_BIN
            );
        Create Table [#PorMasterDetailPlus]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35) Collate Latin1_General_BIN
            , [Line] Varchar(15) Collate Latin1_General_BIN
            , [Confirmed] Varchar(35) Collate Latin1_General_BIN
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
				Insert [#PorMasterHdr]
						( [DatabaseName]
						, [PurchaseOrder]
						, [Buyer]
						, [Supplier]
						, [OrderStatus]
						)
				SELECT [DatabaseName]=@DBCode
					 , [pmh].[PurchaseOrder]
					 , [pmh].[Buyer]
					 , [pmh].[Supplier]
					 , [OrderStatus]
				FROM [PorMasterHdr] [pmh]
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
							Insert [#PorMasterDetail]
			        ( [DatabaseName]
			        , [PurchaseOrder]
			        , [Line]
			        , [StockCode]
			        , [StockDes]
			        , [SupCatalogue]
			        , [OrderQty]
			        , [ReceivedQty]
					, MPrice
			        , [OrderUom]
			        , [Warehouse]
			        , [LatestDueDate]
			        , [CompleteFlag]
					, MForeignPrice
					,[MGlCode] 
			        )
			SELECT [DatabaseName] = @DBCode
                 , [pmd].[PurchaseOrder]
                 , [pmd].[Line]
                 , [pmd].[MStockCode]
                 , [pmd].[MStockDes]
                 , [pmd].[MSupCatalogue]
                 , [pmd].[MOrderQty]
                 , [pmd].[MReceivedQty]
				 , MPrice
                 , [pmd].[MOrderUom]
                 , [pmd].[MWarehouse]
                 , [pmd].[MLatestDueDate]
                 , [pmd].[MCompleteFlag]
				 , [MForeignPrice]
				 ,[MGlCode] 
			From [PorMasterDetail] As [pmd]
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
							Insert [#ApSupplier]
		        ( [DatabaseName]
		        , [Supplier]
		        , [SupplierName]
		        )
		SELECT [DatabaseName]=@DBCode
             , [as].[Supplier]
             , [as].[SupplierName] FROM [ApSupplier] As [as]
			End
	End';
        Declare @SQL4 Varchar(Max) = '
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
			print @ActualCountOfTables
			print @RequiredCountOfTables
			If @ActualCountOfTables=@RequiredCountOfTables
			
			BEGIN
			Insert [#PorMasterDetailPlus]
			        ( [DatabaseName]
			        , [PurchaseOrder]
			        , [Line]
			        , [Confirmed]
			        )
			SELECT [DatabaseName]=@DBCode
                 , [pmdp].[PurchaseOrder]
                 , [pmdp].[Line]
                 , [pmdp].[Confirmed] 
			From [PorMasterDetail+] As [pmdp]
			end
	End';

--Enable this function to check script changes (try to run script directly against db manually)
		--Print @SQL1
		--Print @SQL2
		--Print @SQL3
		--Print @SQL4

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;

--define the results you want to return
        Create Table [#Results]
            (
              [Company] Varchar(250) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35) Collate Latin1_General_BIN
            , [Line] Varchar(15) Collate Latin1_General_BIN
            , [Supplier] Varchar(35) Collate Latin1_General_BIN
            , [SupplierName] Varchar(150) Collate Latin1_General_BIN
            , [Buyer] Varchar(35) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [StockDescription] Varchar(150) Collate Latin1_General_BIN
            , [SupCatalogue] Varchar(50) Collate Latin1_General_BIN
            , [OrderQty] Numeric(20 , 7)
            , [ReceivedQty] Numeric(20 , 7)
            , [OrderUom] Varchar(10) Collate Latin1_General_BIN
            , [Warehouse] Varchar(35) Collate Latin1_General_BIN
            , [LatestDueDate] Date
            , [Confirmed] Varchar(35) Collate Latin1_General_BIN
            , [OrderStatusDescription] Varchar(150) Collate Latin1_General_BIN
            , [MPrice] Numeric(20 , 2)
            , [MForeignPrice] Numeric(20 , 2)
            , [GLCode] Varchar(35) Collate Latin1_General_BIN
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table

--return results
        Insert  [#Results]
                ( [Company]
                , [PurchaseOrder]
                , [Line]
                , [Supplier]
                , [SupplierName]
                , [Buyer]
                , [StockCode]
                , [StockDescription]
                , [SupCatalogue]
                , [OrderQty]
                , [ReceivedQty]
                , [OrderUom]
                , [Warehouse]
                , [LatestDueDate]
                , [Confirmed]
                , [OrderStatusDescription]
                , [MPrice]
                , [MForeignPrice]
                , [GLCode]
                )
                Select  [Company] = [PH].[DatabaseName]
                      , [PH].[PurchaseOrder]
                      , [PD].[Line]
                      , [APS].[Supplier]
                      , [APS].[SupplierName]
                      , [PH].[Buyer]
                      , [StockCode] = [PD].[StockCode]
                      , [StockDescription] = [PD].[StockDes]
                      , [SupCatalogue] = [PD].[SupCatalogue]
                      , [OrderQty] = [PD].[OrderQty]
                      , [ReceivedQty] = [PD].[ReceivedQty]
                      , [OrderUom] = [PD].[OrderUom]
                      , [Warehouse] = [PD].[Warehouse]
                      , [LatestDueDate] = [PD].[LatestDueDate]
                      , [Confirmed] = [PMp].[Confirmed]
                      , [pos].[OrderStatusDescription]
                      , [PD].[MPrice]
                      , [PD].[MForeignPrice]
                      , [GLCode] = [PD].[MGlCode]
                From    [#PorMasterHdr] [PH]
                        Inner Join [#PorMasterDetail] [PD] On [PH].[PurchaseOrder] = [PD].[PurchaseOrder]
                                                              And [PD].[DatabaseName] = [PH].[DatabaseName]
                        Inner Join [#ApSupplier] [APS] On [PH].[Supplier] = [APS].[Supplier]
                                                          And [APS].[DatabaseName] = [PD].[DatabaseName]
                        Left Outer Join [#PorMasterDetailPlus] [PMp] With ( NoLock ) On [PD].[PurchaseOrder] = [PMp].[PurchaseOrder]
                                                              And [PMp].[DatabaseName] = [PD].[DatabaseName]
                                                              And [PD].[Line] = [PMp].[Line]
                        Left Join [Lookups].[PurchaseOrderStatus] As [pos] On [APS].[DatabaseName] = [pos].[Company] Collate Latin1_General_BIN
                                                              And [PH].[OrderStatus] = [pos].[OrderStatusCode] Collate Latin1_General_BIN
                Where   [PH].[OrderStatus] <> '*'
                        And [PD].[OrderQty] > [PD].[ReceivedQty]
                        And ( [PD].[CompleteFlag] <> 'Y' );

        Select  [cn].[CompanyName]
              , [r].[PurchaseOrder]
              , [r].[Line]
              , [r].[Supplier]
              , [r].[SupplierName]
              , [r].[Buyer]
              , [r].[StockCode]
              , [r].[StockDescription]
              , [r].[SupCatalogue]
              , [r].[OrderQty]
              , [r].[ReceivedQty]
              , [r].[OrderUom]
              , [r].[Warehouse]
              , [LatestDueDate] = Cast([r].[LatestDueDate] As Date)
              , [r].[Confirmed]
              , [r].[OrderStatusDescription]
              , [Price] = [r].[MPrice]
              , [ForeignPrice] = [r].[MForeignPrice]
              , [r].[GLCode]
			  , [GLCodeDescription] = [GM].[Description]
        From    [#Results] As [r]
                Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company] = [r].[Company] Collate Latin1_General_BIN
                Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [GM].[GlCode] = [r].[GLCode]
                                                              And [GM].[Company] = [r].[Company];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'purchase order details for open purchase orders', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_PurchaseOrdersOpen', NULL, NULL
GO
