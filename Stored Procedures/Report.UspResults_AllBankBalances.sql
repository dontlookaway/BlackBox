SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AllBankBalances]
--Exec [Report].[UspResults_AllBankBalances]
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			15/10/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
Declare @Company VARCHAR(Max)='All'
--remove nocount on to speed up query
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'AssetDepreciation,TblApTerms' 

--create temporary tables to be pulled from different databases, including a column to id
Create Table #Base
    (DatabaseName VARCHAR(150)collate Latin1_General_BIN
    , BaseCcy CHAR(3)collate Latin1_General_BIN
    , BaseCcyName VARCHAR(150)collate Latin1_General_BIN
    );
Create Table #SecondConvert
    (
      DatabaseName VARCHAR(150)collate Latin1_General_BIN
    , SecondConvert CHAR(3)collate Latin1_General_BIN
    , SecondConvertSellRate NUMERIC(20, 7)
    , SecondConvertBuyRate NUMERIC(20, 7)
    );
Create Table #TblCurrency
    (
      DatabaseName VARCHAR(150)collate Latin1_General_BIN
    , [Currency] CHAR(3)collate Latin1_General_BIN
    , [Description] VARCHAR(150)collate Latin1_General_BIN
    , [BuyExchangeRate] NUMERIC(20, 7)
    , [SellExchangeRate] NUMERIC(20, 7)
    );
Create Table #ApBank
    (
      DatabaseName VARCHAR(150) collate Latin1_General_BIN
    , [Bank] VARCHAR(15)		collate Latin1_General_BIN
    , [Description] VARCHAR(50)	collate Latin1_General_BIN
    , [CashGlCode] VARCHAR(50)	collate Latin1_General_BIN
    , [Currency] CHAR(3)
    , [CurrentBalance] NUMERIC(20, 7)
    , [StatementBalance] NUMERIC(20, 7)
    , [OutStandingDeposits] NUMERIC(20, 7)
    , [OutStandingWithdrawals] NUMERIC(20, 7)
    , [PrevMonth1CurrentBalance] NUMERIC(20, 7)
    , [PrevMonth1StatementBalance] NUMERIC(20, 7)
    , [PrevMonth1OutStandingDeposits] NUMERIC(20, 7)
    , [PrevMonth1OutStandingWithdrawals] NUMERIC(20, 7)
    , [PrevMonth2CurrentBalance] NUMERIC(20, 7)
    , [PrevMonth2StatementBalance] NUMERIC(20, 7)
    , [PrevMonth2OutStandingDeposits] NUMERIC(20, 7)
    , [PrevMonth2OutStandingWithdrawals] NUMERIC(20, 7)
    );

--create script to pull data from each db into the tables
	Declare @SQLBase VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
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
	End'
	Declare @SQLSecondConvert VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
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
	End'
	Declare @SQLTblCurrency VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
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
	End'
	Declare @SQLApBank VARCHAR(max) = 'USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
--Only query DBs beginning SysProCompany
'
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'+ --only companies selected in main run, or if companies selected then all
'
IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
, @RequiredCountOfTables INT
, @ActualCountOfTables INT'+
--count number of tables requested (number of commas plus one)
'
Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
--Count of the tables requested how many exist in the db
'
Select @ActualCountOfTables = COUNT(1) FROM sys.tables
Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
--only if the count matches (all the tables exist in the requested db) then run the script
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
End'
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
Print 1
	Exec sp_MSforeachdb @SQLBase
Print 2
	Exec sp_MSforeachdb @SQLSecondConvert
Print 3
	Exec sp_MSforeachdb @SQLTblCurrency
Print 4
	Exec sp_MSforeachdb @SQLApBank
Print 5

