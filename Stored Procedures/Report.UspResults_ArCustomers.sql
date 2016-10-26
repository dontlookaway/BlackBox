SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ArCustomers]
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
List of all AR customers
--exec [Report].[UspResults_ArCustomers] 10
*/

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ArCustomers' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ArCustomer'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ArCustomer]
            (
              [DatabaseName] Varchar(150)	collate latin1_general_bin
            , [Customer] Varchar(25)		collate latin1_general_bin
            , [Name] Varchar(255)			collate latin1_general_bin
            , [InvoiceCount] Int
            , [DateLastSale] DateTime2
            , [DateLastPay] DateTime2
            , [DateCustAdded] DateTime2
            , [Contact] Varchar(100)		collate latin1_general_bin
            , [Telephone] Varchar(20)		collate latin1_general_bin
            , [Email] Varchar(255)			collate latin1_general_bin
            , [Nationality] Char(3)			collate latin1_general_bin
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
				Insert [#ArCustomer]
        ( [DatabaseName]
        , [Customer]
        , [Name]
        , [InvoiceCount]
        , [DateLastSale]
        , [DateLastPay]
        , [DateCustAdded]
        , [Contact]
        , [Telephone]
        , [Email]
        , [Nationality]
        )
Select @DBCode
	,[Customer]
	,[Name]
	,[InvoiceCount]
	,[DateLastSale]
	,[DateLastPay]
	,[DateCustAdded]
	,[Contact]
	,[Telephone]
	,[Email]
	,[Nationality]
 FROM [dbo].[ArCustomer] As [ac]	
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table

--return results
        Select  [cn].[CompanyName]
              , [ac].[Customer]
              , [ac].[Name]
              , [ac].[InvoiceCount]
              , [DateLastSale] = Cast([ac].[DateLastSale] As Date)
              , [DateLastPay] = Cast([ac].[DateLastPay] As Date)
              , [DateCustAdded] = Cast([ac].[DateCustAdded] As Date)
              , [Contact] = Case When [ac].[Contact] = '' Then Null
                                 Else [ac].[Contact]
                            End
              , [ac].[Telephone]
              , [ac].[Email]
              , [ac].[Nationality]
        From    [#ArCustomer] As [ac]
                Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [ac].[DatabaseName] = [cn].[Company] Collate Latin1_General_BIN;

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of all AR customers', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ArCustomers', NULL, NULL
GO
