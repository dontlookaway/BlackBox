
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AllBankBalances]
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--Exec [Report].[UspResults_AllBankBalances]
*/
        Declare @Company Varchar(Max)= 'All';

        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#Base]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [BaseCcy] Char(3) Collate Latin1_General_BIN
            , [BaseCcyName] Varchar(150) Collate Latin1_General_BIN
            );
        Create Table [#SecondConvert]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [SecondConvert] Char(3) Collate Latin1_General_BIN
            , [SecondConvertSellRate] Numeric(20 , 7)
            , [SecondConvertBuyRate] Numeric(20 , 7)
            );
        Create Table [#TblCurrency]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Currency] Char(3) Collate Latin1_General_BIN
            , [Description] Varchar(150) Collate Latin1_General_BIN
            , [BuyExchangeRate] Numeric(20 , 7)
            , [SellExchangeRate] Numeric(20 , 7)
            );
        Create Table [#ApBank]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Bank] Varchar(15) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            , [CashGlCode] Varchar(50) Collate Latin1_General_BIN
            , [Currency] Char(3)
            , [CurrentBalance] Numeric(20 , 7)
            , [StatementBalance] Numeric(20 , 7)
            , [OutStandingDeposits] Numeric(20 , 7)
            , [OutStandingWithdrawals] Numeric(20 , 7)
            , [PrevMonth1CurrentBalance] Numeric(20 , 7)
            , [PrevMonth1StatementBalance] Numeric(20 , 7)
            , [PrevMonth1OutStandingDeposits] Numeric(20 , 7)
            , [PrevMonth1OutStandingWithdrawals] Numeric(20 , 7)
            , [PrevMonth2CurrentBalance] Numeric(20 , 7)
            , [PrevMonth2StatementBalance] Numeric(20 , 7)
            , [PrevMonth2OutStandingDeposits] Numeric(20 , 7)
            , [PrevMonth2OutStandingWithdrawals] Numeric(20 , 7)
            );

