
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
    Declare @RedTagDB Varchar(255)= Db_Name();
    Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
        @StoredProcSchema = 'Report' ,
        @StoredProcName = 'UspResults_GenJournalDetails' ,
        @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
        @UsedByDb = @RedTagDB;

    Create Table [#Results]
        (
          [SourceDetail] Varchar(100)
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
        , [DatabaseName] Varchar(300)
        );


    Declare @SQL Varchar(Max)= 'Use [?];

If lower(db_name()) like ''sysprocompany%'' and lower(db_name()) not like ''%srs'' and Replace(Db_Name() , ''SysproCompany'' , '''') Not In ( ''A'' , ''B'' , ''C'' , ''D'' ,
                                                      ''E'' , ''F'' , ''G'' , ''H'' ,
                                                      ''P'' , ''Q'' , ''T'' , ''U'' ,
                                                      ''V'' )
begin
If Exists (Select 1 From sys.[tables] As [T] Where [T].[name] =''GenJournalDetail'')
	begin
	declare @SubSQL varchar(2000) = ''
	SELECT SourceDetail = Coalesce([GJDS].[GJSourceDetail],''''No Source'''')
			,[GJD].[GlYear]
			 , [GJD].[GlPeriod]
			 , [GJD].[Journal]
			 , [GJD].[EntryNumber]
			 , [GJD].[EntryType]
			 , [GJD].[GlCode]
			 , [GJD].[Reference]
			 , [GJD].[Comment]
			 , [GJD].[EntryValue]
			 , [GJD].[InterCompanyFlag]
			 , [GJD].[Company]
			 , [GJD].[EntryDate]
			 , [GJD].[EntryPosted]
			 , [GJD].[CurrencyValue]
			 , [GJD].[PostCurrency]
			 , [TypeDetail] = Coalesce([GJT].[TypeDetail],''''No Type'''')
			 , [GJD].[CommitmentFlag]
			 , [GJD].[TransactionDate]
			 , [GJD].[DocumentDate] 
			 , DatabaseName = db_name()
	From [dbo].[GenJournalDetail] As [GJD]
	Left Join [BlackBox].[Lookups].[GenJournalDetailSource] As [GJDS] On [GJDS].[GJSource]=[GJD].[Source]
	Left Join [BlackBox].[Lookups].[GenJournalType] As [GJT] On [GJD].[Type]=[GJT].[TypeCode]
	And [GJD].[SubModWh]<>''''RM'''';''


	Insert [#Results]
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
			, DatabaseName
			)
	exec (@SubSQL)
	end
end';

    Exec [Process].[ExecForEachDB] @cmd = @SQL;

    Select  [CN].[CompanyName]
          , [Co] = Replace([R].[DatabaseName] , 'SysproCompany' , '')
          , [R].[SourceDetail]
          , [R].[GlYear]
          , [R].[GlPeriod]
          , [R].[Journal]
          , [R].[EntryNumber]
          , [R].[EntryType]
          , [R].[GlCode]
          , [R].[Reference]
          , [R].[Comment]
          , [R].[EntryValue]
          , [R].[InterCompanyFlag]
          , [R].[Company]
          , [R].[EntryDate]
          , [R].[EntryPosted]
          , [R].[CurrencyValue]
          , [R].[PostCurrency]
          , [R].[TypeDetail]
          , [R].[CommitmentFlag]
          , [R].[TransactionDate]
          , [R].[DocumentDate]
    From    [#Results] As [R]
            Left Join [Lookups].[CompanyNames] As [CN] On [CN].[Company] = Replace([R].[DatabaseName] ,
                                                              'SysproCompany' ,
                                                              '');

    Drop Table [#Results];
GO
