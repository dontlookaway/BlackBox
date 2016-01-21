SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrdersOpen] ( @Company VARCHAR(Max) )
As --Exec [Report].[UspResults_PurchaseOrdersOpen]  10
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Returns details of all open (non cancelled & non fulfilled) PO's														///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			25/9/2015	Chris Johnson			Initial version created																///
///			30/9/2015	Chris Johnson			Added foreign price and company name												///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
        Set NoCount Off;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'PorMasterHdr,PorMasterDetail,ApSupplier,PorMasterDetail+'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #PorMasterHdr
            (
              DatabaseName VARCHAR(150)
            , PurchaseOrder VARCHAR(35)
            , Buyer VARCHAR(35)
            , Supplier VARCHAR(35)
            , OrderStatus VARCHAR(35)
            );
        Create Table #PorMasterDetail
            (
              DatabaseName VARCHAR(150)
            , PurchaseOrder VARCHAR(35)
            , Line VARCHAR(15)
            , StockCode VARCHAR(35)
            , StockDes VARCHAR(150)
            , SupCatalogue VARCHAR(50)
            , OrderQty  NUMERIC(20,7)
            , ReceivedQty NUMERIC(20,7)
			, MPrice  NUMERIC(20,3)
            , OrderUom VARCHAR(10)
            , Warehouse VARCHAR(35)
            , LatestDueDate DATETIME2
            , CompleteFlag CHAR(5)
			, [MForeignPrice] NUMERIC(20,3)
            );
        Create Table #ApSupplier
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(35)
            , SupplierName VARCHAR(150)
            );
        Create Table #PorMasterDetailPlus
            (
              DatabaseName VARCHAR(150)
            , PurchaseOrder VARCHAR(35)
            , Line VARCHAR(15)
            , Confirmed VARCHAR(35)
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
			From [PorMasterDetail] As [pmd]
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
             , [as].[SupplierName] FROM [ApSupplier] As [as]
			End
	End';
        Declare @SQL4 VARCHAR(Max) = '
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
        Exec sp_MSforeachdb @SQL1;
        Exec sp_MSforeachdb @SQL2;
		Exec sp_MSforeachdb @SQL3;
		Exec sp_MSforeachdb @SQL4;

--define the results you want to return
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	--Insert #Results
	--        ( DatabaseName, Results )
	--Select DatabaseName,ColumnName FROM #Table1

--return results
        Select Company			= [PH].[DatabaseName]
          , [PH].PurchaseOrder
          , [PD].Line
          , [APS].Supplier
          , [APS].SupplierName
          , [PH].Buyer
          , StockCode			= PD.StockCode
          , StockDescription	= PD.StockDes
          , SupCatalogue		= PD.SupCatalogue
          , OrderQty			= PD.OrderQty
          , ReceivedQty			= PD.ReceivedQty
          , OrderUom			= PD.OrderUom
          , Warehouse			= PD.Warehouse
          , LatestDueDate		= PD.LatestDueDate
          , Confirmed			= PMp.Confirmed
		  , [pos].[OrderStatusDescription]
		  , [PD].[MPrice]
		  , [PD].[MForeignPrice]
		  Into #Results
        From
            #PorMasterHdr PH
        Inner Join #PorMasterDetail PD
            On PH.PurchaseOrder = PD.PurchaseOrder
               And [PD].[DatabaseName] = [PH].[DatabaseName]
        Inner Join #ApSupplier APS
            On PH.Supplier = APS.Supplier
               And [APS].[DatabaseName] = [PD].[DatabaseName]
        Left Outer Join [#PorMasterDetailPlus] PMp With ( NoLock )
            On PD.PurchaseOrder = PMp.PurchaseOrder
               And [PMp].[DatabaseName] = [PD].[DatabaseName]
               And PD.Line = PMp.Line
		Left Join [Lookups].[PurchaseOrderStatus] As [pos] 
			On [APS].[DatabaseName]=[pos].[Company] Collate Latin1_General_BIN
				And [PH].[OrderStatus]=pos.[OrderStatusCode] Collate Latin1_General_BIN
        Where
            PH.OrderStatus <> '*'
            And PD.OrderQty > PD.ReceivedQty 
            And ( PD.CompleteFlag <> 'Y' );

		SELECT [cn].[CompanyName]
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
             , [LatestDueDate] = CAST([r].[LatestDueDate] As DATE)
             , [r].[Confirmed]
             , [r].[OrderStatusDescription]
			 , Price = MPrice
			 , ForeignPrice = [r].[MForeignPrice]
		 FROM [#Results] As [r]
		 Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company]=[r].[Company] Collate Latin1_General_BIN

    End;

GO
