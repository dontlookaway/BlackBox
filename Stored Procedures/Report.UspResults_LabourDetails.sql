
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LabourDetails]
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
--exec Report.UspResults_LabourDetails 10
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
            @StoredProcName = 'UspResults_LabourDetails' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'WipLabJnl'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#WipLabJnl]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Job] Varchar(35)
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Machine] Varchar(150)
            , [WorkCentre] Varchar(35)
            , [Employee] Varchar(35)
            , [SetUpRate] Numeric(20 , 7)
            , [RunTimeRate] Numeric(20 , 7)
            , [FixedOhRate] Numeric(20 , 7)
            , [VariableOhRate] Numeric(20 , 7)
            , [StartUpRate] Numeric(20 , 7)
            , [TeardownRate] Numeric(20 , 7)
            , [LabourValue] Numeric(20 , 7)
            , [EntryDate] DateTime2
            , [RunTime] Numeric(20 , 7)
            , [SetUpTime] Numeric(20 , 7)
            , [StartUpTime] Numeric(20 , 7)
            , [TeardownTime] Numeric(20 , 7)
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
					Insert #WipLabJnl
								( DatabaseName, TrnYear
								, TrnMonth, Machine
								, WorkCentre, Employee
								, SetUpRate, RunTimeRate
								, FixedOhRate, VariableOhRate
								, StartUpRate, TeardownRate
								, LabourValue, EntryDate
								, Job
								, RunTime, SetUpTime
								, StartUpTime, TeardownTime
								)
						SELECT DatabaseName = @DBCode
							 , TrnYear
							 , TrnMonth, Machine
							 , WorkCentre, Employee
							 , SetUpRate, RunTimeRate
							 , FixedOhRate, VariableOhRate
							 , StartUpRate, TeardownRate
							 , LabourValue, EntryDate 
							 , Job
							 , RunTime, SetUpTime
							 , StartUpTime, TeardownTime
					FROM WipLabJnl
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#LabourDetailsResults]
            (
              [Company] Varchar(150) Collate Latin1_General_BIN
            , [Job] Varchar(35)
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Machine] Varchar(150)
            , [WorkCentre] Varchar(35)
            , [Employee] Varchar(35)
            , [SetUpRate] Numeric(20 , 7)
            , [RunTimeRate] Numeric(20 , 7)
            , [FixedOhRate] Numeric(20 , 7)
            , [VariableOhRate] Numeric(20 , 7)
            , [StartUpRate] Numeric(20 , 7)
            , [TeardownRate] Numeric(20 , 7)
            , [LabourValue] Numeric(20 , 7)
            , [EntryDate] DateTime2
            , [RunTime] Numeric(20 , 7)
            , [SetUpTime] Numeric(20 , 7)
            , [StartUpTime] Numeric(20 , 7)
            , [TeardownTime] Numeric(20 , 7)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  [#LabourDetailsResults]
                ( [Company]
                , [Job]
                , [TrnYear]
                , [TrnMonth]
                , [Machine]
                , [WorkCentre]
                , [Employee]
                , [SetUpRate]
                , [RunTimeRate]
                , [FixedOhRate]
                , [VariableOhRate]
                , [StartUpRate]
                , [TeardownRate]
                , [LabourValue]
                , [EntryDate]
                , [RunTime]
                , [SetUpTime]
                , [StartUpTime]
                , [TeardownTime]
	            )
                Select  [Company] = [cn].[CompanyName]
                      , [WJL].[Job]
                      , [WJL].[TrnYear]
                      , [WJL].[TrnMonth]
                      , [WJL].[Machine]
                      , [WJL].[WorkCentre]
                      , [WJL].[Employee]
                      , [WJL].[SetUpRate]
                      , [WJL].[RunTimeRate]
                      , [WJL].[FixedOhRate]
                      , [WJL].[VariableOhRate]
                      , [WJL].[StartUpRate]
                      , [WJL].[TeardownRate]
                      , [WJL].[LabourValue]
                      , [WJL].[EntryDate]
                      , [WJL].[RunTime]
                      , [WJL].[SetUpTime]
                      , [WJL].[StartUpTime]
                      , [WJL].[TeardownTime]
                From    [#WipLabJnl] [WJL]
                        Left Join [Lookups].[CompanyNames] As [cn] On [WJL].[DatabaseName] = [cn].[Company];

--return results
        Select  [r].[Company]
              , [r].[Job]
              , [r].[TrnYear]
              , [r].[TrnMonth]
              , [r].[Machine]
              , [r].[WorkCentre]
              , [r].[Employee]
              , [r].[SetUpRate]
              , [r].[RunTimeRate]
              , [r].[FixedOhRate]
              , [r].[VariableOhRate]
              , [r].[StartUpRate]
              , [r].[TeardownRate]
              , [r].[LabourValue]
              , [r].[RunTime]
              , [r].[SetUpTime]
              , [r].[StartUpTime]
              , [r].[TeardownTime]
        From    [#LabourDetailsResults] As [r];

        Drop Table [#LabourDetailsResults];
    End;

GO
