SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ApSupplierNar]
    (
      @Company Varchar(Max)
    , @Supplier Varchar(Max)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015												
Stored procedure set out to query multiple databases with the same information and return it in a collated format
Returns ApSupplierNar table for PO																				
*/
        Set NoCount Off;
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApSupplierNar'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApSupplierNar]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(15) Collate Latin1_General_BIN
            , [Invoice] Varchar(20) Collate Latin1_General_BIN
            , [NoteType] Char(1) Collate Latin1_General_BIN
            , [Line] Int
            , [Text] Varchar(100) Collate Latin1_General_BIN
            );

	
--create script to pull data from each db into the tables
        Declare @SQLApSupplierNar Varchar(Max) = '
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
				Insert #ApSupplierNar
						( DatabaseName
						, Supplier
						, Invoice
						, NoteType
						, Line
						, Text
						)
				SELECT DatabaseName = @DBCode
					 , Supplier
					 , Invoice
					 , NoteType
					 , Line
					 , Text
				FROM ApSupplierNar
				Where Supplier=''' + @Supplier + '''
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
       -- Print @SQLApSupplierNar;

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLApSupplierNar;

--define the results you want to return

        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [NoteType] Char(1)
            , [Line] Int
            , [Text] Varchar(100)
            );
--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Supplier]
                , [Invoice]
                , [NoteType]
                , [Line]
                , [Text]
                )
                Select  [Company] = [ASN].[DatabaseName]
                      , [ASN].[Supplier]
                      , [ASN].[Invoice]
                      , [ASN].[NoteType]
                      , [ASN].[Line]
                      , [ASN].[Text]
                From    [#ApSupplierNar] As [ASN];
--return results

        Select  [R].[DatabaseName]
              , [R].[Supplier]
              , [R].[Invoice]
              , [R].[NoteType]
              , [R].[Line]
              , [R].[Text]
        From    [#Results] As [R];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'used to return AP supp narrative in documents', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ApSupplierNar', NULL, NULL
GO
