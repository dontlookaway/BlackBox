SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AllSalesOrders]
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
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_Template' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'SorMaster,SorDetail,ArCustomer'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ArCustomer]
            (
              [DatabaseName] sysname
            , [Customer] Varchar(15)
            , [Name] Varchar(50)
            , [ShortName] Varchar(20)
            , [Area] Varchar(10)
            , [Currency] Varchar(3)
            , [DateCustAdded] Date
            , [Nationality] Char(3)
            , [SoldToAddr1] Varchar(40)
            , [SoldToAddr2] Varchar(40)
            , [SoldToAddr3] Varchar(40)
            , [SoldToAddr3Loc] Varchar(40)
            , [SoldToAddr4] Varchar(40)
            , [SoldToAddr5] Varchar(40)
            , [SoldPostalCode] Varchar(10)
            );
        Create Table [#SorDetail]
            (
              [DatabaseName] sysname
            , [SalesOrder] Varchar(20)
            , [SalesOrderLine] Int
            , [LineType] Char(1)
            , [MStockCode] Varchar(30)
            , [MStockDes] Varchar(50)
            , [MWarehouse] Varchar(10)
            , [MBin] Varchar(20)
            , [MOrderQty] Numeric(20 , 6)
            , [MShipQty] Numeric(20 , 6)
            , [MBackOrderQty] Numeric(20 , 6)
            , [MUnitCost] Numeric(20 , 6)
            , [MDecimals] Int
            , [MOrderUom] Varchar(10)
            , [MStockQtyToShp] Numeric(20 , 6)
            , [MStockingUom] Varchar(10)
            , [MPrice] Numeric(20 , 6)
            , [MPriceUom] Varchar(10)
            , [MProductClass] Varchar(20)
            , [MTaxCode] Char(3)
            , [MLineShipDate] Date
            , [MQtyDispatched] Numeric(20 , 6)
            , [QtyReserved] Numeric(20 , 6)
            , [NComment] Varchar(100)
            );
        Create Table [#SorMaster]
            (
              [DatabaseName] sysname
            , [SalesOrder] Varchar(20)
            , [OrderStatus] Char(1)
            , [CustomerPoNumber] Varchar(30)
            , [OrderDate] Date
            , [EntrySystemDate] Date
            , [ReqShipDate] Date
            , [ShippingInstrs] Varchar(50)
            , [ExchangeRate] Float
            , [MulDiv] Char(1)
            , [Currency] Char(3)
            , [ShipAddress1] Varchar(40)
            , [ShipAddress2] Varchar(40)
            , [ShipAddress3] Varchar(40)
            , [ShipAddress3Loc] Varchar(40)
            , [ShipAddress4] Varchar(40)
            , [ShipAddress5] Varchar(40)
            , [ShipPostalCode] Varchar(10)
            , [Customer] Varchar(15)
            , [CancelledFlag] Char(1)
            );

--create script to pull data from each db into the tables
        Declare @SQLSorCusts Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#ArCustomer]
						( [DatabaseName]
						, [Customer]
						, [Name]
						, [ShortName]
						, [Area]
						, [Currency]
						, [DateCustAdded]
						, [Nationality]
						, [SoldToAddr1]
						, [SoldToAddr2]
						, [SoldToAddr3]
						, [SoldToAddr3Loc]
						, [SoldToAddr4]
						, [SoldToAddr5]
						, [SoldPostalCode]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AC].[Customer]
					 , [AC].[Name]
					 , [AC].[ShortName]
					 , [AC].[Area]
					 , [AC].[Currency]
					 , [AC].[DateCustAdded]
					 , [AC].[Nationality]
					 , [AC].[SoldToAddr1]
					 , [AC].[SoldToAddr2]
					 , [AC].[SoldToAddr3]
					 , [AC].[SoldToAddr3Loc]
					 , [AC].[SoldToAddr4]
					 , [AC].[SoldToAddr5]
					 , [AC].[SoldPostalCode] FROM [ArCustomer] [AC]

				Insert [#SorDetail]
						( [DatabaseName]
						, [SalesOrder]
						, [SalesOrderLine]
						, [LineType]
						, [MStockCode]
						, [MStockDes]
						, [MWarehouse]
						, [MBin]
						, [MOrderQty]
						, [MShipQty]
						, [MBackOrderQty]
						, [MUnitCost]
						, [MDecimals]
						, [MOrderUom]
						, [MStockQtyToShp]
						, [MStockingUom]
						, [MPrice]
						, [MPriceUom]
						, [MProductClass]
						, [MTaxCode]
						, [MLineShipDate]
						, [MQtyDispatched]
						, [QtyReserved]
						, [NComment]
						)
				SELECT [DatabaseName]=@DBCode
					 , [SD].[SalesOrder]
					 , [SD].[SalesOrderLine]
					 , [SD].[LineType]
					 , [SD].[MStockCode]
					 , [SD].[MStockDes]
					 , [SD].[MWarehouse]
					 , [SD].[MBin]
					 , [SD].[MOrderQty]
					 , [SD].[MShipQty]
					 , [SD].[MBackOrderQty]
					 , [SD].[MUnitCost]
					 , [SD].[MDecimals]
					 , [SD].[MOrderUom]
					 , [SD].[MStockQtyToShp]
					 , [SD].[MStockingUom]
					 , [SD].[MPrice]
					 , [SD].[MPriceUom]
					 , [SD].[MProductClass]
					 , [SD].[MTaxCode]
					 , [SD].[MLineShipDate]
					 , [SD].[MQtyDispatched]
					 , [SD].[QtyReserved]
					 , [SD].[NComment] FROM [SorDetail] [SD]

				Insert [#SorMaster]
						( [DatabaseName]
						, [SalesOrder]
						, [OrderStatus]
						, [CustomerPoNumber]
						, [OrderDate]
						, [EntrySystemDate]
						, [ReqShipDate]
						, [ShippingInstrs]
						, [ExchangeRate]
						, [MulDiv]
						, [Currency]
						, [ShipAddress1]
						, [ShipAddress2]
						, [ShipAddress3]
						, [ShipAddress3Loc]
						, [ShipAddress4]
						, [ShipAddress5]
						, [ShipPostalCode]
						, [Customer]
						, [CancelledFlag]
						)
				SELECT [DatabaseName]=@DBCode
					 , [SM].[SalesOrder]
					 , [SM].[OrderStatus]
					 , [SM].[CustomerPoNumber]
					 , [SM].[OrderDate]
					 , [SM].[EntrySystemDate]
					 , [SM].[ReqShipDate]
					 , [SM].[ShippingInstrs]
					 , [SM].[ExchangeRate]
					 , [SM].[MulDiv]
					 , [SM].[Currency]
					 , [SM].[ShipAddress1]
					 , [SM].[ShipAddress2]
					 , [SM].[ShipAddress3]
					 , [SM].[ShipAddress3Loc]
					 , [SM].[ShipAddress4]
					 , [SM].[ShipAddress5]
					 , [SM].[ShipPostalCode]
					 , [SM].[Customer]
					 , [SM].[CancelledFlag] FROM [SorMaster] [SM]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLSorCusts ,
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [SalesOrder] Varchar(20)
            , [OrderStatus] Varchar(150)
            , [CustomerPoNumber] Varchar(30)
            , [OrderDate] Date
            , [EntrySystemDate] Date
            , [ReqShipDate] Date
            , [ShippingInstrs] Varchar(50)
            , [ExchangeRate] Float
            , [MulDiv] Char(1)
            , [Currency] Char(3)
            , [ShipAddress1] Varchar(40)
            , [ShipAddress2] Varchar(40)
            , [ShipAddress3] Varchar(40)
            , [ShipAddress3Loc] Varchar(40)
            , [ShipAddress4] Varchar(40)
            , [ShipAddress5] Varchar(40)
            , [ShipPostalCode] Varchar(10)
            , [SalesOrderLine] Int
            , [LineType] Int
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [Warehouse] Varchar(10)
            , [Bin] Varchar(20)
            , [OrderQty] Numeric(20 , 6)
            , [ShipQty] Numeric(20 , 6)
            , [BackOrderQty] Numeric(20 , 6)
            , [UnitCost] Numeric(20 , 6)
            , [Decimals] Int
            , [OrderUom] Char(3)
            , [StockQtyToShp] Numeric(20 , 6)
            , [StockingUom] Char(3)
            , [Price] Numeric(20 , 6)
            , [PriceUom] Char(3)
            , [ProductClass] Varchar(20)
            , [TaxCode] Char(3)
            , [LineShipDate] Date
            , [QtyDispatched] Numeric(20 , 6)
            , [QtyReserved] Numeric(20 , 6)
            , [LineComment] Varchar(100)
            , [Customer] Varchar(15)
            , [CustomerName] Varchar(50)
            , [CustomerShortName] Varchar(20)
            , [Area] Varchar(10)
            , [CustomerCurrency] Varchar(3)
            , [DateCustAdded] Date
            , [Nationality] Char(3)
            , [SoldToAddr1] Varchar(40)
            , [SoldToAddr2] Varchar(40)
            , [SoldToAddr3] Varchar(40)
            , [SoldToAddr3Loc] Varchar(40)
            , [SoldToAddr4] Varchar(40)
            , [SoldToAddr5] Varchar(40)
            , [SoldPostalCode] Varchar(10)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [SalesOrder]
                , [OrderStatus]
                , [CustomerPoNumber]
                , [OrderDate]
                , [EntrySystemDate]
                , [ReqShipDate]
                , [ShippingInstrs]
                , [ExchangeRate]
                , [MulDiv]
                , [Currency]
                , [ShipAddress1]
                , [ShipAddress2]
                , [ShipAddress3]
                , [ShipAddress3Loc]
                , [ShipAddress4]
                , [ShipAddress5]
                , [ShipPostalCode]
                , [SalesOrderLine]
                , [LineType]
                , [StockCode]
                , [StockDescription]
                , [Warehouse]
                , [Bin]
                , [OrderQty]
                , [ShipQty]
                , [BackOrderQty]
                , [UnitCost]
                , [Decimals]
                , [OrderUom]
                , [StockQtyToShp]
                , [StockingUom]
                , [Price]
                , [PriceUom]
                , [ProductClass]
                , [TaxCode]
                , [LineShipDate]
                , [QtyDispatched]
                , [QtyReserved]
                , [LineComment]
                , [Customer]
                , [CustomerName]
                , [CustomerShortName]
                , [Area]
                , [CustomerCurrency]
                , [DateCustAdded]
                , [Nationality]
                , [SoldToAddr1]
                , [SoldToAddr2]
                , [SoldToAddr3]
                , [SoldToAddr3Loc]
                , [SoldToAddr4]
                , [SoldToAddr5]
                , [SoldPostalCode]
                )
                Select  [SM].[DatabaseName]
                      , [SM].[SalesOrder]
                      , [OrderStatus] = [SOS].[OrderStatusDescription]
                      , [SM].[CustomerPoNumber]
                      , [SM].[OrderDate]
                      , [SM].[EntrySystemDate]
                      , [SM].[ReqShipDate]
                      , [SM].[ShippingInstrs]
                      , [SM].[ExchangeRate]
                      , [SM].[MulDiv]
                      , [SM].[Currency]
                      , [SM].[ShipAddress1]
                      , [SM].[ShipAddress2]
                      , [SM].[ShipAddress3]
                      , [SM].[ShipAddress3Loc]
                      , [SM].[ShipAddress4]
                      , [SM].[ShipAddress5]
                      , [SM].[ShipPostalCode]
                      , [SD].[SalesOrderLine]
                      , [SD].[LineType]
                      , [SD].[MStockCode]
                      , [SD].[MStockDes]
                      , [SD].[MWarehouse]
                      , [SD].[MBin]
                      , [SD].[MOrderQty]
                      , [SD].[MShipQty]
                      , [SD].[MBackOrderQty]
                      , [SD].[MUnitCost]
                      , [SD].[MDecimals]
                      , [SD].[MOrderUom]
                      , [SD].[MStockQtyToShp]
                      , [SD].[MStockingUom]
                      , [SD].[MPrice]
                      , [SD].[MPriceUom]
                      , [SD].[MProductClass]
                      , [SD].[MTaxCode]
                      , [SD].[MLineShipDate]
                      , [SD].[MQtyDispatched]
                      , [SD].[QtyReserved]
                      , [SD].[NComment]
                      , [AC].[Customer]
                      , [AC].[Name]
                      , [AC].[ShortName]
                      , [AC].[Area]
                      , [AC].[Currency]
                      , [AC].[DateCustAdded]
                      , [AC].[Nationality]
                      , [AC].[SoldToAddr1]
                      , [AC].[SoldToAddr2]
                      , [AC].[SoldToAddr3]
                      , [AC].[SoldToAddr3Loc]
                      , [AC].[SoldToAddr4]
                      , [AC].[SoldToAddr5]
                      , [AC].[SoldPostalCode]
                From    [#SorMaster] [SM]
                        Left Join [#SorDetail] [SD]
                            On [SD].[SalesOrder] = [SM].[SalesOrder]
                               And [SD].[DatabaseName] = [SM].[DatabaseName]
                        Left Join [#ArCustomer] [AC]
                            On [AC].[Customer] = [SM].[Customer]
                               And [AC].[DatabaseName] = [SM].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[SalesOrderStatus] [SOS]
                            On [SOS].[Company] = [SM].[DatabaseName]
                               And [SOS].[OrderStatusCode] = [SM].[OrderStatus]
                Where   Coalesce([SM].[CancelledFlag] , 'N') <> 'Y';


        Set NoCount Off;
--return results
        Select  [DatabaseName]
              , [SalesOrder]
              , [OrderStatus]
              , [CustomerPoNumber]
              , [OrderDate]
              , [EntrySystemDate]
              , [ReqShipDate]
              , [ShippingInstrs]
              , [ExchangeRate]
              , [MulDiv]
              , [Currency]
              , [ShipAddress1]
              , [ShipAddress2]
              , [ShipAddress3]
              , [ShipAddress3Loc]
              , [ShipAddress4]
              , [ShipAddress5]
              , [ShipPostalCode]
              , [SalesOrderLine]
              , [LineType]
              , [StockCode]
              , [StockDescription]
              , [Warehouse]
              , [Bin]
              , [OrderQty]
              , [ShipQty]
              , [BackOrderQty]
              , [UnitCost]
              , [Decimals]
              , [OrderUom]
              , [StockQtyToShp]
              , [StockingUom]
              , [Price]
              , [PriceUom]
              , [ProductClass]
              , [TaxCode]
              , [LineShipDate]
              , [QtyDispatched]
              , [QtyReserved]
              , [LineComment]
              , [Customer]
              , [CustomerName]
              , [CustomerShortName]
              , [Area]
              , [CustomerCurrency]
              , [DateCustAdded]
              , [Nationality]
              , [SoldToAddr1]
              , [SoldToAddr2]
              , [SoldToAddr3]
              , [SoldToAddr3Loc]
              , [SoldToAddr4]
              , [SoldToAddr5]
              , [SoldPostalCode]
        From    [#Results];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'list of all sales orders', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AllSalesOrders', NULL, NULL
GO
