SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GLAccountType]
    (
      @PrevCheck INT --if count is less than previous don't update
    , @HoursBetweenUpdates INT
    )
As --exec  [Process].[UspUpdate_GLAccountType] 0,-1
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with AccountType Names		///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			18/11/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

        Set NoCount On;

        Print 1;
--check if table exists and create if it doesn't
        If ( Not Exists ( Select
                            *
                          From
                            INFORMATION_SCHEMA.TABLES
                          Where
                            TABLE_SCHEMA = 'Lookups'
                            And TABLE_NAME = 'GLAccountType' )
           )
            Begin
                Print 2;
                Create --drop --alter 
				Table Lookups.GLAccountType
                    (
                      GLAccountType VARCHAR(10)
                    , GLAccountTypeDesc Varchar(250)
                    , LastUpdated DATETIME2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DATETIME2;

        Print 3;
        Select
            @LastDate = MAX(LastUpdated)
        From
            Lookups.GLAccountType;

        If @LastDate Is Null
            Or DATEDIFF(Hour, @LastDate, GETDATE()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DATETIME2;
                Select
                    @LastUpdated = GETDATE();
                Print 4;
	--create master list of how codes affect stock
                Create --drop --alter 
	Table #GLAccountType
                    (
                      AccountType VARCHAR(10) Collate Latin1_General_BIN
                    , AccountTypeDescription VARCHAR(250)
                    );

                Print 5;
                Insert  #GLAccountType
                        ( AccountType
                        , AccountTypeDescription
                        )
                        Select
                            AccountType
                          , AccountTypeDescription
                        From
                            (
                              Select
                                AccountType = 'A'
                              , AccountTypeDescription = 'Asset'
                              Union
                              Select
                                AccountType = 'C'
                              , AccountTypeDescription = 'Capital'
                              Union
                              Select
                                AccountType = 'E'
                              , AccountTypeDescription = 'Expense'
                              Union
                              Select
                                AccountType = 'L'
                              , AccountTypeDescription = 'Liability'
                              Union
                              Select
                                AccountType = 'R'
                              , AccountTypeDescription = 'Revenue'
                              Union
                              Select
                                AccountType = 'S'
                              , AccountTypeDescription = 'Statistical'
                              Union
                              Select
                                AccountType = 'T'
                              , AccountTypeDescription = 'Template'
                            ) t;


					
	--all companies process the same way
                Select
                    [AccountType]= Coalesce(GAT.[AccountType],GM.AccountType)
                  , [AccountTypeDescription] = COALESCE([AccountTypeDescription], 'Unknown')
                Into
                    #ResultsAccountTypeName 
                From
                    #GLAccountType As GAT
					Full Outer Join SysproCompany40.dbo.GenMaster As GM
					On GM.AccountType = GAT.AccountType;


	--placeholder for anomalous results that are different to master list
	--Update #ResultsPoStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  [Lookups].GLAccountType
                        ( [GLAccountType]
                        , [GLAccountTypeDesc]
                        , [LastUpdated]
	                    )
                        Select
                            [rcn].[AccountType]
                          , [rcn].[AccountTypeDescription]
                          , @LastUpdated
                        From
                            #ResultsAccountTypeName As [rcn];

                If @PrevCheck = 1
                    Begin
                        Declare
                            @CurrentCount INT
                          , @PreviousCount INT;
	
                        Select
                            @CurrentCount = COUNT(*)
                        From
                            Lookups.[GLAccountType] As [cn]
                        Where
                            LastUpdated = @LastUpdated;

                        Select
                            @PreviousCount = COUNT(*)
                        From
                            Lookups.[GLAccountType] As [cn]
                        Where
                            LastUpdated <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete
                                    Lookups.[GLAccountType]
                                Where
                                    LastUpdated = @LastDate;
                                Print 'UspUpdate_GLAccountType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + CAST(@CurrentCount As VARCHAR(5))
                                    + ' Previous Count = '
                                    + CAST(@PreviousCount As VARCHAR(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete
                                    Lookups.[GLAccountType]
                                Where
                                    LastUpdated <> @LastUpdated
                                    Or [LastUpdated] Is Null;
                                Print 'UspUpdate_GLAccountType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete
                            Lookups.[GLAccountType]
                        Where
                            LastUpdated <> @LastUpdated;
                        Print 'UspUpdate_GLAccountType - Update applied successfully';
                    End;
            End;
    End;
    If DATEDIFF(Hour, @LastDate, GETDATE()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_GLAccountType - Table was last updated at '
                + CAST(@LastDate As VARCHAR(255)) + ' no update applied';
        End;
GO
