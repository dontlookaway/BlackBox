
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Report].[UspResults_ListAllCompanies]
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure created by Chris Johnson, Prometic Group September 2015 to return a list of all SysPro databases
for use in report dropdowns
*/
        Declare @Company Varchar(3)= 'All';
--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = ''; 
		--no tables required as querying variables

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#Table1]
            (
              [CompanyName] Varchar(150)
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
			--Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
			--		, @RequiredCountOfTables INT
			--		, @ActualCountOfTables INT'
            + ----removed table count from template
            '--
			--Select @RequiredCountOfTables=BlackBox.dbo.[Udf_CountText]('','',@ListOfTables)+1'
            + ----removed table count from template
            '
			--Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			--Where name In (Select Value Collate Latin1_General_BIN From LocalDev.dbo.udfSplitString(@ListOfTables,'','')) '
            + ----removed table count from template
            '
			--If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #Table1
					( CompanyName )
				Select @DBCode
				
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
        Print @SQL;

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#Results]
            (
              [CompanyName] Varchar(150)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [CompanyName]
                )
                Select  [CompanyName]
                From    [#Table1]
                Union
                Select  'All';

--return results
        Select  [CompanyName]
        From    [#Results]
        Order By Case When [CompanyName] = 'All' Then 0
                      When IsNumeric([CompanyName]) = 1 Then 1
                      Else 2
                 End Asc
              , [CompanyName] Asc;


    End;

GO
