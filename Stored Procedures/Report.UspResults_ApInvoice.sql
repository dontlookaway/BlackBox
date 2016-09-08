SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_ApInvoice]
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
            @StoredProcName = 'UspResults_ApInvoice' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApInvoice'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [JournalDate] Date
            , [Journal] Int
            , [InvoiceDate] Date
            , [DiscountDate] Date
            , [DueDate] Date
            , [Reference] Varchar(30)
            , [InvoiceStatus] Char(1)
            , [Currency] Char(3)
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [ExchangeRate] Numeric(15 , 8)
            , [CurrencyValue] Numeric(20 , 2)
            , [PostCurrency] Char(3)
            , [ConvRate] Numeric(15 , 8)
            , [PaymentNumber] Varchar(15)
            );



--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#ApInvoice]
						( [DatabaseName]
						, [Supplier]
						, [Invoice]
						, [JournalDate]
						, [Journal]
						, [InvoiceDate]
						, [DiscountDate]
						, [DueDate]
						, [Reference]
						, [InvoiceStatus]
						, [Currency]
						, [InvoiceYear]
						, [InvoiceMonth]
						, [ExchangeRate]
						, [CurrencyValue]
						, [PostCurrency]
						, [ConvRate]
						, [PaymentNumber]
						)
				SELECT @DBCode
						, [AI].[Supplier]
						, [AI].[Invoice]
						, [AI].[JournalDate]
						, [AI].[Journal]
						, [AI].[InvoiceDate]
						, [AI].[DiscountDate]
						, [AI].[DueDate]
						, [AI].[Reference]
						, [AI].[InvoiceStatus]
						, [AI].[Currency]
						, [AI].[InvoiceYear]
						, [AI].[InvoiceMonth]
						, [AI].[ExchangeRate]
						, [AI].[CurrencyValue]
						, [AI].[PostCurrency]
						, [AI].[ConvRate]
						, [AI].[PaymentNumber]
				 FROM [dbo].[ApInvoice] [AI]        
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
        Select  [AI].[DatabaseName]
              , [AI].[Supplier]
              , [AI].[Invoice]
              , [AI].[JournalDate]
              , [AI].[Journal]
              , [AI].[InvoiceDate]
              , [AI].[DiscountDate]
              , [AI].[DueDate]
              , [AI].[Reference]
              , [AI].[InvoiceStatus]
              , [AI].[Currency]
              , [AI].[InvoiceYear]
              , [AI].[InvoiceMonth]
              , [AI].[ExchangeRate]
              , [AI].[CurrencyValue]
              , [AI].[PostCurrency]
              , [AI].[ConvRate]
              , [AI].[PaymentNumber]
        From    [#ApInvoice] [AI];

    End;

GO
