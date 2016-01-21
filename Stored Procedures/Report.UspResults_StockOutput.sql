SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockOutput] ( @Company VARCHAR(Max) )
As --exec [Report].[UspResults_StockOutput]  10
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Details of where lots are distributd																					///
///																																	///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			28/9/2015	Chris Johnson			Initial version created																///
///												Designed for Richard Hawkins & Colin Grant											///
///			28/9/2015	Chris Johnson			Added Customer PO number															///
///			05/10/2015	Chris Johnson			Added StockUom, UnitCost & Warehouse												///
///			04/11/2015	Chris Johnson			Added narration and reference														///
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
        Declare @ListOfTables VARCHAR(Max) = 'LotTransactions,WipMaster,SorMaster'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #LotTransactions
            (
              DatabaseName			VARCHAR(150) Collate Latin1_General_BIN
            , [JobPurchOrder]		VARCHAR(50) Collate Latin1_General_BIN
            , [Lot]					VARCHAR(50) Collate Latin1_General_BIN
            , [TrnQuantity]			NUMERIC(20,7)
            , [TrnValue]			NUMERIC(20,2)
            , [TrnType]				VARCHAR(5) Collate Latin1_General_BIN
            , [TrnDate]				DATETIME2
            , [OldExpiryDate]		DATETIME2
            , [NewExpiryDate]		DATETIME2
            , [Job]					VARCHAR(50) Collate Latin1_General_BIN
            , [Bin]					VARCHAR(50) Collate Latin1_General_BIN
			, [UnitCost]			NUMERIC(20,7)
			, [Warehouse]			VARCHAR(10) Collate Latin1_General_BIN
			, [Narration]			VARCHAR(150) Collate Latin1_General_BIN
			, [Reference]			VARCHAR(150) Collate Latin1_General_BIN
            );
        Create Table #WipMaster
            (
              DatabaseName			VARCHAR(150) Collate Latin1_General_BIN
            , [Customer]			VARCHAR(50) Collate Latin1_General_BIN
            , [CustomerName]		VARCHAR(255) Collate Latin1_General_BIN
            , [Job]					VARCHAR(50) Collate Latin1_General_BIN
            , [JobDescription]		VARCHAR(255) Collate Latin1_General_BIN
            , [JobClassification]	VARCHAR(50) Collate Latin1_General_BIN
            , [SellingPrice]		NUMERIC(20,2)
			, [SalesOrder]			VARCHAR(50) Collate Latin1_General_BIN
            , [SalesOrderLine]		VARCHAR(15) Collate Latin1_General_BIN
            );
        Create Table #Lots
            (
              DatabaseName			VARCHAR(150) Collate Latin1_General_BIN
            , [JobPurchOrder]		VARCHAR(50) Collate Latin1_General_BIN
            , [Lot]					VARCHAR(50)
			, StockCode				VARCHAR(50)
			, StockDescription		VARCHAR(255)
            );
		CREATE TABLE #SorMaster
		(
			  DatabaseName			VARCHAR(150) Collate Latin1_General_BIN
            , SalesOrder			VARCHAR(50) Collate Latin1_General_BIN
            , CustomerPoNumber		VARCHAR(150)
		)
		CREATE TABLE #InvMaster
		( DatabaseName			VARCHAR(150) Collate Latin1_General_BIN
		    , StockCode			VARCHAR(50)
			, [StockUom]		VARCHAR(10)
		)

		
		

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
        Exec sp_MSforeachdb
            @SQL1;
        Exec sp_MSforeachdb
            @SQL2;
		Exec sp_MSforeachdb
            @SQL3;
		Exec sp_MSforeachdb
            @SQL4;
