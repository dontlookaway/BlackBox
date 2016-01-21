SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_Labour]
--Exec [Report].[UspResults_Labour] 10
(@Company VARCHAR(Max))
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
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'AssetDepreciation,TblApTerms' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE [#WipLabJnl]
	(	DatabaseName		VARCHAR(150)	 Collate Latin1_General_BIN
	    ,EntryMonth			DATE
		,EntryDate			DATETIME2
		,[Employee]			VARCHAR(20)
		,[RunTime]			NUMERIC(20,7)
		,[RunTimeRate]		NUMERIC(20,7)
		,[SetUpTime]		NUMERIC(20,7)
		,[SetUpRate]		NUMERIC(20,7)
		,[StartUpTime]		NUMERIC(20,7)
		,[StartUpRate]		NUMERIC(20,7)
		,[TeardownTime]		NUMERIC(20,7)
		,[TeardownRate]		NUMERIC(20,7)
		,[LabourValue]		NUMERIC(20,7)
		,[FixedOhRate]		NUMERIC(20,7)
		,[VariableOhRate]	NUMERIC(20,7)
		,[WorkCentre]		VARCHAR(150)
		,[Job]				VARCHAR(50)
	)

--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(max) = 'USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
--Only query DBs beginning SysProCompany
'
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'+ --only companies selected in main run, or if companies selected then all
	'
	IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'+
		--count number of tables requested (number of commas plus one)
		'
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
		--Count of the tables requested how many exist in the db
		'
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
		--only if the count matches (all the tables exist in the requested db) then run the script
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
End'

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL

--define the results you want to return
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	--Insert #Results
	--        ( DatabaseName, Results )
	--Select DatabaseName,ColumnName FROM #Table1

--return results
	SELECT [wlj].[DatabaseName]
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
	From [#WipLabJnl] As [wlj]
	Left Join [Lookups].[CompanyNames] As [cn]
		On [wlj].[DatabaseName]=[cn].[Company]

End

GO
