
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_FixedAssets] ( @Company Varchar(Max) )
As 
/*
Template designed by Chris Johnson, Prometic Group September 2015	
Stored procedure set out to query multiple databases with the same information and return it in a collated format 
Exec [Report].[UspResults_FixedAssets] 10
*/
    Begin

        Set NoCount Off;
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetMaster,AssetType,AssetLocation'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#AssetMaster]
            (
              [DatabaseName] Varchar(150)
            , [Asset] Varchar(50)
            , [Description] Varchar(100)
            , [AssetQty] Numeric(20 , 7)
            , [OriginalAssetQty] Numeric(20 , 7)
            , [OriginalAssetValue] Numeric(20 , 7)
            , [GlCode] Varchar(150)
            , [AssetType] Varchar(50)
            , [Location] Varchar(50)
            , [AssetGroupCode] Varchar(10)
            , [PurchaseDate] Date
            , [FirstInstalDate] Date
            , [DateSold] Date
            );
        Create Table [#AssetType]
            (
              [DatabaseName] Varchar(150)
            , [AssetType] Varchar(50)
            , [Description] Varchar(100)
            );
        Create Table [#AssetLocation]
            (
              [DatabaseName] Varchar(150)
            , [Location] Varchar(50)
            , [Description] Varchar(100)
            );
        Create Table [#AssetGroup]
            (
              [DatabaseName] Varchar(150)
            , [AssetGroupCode] Varchar(10)
            , [Description] Varchar(100)
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
						Insert [#AssetType]
		        ( [DatabaseName]
		        , [AssetType]
		        , [Description]
		        )
		SELECT [DatabaseName]=@DBCode
             , [at].[AssetType]
             , [at].[Description] FROM [AssetType] As [at]
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
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Print 1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Print 2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Print 3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Print 4;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
        Print 5;
--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Asset] Varchar(50)
            , [Description] Varchar(100)
            , [Location] Varchar(100)
            , [AssetType] Varchar(100)
            , [AssetQty] Numeric(20 , 7)
            , [OriginalAssetQty] Numeric(20 , 7)
            , [OriginalAssetValue] Numeric(20 , 7)
            , [GlCode] Varchar(150)
            , [AssetGroup] Varchar(150)
            , [PurchaseDate] Date
            , [FirstInstalDate] Date
            , [DateSold] Date
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  [#Results]
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
                , [PurchaseDate]
                , [FirstInstalDate]
                , [DateSold]			
	            )
                Select  [am].[DatabaseName]
                      , [am].[Asset]
                      , [am].[Description]
                      , [Location] = [al].[Description]
                      , [AssetType] = [at].[Description]
                      , [am].[AssetQty]
                      , [am].[OriginalAssetQty]
                      , [am].[OriginalAssetValue]
                      , [am].[GlCode]
                      , [ag].[Description]
                      , [am].[PurchaseDate]
                      , [am].[FirstInstalDate]
                      , [am].[DateSold]
                From    [#AssetMaster] As [am]
                        Left Join [#AssetType] As [at] On [at].[AssetType] = [am].[AssetType]
                                                          And [at].[DatabaseName] = [am].[DatabaseName]
                        Left Join [#AssetLocation] As [al] On [al].[Location] = [am].[Location]
                                                              And [al].[DatabaseName] = [am].[DatabaseName]
                        Left Join [#AssetGroup] As [ag] On [ag].[AssetGroupCode] = [am].[AssetGroupCode]
                                                           And [ag].[DatabaseName] = [am].[DatabaseName];

--return results
        Select  [cn].[CompanyName]
              , [r].[Asset]
              , [r].[Description]
              , [r].[Location]
              , [r].[AssetType]
              , [r].[AssetQty]
              , [r].[OriginalAssetQty]
              , [r].[OriginalAssetValue]
              , [r].[GlCode]
              , [r].[AssetGroup]
              , [r].[PurchaseDate]
              , [r].[FirstInstalDate]
              , [r].[DateSold]
        From    [#Results] [r]
                Left Join [Lookups].[CompanyNames] As [cn] On [r].[DatabaseName] = [cn].[Company];

    End;

GO
