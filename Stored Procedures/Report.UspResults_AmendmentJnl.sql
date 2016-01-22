
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AmendmentJnl]
(@Company VARCHAR(Max))
As
Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015														///
Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'ApAmendmentJnl' 

--create temporary tables to be pulled from different databases, including a column to id
	Create TABLE #ApAmendmentJnl
	(	[Company] VARCHAR(50)
		, [JnlDate] DATETIME2
		, [JnlTime] DECIMAL
		, [JnlLine] DECIMAL
		, [Supplier] VARCHAR(15)
		, [JournalPrinted] CHAR(1)
		, [ChangeFlag] CHAR(1)
		, [ColumnName] VARCHAR(50)
		, [Before] VARCHAR(255)
		, [After] VARCHAR(255)
		, [OperatorCode] VARCHAR(20)
	)

--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(Max) = '
	USE [?];
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
					Insert #ApAmendmentJnl
						( Company
						, JnlDate
						, JnlTime
						, JnlLine
						, Supplier
						, JournalPrinted
						, ChangeFlag
						, ColumnName
						, Before
						, After
						, OperatorCode
						)
				Select @DBCode
					, JnlDate
					, JnlTime
					, JnlLine
					, Supplier
					, JournalPrinted
					, ChangeFlag
					, ColumnName
					, Before
					, After
					, OperatorCode
				From
				ApAmendmentJnl With ( NoLock )
			End
	End'

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec [Process].[ExecForEachDB] @cmd = @SQL

--define the results you want to return

--Placeholder to create indexes as required --*** not required as no joins are in place***

--script to combine base data and insert into results table --*** Not required as is direct dump***

--return results
	Select [Company]
         , [JnlDate]
         , [JnlTime]
         , [JnlLine]
         , [Supplier]
         , [JournalPrinted]
         , [ChangeFlag]
         , [ColumnName]
         , [Before]
         , [After]
         , [OperatorCode] From #ApAmendmentJnl

End


GO