--define the results you want to return
Create Table #CurrencyConversions
    (DatabaseName VARCHAR(150)collate Latin1_General_BIN
    , [Currency] CHAR(3)
    , [Description] VARCHAR(150)collate Latin1_General_BIN
    , [BuyExchangeRate] NUMERIC(20, 7)
    , [SellExchangeRate] NUMERIC(20, 7)
    , [BaseCcy] CHAR(3)
    , [BaseCcyName] VARCHAR(150)collate Latin1_General_BIN
    , [SecondConvertBuyRate] NUMERIC(20, 7)
    , [SecondConvertSellRate] NUMERIC(20, 7)
    , [SecondConvert] CHAR(3)
    , RateSell NUMERIC(20, 7)
    , RateBuy NUMERIC(20, 7)
    );
CREATE TABLE #Results
([DatabaseName] VARCHAR(150)
		 , [CompanyName] VARCHAR(150)
         , [Bank] VARCHAR(10)
         , [BankDescription] VARCHAR(150)
         , [CashGlCode] VARCHAR(150)
         , [BankCurrency] CHAR(3)
         , [CurrentBalance] NUMERIC(20,7)
         , [StatementBalance] NUMERIC(20,7) 
         , [OutStandingDeposits] NUMERIC(20,7)
         , [OutStandingWithdrawals] NUMERIC(20,7)
         , [PrevMonth1CurrentBalance] NUMERIC(20,7)
         , [PrevMonth1StatementBalance] NUMERIC(20,7)
         , [PrevMonth1OutStandingDeposits] NUMERIC(20,7)
         , [PrevMonth1OutStandingWithdrawals] NUMERIC(20,7)
         , [PrevMonth2CurrentBalance] NUMERIC(20,7)
         , [PrevMonth2StatementBalance] NUMERIC(20,7)
         , [PrevMonth2OutStandingDeposits] NUMERIC(20,7)
         , [PrevMonth2OutStandingWithdrawals] NUMERIC(20,7)
         , [CurrencyDescription] VARCHAR(150)
         , [BuyExchangeRate] NUMERIC(20,7)
         , [SellExchangeRate] NUMERIC(20,7)
         , [BaseCcy] CHAR(3)
         , [BaseCcyName]VARCHAR(150)
         , [SecondConvertBuyRate] NUMERIC(20,7)
         , [SecondConvertSellRate] NUMERIC(20,7)
         , [SecondConvert] CHAR(3)
         , [RateSell] NUMERIC(20,7)
         , [RateBuy] NUMERIC(20,7)
    
)
--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
Print 6
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
        Select
            [tc].[DatabaseName]
          , [tc].[Currency]
          , [tc].[Description]
          , [tc].[BuyExchangeRate]
          , [tc].[SellExchangeRate]
          , [b].[BaseCcy]
          , [b].[BaseCcyName]
          , [c].[SecondConvertBuyRate]
          , [c].[SecondConvertSellRate]
          , [c].[SecondConvert]
          , RateSell = [tc].[SellExchangeRate] / [c].[SecondConvertSellRate]
          , RateBuy = [tc].[BuyExchangeRate] / [c].[SecondConvertBuyRate]
        From
            [#TblCurrency] As [tc]
        Left Join [#Base] As [b] On [b].[DatabaseName] = [tc].[DatabaseName]
        Left Join [#SecondConvert] As [c] On [c].[DatabaseName] = [tc].[DatabaseName]
        Order By
            [c].[SecondConvert];

Print 7
Insert [#Results]
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
Select [ab].[DatabaseName]
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
From
    [#ApBank] As [ab]
Left Join [#CurrencyConversions] As [cc]
    On [cc].[Currency] = [ab].[Currency]
       And [cc].[DatabaseName] = [ab].[DatabaseName]
Left Join [BlackBox].[Lookups].[CompanyNames] As [cn]
	On [cn].[Company]=[ab].[DatabaseName]

--return results
Print 8
	SELECT * FROM #Results
	Order By [DatabaseName] Asc,[Bank],[SecondConvert] Asc

--tidy 
Drop Table [#Base];
Drop Table [#SecondConvert];
Drop Table [#TblCurrency];
Drop Table [#CurrencyConversions];
Drop Table [#ApBank];
End

GO
