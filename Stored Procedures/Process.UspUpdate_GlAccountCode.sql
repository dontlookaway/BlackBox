SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GlAccountCode]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to	GL Account Code
*/

        Set NoCount On;


--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'GlAccountCode' )
           )
            Begin
                Create Table [Lookups].[GlAccountCode]
                    (
                      [Company] Varchar(150)
                    , [GlAccountCode] Char(5)
                    , [GlAccountDescription] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[GlAccountCode];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#OrdersGlAccountCode]
                    (
                      [GlAccountCode] Varchar(5)
                    , [GlAccountDescription] Varchar(150)
                    );

                Insert  [#OrdersGlAccountCode]
                        ( [GlAccountCode]
                        , [GlAccountDescription]
	                    )
                        Select  [t].[GlAccountCode]
                              , [t].[GlAccountDescription]
                        From    ( Select    [GlAccountCode] = 'M'
                                          , [GlAccountDescription] = 'Merchandise expense'
                                  Union
                                  Select    [GlAccountCode] = 'F'
                                          , [GlAccountDescription] = 'Freight-in expense'
                                  Union
                                  Select    [GlAccountCode] = 'O'
                                          , [GlAccountDescription] = 'Other expense'
                                ) [t];

	--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = 'USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #Table1
			( CompanyName )
		Select @DBCode
		End';

	--all companies process the same way
                Select  [CompanyName] = '40'
                      , [O].[GlAccountCode]
                      , [O].[GlAccountDescription]
                Into    [#ResultsGlAccountCode]
                From    [#OrdersGlAccountCode] [O];

                Insert  [Lookups].[GlAccountCode]
                        ( [Company]
                        , [GlAccountCode]
                        , [GlAccountDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [GlAccountCode]
                              , [GlAccountDescription]
                              , @LastUpdated
                        From    [#ResultsGlAccountCode];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[GlAccountCode]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[GlAccountCode]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[GlAccountCode]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_GlAccountCode - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[GlAccountCode]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_GlAccountCode - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[GlAccountCode]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_GlAccountCode - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_GlAccountCode - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_GlAccountCode', NULL, NULL
GO
