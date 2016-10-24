
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_BankBalances]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with BankBalances details
transaction types when relating to inventory changes
--Exec [Process].[UspUpdate_BankBalances]@PrevCheck =0    , @HoursBetweenUpdates =0
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

        Declare @ListOfTables Varchar(Max) = 'ApBank'; 

--create script to pull data from each db into the tables
        Declare @Company Varchar(max) = 'All';
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
			Declare @LD date =''' + Cast(@LoadDate As Varchar(50))
            + '''
				Insert  [BlackBox].[Lookups].[BankBalances]
        ( [DatabaseName], [CompanyName], [Bank], [BankDescription], [CashGlCode], [BankCurrency], [CurrentBalance], [StatementBalance], [OutStandingDeposits], [OutStandingWithdrawals], [PrevMonth1CurrentBalance], [PrevMonth1StatementBalance], [PrevMonth1OutStandingDeposits], [PrevMonth1OutStandingWithdrawals], [PrevMonth2CurrentBalance], [PrevMonth2StatementBalance], [PrevMonth2OutStandingDeposits], [PrevMonth2OutStandingWithdrawals], [DateOfBalance])
         Select  Db_Name()
                          , [CN].[CompanyName]
                          , [AP].[Bank]
                          , [AP].[Description]
                          , [AP].[CashGlCode]
                          , [AP].[Currency]
                          , [AP].[CbCurBalLoc1]
                          , [AP].[CbStmtBal1]
                          , [AP].[OutstDep1]
                          , [AP].[OutstWith1]
                          , [AP].[CbCurBal2]
                          , [AP].[CbStmtBal2]
                          , [AP].[OutstDep2]
                          , [AP].[OutstWith2]
                          , [AP].[CbCurBal3]
                          , [AP].[CbStmtBal3]
                          , [AP].[OutstDep3]
                          , [AP].[OutstWith3]
                          , @LD
                    From    [dbo].[ApBank] [AP]
                            Cross Join [BlackBox].[Lookups].[CompanyNames] As [CN]
                    Where   [CN].[Company] = @DBCode;
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQLBanks

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLBanks;

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
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_BankBalances', NULL, NULL
GO
