SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_UnpaidGRNAssets]
    (
      @Company Varchar(Max)
    , @PeriodYYYYMM Int
    )
As
    Begin
--exec [Report].[UspResults_UnpaidGRNAssets] @Company ='10', @PeriodYYYYMM =201504
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Compares GRN amounts and confirms how much is outstanding																///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			07/09/2015	Chris Johnson			Initial version created																///
///			07/09/2015	Chris Johnson			Changed to use of udf_SplitString to define tables to return						///
///			09/12/2015	Chris Johnson			Added uppercase to company															///
///			17/12/2015	Placeholder				created initial from template														///
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
        Declare @ListOfTables Varchar(Max) = 'GrnDetails,GrnAdjustment,GrnMatching'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GrnDets]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Grn] Varchar(20)
            , [GrnSource] Char(1)
            , [Journal] Int
            , [JournalEntry] Int
            , [DebitRecGlCode] Varchar(35)
            , [Description] Varchar(50)
            , [OrigGrnValue] Numeric(20 , 8)
            , [PurchaseOrder] Varchar(20)
            , [PurchaseOrderLin] Int
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [SupCatalogueNum] Varchar(50)
            , [Warehouse] Varchar(10)
            , [QtyReceived] Numeric(20 , 8)
            , [PostCurrency] Char(3)
            , [ConvRate] Numeric(20 , 8)
            , [MulDiv] Char(1)
            , [GrnYear] Int
            , [GrnMonth] Int
            );
        Create Table [#GrnAdjust]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Grn] Varchar(20)
            , [GrnSource] Char(1)
            , [OrigJournal] Int
            , [OrigJournalEntry] Int
            , [GrnAdjValue] Numeric(20 , 8)
            );
        Create Table [#GrnMatch]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Grn] Varchar(20)
            , [TransactionType] Char(1)
            , [Journal] Int
            , [EntryNumber] Int
            , [MatchedValue] Numeric(20 , 8)
            );

