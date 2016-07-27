SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GlExpenseCode]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'GlExpenseCode' )
           )
            Begin
                Create Table [Lookups].[GlExpenseCode]
                    (
                      [Company] Varchar(150)
                    , [GlExpenseCode] Char(5)
                    , [GlExpenseDescription] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[GlExpenseCode];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#OrdersGlExpenseCode]
                    (
                      [GlExpenseCode] Varchar(5)
                    , [GlExpenseDescription] Varchar(150)
                    );

                Insert  [#OrdersGlExpenseCode]
                        ( [GlExpenseCode]
                        , [GlExpenseDescription]
	                    )
                        Select  [t].[GlExpenseCode]
                              , [t].[GlExpenseDescription]
                        From    ( Select    [GlExpenseCode] = 'M'
                                          , [GlExpenseDescription] = 'Merchandise expense'
                                  Union
                                  Select    [GlExpenseCode] = 'F'
                                          , [GlExpenseDescription] = 'Freight-in expense'
                                  Union
                                  Select    [GlExpenseCode] = 'O'
                                          , [GlExpenseDescription] = 'Other expense'
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
                      , [O].[GlExpenseCode]
                      , [O].[GlExpenseDescription]
                Into    [#ResultsGlExpenseCode]
                From    [#OrdersGlExpenseCode] [O];
		

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[GlExpenseCode]
                        ( [Company]
                        , [GlExpenseCode]
                        , [GlExpenseDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [GlExpenseCode]
                              , [GlExpenseDescription]
                              , @LastUpdated
                        From    [#ResultsGlExpenseCode];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[GlExpenseCode]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[GlExpenseCode]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[GlExpenseCode]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_GlExpenseCode - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[GlExpenseCode]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_GlExpenseCode - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[GlExpenseCode]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_GlExpenseCode - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_GlExpenseCode - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
