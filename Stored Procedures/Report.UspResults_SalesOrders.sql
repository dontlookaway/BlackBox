
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_SalesOrders]
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
List of all Sales orders with details
--exec [Report].[UspResults_SalesOrders]  10
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
            @StoredProcName = 'UspResults_SalesOrders' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'SorMaster,SorDetail,SalSalesperson'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#SorMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [SalesOrder] Varchar(35) Collate Latin1_General_BIN
            , [CancelledFlag] Char(1)
            , [Customer] Varchar(50) Collate Latin1_General_BIN
            , [CustomerName] Varchar(255) Collate Latin1_General_BIN
            , [OrderStatus] Varchar(5) Collate Latin1_General_BIN
            , [Salesperson] Varchar(20) Collate Latin1_General_BIN
            , [Branch] Varchar(10) Collate Latin1_General_BIN
            , [CustomerPoNumber] Varchar(30) Collate Latin1_General_BIN
            , [OrderDate] DateTime2
            , [EntrySystemDate] DateTime2
            , [ReqShipDate] DateTime2
            , [Currency] Varchar(5) Collate Latin1_General_BIN
            );
        Create Table [#SorDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [SalesOrder] Varchar(35) Collate Latin1_General_BIN
            , [SalesOrderLine] Int
            , [LineType] Varchar(10) Collate Latin1_General_BIN
            , [MStockCode] Varchar(35) Collate Latin1_General_BIN
            , [MStockDes] Varchar(255) Collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 7)
            , [MOrderUom] Varchar(5) Collate Latin1_General_BIN
            , [MPrice] Numeric(20 , 2)
            , [NComment] Varchar(100) Collate Latin1_General_BIN
            , [NMscProductCls] Varchar(20) Collate Latin1_General_BIN
            , [NMscChargeValue] Numeric(20 , 3)
            );
        Create Table [#SalSalesperson]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Name] Varchar(50) Collate Latin1_General_BIN
            , [Branch] Varchar(10) Collate Latin1_General_BIN
            , [Salesperson] Varchar(20) Collate Latin1_General_BIN
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
				Insert  [#SorMaster]
                ( [DatabaseName]
                , [SalesOrder]
                , [CancelledFlag]
                , [Customer]
                , [CustomerName]
                , [OrderStatus]
                , [Salesperson]
                , [Branch]
                , [CustomerPoNumber]
                , [OrderDate]
                , [EntrySystemDate]
                , [ReqShipDate]
                , [Currency]
                )
                Select
                    [DatabaseName] = @DBCode
                  , [sm].[SalesOrder]
                  , [sm].[CancelledFlag]
                  , [sm].[Customer]
                  , [sm].[CustomerName]
                  , [sm].[OrderStatus]
                  , [sm].[Salesperson]
                  , [sm].[Branch]
                  , [sm].[CustomerPoNumber]
                  , [sm].[OrderDate]
                  , [sm].[EntrySystemDate]
                  , [sm].[ReqShipDate]
                  , [sm].[Currency]
                From
                    [SorMaster] As [sm];
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
				Insert  [#SorDetail]
                ( [DatabaseName]
                , [SalesOrder]
                , [SalesOrderLine]
                , [LineType]
                , [MStockCode]
                , [MStockDes]
                , [MOrderQty]
                , [MOrderUom]
                , [MPrice]
                , [NComment]
                , [NMscProductCls]
                , [NMscChargeValue]
                )
                Select
                    [DatabaseName] = @DBCode
                  , [sd].[SalesOrder]
                  , [sd].[SalesOrderLine]
                  , [sd].[LineType]
                  , [sd].[MStockCode]
                  , [sd].[MStockDes]
                  , [sd].[MOrderQty]
                  , [sd].[MOrderUom]
                  , [sd].[MPrice]
                  , [sd].[NComment]
                  , [sd].[NMscProductCls]
                  , [sd].[NMscChargeValue]
                From
                    [SorDetail] As [sd];
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
				Insert  [#SalSalesperson]
                ( [DatabaseName]
                , [Name]
                , [Branch]
                , [Salesperson]
                )
                Select
                    [DatabaseName] = @DBCode
                  , [ss].[Name]
                  , [ss].[Branch]
                  , [ss].[Salesperson]
                From
                    [SalSalesperson] As [ss];
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [SalesOrder] Varchar(35) Collate Latin1_General_BIN
            , [OrderStatusDescription] Varchar(255) Collate Latin1_General_BIN
            , [CancelledFlag] Char(1)
            , [Customer] Varchar(35) Collate Latin1_General_BIN
            , [CustomerName] Varchar(255) Collate Latin1_General_BIN
            , [Name] Varchar(150) Collate Latin1_General_BIN
            , [CustomerPoNumber] Varchar(150) Collate Latin1_General_BIN
            , [OrderDate] DateTime2
            , [EntrySystemDate] DateTime2
            , [ReqShipDate] DateTime2
            , [Currency] Varchar(5) Collate Latin1_General_BIN
            , [SalesOrderLine] Int
            , [LineTypeDescription] Varchar(150) Collate Latin1_General_BIN
            , [MStockCode] Varchar(35) Collate Latin1_General_BIN
            , [MStockDes] Varchar(150) Collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 7)
            , [MOrderUom] Varchar(10) Collate Latin1_General_BIN
            , [MPrice] Numeric(20 , 3)
            , [NComment] Varchar(100) Collate Latin1_General_BIN
            , [NMscProductCls] Varchar(20) Collate Latin1_General_BIN
            , [NMscChargeValue] Numeric(20 , 3)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [SalesOrder]
                , [OrderStatusDescription]
                , [CancelledFlag]
                , [Customer]
                , [CustomerName]
                , [Name]
                , [CustomerPoNumber]
                , [OrderDate]
                , [EntrySystemDate]
                , [ReqShipDate]
                , [Currency]
                , [SalesOrderLine]
                , [LineTypeDescription]
                , [MStockCode]
                , [MStockDes]
                , [MOrderQty]
                , [MOrderUom]
                , [MPrice]
                , [NComment]
                , [NMscProductCls]
                , [NMscChargeValue]
                )
                Select  [sm].[DatabaseName]
                      , [sm].[SalesOrder]
                      , [sos].[OrderStatusDescription]
                      , [sm].[CancelledFlag]
                      , [sm].[Customer]
                      , [sm].[CustomerName]
                      , [ss].[Name]
                      , [sm].[CustomerPoNumber]
                      , [sm].[OrderDate]
                      , [sm].[EntrySystemDate]
                      , [sm].[ReqShipDate]
                      , [sm].[Currency]
                      , [sd].[SalesOrderLine]
                      , [solt].[LineTypeDescription]
                      , [sd].[MStockCode]
                      , [sd].[MStockDes]
                      , [sd].[MOrderQty]
                      , [sd].[MOrderUom]
                      , [sd].[MPrice]
                      , [sd].[NComment]
                      , [sd].[NMscProductCls]
                      , [sd].[NMscChargeValue]
                From    [#SorMaster] As [sm]
                        Left Join [#SorDetail] As [sd] On [sd].[SalesOrder] = [sm].[SalesOrder]
                                                          And [sd].[DatabaseName] = [sm].[DatabaseName]
                        Left Join [#SalSalesperson] As [ss] On [ss].[Branch] = [sm].[Branch]
                                                              And [ss].[Salesperson] = [sm].[Salesperson]
                                                              And [ss].[DatabaseName] = [sd].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[SalesOrderStatus] As [sos] On [sm].[OrderStatus] = [sos].[OrderStatusCode]
                                                              And [sos].[Company] = [sm].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[SalesOrderLineType] As [solt] On [sd].[LineType] = [solt].[LineTypeCode]
                                                              And [solt].[Company] = [sm].[DatabaseName];

--return results
        Select  [Company] = [DatabaseName]
              , [SalesOrder]
              , [OrderStatus] = [OrderStatusDescription]
              , [CancelledFlag] = Case When [CancelledFlag] = '' Then 'N'
                                       Else [CancelledFlag]
                                  End
              , [Customer]
              , [CustomerName]
              , [SalesPerons] = [Name]
              , [CustomerPoNumber]
              , [OrderDate] = Cast([OrderDate] As Date)
              , [EntrySystemDate] = Cast([EntrySystemDate] As Date)
              , [ReqShipDate] = Cast([ReqShipDate] As Date)
              , [Currency]
              , [Line] = [SalesOrderLine]
              , [LineType] = [LineTypeDescription]
              , [StockCode] = [MStockCode]
              , [StockDescription] = [MStockDes]
              , [OrderQty] = [MOrderQty]
              , [OrderUom] = [MOrderUom]
              , [Price] = [MPrice]
              , [Comment] = [NComment]
              , [ProductClass] = [NMscProductCls]
              , [ChargeValue] = [NMscChargeValue]
        From    [#Results];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'list of sales orders ', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_SalesOrders', NULL, NULL
GO