--create script to pull data from each db into the tables
        Declare @SQLBase Varchar(Max) = '
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
				Insert  [#Base]
						( [DatabaseName]
						, [BaseCcy]
						, [BaseCcyName]
						)
				Select
					@DBCode
					, BaseCcy = [tc].[Currency]
					, BaseCcyName = [tc].[Description]
				From
					[dbo].[TblCurrency] As [tc]
				Where [tc].[BuyExchangeRate] = 1;
			End
	End';
        Declare @SQLSecondConvert Varchar(Max) = '
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
				Insert  [#SecondConvert]
						( [DatabaseName]
						, [SecondConvert]
						, [SecondConvertSellRate]
						, [SecondConvertBuyRate]
						)
				Select @DBCode
					, SecondConvert = [tc].[Currency]
					, SecondConvertSellRate = [tc].[SellExchangeRate]
					, SecondConvertBuyRate = [tc].[BuyExchangeRate]
				From [dbo].[TblCurrency] As [tc];
			End
	End';
        Declare @SQLTblCurrency Varchar(Max) = '
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
				Insert  [#TblCurrency]
				( [DatabaseName]
				, [Currency]
				, [Description]
				, [BuyExchangeRate]
				, [SellExchangeRate]
				)
				Select @DBCode
				  , [tc].[Currency]
				  , [tc].[Description]
				  , [tc].[BuyExchangeRate]
				  , [tc].[SellExchangeRate]
				From [TblCurrency] As [tc];
			End
	End';
        Declare @SQLApBank Varchar(Max) = 'USE [?];
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
Insert  [#ApBank]
( [DatabaseName], [Bank]
, [Description], [CashGlCode]
, [Currency], [CurrentBalance]
, [StatementBalance], [OutStandingDeposits]
, [OutStandingWithdrawals], [PrevMonth1CurrentBalance]
, [PrevMonth1StatementBalance], [PrevMonth1OutStandingDeposits]
, [PrevMonth1OutStandingWithdrawals], [PrevMonth2CurrentBalance]
, [PrevMonth2StatementBalance], [PrevMonth2OutStandingDeposits]
, [PrevMonth2OutStandingWithdrawals]
)
Select
@DBCode, [Bank]
, [Description], [CashGlCode]
, [Currency], [CurrentBalance] = [CbCurBalLoc1]
, [StatementBalance] = [CbStmtBal1], [OutStandingDeposits] = OutstDep1
, [OutStandingWithdrawals] = OutstWith1, [PrevMonth1CurrentBalance] = CbCurBal2
, [PrevMonth1StatementBalance] = CbStmtBal2, [PrevMonth1OutStandingDeposits] = OutstDep2
, [PrevMonth1OutStandingWithdrawals] = OutstWith2, [PrevMonth2CurrentBalance] = CbCurBal3
, [PrevMonth2StatementBalance] = CbStmtBal3, [PrevMonth2OutStandingDeposits] = OutstDep3
, [PrevMonth2OutStandingWithdrawals] = OutstWith3
From dbo.ApBank;
End
End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
--Print 1
        Exec [Process].[ExecForEachDB] @cmd = @SQLBase;
--Print 2
        Exec [Process].[ExecForEachDB] @cmd = @SQLSecondConvert;
--Print 3
        Exec [Process].[ExecForEachDB] @cmd = @SQLTblCurrency;
--Print 4
        Exec [Process].[ExecForEachDB] @cmd = @SQLApBank;
--Print 5

--define the results you want to return
        Create Table [#CurrencyConversions]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Currency] Char(3)
            , [Description] Varchar(150) Collate Latin1_General_BIN
            , [BuyExchangeRate] Numeric(20 , 7)
            , [SellExchangeRate] Numeric(20 , 7)
            , [BaseCcy] Char(3)
            , [BaseCcyName] Varchar(150) Collate Latin1_General_BIN
            , [SecondConvertBuyRate] Numeric(20 , 7)
            , [SecondConvertSellRate] Numeric(20 , 7)
            , [SecondConvert] Char(3)
            , [RateSell] Numeric(20 , 7)
            , [RateBuy] Numeric(20 , 7)
            );
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [CompanyName] Varchar(150)
            , [Bank] Varchar(10)
            , [BankDescription] Varchar(150)
            , [CashGlCode] Varchar(150)
            , [BankCurrency] Char(3)
            , [CurrentBalance] Numeric(20 , 7)
            , [StatementBalance] Numeric(20 , 7)
            , [OutStandingDeposits] Numeric(20 , 7)
            , [OutStandingWithdrawals] Numeric(20 , 7)
            , [PrevMonth1CurrentBalance] Numeric(20 , 7)
            , [PrevMonth1StatementBalance] Numeric(20 , 7)
            , [PrevMonth1OutStandingDeposits] Numeric(20 , 7)
            , [PrevMonth1OutStandingWithdrawals] Numeric(20 , 7)
            , [PrevMonth2CurrentBalance] Numeric(20 , 7)
            , [PrevMonth2StatementBalance] Numeric(20 , 7)
            , [PrevMonth2OutStandingDeposits] Numeric(20 , 7)
            , [PrevMonth2OutStandingWithdrawals] Numeric(20 , 7)
            , [CurrencyDescription] Varchar(150)
            , [BuyExchangeRate] Numeric(20 , 7)
            , [SellExchangeRate] Numeric(20 , 7)
            , [BaseCcy] Char(3)
            , [BaseCcyName] Varchar(150)
            , [SecondConvertBuyRate] Numeric(20 , 7)
            , [SecondConvertSellRate] Numeric(20 , 7)
            , [SecondConvert] Char(3)
            , [RateSell] Numeric(20 , 7)
            , [RateBuy] Numeric(20 , 7)
            );
--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Print 6;
        Insert  [#CurrencyConversions]
                ( [DatabaseName]
                , [Currency]
                , [Description]
                , [BuyExchangeRate]
                , [SellExchangeRate]
                , [BaseCcy]
                , [BaseCcyName]
                , [SecondConvertBuyRate]
                , [SecondConvertSellRate]
                , [SecondConvert]
                , [RateSell]
                , [RateBuy]
                )
                Select  [tc].[DatabaseName]
                      , [tc].[Currency]
                      , [tc].[Description]
                      , [tc].[BuyExchangeRate]
                      , [tc].[SellExchangeRate]
                      , [b].[BaseCcy]
                      , [b].[BaseCcyName]
                      , [c].[SecondConvertBuyRate]
                      , [c].[SecondConvertSellRate]
                      , [c].[SecondConvert]
                      , [RateSell] = [tc].[SellExchangeRate]
                        / [c].[SecondConvertSellRate]
                      , [RateBuy] = [tc].[BuyExchangeRate]
                        / [c].[SecondConvertBuyRate]
                From    [#TblCurrency] As [tc]
                        Left Join [#Base] As [b] On [b].[DatabaseName] = [tc].[DatabaseName]
                        Left Join [#SecondConvert] As [c] On [c].[DatabaseName] = [tc].[DatabaseName]
                Order By [c].[SecondConvert];

        Print 7;
        Insert  [#Results]
                ( [DatabaseName]
                , [CompanyName]
                , [Bank]
                , [BankDescription]
                , [CashGlCode]
                , [BankCurrency]
                , [CurrentBalance]
                , [StatementBalance]
                , [OutStandingDeposits]
                , [OutStandingWithdrawals]
                , [PrevMonth1CurrentBalance]
                , [PrevMonth1StatementBalance]
                , [PrevMonth1OutStandingDeposits]
                , [PrevMonth1OutStandingWithdrawals]
                , [PrevMonth2CurrentBalance]
                , [PrevMonth2StatementBalance]
                , [PrevMonth2OutStandingDeposits]
                , [PrevMonth2OutStandingWithdrawals]
                , [CurrencyDescription]
                , [BuyExchangeRate]
                , [SellExchangeRate]
                , [BaseCcy]
                , [BaseCcyName]
                , [SecondConvertBuyRate]
                , [SecondConvertSellRate]
                , [SecondConvert]
                , [RateSell]
                , [RateBuy]
                )
                Select  [ab].[DatabaseName]
                      , [cn].[CompanyName]
                      , [ab].[Bank]
                      , [ab].[Description]
                      , [ab].[CashGlCode]
                      , [ab].[Currency]
                      , [ab].[CurrentBalance]
                      , [ab].[StatementBalance]
                      , [ab].[OutStandingDeposits]
                      , [ab].[OutStandingWithdrawals]
                      , [ab].[PrevMonth1CurrentBalance]
                      , [ab].[PrevMonth1StatementBalance]
                      , [ab].[PrevMonth1OutStandingDeposits]
                      , [ab].[PrevMonth1OutStandingWithdrawals]
                      , [ab].[PrevMonth2CurrentBalance]
                      , [ab].[PrevMonth2StatementBalance]
                      , [ab].[PrevMonth2OutStandingDeposits]
                      , [ab].[PrevMonth2OutStandingWithdrawals]
                      , [cc].[Description]
                      , [cc].[BuyExchangeRate]
                      , [cc].[SellExchangeRate]
                      , [cc].[BaseCcy]
                      , [cc].[BaseCcyName]
                      , [cc].[SecondConvertBuyRate]
                      , [cc].[SecondConvertSellRate]
                      , [cc].[SecondConvert]
                      , [cc].[RateSell]
                      , [cc].[RateBuy]
                From    [#ApBank] As [ab]
                        Left Join [#CurrencyConversions] As [cc] On [cc].[Currency] = [ab].[Currency]
                                                              And [cc].[DatabaseName] = [ab].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [cn].[Company] = [ab].[DatabaseName];

--return results
        Print 8;
        Select  *
        From    [#Results]
        Order By [DatabaseName] Asc
              , [Bank]
              , [SecondConvert] Asc;

--tidy 
        Drop Table [#Base];
        Drop Table [#SecondConvert];
        Drop Table [#TblCurrency];
        Drop Table [#CurrencyConversions];
        Drop Table [#ApBank];
    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'returns list of all bank balances', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AllBankBalances', NULL, NULL
GO
