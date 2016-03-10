
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_OpenPurchaseOrderStock]
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
            @StoredProcName = 'UspResults_OpenPurchaseOrderStock' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [PurchaseOrder] Varchar(20)
            , [OrderDueDate] Date
            , [DeliveryAddr1] Varchar(40)
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [Line] Int
            , [MSupCatalogue] Varchar(50)
            , [MStockDes] Varchar(50)
            , [MStockCode] Varchar(30)
            , [MLatestDueDate] Date
            , [MCompleteFlag] Char(1)
            , [MOrderQty] Numeric(20 , 8)
            , [MReceivedQty] Numeric(20 , 8)
            , [MOrderUom] Varchar(10)
            , [MWarehouse] Varchar(10)
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [SupplierName] Varchar(50)
            );


	
--create script to pull data from each db into the tables
        Declare @SQLPorMasterDetail Varchar(Max) = '
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
						, [MSupCatalogue]
						, [MStockDes]
						, [MStockCode]
						, [MLatestDueDate]
						, [MCompleteFlag]
						, [MOrderQty]
						, [MOrderUom]
						, [MWarehouse]
						, [MReceivedQty]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMD].[PurchaseOrder]
					 , [PMD].[Line]
					 , [PMD].[MSupCatalogue]
					 , [PMD].[MStockDes]
					 , [PMD].[MStockCode]
					 , [PMD].[MLatestDueDate]
					 , [PMD].[MCompleteFlag]
					 , [PMD].[MOrderQty]
					 , [PMD].[MOrderUom]
					 , [PMD].[MWarehouse]
					 , [PMD].[MReceivedQty] FROM [PorMasterDetail] As [PMD]
			End
	End';
        Declare @SQLPorMasterHdr Varchar(Max) = '
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
						, [Supplier]
						, [PurchaseOrder]
						, [OrderDueDate]
						, [DeliveryAddr1]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMH].[Supplier]
					 , [PMH].[PurchaseOrder]
					 , [PMH].[OrderDueDate]
					 , [PMH].[DeliveryAddr1] FROM [PorMasterHdr] As [PMH]
					 where [OrderStatus] not in (''*'')
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
			        )
			SELECT [DatabaseName]=@DBCode
                 , [AS].[Supplier]
                 , [AS].[SupplierName] FROM [ApSupplier] As [AS]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLApSupplier;
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasterDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasterHdr;

--define the results you want to return
        
--Placeholder to create indexes as required

--script to combine base data and insert into results table


--return results
        Select  [PMH].[Supplier]
              , [AS].[SupplierName]
              , [PurchaseOrder] = Case When IsNumeric([PMH].[PurchaseOrder]) = 1
                                       Then Convert(Varchar(20) , Convert(Int , [PMH].[PurchaseOrder]))
                                       Else [PMH].[PurchaseOrder]
                                  End
              , [PMD].[Line]
              , [SupplierCatalogue] = [PMD].[MSupCatalogue]
              , [StockDescription] = [PMD].[MStockDes]
              , [StockCode] = [PMD].[MStockCode]
              , [PMH].[OrderDueDate]
              , [LatestDueDate] = [PMD].[MLatestDueDate]
              , [Overdue] = Case When DateDiff(Day , [PMD].[MLatestDueDate] ,
                                               GetDate()) > 0 Then 'Overdue'
                            End
              , [Complete] = Case When [PMD].[MCompleteFlag] = '' Then 'N'
                                  Else [PMD].[MCompleteFlag]
                             End
              , [PMD].[MOrderQty]
              , [PMD].[MOrderUom]
              , [PMD].[MWarehouse]
              , [PMH].[DeliveryAddr1]
              , [PMD].[MReceivedQty]
        From    [#PorMasterHdr] As [PMH]
                Left Join [#PorMasterDetail] As [PMD] On [PMD].[PurchaseOrder] = [PMH].[PurchaseOrder]
                                                         And [PMD].[DatabaseName] = [PMH].[DatabaseName]
                Left Join [#ApSupplier] As [AS] On [AS].[Supplier] = [PMH].[Supplier]
                                                   And [AS].[DatabaseName] = [PMH].[DatabaseName]
        Where   Coalesce([PMD].[MCompleteFlag] , 'N') <> 'Y'
                And [PMD].[MStockCode] Not In ( '' , 'N/A' )
                And [PMD].[MWarehouse] = 'RM'
        Order By [AS].[SupplierName] Asc;
						

    End;

GO
