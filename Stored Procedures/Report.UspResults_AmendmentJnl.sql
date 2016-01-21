SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AmendmentJnl]
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
///			7/9/2015	Chris Johnson			Changed to use of udf_SplitString to define tables to return						///
///			10/9/2015	Chris Johnson			amend to replace SysproCompany40..K3_vw_ApAmendmentJnlConsol						///
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

/*
K3 query being replaced
Create View [dbo].[K3_vw_ApAmendmentJnlConsol]
As
Select        '10' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany10.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '11' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany11.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '20' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany20.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '21' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany21.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '22' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany22.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '40' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany40.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '41' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany41.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '42' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany42.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '43' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany43.dbo.ApAmendmentJnl With (NoLock)
Union All
Select        '70' As Company, JnlDate, JnlTime, JnlLine, Supplier, JournalPrinted, ChangeFlag, ColumnName, Before, After, OperatorCode
From            SysproCompany70.dbo.ApAmendmentJnl With (NoLock)
*/



--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'ApAmendmentJnl' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #ApAmendmentJnl
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
	Exec sp_MSforeachdb @SQL

--define the results you want to return --*** Not required as is direct dump***
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required --*** not required as no joins are in place***
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table --*** Not required as is direct dump***
	--Insert #Results
	--        ( DatabaseName, Results )
	--Select DatabaseName,ColumnName From #Table1

--return results
	Select * From #ApAmendmentJnl

End


GO
