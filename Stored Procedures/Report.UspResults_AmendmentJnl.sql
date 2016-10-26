SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AmendmentJnl]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
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


        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_AmendmentJnl' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApAmendmentJnl'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApAmendmentJnl]
            (
              [Company] Varchar(50)			 Collate Latin1_General_BIN
            , [JnlDate] DateTime2			 
            , [JnlTime] Decimal				 
            , [JnlLine] Decimal				 
            , [Supplier] Varchar(15)		 Collate Latin1_General_BIN
            , [JournalPrinted] Char(1)		 Collate Latin1_General_BIN
            , [ChangeFlag] Char(1)			 Collate Latin1_General_BIN
            , [ColumnName] Varchar(50)		 Collate Latin1_General_BIN
            , [Before] Varchar(255)			 Collate Latin1_General_BIN
            , [After] Varchar(255)			 Collate Latin1_General_BIN
            , [OperatorCode] Varchar(20)	 Collate Latin1_General_BIN
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
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return

--Placeholder to create indexes as required --*** not required as no joins are in place***

--script to combine base data and insert into results table --*** Not required as is direct dump***

--return results
        Select  [Company]
              , [JnlDate]
              , [JnlTime]
              , [JnlLine]
              , [Supplier]
              , [JournalPrinted]
              , [ChangeFlag]
              , [ColumnName]
              , [Before]
              , [After]
              , [OperatorCode]
        From    [#ApAmendmentJnl];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'details from the amendment jnl', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AmendmentJnl', NULL, NULL
GO
