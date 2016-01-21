SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockLevels] ( @Company VARCHAR(Max) )
As --exec [Report].[UspResults_StockLevels]  10
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			2/10/2015	Chris Johnson			Initial version created																///
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
        Declare @ListOfTables VARCHAR(Max) = 'InvWarehouse,InvMultBin,InvMaster,InvFifoLifo'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #InvWarehouse
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [Warehouse] VARCHAR(10) Collate Latin1_General_BIN
            , [StockCode] VARCHAR(35) Collate Latin1_General_BIN
            , [QtyOnHand] NUMERIC(20, 7)
            , [UnitCost] NUMERIC(20, 7)
            , [OpenBalCost1] NUMERIC(20, 7)
            , [OpenBalCost2] NUMERIC(20, 7)
            , [OpenBalCost3] NUMERIC(20, 7)
            );
        Create Table #InvMultBin
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [Warehouse] VARCHAR(10) Collate Latin1_General_BIN
            , [QtyOnHand1] NUMERIC(20, 7)
            , [QtyOnHand2] NUMERIC(20, 7)
            , [QtyOnHand3] NUMERIC(20, 7)
            , [StockCode] VARCHAR(35) Collate Latin1_General_BIN
            );
        Create Table #InvMaster
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [StockCode] VARCHAR(35) Collate Latin1_General_BIN
            , [Description] VARCHAR(150) Collate Latin1_General_BIN
            );
		Create Table #InvFifoLifo
			(DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [Warehouse] VARCHAR(10) Collate Latin1_General_BIN
			, [StockCode] VARCHAR(35) Collate Latin1_General_BIN
			, [ReceiptQty] NUMERIC(20,7)
			, [UnitCost1] NUMERIC(20,7)
			, [UnitCost2] NUMERIC(20,7)
			, [UnitCost3] NUMERIC(20,7)
			, [QtyOnHand1] NUMERIC(20,7)
			, [QtyOnHand2] NUMERIC(20,7)
			, [QtyOnHand3] NUMERIC(20,7)
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
				Insert [#InvWarehouse]
						( [DatabaseName]
						, [Warehouse]
						, [StockCode]
						, [QtyOnHand]
						, [UnitCost]
						, [OpenBalCost1]
						, [OpenBalCost2]
						, [OpenBalCost3]
						)
				SELECT [DatabaseName]=@DBCode
					 , [iw].[Warehouse]
					 , [iw].[StockCode]
					 , [iw].[QtyOnHand]
					 , [iw].[UnitCost]
					 , [iw].[OpenBalCost1]
					 , [iw].[OpenBalCost2]
					 , [iw].[OpenBalCost3] 
				From [InvWarehouse] As [iw]
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
				Insert [#InvMultBin]
						( [DatabaseName]
						, [Warehouse]
						, [QtyOnHand1]
						, [QtyOnHand2]
						, [QtyOnHand3]
						, [StockCode]
						)
				SELECT [DatabaseName]=@DBCode
					 , [imb].[Warehouse]
					 , [imb].[QtyOnHand1]
					 , [imb].[QtyOnHand2]
					 , [imb].[QtyOnHand3]
					 , [imb].[StockCode] 
				From [InvMultBin] As [imb]
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
				Insert [#InvMaster]
						( [DatabaseName]
						, [StockCode]
						, [Description]
						)
				SELECT [DatabaseName]=@DBCode
					 , [im].[StockCode]
					 , [im].[Description] 
				From [InvMaster] As [im]
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
			Insert [#InvFifoLifo]
					( [DatabaseName]
					, [Warehouse]
					, [StockCode]
					, [ReceiptQty]
					, [UnitCost1]
					, [UnitCost2]
					, [UnitCost3]
					, [QtyOnHand1]
					, [QtyOnHand2]
					, [QtyOnHand3]
					)
			SELECT [DatabaseName] = @DBCode
				 , [ifl].[Warehouse]
				 , [ifl].[StockCode]
				 , [ifl].[ReceiptQty]
				 , [ifl].[UnitCost1]
				 , [ifl].[UnitCost2]
				 , [ifl].[UnitCost3]
				 , [ifl].[QtyOnHand1]
				 , [ifl].[QtyOnHand2]
				 , [ifl].[QtyOnHand3] 
			From [InvFifoLifo] As [ifl]
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
        --Create Table #Results
        --    (
        --      DatabaseName VARCHAR(150)
        --    , [Warehouse] VARCHAR(10)
        --    , [StockCode] VARCHAR(35)
        --    , [StockDescription] VARCHAR(150)
        --    , [QtyOnHand] NUMERIC(20, 7)
        --    , [UnitCost] NUMERIC(20, 3)
        --    , [Value1] NUMERIC(20, 3)
        --    , [Value2] NUMERIC(20, 3)
        --    , [Value3] NUMERIC(20, 3)
        --    , [Quantity1] NUMERIC(20, 3)
        --    , [Quantity2] NUMERIC(20, 3)
        --    , [Quantity3] NUMERIC(20, 3)
        --    , [OpenBalCost1] NUMERIC(20, 3)
        --    , [OpenBalCost2] NUMERIC(20, 3)
        --    , [OpenBalCost3] NUMERIC(20, 3)
        --    );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
   --     Insert  [#Results]
   --             ( [DatabaseName]
   --             , [Warehouse]
   --             , [StockCode]
   --             , [StockDescription]
   --             , [QtyOnHand]
   --             , [UnitCost]
   --             , [Value1]
   --             , [Value2]
   --             , [Value3]
   --             , [Quantity1]
   --             , [Quantity2]
   --             , [Quantity3]
   --             , [OpenBalCost1]
   --             , [OpenBalCost2]
   --             , [OpenBalCost3]
   --             )
   --             Select
   --                 [iw].[DatabaseName]
   --               , [iw].[Warehouse]
   --               , [iw].[StockCode]
   --               , [StockDescription] = [im].[Description]
   --               , [iw].[QtyOnHand]
   --               , [iw].[UnitCost]
   --               , [Value1] = CAST(SUM(ROUND([IB].[QtyOnHand1]
   --                                           * [iw].OpenBalCost1, 2)) As NUMERIC(20,
   --                                                           3))
   --               , [Value2] = CAST(SUM(ROUND([IB].[QtyOnHand2]
   --                                           * [iw].OpenBalCost2, 2)) As NUMERIC(20,
   --                                                           3))
   --               , [Value3] = CAST(SUM(ROUND([IB].[QtyOnHand3]
   --                                           * [iw].OpenBalCost3, 2)) As NUMERIC(20,
   --                                                           3))
   --               , [Quantity1] = SUM([IB].[QtyOnHand3])
   --               , [Quantity2] = SUM([IB].[QtyOnHand3])
   --               , [Quantity3] = SUM([IB].[QtyOnHand3])
   --               , [OpenBalCost1]
   --               , [OpenBalCost2]
   --               , [OpenBalCost3]
   --             From
   --                 [#InvWarehouse] As [iw]
   --             Left Join #InvMultBin IB
   --                 On [iw].[StockCode] = [IB].[StockCode]
   --                    And [iw].[Warehouse] = [IB].[Warehouse]
   --                    And [IB].[DatabaseName] = [iw].[DatabaseName]
   --             Left Join [#InvMaster] As [im]
   --                 On [im].[StockCode] = [iw].[StockCode]
   --                    And [im].[DatabaseName] = [iw].[DatabaseName]
   --             Where
   --                 [iw].[StockCode] Is Not Null
   --             Group By
   --                 [iw].[DatabaseName]
   --               , [iw].[Warehouse]
   --               , [iw].[OpenBalCost1]
   --               , [iw].[OpenBalCost2]
   --               , [iw].[OpenBalCost3]
   --               , [iw].[StockCode]
   --               , [iw].[QtyOnHand]
   --               , [iw].[UnitCost]
   --               , [im].[Description]
			--Having SUM([IB].[QtyOnHand3])<>0
			--Or SUM([IB].[QtyOnHand3])<>0
			--Or SUM([IB].[QtyOnHand3])<>0
			--Or [iw].[QtyOnHand]<>0;



--return results
Select [cn].[CompanyName]
  , [ifl].[Warehouse]
  , [ifl].[StockCode]
  , StockDescription = [im].[Description]
  , Receipted = SUM([ifl].ReceiptQty * [ifl].[UnitCost1])
  , Period1Value = SUM([ifl].[UnitCost1] * [ifl].QtyOnHand1)
  , Period2Value = SUM([ifl].[UnitCost2] * [ifl].QtyOnHand2)
  , Period3Value = SUM([ifl].[UnitCost3] * [ifl].QtyOnHand3)
  , Period1Qty = SUM([ifl].[QtyOnHand1])
  , Period2Qty = SUM([ifl].[QtyOnHand2])
  , Period3Qty = SUM([ifl].[QtyOnHand3])
  , [ifl].[UnitCost1]
  , [ifl].[UnitCost2]
  , [ifl].[UnitCost3]
From
    [#InvFifoLifo] As [ifl]
	Left Join [Lookups].[CompanyNames] As [cn] 
				On [ifl].[DatabaseName]=[cn].[Company]
	Left Join [#InvMaster] As [im] 
				On [im].[DatabaseName] = [ifl].[DatabaseName] 
				And [im].[StockCode] = [ifl].[StockCode]
Group By [cn].[CompanyName]
       , [ifl].[Warehouse]
       , [ifl].[StockCode]
       , [im].[Description]
       , [ifl].[UnitCost1]
       , [ifl].[UnitCost2]
       , [ifl].[UnitCost3];

    End;

GO
