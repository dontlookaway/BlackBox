SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_APDaysToPayment]
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
            @StoredProcName = 'UspResults_APDaysToPayment' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApInvoice,ApInvoicePay,CshApPayments,ApBank'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [InvoiceDate] Date
            , [CurrencyValue] Numeric(20 , 2)
            , [ConvRate] Numeric(20 , 6)
            , [MulDiv] Char(1)
            , [PostCurrency] Varchar(3)
            , [DueDate] Date
            );
        Create Table [#ApInvoicePay]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [JournalDate] Date
            , [TrnValue] Numeric(20 , 2)
            , [PaymentReference] Varchar(50)
            , [PaymentNumber] Varchar(15)
            , [PostCurrency] Varchar(3)
            , [PostConvRate] Numeric(20 , 6)
            , [PostMulDiv] Char(1)
            , [Journal] Int
            , [TrnType] Char(1)
            , [Invoice] Varchar(20)
            );
        Create Table [#CshApPayments]
            (
              [DatabaseName] Varchar(150)
            , [CbTrnDate] Date
            , [GrossValue] Numeric(20 , 2)
            , [NetValue] Numeric(20 , 2)
            , [Supplier] Varchar(15)
            , [Invoice] Varchar(20)
            , [PaymentNumber] Varchar(15)
            , [Bank] Varchar(15)
            );
        Create Table [#ApBank]
            (
              [DatabaseName] Varchar(150)
            , [Description] Varchar(50)
            , [Bank] Varchar(15)
            );



--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''+ Upper(@Company)+ ''' = ''ALL''
			BEGIN
					Insert [#ApBank]
				( [DatabaseName], [Description], [Bank])
					SELECT [DatabaseName]=@DBCode
						 , [AB].[Description]
						 , [AB].[Bank] FROM [ApBank] [AB]

					Insert [#ApInvoice]
				( [DatabaseName], [Supplier], [Invoice], [InvoiceDate], [CurrencyValue], [ConvRate], [MulDiv], [PostCurrency], [DueDate])
					SELECT [DatabaseName]=@DBCode
						 , [AI].[Supplier]
						 , [AI].[Invoice]
						 , [AI].[InvoiceDate]
						 , [AI].[CurrencyValue]
						 , [AI].[ConvRate]
						 , [AI].[MulDiv]
						 , [AI].[PostCurrency]
						 , [AI].[DueDate] FROM [ApInvoice] [AI]

					Insert [#ApInvoicePay]
				( [DatabaseName], [Supplier], [JournalDate], [TrnValue], [PaymentReference], [PaymentNumber], [PostCurrency], [PostConvRate], [PostMulDiv], [Journal], [TrnType], [Invoice])
					SELECT [DatabaseName]=@DBCode
						 , [AIP].[Supplier]
						 , [AIP].[JournalDate]
						 , [AIP].[TrnValue]
						 , [AIP].[PaymentReference]
						 , [AIP].[PaymentNumber]
						 , [AIP].[PostCurrency]
						 , [AIP].[PostConvRate]
						 , [AIP].[PostMulDiv]
						 , [AIP].[Journal]
						 , [AIP].[TrnType]
						 , [AIP].[Invoice] FROM [ApInvoicePay] [AIP]

					Insert [#CshApPayments]
				( [DatabaseName], [CbTrnDate], [GrossValue], [NetValue], [Supplier], [Invoice], [PaymentNumber], [Bank])
					SELECT [DatabaseName]=@DBCode
						 , [CAP].[CbTrnDate]
						 , [CAP].[GrossValue]
						 , [CAP].[NetValue]
						 , [CAP].[Supplier]
						 , [CAP].[Invoice]
						 , [CAP].[PaymentNumber]
						 , [CAP].[Bank] FROM [CshApPayments] [CAP]
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;

--define the results you want to return
        Create Table [#Results]
            (
              [Supplier] Varchar(15)
            --, [SalesOrder] Varchar(20)
            , [Invoice] Varchar(20)
            , [InvoiceDate] Date
            , [DueDate] Date
            , [CurrencyValue] Numeric(20 , 2)
            , [ConvRate] Numeric(20 , 6)
            , [MulDiv] Varchar(1)
            , [PostCurrency] Varchar(3)
            , [LocalValue] Numeric(20 , 2)
            , [JournalDate] Date
            , [TrnTypeDesc] Varchar(250)
            , [TrnValue] Numeric(20 , 2)
            , [InvoiceNotation] Varchar(50)
            , [JournalPostCurrency] Varchar(3)
            , [PostConvRate] Numeric(20 , 6)
            , [PostMulDiv] Varchar(1)
            , [LocalJournalValue] Numeric(20 , 2)
            , [Journal] Int
            , [CbTrnDate] Date
            , [GrossPayment] Numeric(20 , 2)
            , [NetPayment] Numeric(20 , 2)
            , [Bank] Varchar(50)
            , [Company] Varchar(150)
            , [CompanyName] Varchar(250)
            );

        Insert  [#Results]
                ( [Supplier]
                , [Invoice]
                , [InvoiceDate]
                , [DueDate]
                , [CurrencyValue]
                , [ConvRate]
                , [MulDiv]
                , [PostCurrency]
                , [LocalValue]
                , [JournalDate]
                , [TrnTypeDesc]
                , [TrnValue]
                , [InvoiceNotation]
                , [JournalPostCurrency]
                , [PostConvRate]
                , [PostMulDiv]
                , [LocalJournalValue]
                , [Journal]
                , [CbTrnDate]
                , [GrossPayment]
                , [NetPayment]
                , [Bank]
                , [Company]
                , [CompanyName]
                )
                Select  [AI].[Supplier]
                      --, [AI].[SalesOrder]
                      , [AI].[Invoice]
                      , [AI].[InvoiceDate]
                      , [AI].[DueDate]
                      , [AI].[CurrencyValue]
                      , [AI].[ConvRate]
                      , [AI].[MulDiv]
                      , [AI].[PostCurrency]
                      , [LocalValue] = Case When [AI].[MulDiv] = 'D'
                                            Then Convert(Numeric(20 , 2) , [AI].[CurrencyValue]
                                                 / [AI].[ConvRate])
                                            Else Convert(Numeric(20 , 2) , [AI].[CurrencyValue]
                                                 * [AI].[ConvRate])
                                       End
                      , [JournalDate] = Convert(Date , [AIP].[JournalDate])
                      , [AIPTT].[TrnTypeDesc]
                      , [AIP].[TrnValue]
                      , [AIP].[PaymentReference]
                      , [JournalPostCurrency] = [AIP].[PostCurrency]
                      , [AIP].[PostConvRate]
                      , [AIP].[PostMulDiv]
                      , [LocalJournalValue] = Case When [AIP].[PostMulDiv] = 'D'
                                                   Then Convert(Numeric(20 , 2) , [AIP].[TrnValue]
                                                        / [AIP].[PostConvRate])
                                                   Else Convert(Numeric(20 , 2) , [AIP].[TrnValue]
                                                        * [AIP].[PostConvRate])
                                              End
                      , [AIP].[Journal]
                      , [CAP].[CbTrnDate]
                      , [CAP].[GrossValue]
                      , [CAP].[NetValue]
                      , [Bank] = [AB].[Description]
                      , [CN].[Company]
                      , [CN].[CompanyName]
                From    [#ApInvoice] [AI]
                        Left Join [#ApInvoicePay] [AIP]
                            On [AIP].[Supplier] = [AI].[Supplier]
                               And [AIP].[Invoice] = [AI].[Invoice]
                               And [AIP].[DatabaseName] = [AI].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[ArInvoicePayTrnType] [AIPTT]
                            On [AIPTT].[TrnType] = [AIP].[TrnType]
                        Left Join [#CshApPayments] [CAP]
                            On [CAP].[Supplier] = [AIP].[Supplier]
                               And [CAP].[Invoice] = [AIP].[Invoice]
                               And [CAP].[PaymentNumber] = [AIP].[PaymentNumber]
                               And [CAP].[DatabaseName] = [AIP].[DatabaseName]
                        Left Join [#ApBank] [AB]
                            On [AB].[Bank] = [CAP].[Bank]
                               And [AB].[DatabaseName] = [CAP].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                            On [CN].[Company] = [AI].[DatabaseName];

        Set NoCount Off;

        Select  [R].[InvoiceDate]
              , [R].[DueDate]
              , [R].[Invoice]
              , [R].[Supplier]
              , [R].[LocalValue]
              , [R].[CurrencyValue]
              , [ReceivedValue] = Sum([R].[LocalJournalValue])
              , [LatestDate] = Max([R].[JournalDate])
              , [ClosedDate] = Case When Abs([R].[LocalValue]) <> Abs(Sum([R].[LocalJournalValue]))
                                    Then Null
                                    Else Max([R].[JournalDate])
                               End
              , [DaysToCloseFromInvoiceDate] = DateDiff(Day ,
                                                        [R].[InvoiceDate] ,
                                                        Max([R].[JournalDate]))
              , [DaysToCloseFromDueDate] = DateDiff(Day , [R].[DueDate] ,
                                                    Max([R].[JournalDate]))
              , [R].[CompanyName]
        From    [#Results] [R]
        Group By [R].[InvoiceDate]
              , [R].[DueDate]
              , [R].[Invoice]
              , [R].[Supplier]
              , [R].[LocalValue]
              , [R].[CurrencyValue]
              , [R].[CompanyName]
        Order By [R].[InvoiceDate] Desc;

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'returns details on how long it takes for AP to be settled', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_APDaysToPayment', NULL, NULL
GO
