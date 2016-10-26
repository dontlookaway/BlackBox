SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_UnpaidGRNAssets]
    (
      @Company Varchar(Max)
    , @PeriodYYYYMM Int
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015														///
Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
Compares GRN amounts and confirms how much is outstanding																
--exec [Report].[UspResults_UnpaidGRNAssets] @Company ='10', @PeriodYYYYMM =201504
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
            @StoredProcName = 'UspResults_UnpaidGRNAssets' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'GrnDetails,GrnAdjustment,GrnMatching'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GrnDets]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Supplier] Varchar(15)				collate latin1_general_bin
            , [Grn] Varchar(20)						collate latin1_general_bin
            , [GrnSource] Char(1)					collate latin1_general_bin
            , [Journal] Int							
            , [JournalEntry] Int					
            , [DebitRecGlCode] Varchar(35)			collate latin1_general_bin
            , [Description] Varchar(50)				collate latin1_general_bin
            , [OrigGrnValue] Numeric(20 , 8)		
            , [PurchaseOrder] Varchar(20)			collate latin1_general_bin
            , [PurchaseOrderLin] Int				
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [StockDescription] Varchar(50)		collate latin1_general_bin
            , [SupCatalogueNum] Varchar(50)			collate latin1_general_bin
            , [Warehouse] Varchar(10)				collate latin1_general_bin
            , [QtyReceived] Numeric(20 , 8)			
            , [PostCurrency] Char(3)				collate latin1_general_bin
            , [ConvRate] Numeric(20 , 8)			
            , [MulDiv] Char(1)						
            , [GrnYear] Int							
            , [GrnMonth] Int						
            );										
        Create Table [#GrnAdjust]					
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Supplier] Varchar(15)				collate latin1_general_bin
            , [Grn] Varchar(20)						collate latin1_general_bin
            , [GrnSource] Char(1)					collate latin1_general_bin
            , [OrigJournal] Int						
            , [OrigJournalEntry] Int				
            , [GrnAdjValue] Numeric(20 , 8)			
            );										
        Create Table [#GrnMatch]					
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Supplier] Varchar(15)				collate latin1_general_bin
            , [Grn] Varchar(20)						collate latin1_general_bin
            , [TransactionType] Char(1)				collate latin1_general_bin
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
Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + ''', @RequiredCountOfTables INT,@ActualCountOfTables INT'
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
Where   ([GrnYear]*100)+[GD].[GrnMonth]<=' + Cast(@PeriodYYYYMM As NChar(6))
            + '
And (Substring([GM2].[GlCode],5,5) In (''11200'',''11201'',''26001'',''26011'',''26021'',''22999'') Or (Substring([GM2].[GlCode],5,5) Like ''22%%1'' ) Or (Substring([GM2].[GlCode],5,9) = ''49900.003'' ))
And [GM2].[Company] = ''' + @Company
            + '''
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
		--Print Len(@SQLGrnDets);
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrnDets;
		--Print @SQLGrnAdjust;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrnAdjust;
		--Print @SQLGrnMatch;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrnMatch;

--define the results you want to return
        Create Table [#Results]
            (
              [GrnPeriod] Int
            , [CompanyName] Varchar(150)		collate latin1_general_bin
            , [Supplier] Varchar(15)			collate latin1_general_bin
            , [Grn] Varchar(20)					collate latin1_general_bin
            , [DebitRecGlCode] Varchar(35)		collate latin1_general_bin
            , [Description] Varchar(50)			collate latin1_general_bin
            , [PurchaseOrder] Varchar(20)		collate latin1_general_bin
            , [PurchaseOrderLine] Int			
            , [StockCode] Varchar(30)			collate latin1_general_bin
            , [StockDescription] Varchar(50)	collate latin1_general_bin
            , [SupCatalogueNum] Varchar(50)		collate latin1_general_bin
            , [Warehouse] Varchar(10)			collate latin1_general_bin
            , [QtyReceived] Numeric(20 , 8)		
            , [GrnValue] Numeric(20 , 8)		
            , [OrigGrnValue] Numeric(20 , 8)	
            , [Matched] Numeric(20 , 8)			
            , [Adjustments] Numeric(20 , 8)		
            , [PostCurrency] Char(3)			collate latin1_general_bin
            , [ConvRate] Numeric(20 , 8)		
            , [MultiDiv] Char(1)				collate latin1_general_bin
            , [ShortName] Varchar(250)			collate latin1_general_bin
            );

--Placeholder to create indexes as required

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
                , [ShortName]
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
                      , [CN].[ShortName]
                From    [#GrnDets] [GD]
                        Left Outer Join [#GrnAdjust] [GA]
                            On [GD].[JournalEntry] = [GA].[OrigJournalEntry]
                               And [GD].[Journal] = [GA].[OrigJournal]
                               And [GD].[GrnSource] = [GA].[GrnSource]
                               And [GD].[Supplier] = [GA].[Supplier]
                               And [GD].[Grn] = [GA].[Grn]
                               And [GA].[DatabaseName] = [GD].[DatabaseName]
                        Left Outer Join [#GrnMatch] [GM]
                            On [GD].[JournalEntry] = [GM].[EntryNumber]
                               And [GD].[Journal] = [GM].[Journal]
                               And [GD].[GrnSource] = [GM].[TransactionType]
                               And [GD].[Supplier] = [GM].[Supplier]
                               And [GD].[Grn] = [GM].[Grn]
                               And [GM].[DatabaseName] = [GD].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                            On [CN].[Company] = [GD].[DatabaseName]
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
                      , [CN].[ShortName]
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
              , [ShortName]
        From    [#Results];

    End;

GO
