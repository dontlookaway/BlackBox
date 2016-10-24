SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AllSuppliers]
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
            @StoredProcName = 'UspResults_AllSuppliers' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApSupplier]
            (
              [DatabaseName] sysname
            , [Supplier] Varchar(15)
            , [SupplierName] Varchar(50)
            , [SupShortName] Varchar(20)
            , [Branch] Varchar(10)
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
				Insert  [#ApSupplier]
        ( [DatabaseName]
        , [Supplier]
        , [SupplierName]
        , [SupShortName]
        , [Branch]
        )
        Select  @DBCode
              , [ApS].[Supplier]
              , [ApS].[SupplierName]
              , [ApS].[SupShortName]
              , [ApS].[Branch]
        From    [dbo].[ApSupplier] [ApS];
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
        Select  [ApS].[DatabaseName]
              , [ApS].[Supplier]
              , [ApS].[SupplierName]
              , [ApS].[SupShortName]
              , [ApS].[Branch]
        From    [#ApSupplier] [ApS];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'list of all suppliers', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AllSuppliers', NULL, NULL
GO
