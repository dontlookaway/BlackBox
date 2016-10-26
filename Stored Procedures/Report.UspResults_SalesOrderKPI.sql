SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_SalesOrderKPI]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

Set NoCount on
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_SalesOrderKPI' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'MdnMasterRep,CusSorMaster+'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#MdnMasterRep]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [PlannedDeliverDate] DateTime			
            , [ActualDeliveryDate] DateTime			
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [Invoice] Varchar(20)					collate latin1_general_bin
            , [DispatchComments1] Varchar(100)		collate latin1_general_bin
            , [DispatchComments2] Varchar(100)		collate latin1_general_bin
            , [DispatchComments3] Varchar(100)		collate latin1_general_bin
            , [DispatchComments4] Varchar(100)		collate latin1_general_bin
            );
        Create Table [#SorMaster]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [OrderDate] DateTime					
            , [EntrySystemDate] DateTime			
            , [ReqShipDate] DateTime				
            , [CustomerPoNumber] Varchar(30)		collate latin1_general_bin
            , [CustomerName] Varchar(50)			collate latin1_general_bin
            , [Customer] Varchar(15)				collate latin1_general_bin
            , [NonMerchFlag] Char(1)				collate latin1_general_bin
            , [OrderStatus] Char(1)					collate latin1_general_bin
            , [Warehouse] Varchar(10)				collate latin1_general_bin
            );
        Create Table [#CusSorMasterPlus]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [AcceptedDate] DateTime
            );
        Create Table [#SorDetail]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [SalesOrderLine] Int					
            , [MStockCode] Varchar(30)				collate latin1_general_bin
            , [MStockDes] Varchar(50)				collate latin1_general_bin
            , [MOrderQty] Numeric(20 , 8)			
            , [LineType] Char(1)					collate latin1_general_bin
            );
        Create Table [#MdnDetail]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [DispatchNote] Varchar(20)			collate latin1_general_bin
            , [DispatchStatus] Char(1)				collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [SalesOrderLine] Int					
            , [LineType] Char(1)					collate latin1_general_bin
            , [JnlYear] Int
            );
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [Job] Varchar(20)						collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [SalesOrderLine] Int					
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [DispatchNote] Varchar(20)			collate latin1_general_bin
            , [Invoice] Varchar(20)					collate latin1_general_bin
            , [NewWarehouse] Varchar(10)			collate latin1_general_bin
            , [JnlYear] Int							
            , [TrnType] Char(1)						collate latin1_general_bin
            , [Reference] Varchar(30)				collate latin1_general_bin
            , [JobPurchOrder] Varchar(30)			collate latin1_general_bin
            );
	