--define the results you want to return
        Create Table #Results
            (
              [DatabaseName] VARCHAR(150)
            , [CompanyName] VARCHAR(150)
            , [JobPurchOrder] VARCHAR(50)
            , [Lot] VARCHAR(50)
			, StockCode VARCHAR(50)
			, StockDescription VARCHAR(255)
            , [Customer] VARCHAR(50)
            , [CustomerName] VARCHAR(255)
            , [JobDescription] VARCHAR(255)
            , [JobClassification] VARCHAR(150)
            , [SellingPrice] NUMERIC(20,2)
            , [SalesOrder] VARCHAR(50)
            , [SalesOrderLine] VARCHAR(15)
            , [TrnQuantity] NUMERIC(20,7)
            , [TrnValue] NUMERIC(20,2)
            , [TrnType] VARCHAR(10)
            , [AmountModifier] INT
            , [TrnDate] DATETIME2
            , [OldExpiryDate] DATETIME2
            , [NewExpiryDate] DATETIME2
            , [Job] VARCHAR(50)
            , [Bin] VARCHAR(50)
			, [CustomerPoNumber] VARCHAR(150)
			, [UnitCost] NUMERIC(20,7)
			, [StockUom] VARCHAR(10)
			, [Warehouse] VARCHAR(200)
			, [Narration]			VARCHAR(150) Collate Latin1_General_BIN
			, [Reference]			VARCHAR(150) Collate Latin1_General_BIN
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
                Select
                    [lt].[DatabaseName]
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
                  , lt.[TrnDate]
                  , lt.[OldExpiryDate]
                  , lt.[NewExpiryDate]
                  , lt.[Job]
                  , lt.[Bin]
				  , sm.[CustomerPoNumber]
				  , lt.[UnitCost]
				  ,	[im].[StockUom] 
				  , [w].[WarehouseDescription]
				  , [lt].[Narration]
				  , [lt].[Reference]
                From
                    #LotTransactions As [lt]
                Inner Join [#Lots] As [l]
                    On [l].[Lot] = [lt].[Lot] Collate Latin1_General_BIN
                       And [l].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
                Left Join #WipMaster As [wm]
                    On [wm].[Job] = [lt].[Job] Collate Latin1_General_BIN
                       And [wm].[DatabaseName] = [lt].[DatabaseName] Collate Latin1_General_BIN
				Left Join [#SorMaster] As [sm]
					On [sm].[SalesOrder] = [wm].[SalesOrder]
						And [sm].[DatabaseName] = [wm].[DatabaseName]
				Left Join [#InvMaster] As [im]
					On [im].[DatabaseName] = [lt].[DatabaseName]
						And [im].[StockCode] = [l].[StockCode]
                Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier] As [ttam]
                    On [ttam].[TrnType] = [lt].[TrnType]  Collate Latin1_General_BIN
                       And [ttam].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
                Left Join [Lookups].[CompanyNames] As [cn]
                    On [cn].[Company] = [lt].[DatabaseName] Collate Latin1_General_BIN
				Left Join [BlackBox].[Lookups].[Warehouse] As [w] 
					On [w].[Warehouse] = [lt].[Warehouse]
					And [w].[Company] = [lt].[DatabaseName]
					;

--return results
        Select
            [Company] = [DatabaseName]
          , [CompanyName]
          , OriginalBatch = [JobPurchOrder]
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
          , [AmountModifier]	= coalesce([AmountModifier],0)
          , [TrnDate]			= CAST([TrnDate] As DATE)
          , [OldExpiryDate]		= CAST([OldExpiryDate] As DATE)
          , [NewExpiryDate]		= CAST([NewExpiryDate] As DATE)
          , [Job]
          , [Bin]
		  , [CustomerPoNumber]
		  , [UnitCost]
		  , [Warehouse]
		  ,	[Uom]				= [StockUom] 
		  , [Narration]			= Case When [Narration]='' Then Null Else [Narration] End
		  , [Reference]			= Case When [Reference]='' Then Null Else [Reference] End
		  , [TranRank]			= RANK() Over ( Partition By [Lot] Order By [TrnDate] Asc) 
		  , [ContainerRank]		= DENSE_RANK() Over ( Partition By [JobPurchOrder] Order By [Lot] Asc) 
        From
            #Results;

    End;

GO
