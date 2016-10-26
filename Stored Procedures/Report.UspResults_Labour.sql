SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_Labour]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
--Exec [Report].[UspResults_Labour] 10
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
            @StoredProcName = 'UspResults_Labour' , @UsedByType = @RedTagType ,
            @UsedByName = @RedTagUse , @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#WipLabJnl]
            (
              [DatabaseName] Varchar(150)	Collate Latin1_General_BIN
            , [EntryMonth] Date
            , [EntryDate] DateTime2
            , [Employee] Varchar(20)		collate latin1_general_bin
            , [RunTime] Numeric(20 , 7)
            , [RunTimeRate] Numeric(20 , 7)
            , [SetUpTime] Numeric(20 , 7)
            , [SetUpRate] Numeric(20 , 7)
            , [StartUpTime] Numeric(20 , 7)
            , [StartUpRate] Numeric(20 , 7)
            , [TeardownTime] Numeric(20 , 7)
            , [TeardownRate] Numeric(20 , 7)
            , [LabourValue] Numeric(20 , 7)
            , [FixedOhRate] Numeric(20 , 7)
            , [VariableOhRate] Numeric(20 , 7)
            , [WorkCentre] Varchar(150)		collate latin1_general_bin
            , [Job] Varchar(50)				collate latin1_general_bin
            );

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
				Insert [#WipLabJnl]
	    ( [DatabaseName], [EntryMonth], [EntryDate]
	    , [Employee], [RunTime], [RunTimeRate]
		, [SetUpTime], [SetUpRate]
		, [StartUpTime], [StartUpRate]
	    , [TeardownTime], [TeardownRate]
	    , [LabourValue], [FixedOhRate], [VariableOhRate]
		,WorkCentre,[Job]
	    )
SELECT  @DBCode,[EntryMonth] = DATEADD(Day,-(DAY([wlj].[EntryDate])-1),[wlj].[EntryDate]),[EntryDate]
,[Employee],[RunTime],[RunTimeRate]
,[SetUpTime],[SetUpRate]
,[StartUpTime],[StartUpRate]
,[TeardownTime],[TeardownRate]
,[LabourValue],[FixedOhRate],[VariableOhRate]
,WorkCentre,[Job]
FROM [WipLabJnl] As [wlj] Order By EntryMonth Desc
		End
End';

--Enable this function to check script changes (try to run script directly against db manually)

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table

--return results
        Select  [wlj].[DatabaseName]
              , [cn].[CompanyName]
              , [wlj].[EntryMonth]
              , [wlj].[EntryDate]
              , [wlj].[Employee]
              , [wlj].[RunTime]
              , [wlj].[RunTimeRate]
              , [wlj].[SetUpTime]
              , [wlj].[SetUpRate]
              , [wlj].[StartUpTime]
              , [wlj].[StartUpRate]
              , [wlj].[TeardownTime]
              , [wlj].[TeardownRate]
              , [wlj].[LabourValue]
              , [wlj].[FixedOhRate]
              , [wlj].[VariableOhRate]
              , [wlj].[WorkCentre]
              , [wlj].[Job]
        From    [#WipLabJnl] As [wlj]
                Left Join [Lookups].[CompanyNames] As [cn] On [wlj].[DatabaseName] = [cn].[Company];

    End;

GO
