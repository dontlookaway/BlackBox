SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [Report].[UspResults_GenJournalDetails]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group Feb 2015
Stored procedure set out to query all live db's and return details of general ledger journal
*/
    Set NoCount On;

--Red tag
    Declare @RedTagDB Varchar(255)= Db_Name()
      , @Company Varchar(255)= 'ALL';
    Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
        @StoredProcSchema = 'Report' ,
        @StoredProcName = 'UspResults_GenJournalDetails' ,
        @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
        @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
    Declare @ListOfTables Varchar(Max) = 'GenJournalDetail,GrnMatching,InvJournalDet'; 

    Create Table [#GenJournalDetail]
        (
          [DatabaseName] Varchar(300)
        , [SourceDetail] Varchar(100)
        , [GlYear] Int
        , [GlPeriod] Int
        , [Journal] Int
        , [EntryNumber] Int
        , [EntryType] Char(1)
        , [GlCode] Varchar(35)
        , [Reference] Varchar(100)
        , [Comment] Varchar(250)
        , [EntryValue] Numeric(20 , 2)
        , [InterCompanyFlag] Char(1)
        , [Company] Varchar(50)
        , [EntryDate] Date
        , [EntryPosted] Char(1)
        , [CurrencyValue] Numeric(20 , 2)
        , [PostCurrency] Varchar(10)
        , [TypeDetail] Varchar(100)
        , [CommitmentFlag] Char(1)
        , [TransactionDate] Date
        , [DocumentDate] Date
        , [SubModJournal] Int
        , [AnalysisEntry] Int
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
        );
    Create Table [#GenAnalysisCode]
        (
          [DatabaseName] Varchar(150)
        , [AnalysisCategory] Varchar(10)
        , [AnalysisCode] Varchar(10)
        , [AnalysisType] Int
        , [Description] Varchar(50)
        );




    Declare @SQLGenJournalDetail Varchar(Max) = '
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
                    Insert  [#GenJournalDetail]
                            ( [SourceDetail]
                            , [GlYear]
                            , [GlPeriod]
                            , [Journal]
                            , [EntryNumber]
                            , [EntryType]
                            , [GlCode]
                            , [Reference]
                            , [Comment]
                            , [EntryValue]
                            , [InterCompanyFlag]
                            , [Company]
                            , [EntryDate]
                            , [EntryPosted]
                            , [CurrencyValue]
                            , [PostCurrency]
                            , [TypeDetail]
                            , [CommitmentFlag]
                            , [TransactionDate]
                            , [DocumentDate]
                            , [DatabaseName]
                            , [SubModJournal]
                            , [AnalysisEntry]
		                    )
                            SELECT  SourceDetail = Coalesce([GJDS].[GJSourceDetail] ,
                                                            ''No Source'')
                                  , [GJD].[GlYear]
                                  , [GJD].[GlPeriod]
                                  , [GJD].[Journal]
                                  , [GJD].[EntryNumber]
                                  , [GJD].[EntryType]
                                  , [GJD].[GlCode]
                                  , [GJD].[Reference]
                                  , [GJD].[Comment]
                                  , [GJD].[EntryValue]
                                  , [GJD].[InterCompanyFlag]
                                  , [Company] = case when [GJD].[Company]='''' then @DBCode else [GJD].[Company] end
                                  , [GJD].[EntryDate]
                                  , [GJD].[EntryPosted]
                                  , [GJD].[CurrencyValue]
                                  , [GJD].[PostCurrency]
                                  , [TypeDetail] = Coalesce([GJT].[TypeDetail] ,
                                                            ''No Type'')
                                  , [GJD].[CommitmentFlag]
                                  , [GJD].[TransactionDate]
                                  , [GJD].[DocumentDate]
                                  , DatabaseName = @DBCode
                                  , [GJD].[SubModJournal]
                                  , [GJD].[AnalysisEntry]
                            From    [dbo].[GenJournalDetail] As [GJD]
                                    Left Join [BlackBox].[Lookups].[GenJournalDetailSource]
                                        As [GJDS]
                                        On [GJDS].[GJSource] = [GJD].[Source]
                                    Left Join [BlackBox].[Lookups].[GenJournalType]
                                        As [GJT]
                                        On [GJD].[Type] = [GJT].[TypeCode]
                                           And [GJD].[SubModWh] <> ''RM'';
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
                Insert  [#GrnMatching]
                        ( [DatabaseName]
                        , [Grn]
                        , [Invoice]
                        )
                        SELECT  [DatabaseName] = @DBCode
                              , [GM].[Grn]
                              , [GM].[Invoice]
                        FROM    [GrnMatching] [GM]
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
                Insert  [#InvJournalDet]
                        ( [DatabaseName]
                        , [JnlYear]
                        , [GlPeriod]
                        , [Journal]
                        , [EntryNumber]
                        , [Supplier]
                        , [PurchaseOrder]
                        , [Reference]
						)
                        SELECT  [DatabaseName] = @DBCode
                              , [IJD].[JnlYear]
                              , [IJD].[GlPeriod]
                              , [IJD].[Journal]
                              , [IJD].[EntryNumber]
                              , [IJD].[Supplier]
                              , [IJD].[PurchaseOrder]
                              , [IJD].[Reference]
                        FROM    [InvJournalDet] [IJD]
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

    Exec [Process].[ExecForEachDB] @cmd = @SQLGenJournalDetail;
    Exec [Process].[ExecForEachDB] @cmd = @SQLGrnMatching;
    Exec [Process].[ExecForEachDB] @cmd = @SQLInvJournalDet;
	Exec [Process].[ExecForEachDB] @cmd = @SQLAnalysis;

    Select  [Co] = [GJD].[DatabaseName]
          , [CN].[CompanyName]
          , [CN].[ShortName]
          , [GJD].[Journal]
          , [GJD].[GlYear]
          , [GJD].[GlPeriod]
          , [GJD].[EntryNumber]
          , [GJD].[EntryType]
          , [GJD].[GlCode]
          , [GLDescription] = [GM2].[Description]
          , [GJD].[Reference]
          , [GJD].[Comment]
          , [GJD].[EntryValue]
          , [GJD].[EntryDate]
          , [GJD].[EntryPosted]
          , [GJD].[SourceDetail]
          , [GJD].[InterCompanyFlag]
          , [GJD].[Company]
          , [GJD].[CurrencyValue]
          , [GJD].[PostCurrency]
          , [GJD].[TypeDetail]
          , [GJD].[CommitmentFlag]
          , [GJD].[TransactionDate]
          , [GJD].[DocumentDate]
          , [Supplier] = Case When [IJD].[Supplier] = '' Then Null
                              Else [IJD].[Supplier]
                         End
          , [PurchaseOrder] = Case When [IJD].[PurchaseOrder] = '' Then Null
                                   Else [IJD].[PurchaseOrder]
                              End
          , [GM].[Grn]
          , [GM].[Invoice]
          , [GAT].[AnalysisCategory]
          , [GAT].[AnalysisCode1]
          , [Analysis1] = [GAC].[Description]
          , [GAT].[AnalysisCode2]
          , [GAT].[AnalysisCode3]
          , [GAT].[AnalysisCode4]
          , [GAT].[AnalysisCode5]
    From    [#GenJournalDetail] As [GJD]
            Left Join [#InvJournalDet] [IJD]
                On [IJD].[JnlYear] = [GJD].[GlYear]
                   And [IJD].[GlPeriod] = [GJD].[GlPeriod]
                   And [IJD].[Journal] = [GJD].[SubModJournal]
                   And [IJD].[EntryNumber] = [GJD].[EntryNumber]
                   And [IJD].[DatabaseName] = [GJD].[DatabaseName]
            Left Join [#GrnMatching] [GM]
                On [IJD].[Reference] = [GM].[Grn]
                   And [GM].[DatabaseName] = [IJD].[DatabaseName]
            Left Join [Lookups].[CompanyNames] As [CN]
                On [CN].[Company] = [GJD].[DatabaseName]
            Left Join [SysproCompany40].[dbo].[GenMaster] [GM2]
                On [GM2].[Company] = [GJD].[DatabaseName]
                   And [GM2].[GlCode] = [GJD].[GlCode]
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

    Drop Table [#GenJournalDetail];
    Drop Table [#GrnMatching];
    Drop Table [#InvJournalDet];
    Drop Table [#GenAnalysisCode];
    Drop Table  [#GenAnalysisTrn];
GO
