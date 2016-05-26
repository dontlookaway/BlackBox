SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GenJournalEntries]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group May 2016
Stored procedure set out to query multiple databases with the same information and return it in a collated format
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_GenJournalEntries' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GenJournalDetail]
            (
              [DatabaseName] Varchar(150)
            , [Journal] Int
            , [GlYear] Int
            , [GlPeriod] Int
            , [EntryNumber] Int
            , [EntryType] Char(1)
            , [GlCode] Varchar(35)
            , [Reference] Varchar(50)
            , [Comment] Varchar(250)
            , [EntryValue] Numeric(20 , 2)
            , [EntryDate] Date
            , [EntryPosted] Char(1)
            , [InterCompanyFlag] Char(1)
            , [Company] Varchar(50)
            , [CurrencyValue] Numeric(20 , 2)
            , [PostCurrency] Varchar(10)
            , [TypeDetail] Varchar(100)
            , [CommitmentFlag] Char(1)
            , [TransactionDate] Date
            , [DocumentDate] Date
            , [SubModJournal] Int
            , [AnalysisEntry] Int
            );
        Create Table [#GenJournalCtl]
            (
              [DatabaseName] Varchar(150)
            , [JnlPrintFlag] Char(1)
            , [JournalDate] Date
            , [NumOfEntries] Int
            , [DebitAmount] Numeric(20 , 2)
            , [CreditAmount] Numeric(20 , 2)
            , [JnlPostingType] Char(1)
            , [Source] Char(1)
            , [Operator] Varchar(20)
            , [JnlStatus] Char(1)
            , [Reference] Varchar(30)
            , [AuthorisedBy] Varchar(20)
            , [PostedBy] Varchar(20)
            , [Authorised] Char(1)
            , [PostDate] Date
            , [Notation] Varchar(100)
            , [GlJournal] Int
            , [GlPeriod] Int
            , [GlYear] Int
            , [JournalSource] Char(2)
            );
        Create Table [#GrnMatching]
            (
              [DatabaseName] Varchar(300)
            , [Grn] Varchar(20)
            , [Invoice] Varchar(20)
            );
        Create Table [#InvJournalDet]
            (
              [DatabaseName] Varchar(300)
            , [JnlYear] Int
            , [GlPeriod] Int
            , [Journal] Int
            , [EntryNumber] Int
            , [Supplier] Varchar(15)
            , [PurchaseOrder] Varchar(20)
            , [Reference] Varchar(30)
            );
        Create Table [#GenAnalysisTrn]
            (
              [DatabaseName] Varchar(150)
            , [AnalysisEntry] Int
            , [GlPeriod] Int
            , [GlYear] Int
            , [AnalysisCategory] Varchar(10)
            , [AnalysisCode1] Varchar(10)
            , [AnalysisCode2] Varchar(10)
            , [AnalysisCode3] Varchar(10)
            , [AnalysisCode4] Varchar(10)
            , [AnalysisCode5] Varchar(10)
            , [EntryValue] Numeric(20 , 2)
            );
        Create Table [#GenAnalysisCode]
            (
              [DatabaseName] Varchar(150)
            , [AnalysisCategory] Varchar(10)
            , [AnalysisCode] Varchar(10)
            , [AnalysisType] Int
            , [Description] Varchar(50)
            );

--create script to pull data from each db into the tables
        Declare @SQLGenJournalDetail Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' and IsNumeric(Replace(Db_Name(),''SysproCompany'',''''))=1
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
			Declare @SubSQL Varchar(1000)

			Select @SubSQL=''SELECT [DatabaseName]=''+@DBCode+''
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
							, [GJD].[InterCompanyFlag]
							, [GJD].[Company]
							, [GJD].[CurrencyValue]
							, [GJD].[PostCurrency]
							, [TypeDetail] = Coalesce([GJT].[TypeDetail],''''No Type'''')
							, [GJD].[CommitmentFlag]
							, [GJD].[TransactionDate]
							, [GJD].[DocumentDate]
							, [GJD].[SubModJournal]
							, [GJD].[AnalysisEntry] FROM [GenJournalDetail] As [GJD]
			Left Join [BlackBox].[Lookups].[GenJournalDetailSource] As [GJDS] On [GJDS].[GJSource]=[GJD].[Source]
			Left Join [BlackBox].[Lookups].[GenJournalType] As [GJT] On [GJD].[Type]=[GJT].[TypeCode]''

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
							, [InterCompanyFlag]
							, [Company]
							, [CurrencyValue]
							, [PostCurrency]
							, [TypeDetail]
							, [CommitmentFlag]
							, [TransactionDate]
							, [DocumentDate]
							, [SubModJournal]
							, [AnalysisEntry]
							)
					Exec (@SubSQL)
			End
	End';
        Declare @SQLGenJournalCtl Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' and IsNumeric(Replace(Db_Name(),''SysproCompany'',''''))=1
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
        Declare @SQLGrnMatching Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' and IsNumeric(Replace(Db_Name(),''SysproCompany'',''''))=1
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
				Insert [#GrnMatching]
				( [DatabaseName] , [Grn] , [Invoice] )
				SELECT [DatabaseName]=@DBCode
				, [GM].[Grn]
				, [GM].[Invoice] 
				FROM [GrnMatching] [GM]
			End
	End';
        Declare @SQLInvJournalDet Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' and IsNumeric(Replace(Db_Name(),''SysproCompany'',''''))=1
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
				Insert [#InvJournalDet]
						( [DatabaseName]
						, [JnlYear]
						, [GlPeriod]
						, [Journal]
						, [EntryNumber]
						, [Supplier]
						, [PurchaseOrder]
						, [Reference]
						)
				SELECT [DatabaseName]=@DBCode
					 , [IJD].[JnlYear]
					 , [IJD].[GlPeriod]
					 , [IJD].[Journal]
					 , [IJD].[EntryNumber]
					 , [IJD].[Supplier]
					 , [IJD].[PurchaseOrder]
					 , [IJD].[Reference]
				FROM [InvJournalDet] [IJD]
			End
	End';
        Declare @SQLAnalysis Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' and IsNumeric(Replace(Db_Name(),''SysproCompany'',''''))=1
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
                    Insert  [#GenAnalysisTrn]
                            ( [DatabaseName]
                            , [AnalysisEntry]
                            , [GlPeriod]
                            , [GlYear]
                            , [AnalysisCategory]
                            , [AnalysisCode1]
                            , [AnalysisCode2]
                            , [AnalysisCode3]
                            , [AnalysisCode4]
                            , [AnalysisCode5]
							, [EntryValue]
							)
                            Select  [DatabaseName] = @DBCode
                                  , [GAT].[AnalysisEntry]
                                  , [GAT].[GlPeriod]
                                  , [GAT].[GlYear]
                                  , [GAT].[AnalysisCategory]
                                  , [AnalysisCode1] = Case When [GAT].[AnalysisCode1] = ''''
                                                           Then Null
                                                           Else [GAT].[AnalysisCode1]
                                                      End
                                  , [AnalysisCode2] = Case When [GAT].[AnalysisCode2] = ''''
                                                           Then Null
                                                           Else [GAT].[AnalysisCode2]
                                                      End
                                  , [AnalysisCode3] = Case When [GAT].[AnalysisCode3] = ''''
                                                           Then Null
                                                           Else [GAT].[AnalysisCode3]
                                                      End
                                  , [AnalysisCode4] = Case When [GAT].[AnalysisCode4] = ''''
                                                           Then Null
                                                           Else [GAT].[AnalysisCode4]
                                                      End
                                  , [AnalysisCode5] = Case When [GAT].[AnalysisCode5] = ''''
                                                           Then Null
                                                           Else [GAT].[AnalysisCode5]
                                                      End
								  , [GAT].[EntryValue]
                            From    [dbo].[GenAnalysisTrn] [GAT];

                    Insert  [#GenAnalysisCode]
                            ( [DatabaseName]
                            , [AnalysisCategory]
                            , [AnalysisCode]
                            , [AnalysisType]
                            , [Description]
	                        )
                            Select  [DatabaseName] = @DBCode
                                  , [GAC].[AnalysisCategory]
                                  , [GAC].[AnalysisCode]
                                  , [GAC].[AnalysisType]
                                  , [GAC].[Description]
                            From    [SysproCompany10].[dbo].[GenAnalysisCode] [GAC];
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLGenJournalCtl;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGenJournalDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrnMatching;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvJournalDet;
        Exec [Process].[ExecForEachDB] @cmd = @SQLAnalysis;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Journal] Int
            , [GlYear] Int
            , [GlPeriod] Int
            , [EntryNumber] Int
            , [EntryType] Char(1)
            , [GlCode] Varchar(35)
            , [Reference] Varchar(50)
            , [Comment] Varchar(250)
            , [EntryValue] Numeric(20 , 2)
            , [EntryDate] Date
            , [EntryPosted] Char(1)
            , [JnlPrintFlag] Char(1)
            , [JournalDate] Date
            , [NumOfEntries] Int
            , [DebitAmount] Numeric(20 , 2)
            , [CreditAmount] Numeric(20 , 2)
            , [JnlPostingType] Char(1)
            , [Source] Char(1)
            , [Operator] Varchar(20)
            , [JnlStatus] Char(1)
            , [AuthorisedBy] Varchar(20)
            , [PostedBy] Varchar(20)
            , [Authorised] Char(1)
            , [PostDate] Date
            , [Notation] Varchar(100)
            , [JournalSource] Char(2)
            , [Supplier] Varchar(15)
            , [PurchaseOrder] Varchar(20)
            , [Grn] Varchar(Max)
            , [Invoice] Varchar(Max)
            , [AnalysisCategory] Varchar(10)
            , [AnalysisCode1] Varchar(10)
            , [Analysis1] Varchar(50)
            , [AnalysisCode2] Varchar(10)
            , [AnalysisCode3] Varchar(10)
            , [AnalysisCode4] Varchar(10)
            , [AnalysisCode5] Varchar(10)
            , [AnalysisEntryValue] Numeric(20 , 2)
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
                , [Supplier]
                , [PurchaseOrder]
                , [Grn]
                , [Invoice]
                , [AnalysisCategory]
                , [AnalysisCode1]
                , [Analysis1]
                , [AnalysisCode2]
                , [AnalysisCode3]
                , [AnalysisCode4]
                , [AnalysisCode5]
                , [AnalysisEntryValue]
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
                      , [Supplier] = Case When [IJD].[Supplier] = '' Then Null
                                          Else [IJD].[Supplier]
                                     End
                      , [PurchaseOrder] = Case When [IJD].[PurchaseOrder] = ''
                                               Then Null
                                               Else [IJD].[PurchaseOrder]
                                          End
                      , [Grn] = Stuff(( Select Distinct
                                                ',' + [GM].[Grn]
                                        From    [#GrnMatching] [GM]
                                        Where   [IJD].[Reference] = [GM].[Grn]
                                                And [GM].[DatabaseName] = [IJD].[DatabaseName]
                                                And Coalesce([GM].[Invoice] ,
                                                             '') <> ''
                                      For
                                        Xml Path('')
                                      ) , 1 , 1 , '')
                      , [Invoice] = Stuff(( Select Distinct
                                                    ',' + [GM].[Invoice]
                                            From    [#GrnMatching] [GM]
                                            Where   [IJD].[Reference] = [GM].[Grn]
                                                    And [GM].[DatabaseName] = [IJD].[DatabaseName]
                                                    And Coalesce([GM].[Invoice] ,
                                                              '') <> ''
                                          For
                                            Xml Path('')
                                          ) , 1 , 1 , '')
                      , [GAT].[AnalysisCategory]
                      , [GAT].[AnalysisCode1]
                      , [Analysis1] = [GAC].[Description]
                      , [GAT].[AnalysisCode2]
                      , [GAT].[AnalysisCode3]
                      , [GAT].[AnalysisCode4]
                      , [GAT].[AnalysisCode5]
                      , [GAT].[EntryValue]
                From    [#GenJournalDetail] As [GJD]
                        Left Join [#GenJournalCtl] As [GJC]
                            On [GJC].[GlJournal] = [GJD].[Journal]
                               And [GJC].[GlPeriod] = [GJD].[GlPeriod]
                               And [GJC].[GlYear] = [GJD].[GlYear]
                               And [GJC].[DatabaseName] = [GJD].[DatabaseName]
                        Left Join [#InvJournalDet] [IJD]
                            On [IJD].[JnlYear] = [GJD].[GlYear]
                               And [IJD].[GlPeriod] = [GJD].[GlPeriod]
                               And [IJD].[Journal] = [GJD].[SubModJournal]
                               And [IJD].[EntryNumber] = [GJD].[EntryNumber]
                               And [IJD].[DatabaseName] = [GJD].[DatabaseName]
                        /*Left Join [#GrnMatching] [GM]
                            On [IJD].[Reference] = [GM].[Grn]
                               And [GM].[DatabaseName] = [IJD].[DatabaseName]*/
                        Left Join [Lookups].[CompanyNames] As [CN]
                            On [CN].[Company] = [GJD].[DatabaseName]
                        Left Join [#GenAnalysisTrn] [GAT]
                            On [GAT].[AnalysisEntry] = [GJD].[AnalysisEntry]
                               And [GAT].[GlPeriod] = [GJD].[GlPeriod]
                               And [GAT].[GlYear] = [GJD].[GlYear]
                               And [GAT].[DatabaseName] = [GJD].[DatabaseName]
                        Left Join [#GenAnalysisCode] [GAC]
                            On [GAC].[AnalysisCategory] = [GAT].[AnalysisCategory]
                               And [GAC].[AnalysisCode] = [GAT].[AnalysisCode1]
                               And [GAC].[AnalysisType] = 1
                               And [GAC].[DatabaseName] = [GAT].[DatabaseName];

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
              , [R].[Supplier]
              , [R].[PurchaseOrder]
              , [R].[Grn]
              , [R].[Invoice]
              , [R].[AnalysisCategory]
              , [R].[AnalysisCode1]
              , [R].[Analysis1]
              , [R].[AnalysisCode2]
              , [R].[AnalysisCode3]
              , [R].[AnalysisCode4]
              , [R].[AnalysisCode5]
              , [R].[AnalysisEntryValue]
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
