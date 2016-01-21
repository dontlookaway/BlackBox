SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE --drop --alter
Proc --exec
[Report].[UspResults_ListAllCompanies]
--(@Company VARCHAR(Max)) --company not required
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to return a list of all SysPro databases		///
///			for use in report dropdowns																								///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			7/9/2015	Chris Johnson			Initial version created																///
///			10/9/2015	Chris Johnson			Updated to exclude dbs ending SRS													///
///			10/9/2015	Chris Johnson			Amended sort function to do ALL, numbers, then letters								///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
Declare @Company VARCHAR(3)='All'
--remove nocount on to speed up query
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = '' 
		--no tables required as querying variables

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #Table1
	(	CompanyName VARCHAR(150)
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
			--Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
			--		, @RequiredCountOfTables INT
			--		, @ActualCountOfTables INT'+
			----removed table count from template
			'--
			--Select @RequiredCountOfTables=BlackBox.dbo.[Udf_CountText]('','',@ListOfTables)+1'+
			----removed table count from template
			'
			--Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			--Where name In (Select Value Collate Latin1_General_BIN From LocalDev.dbo.udfSplitString(@ListOfTables,'','')) '+
			----removed table count from template
			'
			--If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #Table1
					( CompanyName )
				Select @DBCode
				
			End
	End'

--Enable this function to check script changes (try to run script directly against db manually)
Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL

--define the results you want to return
	Create Table #Results
	(CompanyName VARCHAR(150))

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert #Results
	        ( CompanyName)
	Select CompanyName From #Table1
	Union
    Select 'All'

--return results
	Select CompanyName From #Results
	Order By Case When CompanyName = 'All' Then 0
					When ISNUMERIC(CompanyName)=1 Then 1
					Else 2 End Asc,
					CompanyName Asc


End

GO
