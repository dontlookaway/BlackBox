SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_MCompleteFlag]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'MCompleteFlag' )
           )
            Begin
                Create Table [Lookups].[MCompleteFlag]
                    (
                      [Company] Varchar(150) Collate Latin1_General_BIN
                    , [MCompleteFlagCode] Char(5) Collate Latin1_General_BIN
                    , [MCompleteFlagDescription] Varchar(150) Collate Latin1_General_BIN
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[MCompleteFlag];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#Orders]
                    (
                      [MCompleteFlagCode] Varchar(5) Collate Latin1_General_BIN
                    , [MCompleteFlagDescription] Varchar(150) Collate Latin1_General_BIN
                    );

                Insert  [#Orders]
                        ( [MCompleteFlagCode]
                        , [MCompleteFlagDescription]
	                    )
                        Select  [t].[MCompleteFlagCode]
                              , [t].[MCompleteFlagDescription]
                        From    ( Select    [MCompleteFlagCode] = 'Y'
                                          , [MCompleteFlagDescription] = 'Yes'
                                  Union
                                  Select    [MCompleteFlagCode] = 'N'
                                          , [MCompleteFlagDescription] = 'No'
                                  Union
                                  Select    [MCompleteFlagCode] = ' '
                                          , [MCompleteFlagDescription] = 'No'
                                ) [t];

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1]
                    (
                      [CompanyName] Varchar(150)
                    );

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

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

	--all companies process the same way
                Select  [T].[CompanyName]
                      , [O].[MCompleteFlagCode]
                      , [O].[MCompleteFlagDescription]
                Into    [#ResultsMFlag]
                From    [#Table1] [T]
                        Left Join [#Orders] [O]
                            On 1 = 1;

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[MCompleteFlag]
                        ( [Company]
                        , [MCompleteFlagCode]
                        , [MCompleteFlagDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [MCompleteFlagCode]
                              , [MCompleteFlagDescription]
                              , @LastUpdated
                        From    [#ResultsMFlag];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[MCompleteFlag]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[MCompleteFlag]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[MCompleteFlag]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_MCompleteFlag - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[MCompleteFlag]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_MCompleteFlag - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[MCompleteFlag]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_MCompleteFlag - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_MCompleteFlag - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_MCompleteFlag', NULL, NULL
GO
