SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_BankBalances]
--Exec [Process].[UspUpdate_BankBalances]@PrevCheck =0    , @HoursBetweenUpdates =0
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with BankBalances details				///
///			transaction types when relating to inventory changes																	///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			15/1/2016	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

--remove nocount on to speed up query
        Set NoCount On;

        Declare @LoadDate Date = GetDate();
--Create Lookup table if it doesn't exist
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'BankBalances' )
           )
            Begin

                Create Table [Lookups].[BankBalances]
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
                    , [DateOfBalance] Date
                    , [DateTimeOfBalance] DateTime2 Default GetDate()
                    );
            End;

--remove any balances loaded already today
        Delete  From [Lookups].[BankBalances]
        Where   [DateOfBalance] = @LoadDate;
--check last time run and update if it's been longer than @HoursBetweenUpdates hours - Not needed for bank balances
--Declare @LastDate DATETIME2

--Select @LastDate=MAX([DateOfBalance])
--From Lookups.BankBalances

 --       If @LastDate Is Null
 --           Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
 --           Begin
	----Set time of run
 --               Declare @LastUpdated DateTime2;
 --                   Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApBank'; 

--create temporary tables to be pulled from different databases, including a column to id - changed to direct insert
                --Create Table [#Table1]
                --    (
                --      [Company] Varchar(150)
                --    , [BankBalances] Varchar(150)
                --    );

--create script to pull data from each db into the tables
        Declare @Company Varchar(30) = 'All';
        Declare @SQLBanks Varchar(Max) = '
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
			Where name In (Select Value Collate Latin1_General_Bin From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
            '
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Declare @LD date ='''+Cast(@LoadDate As Varchar(50))+'''
				Insert  [BlackBox].[Lookups].[BankBalances]
        ( [DatabaseName], [CompanyName], [Bank], [BankDescription], [CashGlCode], [BankCurrency], [CurrentBalance], [StatementBalance], [OutStandingDeposits], [OutStandingWithdrawals], [PrevMonth1CurrentBalance], [PrevMonth1StatementBalance], [PrevMonth1OutStandingDeposits], [PrevMonth1OutStandingWithdrawals], [PrevMonth2CurrentBalance], [PrevMonth2StatementBalance], [PrevMonth2OutStandingDeposits], [PrevMonth2OutStandingWithdrawals], [DateOfBalance])
        Select  Db_Name()
              , [CN].[CompanyName]
              , [Bank]
              , [Description]
              , [CashGlCode]
              , [Currency]
              , [CbCurBalLoc1]
              , [CbStmtBal1]
              , [OutstDep1]
              , [OutstWith1]
              , [CbCurBal2]
              , [CbStmtBal2]
              , [OutstDep2]
              , [OutstWith2]
              , [CbCurBal3]
              , [CbStmtBal3]
              , [OutstDep3]
              , [OutstWith3]
              , @LD
        From    [dbo].[ApBank]
                Cross Join [BlackBox].[Lookups].[CompanyNames] As [CN] 
		Where [CN].[Company] = @DBCode;
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQLBanks

--execute script against each db, populating the base tables
        --Print Len(@SQLBanks);
        Exec [sys].[sp_MSforeachdb] @SQLBanks;

        If ( Select Count(1)
             From   [Lookups].[BankBalances] As [BB]
             Where  [BB].[DateOfBalance] = Cast(GetDate() As Date)
           ) > 1
            Begin
                Print 'UspUpdate_BankBalances - Update applied successfully';    
            End;
        If ( Select Count(1)
             From   [Lookups].[BankBalances] As [BB]
             Where  [BB].[DateOfBalance] = Cast(GetDate() As Date)
           ) = 0
            Begin
                Declare @ErrorMessage Varchar(150)= 'UspUpdate_BankBalances - Update Error';
                Raiserror (@ErrorMessage,16,1);
            End;
    End;	

GO
