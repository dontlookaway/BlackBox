SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_SalesOrders] ( @Company VARCHAR(Max) )
As --exec [Report].[UspResults_SalesOrders]  10
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			List of all Sales orders with details																					///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			29/9/2015	Chris Johnson			Initial version created																///
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
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'SorMaster,SorDetail,SalSalesperson'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #SorMaster
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [SalesOrder] VARCHAR(35) Collate Latin1_General_BIN
            , [CancelledFlag] CHAR(1)
            , [Customer] VARCHAR(50) Collate Latin1_General_BIN
            , [CustomerName] VARCHAR(255) Collate Latin1_General_BIN
            , [OrderStatus] VARCHAR(5) Collate Latin1_General_BIN
            , [Salesperson] VARCHAR(20) Collate Latin1_General_BIN
            , [Branch] VARCHAR(10) Collate Latin1_General_BIN
            , [CustomerPoNumber] VARCHAR(30) Collate Latin1_General_BIN
            , [OrderDate] DATETIME2
            , [EntrySystemDate] DATETIME2
            , [ReqShipDate] DATETIME2
            , [Currency] VARCHAR(5) Collate Latin1_General_BIN
            );

        Create Table #SorDetail
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [SalesOrder] VARCHAR(35) Collate Latin1_General_BIN
            , [SalesOrderLine] INT
            , [LineType] VARCHAR(10) Collate Latin1_General_BIN
            , [MStockCode] VARCHAR(35) Collate Latin1_General_BIN
            , [MStockDes] VARCHAR(255) Collate Latin1_General_BIN
            , [MOrderQty] NUMERIC(20, 7)
            , [MOrderUom] VARCHAR(5) Collate Latin1_General_BIN
            , [MPrice] NUMERIC(20, 2)
            , [NComment] VARCHAR(100) Collate Latin1_General_BIN
            , [NMscProductCls] VARCHAR(20) Collate Latin1_General_BIN
            , [NMscChargeValue] NUMERIC(20, 3)
            );

        Create Table #SalSalesperson
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [Name] VARCHAR(50) Collate Latin1_General_BIN
            , [Branch] VARCHAR(10) Collate Latin1_General_BIN
            , [Salesperson] VARCHAR(20) Collate Latin1_General_BIN
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
        Exec sp_MSforeachdb
            @SQL1;
        Exec sp_MSforeachdb
            @SQL2;
        Exec sp_MSforeachdb
            @SQL3;

--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [SalesOrder] VARCHAR(35) Collate Latin1_General_BIN
			,  [OrderStatusDescription] VARCHAR(255) Collate Latin1_General_BIN
			,  [CancelledFlag] CHAR(1)
			,  [Customer] VARCHAR(35) Collate Latin1_General_BIN
			,  [CustomerName] VARCHAR(255) Collate Latin1_General_BIN
			,  [Name] VARCHAR(150) Collate Latin1_General_BIN
			,  [CustomerPoNumber] VARCHAR(150)  Collate Latin1_General_BIN
			,  [OrderDate] DATETIME2
			,  [EntrySystemDate] DATETIME2
			,  [ReqShipDate] DATETIME2
			,  [Currency] VARCHAR(5) Collate Latin1_General_BIN
			,  [SalesOrderLine] int
			,  [LineTypeDescription] VARCHAR(150) Collate Latin1_General_BIN
			,  [MStockCode] VARCHAR(35) Collate Latin1_General_BIN
			,  [MStockDes] VARCHAR(150) Collate Latin1_General_BIN
			,  [MOrderQty] NUMERIC(20,7)
			,  [MOrderUom] VARCHAR(10) Collate Latin1_General_BIN
			,  [MPrice] NUMERIC(20,3)
			,  [NComment] VARCHAR(100) Collate Latin1_General_BIN
			,  [NMscProductCls] VARCHAR(20) Collate Latin1_General_BIN
			,  [NMscChargeValue] NUMERIC(20,3)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

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
                Select [sm].[DatabaseName]
                  , [sm].	[SalesOrder]
                  , [sos].	[OrderStatusDescription]
                  , [sm].	[CancelledFlag]
                  , [sm].	[Customer]
                  , [sm].	[CustomerName]
                  , [ss].	[Name]
                  , [sm].	[CustomerPoNumber]
                  , [sm].	[OrderDate]
                  , [sm].	[EntrySystemDate]
                  , [sm].	[ReqShipDate]
                  , [sm].	[Currency]
                  , [sd].	[SalesOrderLine]
                  , [solt].	[LineTypeDescription]
                  , [sd].	[MStockCode]
                  , [sd].	[MStockDes]
                  , [sd].	[MOrderQty]
                  , [sd].	[MOrderUom]
                  , [sd].	[MPrice]
                  , [sd].	[NComment]
                  , [sd].	[NMscProductCls]
                  , [sd].	[NMscChargeValue]
                From
                    [#SorMaster] As [sm]
                Left Join [#SorDetail] As [sd]
                    On [sd].[SalesOrder] = [sm].[SalesOrder]
					And [sd].[DatabaseName] = [sm].[DatabaseName]
                Left Join [#SalSalesperson] As [ss]
                    On [ss].[Branch] = [sm].[Branch]
                       And [ss].[Salesperson] = [sm].[Salesperson]
					   And [ss].[DatabaseName] = [sd].[DatabaseName]
                Left Join [BlackBox].[Lookups].[SalesOrderStatus] As [sos]
                    On sm.[OrderStatus] = [sos].[OrderStatusCode]
                       And [sos].[Company] = sm.[DatabaseName]
                Left Join [BlackBox].[Lookups].[SalesOrderLineType] As [solt]
                    On sd.[LineType] = [solt].[LineTypeCode]
                       And [solt].[Company] = sm.[DatabaseName];

--return results
        Select
            Company				= [DatabaseName]
          , [SalesOrder]
          , [OrderStatus]		= [OrderStatusDescription]
          , [CancelledFlag]		= Case When [CancelledFlag]='' Then 'N' Else [CancelledFlag] End
          , [Customer]
          , [CustomerName]
          , [SalesPerons]		= [Name]
          , [CustomerPoNumber]
          , [OrderDate]			= CAST([OrderDate] As DATE)
          , [EntrySystemDate]	= CAST([EntrySystemDate] As DATE)
          , [ReqShipDate]		= CAST([ReqShipDate] As DATE)
          , [Currency]
          , [Line]				= [SalesOrderLine]
          , [LineType]			= [LineTypeDescription]
          , [StockCode]			= [MStockCode]
          , [StockDescription]	= [MStockDes]
          , [OrderQty]			= [MOrderQty]
          , [OrderUom]			= [MOrderUom]
          , [Price]				= [MPrice]
          , [Comment]			= [NComment]
          , [ProductClass]		= [NMscProductCls]
          , [ChargeValue]		= [NMscChargeValue]
        From
            #Results;

    End;

GO
