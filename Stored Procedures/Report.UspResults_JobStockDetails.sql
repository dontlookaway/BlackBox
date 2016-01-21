SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobStockDetails]
(@Company VARCHAR(Max))
As
--exec Report.UspResults_JobStockDetails 10
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
///			24/9/2015	Chris Johnson			Initial version created																///
///			05/10/2015	Chris Johnson			Added Uom and Unitcost																///
///			13/10/2013	Chris Johnson			Added inward lot																	///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;
--remove nocount on to speed up query
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'InvMovements,InvMaster' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #InvMovements
	(	DatabaseName VARCHAR(150)
	    ,Job VARCHAR(35)
		,Warehouse VARCHAR(20)
		,Bin VARCHAR(20)
		,StockCode VARCHAR(35)
		,TrnType VARCHAR(5)
		,LotSerial VARCHAR(50)
		,TrnQty FLOAT
		,TrnValue FLOAT
		,UnitCost NUMERIC(20,7) 
	)

	CREATE TABLE #InvMaster
	(	DatabaseName VARCHAR(150)
	    ,StockCode VARCHAR(35)
		,StockDescription VARCHAR(150)
		,StockUom VARCHAR(10)
	)


--create script to pull data from each db into the tables
	Declare @SQL1 VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				    Insert  #InvMovements
									( DatabaseName
									, Job
									, Warehouse
									, Bin
									, StockCode
									, TrnType
									, LotSerial
									, TrnQty
									, TrnValue
									,UnitCost
									)
					Select
						DatabaseName=@DBCode
						, Job
						, Warehouse
						, Bin
						, StockCode
						, TrnType
						, LotSerial
						, TrnQty
						,TrnValue
						,UnitCost
					From
						InvMovements
					where Job<>'''';
			End
	End'
	Declare @SQL2 VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #InvMaster
	        ( DatabaseName
	        , StockCode
	        , StockDescription
			,StockUom
	        )
			SELECT DatabaseName=@DBCode
				 , StockCode
				 , Description
				 ,StockUom
			FROM InvMaster
			End
	End'
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1
	Exec sp_MSforeachdb @SQL2

--define the results you want to return
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	--Insert #Results
	--        ( DatabaseName, Results )
	--Select DatabaseName,ColumnName FROM #Table1

--return results
SELECT IM.DatabaseName
		,IM.Job
		,IM.Warehouse
		,IM.Bin
		,IM.StockCode
		,IMA.StockDescription
		,OutwardLot = Case When IM.TrnType = 'R' Then IM.LotSerial Else Null End --receipted Lots generated from job
		,InwardLot = Case When IM.TrnType <> 'R' And IM.LotSerial<>'' Then IM.LotSerial Else Null End --receipted Lots generated from job
		,IM.TrnType
		,Quantity = SUM(IM.TrnQty*TT.AmountModifier)
		,Value = SUM(IM.TrnValue*TT.AmountModifier)
		,[IMA].[StockUom]
		,[IM].[UnitCost]
 FROM #InvMovements IM
Left Join BlackBox.Lookups.TrnTypeAmountModifier TT On TT.TrnType = IM.TrnType Collate Latin1_General_BIN
			And TT.Company=IM.DatabaseName Collate Latin1_General_BIN
Left Join #InvMaster IMA On IMA.StockCode = IM.StockCode Collate Latin1_General_BIN And IMA.DatabaseName = IM.DatabaseName Collate Latin1_General_BIN
Group By IM.DatabaseName
		, IM.Job
        , IM.Warehouse
        , IM.Bin
        , IM.StockCode
		, IMA.StockDescription
		, Case When IM.TrnType = 'R' Then IM.LotSerial Else Null End
		, Case When IM.TrnType <> 'R' And IM.LotSerial<>'' Then IM.LotSerial Else Null End
        , IM.TrnType
		,[IMA].[StockUom]
		,[IM].[UnitCost]

End

GO
