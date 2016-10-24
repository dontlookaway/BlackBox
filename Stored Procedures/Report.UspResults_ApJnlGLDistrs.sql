SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_ApJnlGLDistrs]
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
            @StoredProcName = 'UspResults_Template' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApJnlSummary,ApJnlDistrib'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApJnlDists]
            (
              [DatabaseName] Varchar(150)
            , [Invoice] Varchar(20)
            , [Supplier] Varchar(15)
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Journal] Int
            , [EntryNumber] Int
            , [SubEntry] Int
            , [SupplierGlCode] Varchar(35)
            , [TrnDate] Date
            , [ExpenseGlCode] Varchar(35)
            , [DistrValue] Numeric(20 , 3)
            , [Reference] Varchar(30)
            );

        

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert  [#ApJnlDists]
						( [DatabaseName]
						, [Invoice]
						, [Supplier]
						, [TrnYear]
						, [TrnMonth]
						, [Journal]
						, [EntryNumber]
						, [SubEntry]
						, [SupplierGlCode]
						, [TrnDate]
						, [ExpenseGlCode]
						, [DistrValue]
						, [Reference]
						)
                Select  @DBCode
						, [AJS].[Invoice]
						, [AJS].[Supplier]
						, [AJS].[TrnYear]
						, [AJS].[TrnMonth]
						, [AJS].[Journal]
						, [AJS].[EntryNumber]
						, [AJD].[SubEntry]
						, [AJS].[SupplierGlCode]
						, [AJS].[TrnDate]
						, [ExpenseGlCode] = Case When [AJD].[ExpenseGlCode] = ''''
													Then Null
													Else [AJD].[ExpenseGlCode]
													End
						, [AJD].[DistrValue]
						, [Reference] = Case When [AJD].[Reference] = ''''
													Then Null
													Else [AJD].[Reference]
													End
                From    [dbo].[ApJnlSummary] [AJS]
                        Inner Join [dbo].[ApJnlDistrib] [AJD]
                            On [AJD].[TrnYear] = [AJS].[TrnYear]
                               And [AJD].[TrnMonth] = [AJS].[TrnMonth]
                               And [AJD].[Journal] = [AJS].[Journal]
                               And [AJD].[EntryNumber] = [AJS].[EntryNumber]
                               And [AJD].[AnalysisEntry] = [AJS].[AnalysisEntry];	
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table


        Set NoCount Off;
--return results
        Select  [AJD].[DatabaseName]
              , [AJD].[Invoice]
              , [AJD].[Supplier]
              , [AJD].[TrnYear]
              , [AJD].[TrnMonth]
              , [AJD].[Journal]
              , [AJD].[EntryNumber]
              , [AJD].[SubEntry]
              , [AJD].[SupplierGlCode]
              , [AJD].[TrnDate]
              , [AJD].[ExpenseGlCode]
              , [AJD].[DistrValue]
              , [AJD].[Reference]
        From    [#ApJnlDists] [AJD];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'details of the general ledger distribution from accounts payable with journals', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ApJnlGLDistrs', NULL, NULL
GO
