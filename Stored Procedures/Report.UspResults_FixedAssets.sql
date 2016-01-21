SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_FixedAssets]
(@Company VARCHAR(Max))
As --Exec [Report].[UspResults_FixedAssets] 10
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
///			9/10/2015	Chris Johnson			Initial version created																///
///			23/11/2015	Chris Johnson			Added dates 
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
Declare @ListOfTables VARCHAR(max) = 'AssetMaster,AssetType,AssetLocation' 

--create temporary tables to be pulled from different databases, including a column to id
    Create Table #AssetMaster
        (
          DatabaseName VARCHAR(150)
        , [Asset] VARCHAR(50)
        , [Description] VARCHAR(100)
        , [AssetQty] NUMERIC(20, 7)
        , [OriginalAssetQty] NUMERIC(20, 7)
        , [OriginalAssetValue] NUMERIC(20, 7)
        , [GlCode] VARCHAR(150)
        , [AssetType] VARCHAR(50)
        , [Location] VARCHAR(50)
		, [AssetGroupCode] VARCHAR(10)
		, PurchaseDate Date
		, FirstInstalDate Date
		, DateSold Date
        );
    Create Table #AssetType
        (
          DatabaseName VARCHAR(150)
        , [AssetType] VARCHAR(50)
        , [Description] VARCHAR(100)
        );
    Create Table #AssetLocation
        (
          DatabaseName VARCHAR(150)
        , [Location] VARCHAR(50)
        , [Description] VARCHAR(100)
        );
	Create Table #AssetGroup
	(DatabaseName VARCHAR(150)
	,[AssetGroupCode] VARCHAR(10)
	,[Description] VARCHAR(100))





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
				Insert [#AssetMaster]
				( [DatabaseName]
				, [Asset]
				, [Description]
				, [AssetQty]
				, [OriginalAssetQty]
				, [OriginalAssetValue]
				, [GlCode]
				, [AssetType]
				, [Location]
				,[AssetGroupCode]
				, PurchaseDate		
				, FirstInstalDate 
				, DateSold	
				)
				SELECT [DatabaseName] = @DBCode
				, [am].[Asset]
				, [am].[Description]
				, [am].[AssetQty]
				, [am].[OriginalAssetQty]
				, [am].[OriginalAssetValue]
				, [am].[GlCode]
				, [am].[AssetType]
				, [am].[Location] 
				, [am].[AssetGroupCode]
				, [am].PurchaseDate		
				, [am].FirstInstalDate 
				, [am].DateSold
				From [AssetMaster] As [am]
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
						Insert [#AssetType]
		        ( [DatabaseName]
		        , [AssetType]
		        , [Description]
		        )
		SELECT [DatabaseName]=@DBCode
             , [at].[AssetType]
             , [at].[Description] FROM [AssetType] As [at]
			End
	End'
	Declare @SQL3 VARCHAR(max) = '
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
						Insert [#AssetLocation]
		        ( [DatabaseName]
		        , [Location]
		        , [Description]
		        )
		SELECT [DatabaseName]=@DBCode
             , [al].[Location]
             , [al].[Description] 
		FROM [AssetLocation] As [al]
			End
	End'
		Declare @SQL4 VARCHAR(max) = '
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
			Insert [#AssetGroup]
	        ( [DatabaseName]
	        , [AssetGroupCode]
	        , [Description]
	        )
			SELECT   @DBCode
					,[ag].[AssetGroupCode]
					,[ag].[Description]
			 FROM [dbo].[AssetGroup] As [ag]
			End
	End'
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Print 1
	Exec sp_MSforeachdb @SQL1
	Print 2
	Exec sp_MSforeachdb @SQL2
	Print 3
	Exec  sp_MSforeachdb @SQL3
	Print 4
	Exec  sp_MSforeachdb @SQL4
	Print 5
--define the results you want to return
	Create Table #Results
	(DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[Asset]  VARCHAR(50)
      , [Description] VARCHAR(100)
      , [Location] VARCHAR(100)
      , [AssetType] VARCHAR(100)
      , [AssetQty] NUMERIC(20,7)
	  , [OriginalAssetQty] NUMERIC(20,7)
      , [OriginalAssetValue] NUMERIC(20,7)
      , [GlCode] VARCHAR(150)
	  , [AssetGroup] VARCHAR(150)
	  , PurchaseDate Date
	  , FirstInstalDate Date
	  , DateSold Date
	  )

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert [#Results]
	        ( [DatabaseName]
	        , [Asset]
	        , [Description]
	        , [Location]
	        , [AssetType]
	        , [AssetQty]
	        , [OriginalAssetQty]
	        , [OriginalAssetValue]
	        , [GlCode]
			, [AssetGroup]
			, PurchaseDate		
			, FirstInstalDate 
			, DateSold			
	        )
SELECT   [am].[DatabaseName]
		,[am].[Asset]
		,[am].[Description]
		,[Location]=al.[Description]
		,[AssetType] = [at].[Description]
		,[am].[AssetQty]
		,[am].[OriginalAssetQty]
		,[am].[OriginalAssetValue]
		,[am].[GlCode]
		,[ag].[Description]
		,[am].PurchaseDate		
		,[am].FirstInstalDate 
		,[am].DateSold		
 FROM [#AssetMaster] As [am]
 Left Join [#AssetType] As [at] 
		On [at].[AssetType] = [am].[AssetType]
		And [at].[DatabaseName] = [am].[DatabaseName]
 Left Join [#AssetLocation] As [al] 
		On [al].[Location] = [am].[Location]	
		And [al].[DatabaseName] = [am].[DatabaseName]
Left Join [#AssetGroup] As [ag]
		On [ag].[AssetGroupCode] = [am].[AssetGroupCode]
		And [ag].[DatabaseName] = [am].[DatabaseName]

--return results
	SELECT [cn].[CompanyName]
         , [r].[Asset]
         , [r].[Description]
         , [r].[Location]
         , [r].[AssetType]
         , [r].[AssetQty]
         , [r].[OriginalAssetQty]
         , [r].[OriginalAssetValue]
         , [r].[GlCode]
		 , [AssetGroup]
		 , r.PurchaseDate
		 , r.FirstInstalDate
		 , r.DateSold
		  FROM #Results r Left Join [Lookups].[CompanyNames] As [cn] On [r].[DatabaseName]=[cn].[Company]

End

GO
