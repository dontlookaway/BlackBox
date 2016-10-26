SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockOutputDispatches2]
    (
      @Company Varchar(50)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016

*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

		--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [BlackBox].[Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_StockOutputDispatches2' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
	
	--Dispatches
	--define the results you want to return
        Create Table [#ResultsDispatches]
            (
              [Company] Varchar(150)						collate latin1_general_bin
            , [CompanyName] Varchar(250)				    collate latin1_general_bin
            , [OriginalBatch] Varchar(20)				    collate latin1_general_bin
            , [Lot] Varchar(50)							    collate latin1_general_bin
            , [StockCode] Varchar(30)					    collate latin1_general_bin
            , [Description] Varchar(50)					    collate latin1_general_bin
            , [Customer] Varchar(15)					    collate latin1_general_bin
            , [CustomerName] Varchar(50)				    collate latin1_general_bin
            , [JobDescription] Varchar(50)				    collate latin1_general_bin
            , [JobClassification] Varchar(10)			    collate latin1_general_bin
            , [SellingPrice] Numeric(20 , 2)			    
            , [SalesOrder] Varchar(20)					    collate latin1_general_bin
            , [SalesOrderLine] Int						    
            , [TrnQuantity] Numeric(20 , 8)				    
            , [TrnValue] Numeric(20 , 2)				    
            , [TrnType] Char(1)							    collate latin1_general_bin
            , [AmountModifier] Float					    
            , [TrnDate] Date							    
            , [OldExpiryDate] Date						    
            , [NewExpiryDate] Date						    
            , [Job] Varchar(20)							    collate latin1_general_bin
            , [Bin] Varchar(20)							    collate latin1_general_bin
            , [CustomerPoNumber] Varchar(30)			    collate latin1_general_bin
            , [UnitCost] Numeric(20 , 2)				    
            , [WarehouseDescription] Varchar(200)		    collate latin1_general_bin
            , [StockUom] Varchar(10)					    collate latin1_general_bin
            , [Narration] Varchar(100)					    collate latin1_general_bin
            , [Reference] Varchar(30)					    collate latin1_general_bin
            );												
			--define the results you want to return			
        Create Table [#Results]								
            (												
              [DatabaseName] Varchar(150)					collate latin1_general_bin
            , [CompanyName] Varchar(150)					collate latin1_general_bin
            , [JobPurchOrder] Varchar(50)					collate latin1_general_bin
            , [Lot] Varchar(50)								collate latin1_general_bin
            , [StockCode] Varchar(50)						collate latin1_general_bin
            , [StockDescription] Varchar(255)				collate latin1_general_bin
            , [Customer] Varchar(50)						collate latin1_general_bin
            , [CustomerName] Varchar(255)					collate latin1_general_bin
            , [JobDescription] Varchar(255)					collate latin1_general_bin
            , [JobClassification] Varchar(150)				collate latin1_general_bin
            , [SellingPrice] Numeric(20 , 2)				
            , [SalesOrder] Varchar(50)						collate latin1_general_bin
            , [SalesOrderLine] Varchar(15)					collate latin1_general_bin
            , [TrnQuantity] Numeric(20 , 7)					
            , [TrnValue] Numeric(20 , 2)					
            , [TrnType] Varchar(10)							collate latin1_general_bin
            , [AmountModifier] Int							
            , [TrnDate] DateTime2							
            , [OldExpiryDate] DateTime2						
            , [NewExpiryDate] DateTime2						
            , [Job] Varchar(50)								collate latin1_general_bin
            , [Bin] Varchar(50)								collate latin1_general_bin
            , [CustomerPoNumber] Varchar(150)				collate latin1_general_bin
            , [UnitCost] Numeric(20 , 7)					
            , [StockUom] Varchar(10)						collate latin1_general_bin
            , [Warehouse] Varchar(200)						collate latin1_general_bin
            , [Narration] Varchar(150)						collate latin1_general_bin
            , [Reference] Varchar(150)						collate latin1_general_bin
            );
        Begin
	    --list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
            Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
            Create Table [#LotTransactionsDispatches]
                (
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [Lot] Varchar(50)							collate latin1_general_bin
                , [StockCode] Varchar(30)					collate latin1_general_bin
                , [Customer] Varchar(15)					collate latin1_general_bin
                , [SalesOrder] Varchar(20)					collate latin1_general_bin
                , [SalesOrderLine] Int						
                , [TrnQuantity] Numeric(20 , 8)				
                , [TrnValue] Numeric(20 , 2)				
                , [TrnType] Char(1)							collate latin1_general_bin
                , [TrnDate] Date							
                , [OldExpiryDate] Date						
                , [NewExpiryDate] Date						
                , [Job] Varchar(20)							collate latin1_general_bin
                , [Bin] Varchar(20)							collate latin1_general_bin
                , [UnitCost] Numeric(20 , 2)				
                , [Narration] Varchar(100)					collate latin1_general_bin
                , [Reference] Varchar(30)					collate latin1_general_bin
                , [Warehouse] Varchar(10)					collate latin1_general_bin
                , [JobPurchOrder] Varchar(20)				collate latin1_general_bin
                );											
            Create Table [#InvMasterDispatches]				
                (											
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [StockCode] Varchar(30)					collate latin1_general_bin
                , [Description] Varchar(50)					collate latin1_general_bin
                , [StockUom] Varchar(10)					collate latin1_general_bin
                );											
            Create Table [#ArCustomerDispatches]			
                (											
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [Customer] Varchar(15)					collate latin1_general_bin
                , [Name] Varchar(50)						collate latin1_general_bin
                );											
            Create Table [#WipMasterDispatches]				
                (											
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [Job] Varchar(20)							collate latin1_general_bin
                , [JobDescription] Varchar(50)				collate latin1_general_bin
                , [JobClassification] Varchar(10)			collate latin1_general_bin
                , [SellingPrice] Numeric(20 , 2)			
                );											
            Create Table [#SorMasterDispatches]				
                (											
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [SalesOrder] Varchar(20)					collate latin1_general_bin
                , [CustomerPoNumber] Varchar(30)			collate latin1_general_bin
                );											
            Create Table [#SorDetailDispatches]				
                (											
                  [DatabaseName] Varchar(150)				collate latin1_general_bin
                , [SalesOrder] Varchar(20)					collate latin1_general_bin
                , [SalesOrderLine] Int
                , [MPrice] Numeric(20 , 2)
                );

--create script to pull data from each db into the tables
            Declare @SQLLotTransactions Varchar(Max) = 'USE [?];
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
            Declare @SQLInvMaster Varchar(Max) = 'USE [?];
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
            Declare @SQLArCustomer Varchar(Max) = 'USE [?];
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
            Declare @SQLWipMaster Varchar(Max) = 'USE [?];
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
            Declare @SQLSorMaster Varchar(Max) = 'USE [?];
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
            Declare @SQLSorDetail Varchar(Max) = 'USE [?];
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
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLLotTransactions;
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLInvMaster;
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLArCustomer;
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLWipMaster;
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLSorMaster;
                Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQLSorDetail;
            End;

--Placeholder to create indexes as required
            Create Table [#OriginalBatch]
                (
                  [Lot] Varchar(50)				collate latin1_general_bin
                , [MasterJob] Varchar(20)		collate latin1_general_bin
                , [DatabaseName] Varchar(120)	collate latin1_general_bin
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



            Drop Table [#OriginalBatch];
            Drop Table [#ArCustomerDispatches];
            Drop Table [#InvMasterDispatches];
            Drop Table [#LotTransactionsDispatches];
            Drop Table [#SorMasterDispatches];
            Drop Table [#WipMasterDispatches];
        End;


	--Output
        Begin
	    --create temporary tables to be pulled from different databases, including a column to id
            Create Table [#LotTransactions]
                (
                  [DatabaseName] Varchar(150)		Collate Latin1_General_BIN
                , [JobPurchOrder] Varchar(50)		Collate Latin1_General_BIN
                , [Lot] Varchar(50)					Collate Latin1_General_BIN
                , [TrnQuantity] Numeric(20 , 7)
                , [TrnValue] Numeric(20 , 2)
                , [TrnType] Varchar(5)				Collate Latin1_General_BIN
                , [TrnDate] DateTime2
                , [OldExpiryDate] DateTime2
                , [NewExpiryDate] DateTime2
                , [Job] Varchar(50)					Collate Latin1_General_BIN
                , [Bin] Varchar(50)					Collate Latin1_General_BIN
                , [UnitCost] Numeric(20 , 7)
                , [Warehouse] Varchar(10)			Collate Latin1_General_BIN
                , [Narration] Varchar(150)			Collate Latin1_General_BIN
                , [Reference] Varchar(150)			Collate Latin1_General_BIN
                );
            Create Table [#WipMaster]
                (
                  [DatabaseName] Varchar(150)		Collate Latin1_General_BIN
                , [Customer] Varchar(50)			Collate Latin1_General_BIN
                , [CustomerName] Varchar(255)		Collate Latin1_General_BIN
                , [Job] Varchar(50)					Collate Latin1_General_BIN
                , [JobDescription] Varchar(255)		Collate Latin1_General_BIN
                , [JobClassification] Varchar(50)	Collate Latin1_General_BIN
                , [SellingPrice] Numeric(20 , 2)
                , [SalesOrder] Varchar(50)			Collate Latin1_General_BIN
                , [SalesOrderLine] Varchar(15)		Collate Latin1_General_BIN
                );
            Create Table [#Lots]
                (
                  [DatabaseName] Varchar(150)		collate latin1_general_bin
                , [JobPurchOrder] Varchar(50) 		collate latin1_general_bin
                , [Lot] Varchar(50)					collate latin1_general_bin
                , [StockCode] Varchar(50)			collate latin1_general_bin
                , [StockDescription] Varchar(255)	collate latin1_general_bin
                );
            Create Table [#SorMaster]
                (
                  [DatabaseName] Varchar(150)		Collate Latin1_General_BIN
                , [SalesOrder] Varchar(50)			Collate Latin1_General_BIN
                , [CustomerPoNumber] Varchar(150)	collate latin1_general_bin
                );
            Create Table [#InvMaster]
                (
                  [DatabaseName] Varchar(150)		collate latin1_general_bin
                , [StockCode] Varchar(50)			collate latin1_general_bin
                , [StockUom] Varchar(10)			collate latin1_general_bin
                );

--create script to pull data from each db into the tables
            Declare @SQL1 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
                + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Insert [#LotTransactions]
					( [DatabaseName], [JobPurchOrder]
					, [Lot], [TrnQuantity]
					, [TrnValue], [TrnType]
					, [TrnDate], [OldExpiryDate], [NewExpiryDate]
					, [Job], [Bin]
					, [UnitCost], [Warehouse]
					, [Narration], [Reference]
					)
			SELECT [DatabaseName] = @DBCode
					, [lt].[JobPurchOrder]
					, [lt].[Lot], [lt].[TrnQuantity]
					, [lt].[TrnValue], [lt].[TrnType]
					, [lt].[TrnDate], [lt].[OldExpiryDate], [lt].[NewExpiryDate]
					, [lt].[Job], [lt].[Bin] 
					, [lt].[UnitCost], [Warehouse]
					, [Narration], [Reference]
			FROM [LotTransactions] As [lt]
			Insert [#Lots]
					( [DatabaseName]
					, [JobPurchOrder], [Lot]
					, StockCode, StockDescription
					)
			Select 
					Distinct
				[DatabaseName] = @DBCode
			  , [l].[JobPurchOrder], [l].[Lot]
			  , [l].[StockCode], im.[Description]
			From
				[LotTransactions] As [l]
			Left Join [dbo].[InvMaster] As [im]
				On [im].[StockCode] = [l].[StockCode]
			Where
				[JobPurchOrder] <> ''''
			End
	End';
            Declare @SQL2 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
                + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert [#WipMaster]
						( [DatabaseName]
						, [Customer]
						, [CustomerName]
						, [Job]
						, [JobDescription]
						, [JobClassification]
						, [SellingPrice]
						, [SalesOrder]		
						, [SalesOrderLine]
						)
				SELECT [DatabaseName]=@DBCode
					 , [wm].[Customer]
					 , [wm].[CustomerName]
					 , [wm].[Job]
					 , [wm].[JobDescription]
					 , [wm].[JobClassification]
					 , [wm].[SellingPrice] 
					 , [SalesOrder]		
					 , [SalesOrderLine]
				FROM [WipMaster] As [wm]
			End
	End';
            Declare @SQL3 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
                + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Insert [#SorMaster]
		        ( [DatabaseName]
		        , [SalesOrder]
		        , [CustomerPoNumber]
		        )
			SELECT [DatabaseName]=@DBCode
				 , [sm].[SalesOrder]
				 , [sm].[CustomerPoNumber] 
			FROM [SorMaster] As [sm]
			End
	End';
            Declare @SQL4 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
                + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Insert [#InvMaster]
		        ( [DatabaseName]
		        , [StockCode]
		        , [StockUom]
		        )
			SELECT [DatabaseName]=@DBCode
				 , [im].[StockCode]
				 , [im].[StockUom] 
			From [InvMaster] As [im]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
            Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQL1;
            Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQL2;
            Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQL3;
            Exec [BlackBox].[Process].[ExecForEachDB] @cmd = @SQL4;


--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
            Insert  [#Results]
                    ( [DatabaseName]
                    , [CompanyName]
                    , [JobPurchOrder]
                    , [Lot]
                    , [StockCode]
                    , [StockDescription]
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
                    , [StockUom]
                    , [Warehouse]
                    , [Narration]
                    , [Reference]
				    )
                    Select  [lt].[DatabaseName]
                          , [cn].[CompanyName]
                          , [l].[JobPurchOrder]
                          , [l].[Lot]
                          , [l].[StockCode]
                          , [l].[StockDescription]
                          , [wm].[Customer]
                          , [wm].[CustomerName]
                          , [wm].[JobDescription]
                          , [wm].[JobClassification]
                          , [wm].[SellingPrice]
                          , [wm].[SalesOrder]
                          , [wm].[SalesOrderLine]
                          , [lt].[TrnQuantity]
                          , [lt].[TrnValue]
                          , [lt].[TrnType]
                          , [ttam].[AmountModifier]
                          , [lt].[TrnDate]
                          , [lt].[OldExpiryDate]
                          , [lt].[NewExpiryDate]
                          , [lt].[Job]
                          , [lt].[Bin]
                          , [sm].[CustomerPoNumber]
                          , [lt].[UnitCost]
                          , [im].[StockUom]
                          , [w].[WarehouseDescription]
                          , [lt].[Narration]
                          , [lt].[Reference]
                    From    [#LotTransactions] As [lt]
                            Inner Join [#Lots] As [l] On [l].[Lot] = [lt].[Lot] Collate Latin1_General_BIN
                                                         And [l].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
                            Left Join [#WipMaster] As [wm] On [wm].[Job] = [lt].[Job] Collate Latin1_General_BIN
                                                              And [wm].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
                            Left Join [#SorMaster] As [sm] On [sm].[SalesOrder] = [wm].[SalesOrder]
                                                              And [sm].[DatabaseName] = [wm].[DatabaseName]
                            Left Join [#InvMaster] As [im] On [im].[DatabaseName] = [lt].[DatabaseName]
                                                              And [im].[StockCode] = [l].[StockCode]
                            Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier]
                            As [ttam] On [ttam].[TrnType] = [lt].[TrnType]  Collate Latin1_General_BIN
                                         And [ttam].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
                            Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [cn].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
                            Left Join [BlackBox].[Lookups].[Warehouse] As [w] On [w].[Warehouse] = [lt].[Warehouse]
                                                              And [w].[Company] = [lt].[DatabaseName];


        End;
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
        From    [#ResultsDispatches] As [R]
		Union all
        Select  [Company] = [DatabaseName]
              , [CompanyName]
              , [OriginalBatch] = [JobPurchOrder]
              , [Lot]
              , [StockCode]
              , [StockDescription]
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
              , [AmountModifier] = Coalesce([AmountModifier] , 0)
              , [TrnDate] = Cast([TrnDate] As Date)
              , [OldExpiryDate] = Cast([OldExpiryDate] As Date)
              , [NewExpiryDate] = Cast([NewExpiryDate] As Date)
              , [Job]
              , [Bin]
              , [CustomerPoNumber]
              , [UnitCost]
              , [Warehouse]
              , [Uom] = [StockUom]
              , [Narration] = Case When [Narration] = '' Then Null
                                   Else [Narration]
                              End
              , [Reference] = Case When [Reference] = '' Then Null
                                   Else [Reference]
                              End
              , [TranRank] = Rank() Over ( Partition By [Lot] Order By [TrnDate] Asc )
              , [ContainerRank] = Dense_Rank() Over ( Partition By [JobPurchOrder] Order By [Lot] Asc )
        From    [#Results];
    End;
GO
