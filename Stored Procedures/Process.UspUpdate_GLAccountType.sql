SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GLAccountType]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )
As
    Begin

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'GLAccountType' )
           )
            Begin
                Create Table [Lookups].[GLAccountType]
                    (
                      [GLAccountType] Varchar(10)
                    , [GLAccountTypeDesc] Varchar(250)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[GLAccountType];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();
	--create master list of how codes affect stock
                Create Table [#GLAccountType]
                    (
                      [AccountType] Varchar(10) Collate Latin1_General_BIN
                    , [AccountTypeDescription] Varchar(250)
                    );

                Insert  [#GLAccountType]
                        ( [AccountType]
                        , [AccountTypeDescription]
                        )
                        Select  [t].[AccountType]
                              , [t].[AccountTypeDescription]
                        From    ( Select    [AccountType] = 'A'
                                          , [AccountTypeDescription] = 'Asset'
                                  Union
                                  Select    [AccountType] = 'C'
                                          , [AccountTypeDescription] = 'Capital'
                                  Union
                                  Select    [AccountType] = 'E'
                                          , [AccountTypeDescription] = 'Expense'
                                  Union
                                  Select    [AccountType] = 'L'
                                          , [AccountTypeDescription] = 'Liability'
                                  Union
                                  Select    [AccountType] = 'R'
                                          , [AccountTypeDescription] = 'Revenue'
                                  Union
                                  Select    [AccountType] = 'S'
                                          , [AccountTypeDescription] = 'Statistical'
                                  Union
                                  Select    [AccountType] = 'T'
                                          , [AccountTypeDescription] = 'Template'
                                ) [t];


					
	--all companies process the same way
                Select  [AccountType] = Coalesce([GAT].[AccountType] ,
                                                 [GM].[AccountType])
                      , [AccountTypeDescription] = Coalesce([GAT].[AccountTypeDescription] ,
                                                            'Unknown')
                Into    [#ResultsAccountTypeName]
                From    [#GLAccountType] As [GAT]
                        Full Outer Join [SysproCompany40].[dbo].[GenMaster] As [GM]
                            On [GM].[AccountType] = [GAT].[AccountType]
                Group By Coalesce([GAT].[AccountType] , [GM].[AccountType])
                      , Coalesce([AccountTypeDescription] , 'Unknown');


	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[GLAccountType]
                        ( [GLAccountType]
                        , [GLAccountTypeDesc]
                        , [LastUpdated]
	                    )
                        Select  [rcn].[AccountType]
                              , [rcn].[AccountTypeDescription]
                              , @LastUpdated
                        From    [#ResultsAccountTypeName] As [rcn];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[GLAccountType] As [cn]
                        Where   [cn].[LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[GLAccountType] As [cn]
                        Where   [cn].[LastUpdated] <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[GLAccountType]
                                Where   [LastUpdated] = @LastDate;
                                Print 'UspUpdate_GLAccountType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[GLAccountType]
                                Where   [LastUpdated] <> @LastUpdated
                                        Or [LastUpdated] Is Null;
                                Print 'UspUpdate_GLAccountType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[GLAccountType]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_GLAccountType - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_GLAccountType - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
