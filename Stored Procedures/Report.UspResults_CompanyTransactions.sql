SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_CompanyTransactions]
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
            @StoredProcName = 'UspResults_CompanyTransactions' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GenJournalDetail]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Journal] Int
            , [GlYear] Int
            , [GlPeriod] Int
            , [EntryNumber] Int
            , [EntryType] Char(1)				collate latin1_general_bin
            , [GlCode] Varchar(35)				collate latin1_general_bin
            , [Reference] Varchar(50)			collate latin1_general_bin
            , [Comment] Varchar(250)			collate latin1_general_bin
            , [EntryValue] Numeric(20 , 2)
            , [EntryDate] Date
            , [EntryPosted] Char(1)				collate latin1_general_bin
            );
        Create Table [#GenJournalCtl]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [JnlPrintFlag] Char(1)			collate latin1_general_bin
            , [JournalDate] Date				
            , [NumOfEntries] Int				
            , [DebitAmount] Numeric(20 , 2)		
            , [CreditAmount] Numeric(20 , 2)	
            , [JnlPostingType] Char(1)			collate latin1_general_bin
            , [Source] Char(1)					collate latin1_general_bin
            , [Operator] Varchar(20)			collate latin1_general_bin
            , [JnlStatus] Char(1)				collate latin1_general_bin
            , [Reference] Varchar(30)			collate latin1_general_bin
            , [AuthorisedBy] Varchar(20)		collate latin1_general_bin
            , [PostedBy] Varchar(20)			collate latin1_general_bin
            , [Authorised] Char(1)				collate latin1_general_bin
            , [PostDate] Date					
            , [Notation] Varchar(100)			collate latin1_general_bin
            , [GlJournal] Int
            , [GlPeriod] Int
            , [GlYear] Int
            , [JournalSource] Char(2)			collate latin1_general_bin
            );
	
