SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ApGlDisburse]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

        Declare @CompanyCommas Varchar(Max) = Replace(@Company , ',' , ''',''');


--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_Template' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApGlDisburse'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApGlDisburse]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [DistrEntry] Int
            , [GlCode] Varchar(35) Collate Latin1_General_BIN
            , [GlIntPeriod] Int
            , [GlIntYear] Int
            , [GlJournal] BigInt
            , [GlPeriod] Int
            , [GlYear] Int
            , [PostConvRate] Float
            , [PostCurrency] Varchar(10) Collate Latin1_General_BIN
            , [PostMulDiv] Varchar(10) Collate Latin1_General_BIN
            , [SupplierName] Varchar(50) Collate Latin1_General_BIN
            , [Supplier] Varchar(15) Collate Latin1_General_BIN
            , [TriangConvRate] Float
            , [TriangCurrency] Varchar(10) Collate Latin1_General_BIN
            , [TriangMulDiv] Varchar(5) Collate Latin1_General_BIN
            , [TrnValue] Numeric(20 , 3)
            , [Invoice] Varchar(20) Collate Latin1_General_BIN
            );

		
	

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + @CompanyCommas + ''') or ''' + @Company
            + ''' = ''ALL''
			BEGIN
				Insert [#ApGlDisburse]
						( [DatabaseName]
						, [DistrEntry]
						, [GlCode]
						, [GlIntPeriod]
						, [GlIntYear]
						, [GlJournal]
						, [GlPeriod]
						, [GlYear]
						, [PostConvRate]
						, [PostCurrency]
						, [PostMulDiv]
						, [SupplierName]
						, [Supplier]
						, [TriangConvRate]
						, [TriangCurrency]
						, [TriangMulDiv]
						, [TrnValue]
						, [Invoice]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AGD].[DistrEntry]
					 , [AGD].[GlCode]
					 , [AGD].[GlIntPeriod]
					 , [AGD].[GlIntYear]
					 , [AGD].[GlJournal]
					 , [AGD].[GlPeriod]
					 , [AGD].[GlYear]
					 , [AGD].[PostConvRate]
					 , [AGD].[PostCurrency]
					 , [AGD].[PostMulDiv]
					 , [AGD].[SupplierName]
					 , [AGD].[Supplier]
					 , [AGD].[TriangConvRate]
					 , [AGD].[TriangCurrency]
					 , [AGD].[TriangMulDiv]
					 , [AGD].[TrnValue]
					 , [AGD].[Invoice]
				FROM [ApGlDisburse] [AGD]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return
        

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        

        Set NoCount Off;
--return results
        Select  [AGD].[DatabaseName]
              , [AGD].[DistrEntry]
              , [AGD].[GlCode]
              , [AGD].[GlIntPeriod]
              , [AGD].[GlIntYear]
              , [AGD].[GlJournal]
              , [AGD].[GlPeriod]
              , [AGD].[GlYear]
              , [AGD].[PostConvRate]
              , [AGD].[PostCurrency]
              , [AGD].[PostMulDiv]
              , [AGD].[SupplierName]
              , [AGD].[Supplier]
              , [AGD].[TriangConvRate]
              , [AGD].[TriangCurrency]
              , [AGD].[TriangMulDiv]
              , [AGD].[TrnValue]
              , [AGD].[Invoice]
        From    [#ApGlDisburse] [AGD];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'details of the general ledger distribution from accounts payable', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ApGlDisburse', NULL, NULL
GO
