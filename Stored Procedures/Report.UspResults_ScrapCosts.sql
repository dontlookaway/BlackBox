SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ScrapCosts]
(@Company VARCHAR(Max))
--exec [Report].[UspResults_ScrapCosts] '10'
As
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
///			23/10/2015	Chris Johnson			Initial version created																///
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
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'InvInspect,InvInspectDet' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #InvInspect
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[Lot] VARCHAR(50) Collate Latin1_General_BIN
		,[QtyScrapped] NUMERIC(20,8)
		,[StockCode] VARCHAR(50)
		,[PoPrice] NUMERIC(20,8)
		,[PriceUom] VARCHAR(10)
		,[PrcFactor] CHAR(1)
		,[ConvFactPrcUom] INT
		,[ConvFactOrdUom] INT
		,[Grn] VARCHAR(50) Collate Latin1_General_BIN
	)
	CREATE TABLE #InvInspectDet
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[TrnQty] NUMERIC(20,8)
		,[TrnDate] DATE
		,[RejectScrapCode] VARCHAR(50)
		,[TrnType] CHAR(1)
		,[Grn] VARCHAR(50) Collate Latin1_General_BIN
		,[Lot] VARCHAR(50) Collate Latin1_General_BIN
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
			Insert [#InvInspect]
					( [DatabaseName]
					, [Lot]
					, [QtyScrapped]
					, [StockCode]
					, [PoPrice]
					, [PriceUom]
					, [PrcFactor]
					, [ConvFactPrcUom]
					, [ConvFactOrdUom]
					, [Grn]
					)
			SELECT [DatabaseName]=@DBCode
				 , [ii].[Lot]
				 , [ii].[QtyScrapped]
				 , [ii].[StockCode]
				 , [ii].[PoPrice]
				 , [ii].[PriceUom]
				 , [ii].[PrcFactor]
				 , [ii].[ConvFactPrcUom]
				 , [ii].[ConvFactOrdUom] 
				 , [Grn]
			From [InvInspect] As [ii]
			where [ii].[QtyScrapped]<>0
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
			Insert [#InvInspectDet]
					( [DatabaseName]
					, [TrnQty]
					, [TrnDate]
					, [RejectScrapCode]
					, [TrnType]
					,[Grn]
					,[Lot] 
					)
			SELECT [DatabaseName]=@DBCode
				 , [iid].[TrnQty]
				 , [iid].[TrnDate]
				 , [iid].[RejectScrapCode]
				 , [iid].[TrnType] 
				 ,[Grn]
				 ,[Lot] 
			From [InvInspectDet] As [iid]
			where [iid].[TrnType]=''S''
			End
	End'
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1;
	Exec sp_MSforeachdb @SQL2;

--define the results you want to return
	Create Table #Results
	(DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[Lot] VARCHAR(35) Collate Latin1_General_BIN
     , [TotalScrapped] NUMERIC(20,8)
     , [TrnQty] NUMERIC(20,8)
     , [StockCode] VARCHAR(50)
     , [PoPrice] NUMERIC(20,8)
     , [TrnDate] DATE
     , [PriceUom] VARCHAR(10)
     , [PrcFactor] CHAR(1)
     , [TotalValue] NUMERIC(20,8)
     , [Value] NUMERIC(20,8)
     , [RejectScrapCode] VARCHAR(50)
     , [ConvFactPrcUom] INT
     , [ConvFactOrdUom] INT)

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert [#Results]
	        ( [DatabaseName]
	        , [Lot]
	        , [TotalScrapped]
	        , [TrnQty]
	        , [StockCode]
	        , [PoPrice]
	        , [TrnDate]
	        , [PriceUom]
	        , [PrcFactor]
	        , [TotalValue]
	        , [Value]
	        , [RejectScrapCode]
	        , [ConvFactPrcUom]
	        , [ConvFactOrdUom]
	        )
	Select   [ii].[DatabaseName]
		,[ii] .[Lot]
		,TotalScrapped		= [ii].[QtyScrapped]
		,[iid].[TrnQty]
		,[ii] .[StockCode]
		,[ii] .[PoPrice]
		,[iid].[TrnDate]
		,[ii] .[PriceUom]
		,[ii] .[PrcFactor]
		,TotalValue			= [ii].[PoPrice]
								*[ii].[QtyScrapped]
		,Value				= [ii].[PoPrice]
								*[iid].[TrnQty]
		,[iid].[RejectScrapCode]
		,[ii] .[ConvFactPrcUom]
		,[ii] .[ConvFactOrdUom]
From		[#InvInspect]		As [ii]
Inner Join	[#InvInspectDet]	As [iid] On [iid].[Grn] = [ii].[Grn] AND [iid].[Lot] = [ii].[Lot] And [iid].[DatabaseName] = [ii].[DatabaseName]



--return results
	SELECT [cn].[CompanyName]
	 , [Lot]
     , [TotalScrapped]
     , [TrnQty]
     , [StockCode]
     , [PoPrice]
     , [TrnDate]
     , [PriceUom]
     , [PrcFactor]
     , [TotalValue]
     , [Value]
     , [RejectScrapCode]
     , [ConvFactPrcUom]
     , [ConvFactOrdUom] 
From [#Results] As [r]
Left Join [Lookups].[CompanyNames] As [cn] On [r].[DatabaseName]=[cn].[Company]

End

GO