--create script to pull data from each db into the tables
        Declare @SQLGrnDets Varchar(Max) = '
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
Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + ''', @RequiredCountOfTables INT,@ActualCountOfTables INT'
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
Insert  [#GrnDets]
(DatabaseName,Supplier,Grn,GrnSource,Journal,JournalEntry,DebitRecGlCode,Description,OrigGrnValue,PurchaseOrder,PurchaseOrderLin,StockCode,StockDescription,SupCatalogueNum,Warehouse,QtyReceived,PostCurrency,ConvRate,MulDiv,GrnYear,GrnMonth)
Select  @DBCode
, Supplier,Grn,GrnSource,Journal,JournalEntry,DebitRecGlCode
, GM2.Description
, OrigGrnValue = Sum(GD.OrigGrnValue)
, PurchaseOrder, PurchaseOrderLin, StockCode, StockDescription, SupCatalogueNum, Warehouse
, QtyReceived = Sum(GD.QtyReceived)
, PostCurrency, ConvRate, MulDiv, GrnYear, GrnMonth
From    [GrnDetails] [GD] Left Join [SysproCompany40].[dbo].[GenMaster] As [GM2] On [GD].[DebitRecGlCode] = [GM2].[GlCode]
Where   ([GrnYear]*100)+[GD].[GrnMonth]<='+ Cast(@PeriodYYYYMM As NChar(6))+ '
And (Substring([GM2].[GlCode],5,5) In (''11200'',''11201'',''26001'',''26011'',''26021'',''22999'') Or (Substring([GM2].[GlCode],5,5) Like ''22%%1'' ) Or (Substring([GM2].[GlCode],5,9) = ''49900.003'' ))
And [GM2].[Company] = ''' + @Company + '''
Group By [Supplier],[Grn],[DebitRecGlCode],[GM2].[Description],[PurchaseOrder],[PurchaseOrderLin],[StockCode],[StockDescription],[SupCatalogueNum],[Warehouse],[GrnSource],[Journal],[JournalEntry],[PostCurrency],[ConvRate],[MulDiv],[GrnYear],[GrnMonth];
End
End';
        Declare @SQLGrnAdjust Varchar(Max) = '
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
		Insert  [#GrnAdjust]
				( [DatabaseName]
				, [Supplier]
				, [Grn]
				, [GrnSource]
				, [OrigJournal]
				, [OrigJournalEntry]
				, [GrnAdjValue]
				)
        Select @DBCode
			  , [GA].[Supplier]
              , [GA].[Grn]
              , [GA].[GrnSource]
              , [GA].[OrigJournal]
              , [GA].[OrigJournalEntry]
              , [GrnAdjValue] = Sum([GA].[GrnAdjValue])
        From    [GrnAdjustment] [GA] With ( NoLock )
        Where   ( [GA].[AdjYear] * 100 ) + [GA].[AdjMonth] <= '
            + Cast(@PeriodYYYYMM As NChar(6)) + '
        Group By [GA].[Supplier]
              , [GA].[Grn]
              , [GA].[GrnSource]
              , [GA].[OrigJournal]
              , [GA].[OrigJournalEntry];
			End
	End';
        Declare @SQLGrnMatch Varchar(Max) = '
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
		Insert  [#GrnMatch]
        ( [DatabaseName]
		, [Supplier]
        , [Grn]
        , [TransactionType]
        , [Journal]
        , [EntryNumber]
        , [MatchedValue]
        )
        Select @DBCode
			  , [GM].[Supplier]
              , [GM].[Grn]
              , [GM].[TransactionType]
              , [GM].[Journal]
              , [GM].[EntryNumber]
              , [MatchedValue] = Sum([GM].[MatchedValue])
        From    [GrnMatching] [GM] With ( NoLock )
        Where   [GM].[MatchedYear] * 100 + [GM].[MatchedMonth] <= '
            + Cast(@PeriodYYYYMM As NChar(6)) + '
        Group By [GM].[Supplier]
              , [GM].[Grn]
              , [GM].[TransactionType]
              , [GM].[Journal]
              , [GM].[EntryNumber];

			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        --Print @SQLGrnDets;
		Print Len(@SQLGrnDets);
        Exec [sys].[sp_MSforeachdb] @SQLGrnDets;
		Print @SQLGrnAdjust;
        Exec [sys].[sp_MSforeachdb] @SQLGrnAdjust;
		Print @SQLGrnMatch;
		Exec [sys].[sp_MSforeachdb] @SQLGrnMatch;

--define the results you want to return
        Create Table [#Results]
            (
              [GrnPeriod] Int
            , [CompanyName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Grn] Varchar(20)
            , [DebitRecGlCode] Varchar(35)
            , [Description] Varchar(50)
            , [PurchaseOrder] Varchar(20)
            , [PurchaseOrderLine] Int
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [SupCatalogueNum] Varchar(50)
            , [Warehouse] Varchar(10)
            , [QtyReceived] Numeric(20 , 8)
            , [GrnValue] Numeric(20 , 8)
            , [OrigGrnValue] Numeric(20 , 8)
            , [Matched] Numeric(20 , 8)
            , [Adjustments] Numeric(20 , 8)
            , [PostCurrency] Char(3)
            , [ConvRate] Numeric(20 , 8)
            , [MultiDiv] Char(1)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [GrnPeriod]
                , [CompanyName]
                , [Supplier]
                , [Grn]
                , [DebitRecGlCode]
                , [Description]
                , [PurchaseOrder]
                , [PurchaseOrderLine]
                , [StockCode]
                , [StockDescription]
                , [SupCatalogueNum]
                , [Warehouse]
                , [QtyReceived]
                , [GrnValue]
                , [OrigGrnValue]
                , [Matched]
                , [Adjustments]
                , [PostCurrency]
                , [ConvRate]
                , [MultiDiv]
                )
                Select  [GrnPeriod] = @PeriodYYYYMM
                      , [CN].[CompanyName]
                      , [GD].[Supplier]
                      , [GD].[Grn]
                      , [GD].[DebitRecGlCode]
                      , [GD].[Description]
                      , [GD].[PurchaseOrder]
                      , [PurchaseOrderLine] = [GD].[PurchaseOrderLin]
                      , [GD].[StockCode]
                      , [GD].[StockDescription]
                      , [GD].[SupCatalogueNum]
                      , [GD].[Warehouse]
                      , [QtyReceived] = Sum([GD].[QtyReceived])
                      , [GrnValue] = Coalesce(Sum([GD].[OrigGrnValue]) , 0)
                        - Coalesce(Sum([GM].[MatchedValue]) , 0)
                        + Coalesce(Sum([GA].[GrnAdjValue]) , 0)
                      , [OrigGrnValue] = Coalesce(Sum([GD].[OrigGrnValue]) , 0)
                      , [Matched] = Sum([GM].[MatchedValue])
                      , [Adjustments] = Sum([GA].[GrnAdjValue])
                      , [GD].[PostCurrency]
                      , [GD].[ConvRate]
                      , [MultiDiv] = [GD].[MulDiv]
                From    [#GrnDets] [GD]
                        Left Outer Join [#GrnAdjust] [GA] On [GD].[JournalEntry] = [GA].[OrigJournalEntry]
                                                             And [GD].[Journal] = [GA].[OrigJournal]
                                                             And [GD].[GrnSource] = [GA].[GrnSource]
                                                             And [GD].[Supplier] = [GA].[Supplier]
                                                             And [GD].[Grn] = [GA].[Grn]
                                                             And [GA].[DatabaseName] = [GD].[DatabaseName]
                        Left Outer Join [#GrnMatch] [GM] On [GD].[JournalEntry] = [GM].[EntryNumber]
                                                            And [GD].[Journal] = [GM].[Journal]
                                                            And [GD].[GrnSource] = [GM].[TransactionType]
                                                            And [GD].[Supplier] = [GM].[Supplier]
                                                            And [GD].[Grn] = [GM].[Grn]
                                                            And [GM].[DatabaseName] = [GD].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN] On [CN].[Company] = [GD].[DatabaseName]
                Group By [GD].[Supplier]
                      , [GD].[Grn]
                      , [GD].[DebitRecGlCode]
                      , [GD].[Description]
                      , [GD].[PurchaseOrder]
                      , [GD].[PurchaseOrderLin]
                      , [GD].[StockCode]
                      , [GD].[StockDescription]
                      , [GD].[SupCatalogueNum]
                      , [GD].[Warehouse]
                      , [GD].[PostCurrency]
                      , [GD].[ConvRate]
                      , [GD].[MulDiv]
					  , [CN].[CompanyName]
                Having  ( Sum([OrigGrnValue])
                          - IsNull(Sum(IsNull([GM].[MatchedValue] , 0)) , 0)
                          + Sum(IsNull([GA].[GrnAdjValue] , 0)) <> 0 );

        Drop Table [#GrnAdjust];
        Drop Table [#GrnMatch];
        Drop Table [#GrnDets];

--return results
        Select  [GrnPeriod]
              , [CompanyName]
              , [Supplier]
              , [Grn]
              , [DebitRecGlCode]
              , [Description]
              , [PurchaseOrder]
              , [PurchaseOrderLine]
              , [StockCode]
              , [StockDescription]
              , [SupCatalogueNum]
              , [Warehouse]
              , [QtyReceived]
              , [GrnValue]
              , [OrigGrnValue]
              , [Matched]
              , [Adjustments]
              , [PostCurrency]
              , [ConvRate]
              , [MultiDiv]
        From    [#Results];

    End;

GO
