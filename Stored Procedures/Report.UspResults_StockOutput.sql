SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockOutput]
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
Details of where lots are distributed
--exec [Report].[UspResults_StockOutput]  10
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
            @StoredProcName = 'UspResults_StockOutput' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'LotTransactions,WipMaster,SorMaster'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [JobPurchOrder] Varchar(50)	Collate Latin1_General_BIN
            , [Lot] Varchar(50)				Collate Latin1_General_BIN
            , [TrnQuantity] Numeric(20 , 7)
            , [TrnValue] Numeric(20 , 2)
            , [TrnType] Varchar(5)			Collate Latin1_General_BIN
            , [TrnDate] DateTime2
            , [OldExpiryDate] DateTime2
            , [NewExpiryDate] DateTime2
            , [Job] Varchar(50)				Collate Latin1_General_BIN
            , [Bin] Varchar(50)				Collate Latin1_General_BIN
            , [UnitCost] Numeric(20 , 7)
            , [Warehouse] Varchar(10)		Collate Latin1_General_BIN
            , [Narration] Varchar(150)		Collate Latin1_General_BIN
            , [Reference] Varchar(150)		Collate Latin1_General_BIN
            );
        Create Table [#WipMaster]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [Customer] Varchar(50)		Collate Latin1_General_BIN
            , [CustomerName] Varchar(255)	Collate Latin1_General_BIN
            , [Job] Varchar(50)				Collate Latin1_General_BIN
            , [JobDescription] Varchar(255) Collate Latin1_General_BIN
            , [JobClassification] Varchar(50) Collate Latin1_General_BIN
            , [SellingPrice] Numeric(20 , 2)
            , [SalesOrder] Varchar(50)		Collate Latin1_General_BIN
            , [SalesOrderLine] Varchar(15) Collate Latin1_General_BIN
            );
        Create Table [#Lots]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [JobPurchOrder] Varchar(50)		collate latin1_general_bin
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
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [CompanyName] Varchar(150)			collate latin1_general_bin
            , [JobPurchOrder] Varchar(50)			collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [StockCode] Varchar(50)				collate latin1_general_bin
            , [StockDescription] Varchar(255)		collate latin1_general_bin
            , [Customer] Varchar(50)				collate latin1_general_bin
            , [CustomerName] Varchar(255)			collate latin1_general_bin
            , [JobDescription] Varchar(255)			collate latin1_general_bin
            , [JobClassification] Varchar(150)		collate latin1_general_bin
            , [SellingPrice] Numeric(20 , 2)		
            , [SalesOrder] Varchar(50)				collate latin1_general_bin
            , [SalesOrderLine] Varchar(15)			collate latin1_general_bin
            , [TrnQuantity] Numeric(20 , 7)			
            , [TrnValue] Numeric(20 , 2)			
            , [TrnType] Varchar(100)				collate latin1_general_bin
            , [AmountModifier] Int					
            , [TrnDate] DateTime2					
            , [OldExpiryDate] DateTime2				
            , [NewExpiryDate] DateTime2				
            , [Job] Varchar(50)						collate latin1_general_bin
            , [Bin] Varchar(50)						collate latin1_general_bin
            , [CustomerPoNumber] Varchar(150)		collate latin1_general_bin
            , [UnitCost] Numeric(20 , 7)			
            , [StockUom] Varchar(10)				collate latin1_general_bin
            , [Warehouse] Varchar(200)				collate latin1_general_bin
            , [Narration] Varchar(150)				Collate Latin1_General_BIN
            , [Reference] Varchar(150)				Collate Latin1_General_BIN
            );

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
                      , [TrnType] = [LTTT].[TrnTypeDescription]--[lt].[TrnType]
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
                        Inner Join [#Lots] As [l]
                            On [l].[Lot] = [lt].[Lot] Collate Latin1_General_BIN
                               And [l].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [#WipMaster] As [wm]
                            On [wm].[Job] = [lt].[Job] Collate Latin1_General_BIN
                               And [wm].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [#SorMaster] As [sm]
                            On [sm].[SalesOrder] = [wm].[SalesOrder]
                               And [sm].[DatabaseName] = [wm].[DatabaseName]
                        Left Join [#InvMaster] As [im]
                            On [im].[DatabaseName] = [lt].[DatabaseName]
                               And [im].[StockCode] = [l].[StockCode]
                        Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier]
                            As [ttam]
                            On [ttam].[TrnType] = [lt].[TrnType]  Collate Latin1_General_BIN
                               And [ttam].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [Lookups].[CompanyNames] As [cn]
                            On [cn].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [BlackBox].[Lookups].[Warehouse] As [w]
                            On [w].[Warehouse] = [lt].[Warehouse]
                               And [w].[Company] = [lt].[DatabaseName]
                        Left Join [Lookups].[LotTransactionTrnType] [LTTT]
                            On [LTTT].[TrnType] = [lt].[TrnType];

--return results
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
