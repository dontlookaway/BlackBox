SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockDispatches]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016
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
            @StoredProcName = 'UspResults_StockDispatches' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#LotTransactionsDispatches]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Lot] Varchar(50)					collate latin1_general_bin
            , [StockCode] Varchar(30)			collate latin1_general_bin
            , [Customer] Varchar(15)			collate latin1_general_bin
            , [SalesOrder] Varchar(20)			collate latin1_general_bin
            , [SalesOrderLine] Int				
            , [TrnQuantity] Numeric(20 , 8)		
            , [TrnValue] Numeric(20 , 2)		
            , [TrnType] Char(1)					collate latin1_general_bin
            , [TrnDate] Date					
            , [OldExpiryDate] Date				
            , [NewExpiryDate] Date				
            , [Job] Varchar(20)					collate latin1_general_bin
            , [Bin] Varchar(20)					collate latin1_general_bin
            , [UnitCost] Numeric(20 , 2)		
            , [Narration] Varchar(100)			collate latin1_general_bin
            , [Reference] Varchar(30)			collate latin1_general_bin
            , [Warehouse] Varchar(10)			collate latin1_general_bin
            , [JobPurchOrder] Varchar(20)		collate latin1_general_bin
            );									
        Create Table [#InvMasterDispatches]		
            (									
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [StockCode] Varchar(30)			collate latin1_general_bin
            , [Description] Varchar(50)			collate latin1_general_bin
            , [StockUom] Varchar(10)			collate latin1_general_bin
            );									
        Create Table [#ArCustomerDispatches]	
            (									
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Customer] Varchar(15)			collate latin1_general_bin
            , [Name] Varchar(50)				collate latin1_general_bin
            );									
        Create Table [#WipMasterDispatches]		
            (									
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Job] Varchar(20)					collate latin1_general_bin
            , [JobDescription] Varchar(50)		collate latin1_general_bin
            , [JobClassification] Varchar(10)	collate latin1_general_bin
            , [SellingPrice] Numeric(20 , 2)	
            );									
        Create Table [#SorMasterDispatches]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [SalesOrder] Varchar(20)			collate latin1_general_bin
            , [CustomerPoNumber] Varchar(30)	collate latin1_general_bin
            );									
        Create Table [#SorDetailDispatches]		
            (									
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [SalesOrder] Varchar(20)			collate latin1_general_bin
            , [SalesOrderLine] Int
            , [MPrice] Numeric(20 , 2)
            );

--create script to pull data from each db into the tables
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
				Insert [#LotTransactionsDispatches]
						( [DatabaseName]
						, [Lot]
						, [StockCode]
						, [Customer]
						, [SalesOrder]
						, [SalesOrderLine]
						, [TrnQuantity]
						, [TrnValue]
						, [TrnType]
						, [TrnDate]
						, [OldExpiryDate]
						, [NewExpiryDate]
						, [Job]
						, [Bin]
						, [UnitCost]
						, [Narration]
						, [Reference]
						, [Warehouse]
						, [JobPurchOrder]
						)
				SELECT [DatabaseName]=@DBCode
					 , [LT].[Lot]
					 , [LT].[StockCode]
					 , [LT].[Customer]
					 , [LT].[SalesOrder]
					 , [LT].[SalesOrderLine]
					 , [LT].[TrnQuantity]
					 , [LT].[TrnValue]
					 , [LT].[TrnType]
					 , [LT].[TrnDate]
					 , [LT].[OldExpiryDate]
					 , [LT].[NewExpiryDate]
					 , [LT].[Job]
					 , [LT].[Bin]
					 , [LT].[UnitCost]
					 , [LT].[Narration]
					 , [LT].[Reference]
					 , [LT].[Warehouse]
					 , [LT].[JobPurchOrder] FROM [LotTransactions] As [LT]
			End
	End';
        Declare @SQLInvMaster Varchar(Max) = '
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
				Insert [#InvMasterDispatches]
						( [DatabaseName]
						, [StockCode]
						, [Description]
						, [StockUom]
						)
				SELECT [DatabaseName]=@DBCode
					 , [IM].[StockCode]
					 , [IM].[Description]
					 , [IM].[StockUom] FROM [InvMaster] As [IM]
			End
	End';
        Declare @SQLArCustomer Varchar(Max) = '
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
			Insert [#ArCustomerDispatches]
			        ( [DatabaseName]
			        , [Customer]
			        , [Name]
			        )
			SELECT [DatabaseName]=@DBCode
                 , [AC].[Customer]
                 , [AC].[Name] FROM [ArCustomer] As [AC]
			End
	End';
        Declare @SQLWipMaster Varchar(Max) = '
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
			Insert [#WipMasterDispatches]
					( [DatabaseName]
					, [Job]
					, [JobDescription]
					, [JobClassification]
					, [SellingPrice]
					)
			SELECT [DatabaseName]=@DBCode
				 , [WM].[Job]
				 , [WM].[JobDescription]
				 , [WM].[JobClassification]
				 , [WM].[SellingPrice] FROM [WipMaster] As [WM]
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
			Insert [#SorMasterDispatches]
			        ( [DatabaseName]
			        , [SalesOrder]
			        , [CustomerPoNumber]
			        )
			SELECT [DatabaseName]=@DBCode
                 , [SM].[SalesOrder]
                 , [SM].[CustomerPoNumber] FROM [SorMaster] As [SM]
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
			Insert [#SorDetailDispatches]
                ( [DatabaseName]
                , [SalesOrder]
                , [SalesOrderLine]
                , [MPrice]
                )
			Select  [DatabaseName]=@DBCode
				  , [SD].[SalesOrder]
				  , [SD].[SalesOrderLine]
				  , [SD].[MPrice]
			From    [SorDetail] As [SD]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Begin
            Exec [Process].[ExecForEachDB] @cmd = @SQLLotTransactions;
            Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
            Exec [Process].[ExecForEachDB] @cmd = @SQLArCustomer;
            Exec [Process].[ExecForEachDB] @cmd = @SQLWipMaster;
            Exec [Process].[ExecForEachDB] @cmd = @SQLSorMaster;
            Exec [Process].[ExecForEachDB] @cmd = @SQLSorDetail;
        End;

--define the results you want to return
        Create Table [#ResultsDispatches]
            (
              [Company] Varchar(150)					collate latin1_general_bin
            , [CompanyName] Varchar(250)				collate latin1_general_bin
            , [OriginalBatch] Varchar(20)				collate latin1_general_bin
            , [Lot] Varchar(50)							collate latin1_general_bin
            , [StockCode] Varchar(30)					collate latin1_general_bin
            , [Description] Varchar(50)					collate latin1_general_bin
            , [Customer] Varchar(15)					collate latin1_general_bin
            , [CustomerName] Varchar(50)				collate latin1_general_bin
            , [JobDescription] Varchar(50)				collate latin1_general_bin
            , [JobClassification] Varchar(10)			collate latin1_general_bin
            , [SellingPrice] Numeric(20 , 2)			
            , [SalesOrder] Varchar(20)					collate latin1_general_bin
            , [SalesOrderLine] Int						
            , [TrnQuantity] Numeric(20 , 8)				
            , [TrnValue] Numeric(20 , 2)				
            , [TrnType] Char(1)							collate latin1_general_bin
            , [AmountModifier] Float					
            , [TrnDate] Date							
            , [OldExpiryDate] Date						
            , [NewExpiryDate] Date						
            , [Job] Varchar(20)							collate latin1_general_bin
            , [Bin] Varchar(20)							collate latin1_general_bin
            , [CustomerPoNumber] Varchar(30)			collate latin1_general_bin
            , [UnitCost] Numeric(20 , 2)				
            , [WarehouseDescription] Varchar(200)		collate latin1_general_bin
            , [StockUom] Varchar(10)					collate latin1_general_bin
            , [Narration] Varchar(100)					collate latin1_general_bin
            , [Reference] Varchar(30)					collate latin1_general_bin
            );

--Placeholder to create indexes as required
        Create Table [#OriginalBatch]
            (
              [Lot] Varchar(50)							collate latin1_general_bin
            , [MasterJob] Varchar(20)					collate latin1_general_bin
            , [DatabaseName] Varchar(120)				collate latin1_general_bin
            );
        Insert  [#OriginalBatch]
                ( [Lot]
                , [MasterJob]
                , [DatabaseName]
                )
                Select Distinct
                        [LT].[Lot]
                      , [MasterJob] = [LT].[JobPurchOrder]
                      , [LT].[DatabaseName]
                From    [#LotTransactionsDispatches] As [LT]
                Where   [LT].[TrnType] = 'R'
                        And [LT].[JobPurchOrder] <> '';
--script to combine base data and insert into results table
        Insert  [#ResultsDispatches]
                ( [Company]
                , [CompanyName]
                , [OriginalBatch]
                , [Lot]
                , [StockCode]
                , [Description]
                , [Customer]
                , [CustomerName]
                , [JobDescription]
                , [JobClassification]
                , [SellingPrice]
                , [SalesOrder]
                , [SalesOrderLine]
                , [TrnQuantity]
                , [TrnValue]
                , [TrnType]
                , [AmountModifier]
                , [TrnDate]
                , [OldExpiryDate]
                , [NewExpiryDate]
                , [Job]
                , [Bin]
                , [CustomerPoNumber]
                , [UnitCost]
                , [WarehouseDescription]
                , [StockUom]
                , [Narration]
                , [Reference]
                )
                Select  [Company] = [CN].[Company]
                      , [CompanyName] = [CN].[CompanyName]
                      , [OriginalBatch] = [OB].[MasterJob]
                      , [LT].[Lot]
                      , [LT].[StockCode]
                      , [IM].[Description]
                      , [LT].[Customer]
                      , [AC].[Name]
                      , [WM].[JobDescription]
                      , [WM].[JobClassification]
                      , [SellingPrice] = [SD].[MPrice]
                      , [LT].[SalesOrder]
                      , [LT].[SalesOrderLine]
                      , [LT].[TrnQuantity]
                      , [LT].[TrnValue]
                      , [LT].[TrnType]
                      , [TTAM].[AmountModifier]
                      , [TrnDate] = Convert(Date , [LT].[TrnDate])
                      , [LT].[OldExpiryDate]
                      , [LT].[NewExpiryDate]
                      , [LT].[Job]
                      , [LT].[Bin]
                      , [SM].[CustomerPoNumber]
                      , [LT].[UnitCost]
                      , [W].[WarehouseDescription]
                      , [IM].[StockUom]
                      , [LT].[Narration]
                      , [LT].[Reference]
                From    [#LotTransactionsDispatches] As [LT]
                        Left Join [#OriginalBatch] As [OB] On [OB].[Lot] = [LT].[Lot]
                                                              And [OB].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [#InvMasterDispatches] As [IM] On [IM].[StockCode] = [LT].[StockCode]
                                                              And [IM].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [#ArCustomerDispatches] As [AC] On [AC].[Customer] = [LT].[Customer]
                                                              And [AC].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [#WipMasterDispatches] As [WM] On [WM].[Job] = [LT].[Job]
                                                              And [WM].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier]
                        As [TTAM] On [TTAM].[TrnType] = [LT].[TrnType]
                                     And [TTAM].[Company] = [LT].[DatabaseName]
                        Left Join [#SorMasterDispatches] As [SM] On [SM].[SalesOrder] = [LT].[SalesOrder]
                                                              And [SM].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[Warehouse] As [W] On [W].[Warehouse] = [LT].[Warehouse]
                                                              And [W].[Company] = [LT].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [LT].[DatabaseName]
                        Left Join [#SorDetailDispatches] As [SD] On [SD].[SalesOrder] = [LT].[SalesOrder]
                                                              And [SD].[SalesOrderLine] = [LT].[SalesOrderLine]
                                                              And [SD].[DatabaseName] = [LT].[DatabaseName]
                Where   [LT].[TrnType] = 'D';

--return results
        Select  [R].[Company]
              , [R].[CompanyName]
              , [R].[OriginalBatch]
              , [R].[Lot]
              , [R].[StockCode]
              , [StockDescription] = [R].[Description]
              , [R].[Customer]
              , [R].[CustomerName]
              , [R].[JobDescription]
              , [R].[JobClassification]
              , [R].[SellingPrice]
              , [R].[SalesOrder]
              , [R].[SalesOrderLine]
              , [R].[TrnQuantity]
              , [R].[TrnValue]
              , [R].[TrnType]
              , [R].[AmountModifier]
              , [R].[TrnDate]
              , [R].[OldExpiryDate]
              , [R].[NewExpiryDate]
              , [R].[Job]
              , [R].[Bin]
              , [R].[CustomerPoNumber]
              , [R].[UnitCost]
              , [Warehouse] = [R].[WarehouseDescription]
              , [Uom] = [R].[StockUom]
              , [R].[Narration]
              , [R].[Reference]
              , [TranRank] = 99
              , [ContainerRank] = 99
        From    [#ResultsDispatches] As [R];

        Drop Table [#OriginalBatch];
        Drop Table [#ArCustomerDispatches];
        Drop Table [#InvMasterDispatches];
        Drop Table [#LotTransactionsDispatches];
        Drop Table [#SorMasterDispatches];
        Drop Table [#ResultsDispatches];
        Drop Table [#WipMasterDispatches];

    End;

GO
