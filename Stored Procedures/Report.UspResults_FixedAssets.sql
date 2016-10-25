SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_FixedAssets]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015	
Stored procedure set out to query multiple databases with the same information and return it in a collated format 
Exec [Report].[UspResults_FixedAssets] 10
*/
    Begin

        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;



--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_FixedAssets' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetMaster,AssetType,AssetLocation'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#AssetMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Asset] Varchar(50) Collate Latin1_General_BIN
            , [Description] Varchar(100) Collate Latin1_General_BIN
            , [AssetQty] Numeric(20 , 7)
            , [OriginalAssetQty] Numeric(20 , 7)
            , [OriginalAssetValue] Numeric(20 , 7)
            , [GlCode] Varchar(150) Collate Latin1_General_BIN
            , [AssetType] Varchar(50) Collate Latin1_General_BIN
            , [Location] Varchar(50) Collate Latin1_General_BIN
            , [AssetGroupCode] Varchar(10) Collate Latin1_General_BIN
            , [PurchaseDate] Date
            , [FirstInstalDate] Date
            , [DateSold] Date
            , [DisposedFlag] Char(1) Collate Latin1_General_BIN
            , [DisposalReason] Varchar(10) Collate Latin1_General_BIN
            );
        Create Table [#AssetType]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [AssetType] Varchar(50) Collate Latin1_General_BIN
            , [Description] Varchar(100) Collate Latin1_General_BIN
            );
        Create Table [#AssetLocation]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Location] Varchar(50) Collate Latin1_General_BIN
            , [Description] Varchar(100) Collate Latin1_General_BIN
            );
        Create Table [#AssetGroup]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [AssetGroupCode] Varchar(10) Collate Latin1_General_BIN
            , [Description] Varchar(100) Collate Latin1_General_BIN
            );
        Create Table [#AssetReasonDisp]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [DisposalReason] Varchar(10) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
				, [AssetGroupCode]
				, [PurchaseDate]		
				, [FirstInstalDate]
				, [DateSold]
				, [DisposedFlag] 
				, [DisposalReason] 
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
				, [am].[DisposedFlag] 
				, [am].[DisposalReason] 
				From [AssetMaster] As [am]
			End
	End';
        Declare @SQL2 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#AssetType]
					( [DatabaseName]
					, [AssetType]
					, [Description]
					)
				SELECT [DatabaseName]=@DBCode
					 , [at].[AssetType]
					 , [at].[Description] 
				FROM [AssetType] As [at]
			End
	End';
        Declare @SQL3 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
        Declare @SQL4 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
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
        Declare @SQL5 Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
			Insert  [#AssetReasonDisp]
                ( [DatabaseName]
                , [DisposalReason]
                , [Description]
                )
                Select  @DBCode
                      , [ARD].[DisposalReason]
                      , [ARD].[Description]
                From    [AssetReasonDisp] [ARD];
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL1 ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL2 ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL3 ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL4 ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL5 ,
            @SchemaTablesToCheck = @ListOfTables;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Asset] Varchar(50) Collate Latin1_General_BIN
            , [Description] Varchar(100) Collate Latin1_General_BIN
            , [Location] Varchar(100) Collate Latin1_General_BIN
            , [AssetType] Varchar(100) Collate Latin1_General_BIN
            , [AssetQty] Numeric(20 , 7)
            , [OriginalAssetQty] Numeric(20 , 7)
            , [OriginalAssetValue] Numeric(20 , 7)
            , [GlCode] Varchar(150) Collate Latin1_General_BIN
            , [AssetGroup] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseDate] Date
            , [FirstInstalDate] Date
            , [DateSold] Date
            , [DisposedFlag] Char(1) Collate Latin1_General_BIN
            , [DisposalReason] Varchar(50) Collate Latin1_General_BIN
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
                , [DisposedFlag]
                , [DisposalReason]		
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
                      , [DisposedFlag] = Case When [am].[DisposedFlag] = ''
                                              Then Null
                                              Else [am].[DisposedFlag]
                                         End
                      , [ARD].[Description]
                From    [#AssetMaster] As [am]
                        Left Join [#AssetType] As [at]
                            On [at].[AssetType] = [am].[AssetType]
                               And [at].[DatabaseName] = [am].[DatabaseName]
                        Left Join [#AssetLocation] As [al]
                            On [al].[Location] = [am].[Location]
                               And [al].[DatabaseName] = [am].[DatabaseName]
                        Left Join [#AssetGroup] As [ag]
                            On [ag].[AssetGroupCode] = [am].[AssetGroupCode]
                               And [ag].[DatabaseName] = [am].[DatabaseName]
                        Left Join [#AssetReasonDisp] [ARD]
                            On [ARD].[DisposalReason] = [am].[DisposalReason];

        Set NoCount Off;
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
              , [r].[DisposedFlag]
              , [r].[DisposalReason]
        From    [#Results] [r]
                Left Join [Lookups].[CompanyNames] As [cn]
                    On [r].[DatabaseName] = [cn].[Company];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'details of all fixed assets', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_FixedAssets', NULL, NULL
GO
