SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LabourDetails] ( @Company VARCHAR(Max) )
--exec Report.UspResults_LabourDetails 10
As
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
///			7/9/2015	Chris Johnson			Initial version created																///
///			5/10/2015	Chris Johnson			Added times																			///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'WipLabJnl'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #WipLabJnl
            (DatabaseName		VARCHAR(150) Collate Latin1_General_BIN
            , Job				VARCHAR(35)
            , TrnYear			INT
            , TrnMonth			INT
            , Machine			VARCHAR(150)
            , WorkCentre		VARCHAR(35)
            , Employee			VARCHAR(35)
            , SetUpRate			NUMERIC(20, 7)
            , RunTimeRate		NUMERIC(20, 7)
            , FixedOhRate		NUMERIC(20, 7)
            , VariableOhRate	NUMERIC(20, 7)
            , StartUpRate		NUMERIC(20, 7)
            , TeardownRate		NUMERIC(20, 7)
            , LabourValue		NUMERIC(20, 7)
            , EntryDate			DATETIME2
            , [RunTime]			NUMERIC(20, 7)
            , [SetUpTime]		NUMERIC(20, 7)
            , [StartUpTime]		NUMERIC(20, 7)
            , [TeardownTime]	NUMERIC(20, 7)
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
        Exec sp_MSforeachdb
            @SQL;

--define the results you want to return
	Create Table [#LabourDetailsResults]
	(Company		VARCHAR(150) Collate Latin1_General_BIN
    , Job				VARCHAR(35)
    , TrnYear			INT
    , TrnMonth			INT
    , Machine			VARCHAR(150)
    , WorkCentre		VARCHAR(35)
    , Employee			VARCHAR(35)
    , SetUpRate			NUMERIC(20, 7)
    , RunTimeRate		NUMERIC(20, 7)
    , FixedOhRate		NUMERIC(20, 7)
    , VariableOhRate	NUMERIC(20, 7)
    , StartUpRate		NUMERIC(20, 7)
    , TeardownRate		NUMERIC(20, 7)
    , LabourValue		NUMERIC(20, 7)
    , EntryDate			DATETIME2
    , [RunTime]			NUMERIC(20, 7)
    , [SetUpTime]		NUMERIC(20, 7)
    , [StartUpTime]		NUMERIC(20, 7)
    , [TeardownTime]	NUMERIC(20, 7)
	)

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert [#LabourDetailsResults]
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
	 Select
            Company =  [cn] .[CompanyName]
			,          [WJL].[Job]
			,          [WJL].[TrnYear]
			,          [WJL].[TrnMonth]
			,          [WJL].[Machine]
			,          [WJL].[WorkCentre]
			,          [WJL].[Employee]
			,          [WJL].[SetUpRate]
			,          [WJL].[RunTimeRate]
			,          [WJL].[FixedOhRate]
			,          [WJL].[VariableOhRate]
			,          [WJL].[StartUpRate]
			,          [WJL].[TeardownRate]
			,          [WJL].[LabourValue]
			,          [WJL].[EntryDate]
			,          [WJL].[RunTime]		
			,          [WJL].[SetUpTime]	
			,          [WJL].[StartUpTime]	
			,          [WJL].[TeardownTime]
        From
            #WipLabJnl WJL 
			Left Join [Lookups].[CompanyNames] As [cn] 
						On [WJL].[DatabaseName]=[cn].[Company];

--return results
SELECT	  [Company]
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
        , [RunTime]
        , [SetUpTime]
        , [StartUpTime]
        , [TeardownTime] 
From [#LabourDetailsResults] As [r]

drop table [#LabourDetailsResults]
    End;

GO
