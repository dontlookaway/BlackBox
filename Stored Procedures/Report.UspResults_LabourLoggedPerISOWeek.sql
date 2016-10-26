SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LabourLoggedPerISOWeek]
    (
      @Company Varchar(Max)
    , @Year Int
    , @MaxDate Date
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
*/
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_LabourLoggedPerISOWeek' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'WipLabJnl'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#WipLabJnl]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Employee] Varchar(20)			collate latin1_general_bin
            , [TrnYear] Int
            , [EntryDate] Date
            , [RunTime] Numeric(20 , 6)
            , [SetUpTime] Numeric(20 , 6)
            , [StartUpTime] Numeric(20 , 6)
            , [TeardownTime] Numeric(20 , 6)
            );

        Create Index [WLJ_DB_Emp_TY_ED] On [#WipLabJnl] ([DatabaseName],[Employee],[TrnYear],[EntryDate]);

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#WipLabJnl]
						( [DatabaseName]
						, [Employee]
						, [TrnYear]
						, [EntryDate]
						, [RunTime]
						, [SetUpTime]
						, [StartUpTime]
						, [TeardownTime]
						)
				SELECT [DatabaseName]=@DBCode
					 , [WLJ].[Employee]
					 , [WLJ].[TrnYear]
					 , [WLJ].[EntryDate]
					 , [WLJ].[RunTime]
					 , [WLJ].[SetUpTime]
					 , [WLJ].[StartUpTime]
					 , [WLJ].[TeardownTime] 
				FROM [WipLabJnl] [WLJ]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)		collate latin1_general_bin
            , [Employee] Varchar(20)			collate latin1_general_bin
            , [TrnYear] Int
            , [ISOWeek] Int
            , [RunTime] Numeric(20 , 6)
            , [SetUpTime] Numeric(20 , 6)
            , [StartUpTime] Numeric(20 , 6)
            , [TeardownTime] Numeric(20 , 6)
            , [TestForFullHoursAccounted] As Case When [RunTime] > 2250
                                                  Then 'More'
                                                  When [RunTime] < 2250
                                                  Then 'Less'
                                                  Else 'Correct'
                                             End
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Employee]
                , [TrnYear]
                , [ISOWeek]
                , [RunTime]
                , [SetUpTime]
                , [StartUpTime]
                , [TeardownTime]
                )
                Select  [wlj].[DatabaseName]
                      , [wlj].[Employee]
                      , [wlj].[TrnYear]
                      , [ISOWeek] = DatePart(iso_week , [wlj].[EntryDate])
                      , [RunTime] = Sum([wlj].[RunTime])
                      , [SetUpTime] = Sum([wlj].[SetUpTime])
                      , [StartUpTime] = Sum([wlj].[StartUpTime])
                      , [TeardownTime] = Sum([wlj].[TeardownTime])
                From    [#WipLabJnl] As [wlj]
                Where   [wlj].[TrnYear] = @Year
                        And [wlj].[EntryDate] <= @MaxDate
                Group By [wlj].[DatabaseName]
                      , DatePart(iso_week , [wlj].[EntryDate])
                      , [wlj].[Employee]
                      , [wlj].[TrnYear];	

        Set NoCount Off;
--return results
        Select  [CN].[CompanyName]
              , [CN].[ShortName]
              , [CN].[Currency]
              , [r].[Employee]
              , [r].[TrnYear]
              , [r].[ISOWeek]
              , [r].[RunTime]
              , [r].[SetUpTime]
              , [r].[StartUpTime]
              , [r].[TeardownTime]
              , [r].[TestForFullHoursAccounted]
        From    [#Results] [r]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [CN].[Company] = [r].[DatabaseName];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'labour logged split by ISO week', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_LabourLoggedPerISOWeek', NULL, NULL
GO
