
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--d

CREATE Proc [Report].[UspResults_GenledgerJournalsGrouped] ( @Company VARCHAR(Max) )
As --Exec [Report].[UspResults_GenledgerJournalsGrouped] @Company ='10'
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			14/10/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
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
        Set NoCount off;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'GenJournalDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GenJournalDetail]
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [GlYear] INT
            , [GlPeriod] INT
            , [EntryDate] DATETIME2
            , [Journal] INT
            , [GlCode] VARCHAR(150) Collate Latin1_General_BIN
            , [EntryType] CHAR(1)
            , [Reference] VARCHAR(255)
            , [Comment] VARCHAR(255)
            , [EntryValue] NUMERIC(20, 7)
            , [EntryPosted] CHAR(1)
            , [SubModJournal] INT
            , [Description] VARCHAR(150)
            );

--create script to pull data from each db into the tables
        Declare @SQL VARCHAR(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
            + UPPER(@Company) + ''' = ''ALL''
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
        Exec sp_MSforeachdb
            @SQL;

--define the results you want to return
        Create Table #ResultsGL
            (
              DatabaseName VARCHAR(150)
            , [Mapping1] VARCHAR(255)
            , [Mapping2] VARCHAR(255)
            , [Mapping3] VARCHAR(255)
            , [Mapping4] VARCHAR(255)
            , [Mapping5] VARCHAR(255)
            , [GlYear] INT
            , [GlPeriod] INT
            , [EntryDate] DATETIME2
            , [Journal] INT
            , [GlCode] VARCHAR(150)
            , [GlStart] CHAR(3)
            , [GlMid] CHAR(5)
            , [GlEnd] CHAR(3)
            , [EntryType] CHAR(1)
            , [Modifier] NUMERIC(20, 7)
            , [Reference] VARCHAR(250)
            , [Comment] VARCHAR(250)
            , [EntryValue] NUMERIC(20, 7)
            , [EntryPosted] CHAR(1)
            , [SubModJournal] INT
            , [GlDescription] VARCHAR(150)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

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
                Select COALESCE([gd].[DatabaseName],[gm].[Company])
                  , [Mapping1] = COALESCE([gm].[Mapping1], 'No map')
                  , [Mapping2] = COALESCE([gm].[Mapping2], 'No map')
                  , [Mapping3] = COALESCE([gm].[Mapping3], 'No map')
                  , [Mapping4] = COALESCE([gm].[Mapping4], 'No map')
                  , [Mapping5] = COALESCE([gm].[Mapping5], 'No map')
                  , [gd].[GlYear]
                  , [gd].[GlPeriod]
                  , [gd].[EntryDate]
                  , [gd].[Journal]
                  , [GlCode] = COALESCE([gd].[GlCode], [gm].[GlCode])
                  , [GlStart]	= cast(COALESCE([gm].[GlStart],
                                         PARSENAME(gd.GlCode, 3))					   as char(3))
                  , [GlMid]		= cast(COALESCE([gm].[GlMid], PARSENAME(gd.GlCode, 2)) as char(5))
                  , [GlEnd]		= cast(COALESCE([gm].[GlEnd], PARSENAME(gd.GlCode, 1)) as char(3))
                  , [gd].[EntryType]
                  , Modifier = Case When gd.[EntryType] = 'D' Then 1
                                    When gd.[EntryType] = 'C' Then -1
                                    Else 0
                               End
                  , [Reference] = Case When [gd].[Reference] = '' Then Null
                                       Else [gd].[Reference]
                                  End
                  , [Comment] = Case When [gd].[Comment] = '' Then Null
                                     Else [gd].[Comment]
                                End
                  , [EntryValue] = COALESCE([gd].[EntryValue], 0)
                  , [gd].[EntryPosted]
                  , [SubModJournal] = Case When [gd].[SubModJournal] = 0
                                           Then Null
                                           Else [gd].[SubModJournal]
                                      End
				  , [gd].[Description]
                From
                    [Lookups].[GLMapping] As [gm]
                Full Outer Join [#GenJournalDetail] gd
                    On [gd].[GlCode] = [gm].[GlCode]
                       And [gd].[DatabaseName] = [gm].[Company];

--return results
        Select
            Company = [rg].[DatabaseName]
		  , CompanyName
          , [rg].[Mapping1]
          , [rg].[Mapping2]
          , [rg].[Mapping3]
          , [rg].[Mapping4]
          , [rg].[Mapping5]
          , [rg].[GlYear]
          , [rg].[GlPeriod]
          , [EntryDate] = CAST([rg].[EntryDate] As DATE)
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
        From
            [#ResultsGL] As [rg]
			left join Lookups.CompanyNames cn on rg.[DatabaseName]=cn.Company
			;

    End;

GO
