
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockLevels] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--exec [Report].[UspResults_StockLevels]  10
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvWarehouse,InvMultBin,InvMaster,InvFifoLifo'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvWarehouse]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Warehouse] Varchar(10) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [QtyOnHand] Numeric(20 , 7)
            , [UnitCost] Numeric(20 , 7)
            , [OpenBalCost1] Numeric(20 , 7)
            , [OpenBalCost2] Numeric(20 , 7)
            , [OpenBalCost3] Numeric(20 , 7)
            );
        Create Table [#InvMultBin]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Warehouse] Varchar(10) Collate Latin1_General_BIN
            , [QtyOnHand1] Numeric(20 , 7)
            , [QtyOnHand2] Numeric(20 , 7)
            , [QtyOnHand3] Numeric(20 , 7)
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [Description] Varchar(150) Collate Latin1_General_BIN
            );
        Create Table [#InvFifoLifo]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Warehouse] Varchar(10) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [ReceiptQty] Numeric(20 , 7)
            , [UnitCost1] Numeric(20 , 7)
            , [UnitCost2] Numeric(20 , 7)
            , [UnitCost3] Numeric(20 , 7)
            , [QtyOnHand1] Numeric(20 , 7)
            , [QtyOnHand2] Numeric(20 , 7)
            , [QtyOnHand3] Numeric(20 , 7)
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
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;

--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table
 
--return results
        Select  [cn].[CompanyName]
              , [ifl].[Warehouse]
              , [ifl].[StockCode]
              , [StockDescription] = [im].[Description]
              , [Receipted] = Sum([ifl].[ReceiptQty] * [ifl].[UnitCost1])
              , [Period1Value] = Sum([ifl].[UnitCost1] * [ifl].[QtyOnHand1])
              , [Period2Value] = Sum([ifl].[UnitCost2] * [ifl].[QtyOnHand2])
              , [Period3Value] = Sum([ifl].[UnitCost3] * [ifl].[QtyOnHand3])
              , [Period1Qty] = Sum([ifl].[QtyOnHand1])
              , [Period2Qty] = Sum([ifl].[QtyOnHand2])
              , [Period3Qty] = Sum([ifl].[QtyOnHand3])
              , [ifl].[UnitCost1]
              , [ifl].[UnitCost2]
              , [ifl].[UnitCost3]
        From    [#InvFifoLifo] As [ifl]
                Left Join [Lookups].[CompanyNames] As [cn] On [ifl].[DatabaseName] = [cn].[Company]
                Left Join [#InvMaster] As [im] On [im].[DatabaseName] = [ifl].[DatabaseName]
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
