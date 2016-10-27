SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GenledgerJournalsGrouped]
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
--Exec [Report].[UspResults_GenledgerJournalsGrouped] @Company ='10'
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount Off;
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_GenledgerJournalsGrouped' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'GenJournalDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GenJournalDetail]
            (
              [DatabaseName] Varchar(150)		collate Latin1_General_BIN
            , [GlYear] Int						
            , [GlPeriod] Int					
            , [EntryDate] DateTime2				
            , [Journal] Int						
            , [GlCode] Varchar(150) 			collate Latin1_General_BIN
            , [EntryType] Char(1)				collate Latin1_General_BIN
            , [Reference] Varchar(255)			collate Latin1_General_BIN
            , [Comment] Varchar(255)			collate Latin1_General_BIN
            , [EntryValue] Numeric(20 , 7)		
            , [EntryPosted] Char(1)				collate Latin1_General_BIN
            , [SubModJournal] Int				
            , [Description] Varchar(150)		collate Latin1_General_BIN
            );

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
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
				Insert [#GenJournalDetail]
						( [DatabaseName], [GlYear]
						, [GlPeriod], [EntryDate]
						, [Journal], [GlCode]
						, [EntryType], [Reference]
						, [Comment], [EntryValue]
						, [EntryPosted], [SubModJournal]
						,[Description]
						)
				SELECT [DatabaseName]=@DBCode, [gjd].[GlYear]
					 , [gjd].[GlPeriod], [gjd].[EntryDate]
					 , [gjd].[Journal], [gjd].[GlCode]
					 , [gjd].[EntryType], [gjd].[Reference]
					 , [gjd].[Comment], [gjd].[EntryValue]
					 , [gjd].[EntryPosted], [gjd].[SubModJournal] 
					 , gm.[Description]
				From [GenJournalDetail] As [gjd]
				left join [SysproCompany40]..[GenMaster] As [gm]
							on gjd.GlCode=gm.GlCode
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#ResultsGL]
            (
              [DatabaseName] Varchar(150)		collate Latin1_General_BIN
            , [Mapping1] Varchar(255)			collate Latin1_General_BIN
            , [Mapping2] Varchar(255)			collate Latin1_General_BIN
            , [Mapping3] Varchar(255)			collate Latin1_General_BIN
            , [Mapping4] Varchar(255)			collate Latin1_General_BIN
            , [Mapping5] Varchar(255)			collate Latin1_General_BIN
            , [GlYear] Int						
            , [GlPeriod] Int					
            , [EntryDate] DateTime2				
            , [Journal] Int						
            , [GlCode] Varchar(150)				collate Latin1_General_BIN
            , [GlStart] Char(3)					collate Latin1_General_BIN
            , [GlMid] Char(5)					collate Latin1_General_BIN
            , [GlEnd] Char(3)					collate Latin1_General_BIN
            , [EntryType] Char(1)				collate Latin1_General_BIN
            , [Modifier] Numeric(20 , 7)		
            , [Reference] Varchar(250)			
            , [Comment] Varchar(250)			
            , [EntryValue] Numeric(20 , 7)		
            , [EntryPosted] Char(1)				collate Latin1_General_BIN
            , [SubModJournal] Int				
            , [GlDescription] Varchar(150)		collate Latin1_General_BIN
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#ResultsGL]
                ( [DatabaseName]
                , [Mapping1]
                , [Mapping2]
                , [Mapping3]
                , [Mapping4]
                , [Mapping5]
                , [GlYear]
                , [GlPeriod]
                , [EntryDate]
                , [Journal]
                , [GlCode]
                , [GlStart]
                , [GlMid]
                , [GlEnd]
                , [EntryType]
                , [Modifier]
                , [Reference]
                , [Comment]
                , [EntryValue]
                , [EntryPosted]
                , [SubModJournal]
                , [GlDescription]
	            )
                Select  Coalesce([gd].[DatabaseName] , [gm].[Company])
                      , [Mapping1] = Coalesce([gm].[Mapping1] , 'No map')
                      , [Mapping2] = Coalesce([gm].[Mapping2] , 'No map')
                      , [Mapping3] = Coalesce([gm].[Mapping3] , 'No map')
                      , [Mapping4] = Coalesce([gm].[Mapping4] , 'No map')
                      , [Mapping5] = Coalesce([gm].[Mapping5] , 'No map')
                      , [gd].[GlYear]
                      , [gd].[GlPeriod]
                      , [gd].[EntryDate]
                      , [gd].[Journal]
                      , [GlCode] = Coalesce([gd].[GlCode] , [gm].[GlCode])
                      , [GlStart] = Cast(Coalesce([gm].[GlStart] ,
                                                  ParseName([gd].[GlCode] , 3)) As Char(3))
                      , [GlMid] = Cast(Coalesce([gm].[GlMid] ,
                                                ParseName([gd].[GlCode] , 2)) As Char(5))
                      , [GlEnd] = Cast(Coalesce([gm].[GlEnd] ,
                                                ParseName([gd].[GlCode] , 1)) As Char(3))
                      , [gd].[EntryType]
                      , [Modifier] = Case When [gd].[EntryType] = 'D' Then 1
                                          When [gd].[EntryType] = 'C' Then -1
                                          Else 0
                                     End
                      , [Reference] = Case When [gd].[Reference] = ''
                                           Then Null
                                           Else [gd].[Reference]
                                      End
                      , [Comment] = Case When [gd].[Comment] = '' Then Null
                                         Else [gd].[Comment]
                                    End
                      , [EntryValue] = Coalesce([gd].[EntryValue] , 0)
                      , [gd].[EntryPosted]
                      , [SubModJournal] = Case When [gd].[SubModJournal] = 0
                                               Then Null
                                               Else [gd].[SubModJournal]
                                          End
                      , [gd].[Description]
                From    [Lookups].[GLMapping] As [gm]
                        Full Outer Join [#GenJournalDetail] [gd] On [gd].[GlCode] = [gm].[GlCode]
                                                              And [gd].[DatabaseName] = [gm].[Company];

--return results
        Select  [Company] = [rg].[DatabaseName]
              , [cn].[CompanyName]
              , [rg].[Mapping1]
              , [rg].[Mapping2]
              , [rg].[Mapping3]
              , [rg].[Mapping4]
              , [rg].[Mapping5]
              , [rg].[GlYear]
              , [rg].[GlPeriod]
              , [EntryDate] = Cast([rg].[EntryDate] As Date)
              , [rg].[Journal]
              , [rg].[GlCode]
              , [rg].[GlStart]
              , [rg].[GlMid]
              , [rg].[GlEnd]
              , [rg].[EntryType]
              , [rg].[Modifier]
              , [rg].[Reference]
              , [rg].[Comment]
              , [rg].[EntryValue]
              , [rg].[EntryPosted]
              , [rg].[SubModJournal]
              , [rg].[GlDescription]
        From    [#ResultsGL] As [rg]
                Left Join [Lookups].[CompanyNames] [cn] On [rg].[DatabaseName] = [cn].[Company];

    End;

GO
