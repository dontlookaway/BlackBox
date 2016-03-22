
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_TrnTypeModifier]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to
transaction types when relating to inventory changes
*/
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'TrnTypeAmountModifier' )
           )
            Begin
                Create Table [Lookups].[TrnTypeAmountModifier]
                    (
                      [Company] Varchar(150)
                    , [TrnType] Char(5)
                    , [AmountModifier] Int
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[TrnTypeAmountModifier];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#AmountsTTM]
                    (
                      [TrnType] Char(5)
                    , [amountmodifier] Int
                    );

                Insert  [#AmountsTTM]
                        ( [TrnType]
                        , [amountmodifier]
			            )
                        Select  [t].[TrnType]
                              , [t].[AmountModifier]
                        From    ( Select    [TrnType] = 'R'
                                          , [AmountModifier] = 1
                                  Union
                                  Select    [TrnType] = 'I'
                                          , [AmountModifier] = -1
                                  Union
                                  Select    [TrnType] = 'P'
                                          , [AmountModifier] = 0
                                  Union
                                  Select    [TrnType] = 'T'
                                          , [AmountModifier] = 1
                                  Union
                                  Select    [TrnType] = 'A'
                                          , [AmountModifier] = 1
                                  Union
                                  Select    [TrnType] = 'C'
                                          , [AmountModifier] = 0
                                  Union
                                  Select    [TrnType] = 'M'
                                          , [AmountModifier] = 0
                                  Union
                                  Select    [TrnType] = 'B'
                                          , [AmountModifier] = 1
                                  Union
                                  Select    [TrnType] = 'S'
                                          , [AmountModifier] = -1
                                  Union
                                  Select    [TrnType] = 'D'
                                          , [AmountModifier] = -1
                                ) [t];

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1TTM]
                    (
                      [CompanyName] Varchar(150)
                    );

	--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = '
		USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
                    + --Only query DBs beginning SysProCompany
                    '
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #Table1TTM
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

	--all companies process the same way
                Select  [T].[CompanyName]
                      , [A].[TrnType]
                      , [A].[amountmodifier]
                Into    [#ResultsTTm]
                From    [#Table1TTM] [T]
                        Left Join [#AmountsTTM] [A] On 1 = 1;

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[TrnTypeAmountModifier]
                        ( [Company]
                        , [TrnType]
                        , [AmountModifier]
                        , [LastUpdated]
                        )
                        Select  [CompanyName]
                              , [TrnType]
                              , [amountmodifier]
                              , @LastUpdated
                        From    [#ResultsTTm];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[TrnTypeAmountModifier]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[TrnTypeAmountModifier]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[TrnTypeAmountModifier]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_TrnTypeModifier - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[TrnTypeAmountModifier]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_TrnTypeModifier - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[TrnTypeAmountModifier]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_TrnTypeModifier - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_TrnTypeModifier - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