--create script to pull data from each db into the tables
        Declare @SQLMdnMasterRep Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
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
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
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
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			 Declare @SQLSub Varchar(2000)= ''Insert  [#CusSorMasterPlus]
                        ( [DatabaseName]
                        , [SalesOrder]
                        , [AcceptedDate]
					    )
						Select  ''''''+@DBCode+''''''
                  , [CSMP].[SalesOrder]
                  , [CSMP].[AcceptedDate]
            From    dbo.[CusSorMaster+] As [CSMP];'';
			
                
                Exec (@SQLSub);
			End
	End';
        Declare @SQLSorDetail Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
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
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
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
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
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
			, [Reference]
			, [JobPurchOrder]
	        )
            Select  @DBCode
                  , [Lot] = case when [LT].[Lot]='''' then null 
								 else [LT].[Lot] end
                  , [LT].[Job]
                  , [LT].[SalesOrder]
                  , [LT].[SalesOrderLine]
                  , [LT].[StockCode]
                  , [LT].[DispatchNote]
                  , [LT].[Invoice]
                  , [LT].[NewWarehouse]
                  , [LT].[JnlYear]
                  , [LT].[TrnType]
				  , [Reference] = case when LT.[Reference]='''' then null 
									   else LT.[Reference] end
				  , [JobPurchOrder] = case when LT.[JobPurchOrder] ='''' then null
											else LT.[JobPurchOrder] end
            From    [LotTransactions] As [LT];
			End
	End';


--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQLCusSorMasterPlus

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
              [CompanyName] Varchar(300)			collate latin1_general_bin
            , [SalesOrder] Varchar(20)				collate latin1_general_bin
            , [SalesOrderLine] Int					
            , [OrderDate] Date						
            , [EntrySystemDate] Date				
            , [ReqShipDate] Date					
            , [AcceptedDate] Date					
            , [CustomerPoNumber] Varchar(30)		collate latin1_general_bin
            , [CustomerName] Varchar(50)			collate latin1_general_bin
            , [Customer] Varchar(15)				collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [StockDescription] Varchar(50)		collate latin1_general_bin
            , [OrderQty] Numeric(20 , 8)			
            , [DispatchNote] Varchar(20)			collate latin1_general_bin
            , [DispatchStatus] Char(1)				collate latin1_general_bin
            , [PlannedDeliverDate] Date				
            , [ActualDeliveryDate] Date				
            , [DaysDiff] Int						
            , [NonMerchFlag] Char(1)				collate latin1_general_bin
            , [OrderStatus] Char(1)					collate latin1_general_bin
            , [Job] Varchar(20)						collate latin1_general_bin
            , [DispatchComments] Varchar(500)		collate latin1_general_bin
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
                        Inner Join [#MdnMasterRep] As [MMR]
                            On [MMR].[SalesOrder] = [SM].[SalesOrder]
                               And [MMR].[DatabaseName] = [SM].[DatabaseName]
                        Left Join [#CusSorMasterPlus] As [CSM]
                            On [CSM].[SalesOrder] = [MMR].[SalesOrder]
                               And [CSM].[DatabaseName] = [MMR].[DatabaseName]
                        Inner Join [#SorDetail] As [SD]
                            On [SD].[SalesOrder] = [SM].[SalesOrder]
                               And [SD].[LineType] <> 5
                               And [SD].[DatabaseName] = [SM].[DatabaseName]
                        Inner Join [#MdnDetail] As [MD]
                            On [MD].[SalesOrder] = [SD].[SalesOrder]
                               And [MD].[SalesOrderLine] = [SD].[SalesOrderLine]
                               And [MD].[LineType] = [SD].[LineType]
                               And [MD].[DatabaseName] = [SD].[DatabaseName]
                        Left Join [#LotTransactions] As [LT]
                            On [LT].[SalesOrder] = [SD].[SalesOrder]
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
                                          , [Job] = Coalesce([LT2].[JobPurchOrder] ,
                                                             [LT2].[Job] ,
                                                             [LT2].[Reference])
                                          , [LT2].[DatabaseName]
                                    From    [#LotTransactions] As [LT2]
                                    Where   [LT2].[TrnType] = 'R'
                                            And Coalesce([LT2].[JobPurchOrder] ,
                                                         [LT2].[Job] ,
                                                         [LT2].[Reference] ,
                                                         '') <> ''
                                  ) [LT3]
                            On [LT].[Lot] = [LT3].[Lot]
                               And [LT].[StockCode] = [LT3].[StockCode]
                               And [LT3].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [Lookups].[CompanyNames] As [CN]
                            On [SM].[DatabaseName] = [CN].[Company]
                Where   [SM].[OrderStatus] In ( '0' , '1' , '2' , '3' , '4' ,
                                                '8' , '9' )
                        And [LT].[Lot] Is Not Null
                Order By [SM].[SalesOrder] Asc;

Set NoCount Off
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
              , [WorkingDaysBetweenAcceptedAndDeliveryDate] = Case
                                                              When [AcceptedDate] Is Null
                                                              Then Null
                                                              When [AcceptedDate] = [ActualDeliveryDate]
                                                              Then 0
                                                              Else [Process].[Udf_WorkingDays]([AcceptedDate] ,
                                                              [ActualDeliveryDate] ,
                                                              'UK') - 1
                                                              End
        From    [#Results];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'data for sales order KPI report', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_SalesOrderKPI', NULL, NULL
GO
