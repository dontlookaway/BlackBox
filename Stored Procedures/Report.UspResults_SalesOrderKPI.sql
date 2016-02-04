
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_SalesOrderKPI] ( @Company Varchar(Max) )
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

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'MdnMasterRep,CusSorMaster+'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#MdnMasterRep]
            (
              [DatabaseName] Varchar(150)
            , [PlannedDeliverDate] DateTime
            , [ActualDeliveryDate] DateTime
            , [SalesOrder] Varchar(20)
            , [Invoice] Varchar(20)
            , [DispatchComments1] Varchar(100)
            , [DispatchComments2] Varchar(100)
            , [DispatchComments3] Varchar(100)
            , [DispatchComments4] Varchar(100)
            );
        Create Table [#SorMaster]
            (
              [DatabaseName] Varchar(150)
            , [SalesOrder] Varchar(20)
            , [OrderDate] DateTime
            , [EntrySystemDate] DateTime
            , [ReqShipDate] DateTime
            , [CustomerPoNumber] Varchar(30)
            , [CustomerName] Varchar(50)
            , [Customer] Varchar(15)
            , [NonMerchFlag] Char(1)
            , [OrderStatus] Char(1)
            , [Warehouse] Varchar(10)
            );
        Create Table [#CusSorMasterPlus]
            (
              [DatabaseName] Varchar(150)
            , [SalesOrder] Varchar(20)
            , [AcceptedDate] DateTime
            );
        Create Table [#SorDetail]
            (
              [DatabaseName] Varchar(150)
            , [SalesOrder] Varchar(20)
            , [SalesOrderLine] Int
            , [MStockCode] Varchar(30)
            , [MStockDes] Varchar(50)
            , [MOrderQty] Numeric(20 , 8)
            , [LineType] Char(1)
            );
        Create Table [#MdnDetail]
            (
              [DatabaseName] Varchar(150)
            , [DispatchNote] Varchar(20)
            , [DispatchStatus] Char(1)
            , [SalesOrder] Varchar(20)
            , [SalesOrderLine] Int
            , [LineType] Char(1)
            , [JnlYear] Int
            );
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)
            , [Lot] Varchar(50)
            , [Job] Varchar(20)
            , [SalesOrder] Varchar(20)
            , [SalesOrderLine] Int
            , [StockCode] Varchar(30)
            , [DispatchNote] Varchar(20)
            , [Invoice] Varchar(20)
            , [NewWarehouse] Varchar(10)
            , [JnlYear] Int
            , [TrnType] Char(1)
            );
	
--create script to pull data from each db into the tables
        Declare @SQLMdnMasterRep Varchar(Max) = '
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
				Insert [#MdnMasterRep]
						( [DatabaseName]
						, [PlannedDeliverDate]
						, [ActualDeliveryDate]
						, [SalesOrder]
						, [Invoice]
						, [DispatchComments1]
						, [DispatchComments2]
						, [DispatchComments3]
						, [DispatchComments4]
						)
				SELECT @DBCode
					 , [MMR].[PlannedDeliverDate]
					 , [MMR].[ActualDeliveryDate]
					 , [MMR].[SalesOrder]
					 , [MMR].[Invoice]
					 , [MMR].[DispatchComments1]
					 , [MMR].[DispatchComments2]
					 , [MMR].[DispatchComments3]
					 , [MMR].[DispatchComments4] 
				FROM [MdnMasterRep] As [MMR]
			End
	End';
        Declare @SQLSorMaster Varchar(Max) = '
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
			Insert  [#SorMaster]
					( [DatabaseName]
					, [SalesOrder]
					, [OrderDate]
					, [EntrySystemDate]
					, [ReqShipDate]
					, [CustomerPoNumber]
					, [CustomerName]
					, [Customer]
					, [NonMerchFlag]
					, [OrderStatus]
					, [Warehouse]
					)
            Select  @DBCode
                  , [SM].[SalesOrder]
                  , [SM].[OrderDate]
                  , [SM].[EntrySystemDate]
                  , [SM].[ReqShipDate]
                  , [SM].[CustomerPoNumber]
                  , [SM].[CustomerName]
                  , [SM].[Customer]
                  , [SM].[NonMerchFlag]
                  , [SM].[OrderStatus]
                  , [SM].[Warehouse]
            From    [SorMaster] As [SM];
			End
	End';
        Declare @SQLCusSorMasterPlus Varchar(Max) = '
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
			Insert  [#CusSorMasterPlus]
					( [DatabaseName]
					, [SalesOrder]
					, [AcceptedDate]
					)
            Select  @DBCode
                  , [CSMP].[SalesOrder]
                  , [CSMP].[AcceptedDate]
            From    [CusSorMaster+] As [CSMP];
			End
	End';
        Declare @SQLSorDetail Varchar(Max) = '
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
			Insert [#SorDetail]
	        ( [DatabaseName]
	        , [SalesOrder]
	        , [SalesOrderLine]
	        , [MStockCode]
	        , [MStockDes]
	        , [MOrderQty]
	        , [LineType]
	        )
			SELECT @DBCode
				 , [SD].[SalesOrder]
				 , [SD].[SalesOrderLine]
				 , [SD].[MStockCode]
				 , [SD].[MStockDes]
				 , [SD].[MOrderQty]
				 , [SD].[LineType] 
			FROM [SorDetail] As [SD]
			End
	End';
        Declare @SQLMdnDetail Varchar(Max) = '
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
			Insert  [#MdnDetail]
            ( [DatabaseName]
            , [DispatchNote]
            , [DispatchStatus]
            , [SalesOrder]
            , [SalesOrderLine]
            , [LineType]
            , [JnlYear]
	        )
            Select  @DBCode
                  , [MD].[DispatchNote]
                  , [MD].[DispatchStatus]
                  , [MD].[SalesOrder]
                  , [MD].[SalesOrderLine]
                  , [MD].[LineType]
                  , [MD].[JnlYear]
            From    [MdnDetail] As [MD];
			End
	End';
        Declare @SQLLotTransactions Varchar(Max) = '
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
			Insert  [#LotTransactions]
            ( [DatabaseName]
            , [Lot]
            , [Job]
            , [SalesOrder]
            , [SalesOrderLine]
            , [StockCode]
            , [DispatchNote]
            , [Invoice]
            , [NewWarehouse]
            , [JnlYear]
            , [TrnType]
	        )
            Select  @DBCode
                  , [LT].[Lot]
                  , [LT].[Job]
                  , [LT].[SalesOrder]
                  , [LT].[SalesOrderLine]
                  , [LT].[StockCode]
                  , [LT].[DispatchNote]
                  , [LT].[Invoice]
                  , [LT].[NewWarehouse]
                  , [LT].[JnlYear]
                  , [LT].[TrnType]
            From    [LotTransactions] As [LT];
			End
	End';


--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLMdnMasterRep;
        Exec [Process].[ExecForEachDB] @cmd = @SQLSorMaster;
        Exec [Process].[ExecForEachDB] @cmd = @SQLCusSorMasterPlus;
        Exec [Process].[ExecForEachDB] @cmd = @SQLSorDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLMdnDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLLotTransactions;

--define the results you want to return
        Create Table [#Results]
            (
              [CompanyName] Varchar(300)
            , [SalesOrder] Varchar(20)
            , [SalesOrderLine] Int
            , [OrderDate] Date
            , [EntrySystemDate] Date
            , [ReqShipDate] Date
            , [AcceptedDate] Date
            , [CustomerPoNumber] Varchar(30)
            , [CustomerName] Varchar(50)
            , [Customer] Varchar(15)
            , [Lot] Varchar(50)
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [OrderQty] Numeric(20 , 8)
            , [DispatchNote] Varchar(20)
            , [DispatchStatus] Char(1)
            , [PlannedDeliverDate] Date
            , [ActualDeliveryDate] Date
            , [DaysDiff] Int
            , [NonMerchFlag] Char(1)
            , [OrderStatus] Char(1)
            , [Job] Varchar(20)
            , [DispatchComments] Varchar(500)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [CompanyName]
                , [SalesOrder]
                , [SalesOrderLine]
                , [OrderDate]
                , [EntrySystemDate]
                , [ReqShipDate]
                , [AcceptedDate]
                , [CustomerPoNumber]
                , [CustomerName]
                , [Customer]
                , [Lot]
                , [StockCode]
                , [StockDescription]
                , [OrderQty]
                , [DispatchNote]
                , [DispatchStatus]
                , [PlannedDeliverDate]
                , [ActualDeliveryDate]
                , [DaysDiff]
                , [NonMerchFlag]
                , [OrderStatus]
                , [Job]
                , [DispatchComments]
                )
                Select  [CN].[CompanyName]
                      , [SM].[SalesOrder]
                      , [SD].[SalesOrderLine]
                      , [OrderDate] = Cast([SM].[OrderDate] As Date)
                      , [EntrySystemDate] = Cast([SM].[EntrySystemDate] As Date)
                      , [ReqShipDate] = Cast([SM].[ReqShipDate] As Date)
                      , [AcceptedDate] = Cast([CSM].[AcceptedDate] As Date)
                      , [SM].[CustomerPoNumber]
                      , [SM].[CustomerName]
                      , [SM].[Customer]
                      , [LT].[Lot]
                      , [SD].[MStockCode]
                      , [SD].[MStockDes]
                      , [SD].[MOrderQty]
                      , [MD].[DispatchNote]
                      , [MD].[DispatchStatus]
                      , [PlannedDeliverDate] = Cast([MMR].[PlannedDeliverDate] As Date)
                      , [ActualDeliveryDate] = Cast([MMR].[ActualDeliveryDate] As Date)
                      , [DaysDiff] = DateDiff(Day , [MMR].[PlannedDeliverDate] ,
                                              [MMR].[ActualDeliveryDate])
                      , [SM].[NonMerchFlag]
                      , [SM].[OrderStatus]
                      , [LT3].[Job]
                      , [DispatchComments] = Coalesce([MMR].[DispatchComments1] ,
                                                      '') + Coalesce(Char(13)
                                                              + Case
                                                              When [MMR].[DispatchComments2] = ''
                                                              Then Null
                                                              Else [MMR].[DispatchComments2]
                                                              End , '')
                        + Coalesce(Char(13)
                                   + Case When [MMR].[DispatchComments3] = ''
                                          Then Null
                                          Else [MMR].[DispatchComments3]
                                     End , '') + Coalesce(Char(13)
                                                          + Case
                                                              When [MMR].[DispatchComments4] = ''
                                                              Then Null
                                                              Else [MMR].[DispatchComments4]
                                                            End , '')
                From    [#SorMaster] As [SM]
                        Inner Join [#MdnMasterRep] As [MMR] On [MMR].[SalesOrder] = [SM].[SalesOrder]
                                                              And [MMR].[DatabaseName] = [SM].[DatabaseName]
                        Left Join [#CusSorMasterPlus] As [CSM] On [CSM].[SalesOrder] = [MMR].[SalesOrder]
                                                              And [CSM].[DatabaseName] = [MMR].[DatabaseName]
                        Inner Join [#SorDetail] As [SD] On [SD].[SalesOrder] = [SM].[SalesOrder]
                                                           And [SD].[LineType] <> 5
                                                           And [SD].[DatabaseName] = [SM].[DatabaseName]
                        Inner Join [#MdnDetail] As [MD] On [MD].[SalesOrder] = [SD].[SalesOrder]
                                                           And [MD].[SalesOrderLine] = [SD].[SalesOrderLine]
                                                           And [MD].[LineType] = [SD].[LineType]
                                                           And [MD].[DatabaseName] = [SD].[DatabaseName]
                        Left Join [#LotTransactions] As [LT] On [LT].[SalesOrder] = [SD].[SalesOrder]
                                                              And [LT].[SalesOrderLine] = [SD].[SalesOrderLine]
                                                              And [LT].[StockCode] = [SD].[MStockCode]
                                                              And [LT].[DispatchNote] = [MD].[DispatchNote]
                                                              And [LT].[Invoice] = [MMR].[Invoice]
                                                              And [LT].[NewWarehouse] = [SM].[Warehouse]
                                                              And [LT].[JnlYear] = [MD].[JnlYear]
                                                              And [LT].[DatabaseName] = [MD].[DatabaseName]
                        Left Join ( Select Distinct
                                            [LT2].[Lot]
                                          , [LT2].[StockCode]
                                          , [LT2].[Job]
                                          , [LT2].[DatabaseName]
                                    From    [#LotTransactions] As [LT2]
                                    Where   [LT2].[TrnType] = 'R'
                                            And Coalesce([LT2].[Job] , '') <> ''
                                  ) [LT3] On [LT].[Lot] = [LT3].[Lot]
                                             And [LT].[StockCode] = [LT3].[StockCode]
                                             And [LT3].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [Lookups].[CompanyNames] As [CN] On [SM].[DatabaseName] = [CN].[Company]
                Where   [SM].[OrderStatus] In ( '0' , '1' , '2' , '3' , '4' ,
                                                '8' , '9' )
                        And [LT].[Lot] Is Not Null
                Order By [SM].[SalesOrder] Asc;

--return results
        Select  [CompanyName]
              , [SalesOrder]
              , [SalesOrderLine]
              , [OrderDate]
              , [EntrySystemDate]
              , [ReqShipDate]
              , [AcceptedDate]
              , [CustomerPoNumber]
              , [CustomerName]
              , [Customer]
              , [Lot]
              , [StockCode]
              , [StockDescription]
              , [OrderQty]
              , [DispatchNote]
              , [DispatchStatus]
              , [PlannedDeliverDate]
              , [ActualDeliveryDate]
              , [DaysDiff]
              , [NonMerchFlag]
              , [OrderStatus]
              , [Job]
              , [DispatchComments]
        From    [#Results];

    End;

GO
