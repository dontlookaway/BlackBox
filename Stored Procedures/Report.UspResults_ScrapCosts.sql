
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ScrapCosts]
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
--exec [Report].[UspResults_ScrapCosts] '10'
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
            @StoredProcName = 'UspResults_ScrapCosts' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvInspect,InvInspectDet'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvInspect]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Lot] Varchar(50) Collate Latin1_General_BIN
            , [QtyScrapped] Numeric(20 , 8)
            , [StockCode] Varchar(50)
            , [PoPrice] Numeric(20 , 8)
            , [PriceUom] Varchar(10)
            , [PrcFactor] Char(1)
            , [ConvFactPrcUom] Int
            , [ConvFactOrdUom] Int
            , [Grn] Varchar(50) Collate Latin1_General_BIN
            );
        Create Table [#InvInspectDet]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [TrnQty] Numeric(20 , 8)
            , [TrnDate] Date
            , [RejectScrapCode] Varchar(50)
            , [TrnType] Char(1)
            , [Grn] Varchar(50) Collate Latin1_General_BIN
            , [Lot] Varchar(50) Collate Latin1_General_BIN
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
	End';
        Declare @SQL2 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Lot] Varchar(35) Collate Latin1_General_BIN
            , [TotalScrapped] Numeric(20 , 8)
            , [TrnQty] Numeric(20 , 8)
            , [StockCode] Varchar(50)
            , [PoPrice] Numeric(20 , 8)
            , [TrnDate] Date
            , [PriceUom] Varchar(10)
            , [PrcFactor] Char(1)
            , [TotalValue] Numeric(20 , 8)
            , [Value] Numeric(20 , 8)
            , [RejectScrapCode] Varchar(50)
            , [ConvFactPrcUom] Int
            , [ConvFactOrdUom] Int
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
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
                Select  [ii].[DatabaseName]
                      , [ii].[Lot]
                      , [TotalScrapped] = [ii].[QtyScrapped]
                      , [iid].[TrnQty]
                      , [ii].[StockCode]
                      , [ii].[PoPrice]
                      , [iid].[TrnDate]
                      , [ii].[PriceUom]
                      , [ii].[PrcFactor]
                      , [TotalValue] = [ii].[PoPrice] * [ii].[QtyScrapped]
                      , [Value] = [ii].[PoPrice] * [iid].[TrnQty]
                      , [iid].[RejectScrapCode]
                      , [ii].[ConvFactPrcUom]
                      , [ii].[ConvFactOrdUom]
                From    [#InvInspect] As [ii]
                        Inner Join [#InvInspectDet] As [iid] On [iid].[Grn] = [ii].[Grn]
                                                              And [iid].[Lot] = [ii].[Lot]
                                                              And [iid].[DatabaseName] = [ii].[DatabaseName];



--return results
        Select  [cn].[CompanyName]
              , [r].[Lot]
              , [r].[TotalScrapped]
              , [r].[TrnQty]
              , [r].[StockCode]
              , [r].[PoPrice]
              , [r].[TrnDate]
              , [r].[PriceUom]
              , [r].[PrcFactor]
              , [r].[TotalValue]
              , [r].[Value]
              , [r].[RejectScrapCode]
              , [r].[ConvFactPrcUom]
              , [r].[ConvFactOrdUom]
        From    [#Results] As [r]
                Left Join [Lookups].[CompanyNames] As [cn] On [r].[DatabaseName] = [cn].[Company];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'list of scrap costs', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ScrapCosts', NULL, NULL
GO