--create script to pull data from each db into the tables
        Declare @SQLGenJournalDetail Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
					Insert [#GenJournalDetail]
							( [DatabaseName]
							, [Journal]
							, [GlYear]
							, [GlPeriod]
							, [EntryNumber]
							, [EntryType]
							, [GlCode]
							, [Reference]
							, [Comment]
							, [EntryValue]
							, [EntryDate]
							, [EntryPosted]
							)
					SELECT [DatabaseName]=@DBCode
						 , [GJD].[Journal]
						 , [GJD].[GlYear]
						 , [GJD].[GlPeriod]
						 , [GJD].[EntryNumber]
						 , [GJD].[EntryType]
						 , [GJD].[GlCode]
						 , [GJD].[Reference]
						 , [GJD].[Comment]
						 , [GJD].[EntryValue]
						 , [GJD].[EntryDate]
						 , [GJD].[EntryPosted] FROM [GenJournalDetail] As [GJD]
			End
	End';
        Declare @SQLGenJournalCtl Varchar(Max) = '
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
					Insert [#GenJournalCtl]
							( [DatabaseName]
							, [JnlPrintFlag]
							, [JournalDate]
							, [NumOfEntries]
							, [DebitAmount]
							, [CreditAmount]
							, [JnlPostingType]
							, [Source]
							, [Operator]
							, [JnlStatus]
							, [Reference]
							, [AuthorisedBy]
							, [PostedBy]
							, [Authorised]
							, [PostDate]
							, [Notation]
							, [GlJournal]
							, [GlPeriod]
							, [GlYear]
							, [JournalSource]
							)
					SELECT [DatabaseName]=@DBCode
						 , [GJC].[JnlPrintFlag]
						 , [GJC].[JournalDate]
						 , [GJC].[NumOfEntries]
						 , [GJC].[DebitAmount]
						 , [GJC].[CreditAmount]
						 , [GJC].[JnlPostingType]
						 , [GJC].[Source]
						 , [GJC].[Operator]
						 , [GJC].[JnlStatus]
						 , [GJC].[Reference]
						 , [GJC].[AuthorisedBy]
						 , [GJC].[PostedBy]
						 , [GJC].[Authorised]
						 , [GJC].[PostDate]
						 , [GJC].[Notation]
						 , [GJC].[GlJournal]
						 , [GJC].[GlPeriod]
						 , [GJC].[GlYear]
						 , [GJC].[JournalSource] FROM [GenJournalCtl] As [GJC]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQLGenJournalCtl
--Print @SQLGenJournalDetail

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLGenJournalCtl;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGenJournalDetail;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Journal] Int						
            , [GlYear] Int						
            , [GlPeriod] Int					
            , [EntryNumber] Int					
            , [EntryType] Char(1)				collate latin1_general_bin
            , [GlCode] Varchar(35)				collate latin1_general_bin
            , [Reference] Varchar(50)			collate latin1_general_bin
            , [Comment] Varchar(250)			collate latin1_general_bin
            , [EntryValue] Numeric(20 , 2)		
            , [EntryDate] Date					
            , [EntryPosted] Char(1)				collate latin1_general_bin
            , [JnlPrintFlag] Char(1)			collate latin1_general_bin
            , [JournalDate] Date				
            , [NumOfEntries] Int				
            , [DebitAmount] Numeric(20 , 2)		
            , [CreditAmount] Numeric(20 , 2)	
            , [JnlPostingType] Char(1)			collate latin1_general_bin
            , [Source] Char(1)					collate latin1_general_bin
            , [Operator] Varchar(20)			collate latin1_general_bin
            , [JnlStatus] Char(1)				collate latin1_general_bin
            , [AuthorisedBy] Varchar(20)		collate latin1_general_bin
            , [PostedBy] Varchar(20)			collate latin1_general_bin
            , [Authorised] Char(1)				collate latin1_general_bin
            , [PostDate] Date					
            , [Notation] Varchar(100)			collate latin1_general_bin
            , [JournalSource] Char(2)			collate latin1_general_bin
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Journal]
                , [GlYear]
                , [GlPeriod]
                , [EntryNumber]
                , [EntryType]
                , [GlCode]
                , [Reference]
                , [Comment]
                , [EntryValue]
                , [EntryDate]
                , [EntryPosted]
                , [JnlPrintFlag]
                , [JournalDate]
                , [NumOfEntries]
                , [DebitAmount]
                , [CreditAmount]
                , [JnlPostingType]
                , [Source]
                , [Operator]
                , [JnlStatus]
                , [AuthorisedBy]
                , [PostedBy]
                , [Authorised]
                , [PostDate]
                , [Notation]
                , [JournalSource]
                )
                Select  [GJD].[DatabaseName]
                      , [GJD].[Journal]
                      , [GJD].[GlYear]
                      , [GJD].[GlPeriod]
                      , [GJD].[EntryNumber]
                      , [GJD].[EntryType]
                      , [GJD].[GlCode]
                      , [GJD].[Reference]
                      , [GJD].[Comment]
                      , [GJD].[EntryValue]
                      , [GJD].[EntryDate]
                      , [GJD].[EntryPosted]
                      , [GJC].[JnlPrintFlag]
                      , [GJC].[JournalDate]
                      , [GJC].[NumOfEntries]
                      , [GJC].[DebitAmount]
                      , [GJC].[CreditAmount]
                      , [GJC].[JnlPostingType]
                      , [GJC].[Source]
                      , [GJC].[Operator]
                      , [GJC].[JnlStatus]
                      , [GJC].[AuthorisedBy]
                      , [GJC].[PostedBy]
                      , [GJC].[Authorised]
                      , [GJC].[PostDate]
                      , [GJC].[Notation]
                      , [GJC].[JournalSource]
                From    [#GenJournalDetail] As [GJD]
                        Left Join [#GenJournalCtl] As [GJC]
                            On [GJC].[GlJournal] = [GJD].[Journal]
                               And [GJC].[GlPeriod] = [GJD].[GlPeriod]
                               And [GJC].[GlYear] = [GJD].[GlYear]
                               And [GJC].[DatabaseName] = [GJD].[DatabaseName];

--return results
        Select  [R].[DatabaseName]
              , [CN].[CompanyName]
              , [R].[Journal]
              , [R].[GlYear]
              , [R].[GlPeriod]
              , [R].[EntryNumber]
              , [R].[EntryType]
              , [R].[GlCode]
              , [GLDescription] = [GM].[Description]
              , [R].[Reference]
              , [R].[Comment]
              , [R].[EntryValue]
              , [R].[EntryDate]
              , [R].[EntryPosted]
              , [R].[JnlPrintFlag]
              , [R].[JournalDate]
              , [R].[NumOfEntries]
              , [R].[DebitAmount]
              , [R].[CreditAmount]
              , [JPT].[JnlPostingTypeDesc]
              , [GJCS].[SourceDescription]
              , [R].[Operator]
              , [JS].[JnlStatusDesc]
              , [R].[AuthorisedBy]
              , [R].[PostedBy]
              , [R].[Authorised]
              , [R].[PostDate]
              , [R].[Notation]
              , [JournalSource] = [GJCJS].[GenJournalCtlJnlSourceDesc]
        From    [#Results] As [R]
                Left Join [BlackBox].[Lookups].[JnlPostingType] [JPT]
                    On [R].[JnlPostingType] = [JPT].[JnlPostingType]
                Left Join [BlackBox].[Lookups].[JnlStatus] [JS]
                    On [R].[JnlStatus] = [JS].[JnlStatus]
                Left Join [BlackBox].[Lookups].[GenJournalCtlSource] [GJCS]
                    On [R].[Source] = [GJCS].[Source]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [GM]
                    On [GM].[GlCode] = [R].[GlCode]
                       And [GM].[Company] = [R].[DatabaseName]
                Left Join [BlackBox].[Lookups].[CompanyNames] As [CN]
                    On [CN].[Company] = [R].[DatabaseName]
                Left Join [Lookups].[GenJournalCtlJnlSource] [GJCJS]
                    On [R].[JournalSource] = [GJCJS].[GenJournalCtlJnlSource];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'journals for each company', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_CompanyTransactions', NULL, NULL
GO
