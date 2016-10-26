SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_SalesOrderLineType]
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
                                    And [TABLE_NAME] = 'SalesOrderLineType' )
           )
            Begin
                Create Table [Lookups].[SalesOrderLineType]
                    (
                      [Company] Varchar(150)					collate latin1_general_bin
                    , [LineTypeCode] Char(5)					collate latin1_general_bin
                    , [LineTypeDescription] Varchar(150)		collate latin1_general_bin
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[SalesOrderLineType];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#SalesOrderLineType]
                    (
                      [LineTypeCode] Varchar(5)				collate latin1_general_bin
                    , [LineTypeDescription] Varchar(150)	collate latin1_general_bin
                    );

                Insert  [#SalesOrderLineType]
                        ( [LineTypeCode]
                        , [LineTypeDescription]
	                    )
                        Select  [t].[LineTypeCode]
                              , [t].[LineTypeDescription]
                        From    ( Select    [LineTypeCode] = '1'
                                          , [LineTypeDescription] = 'Stocked Merchandise'
                                  Union
                                  Select    [LineTypeCode] = '4'
                                          , [LineTypeDescription] = 'Freight'
                                  Union
                                  Select    [LineTypeCode] = '5'
                                          , [LineTypeDescription] = 'Miscellaneous Charges'
                                  Union
                                  Select    [LineTypeCode] = '6'
                                          , [LineTypeDescription] = 'Comment Line'
                                  Union
                                  Select    [LineTypeCode] = '7'
                                          , [LineTypeDescription] = 'Non-stocked Merchandise'
                                ) [t];


	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#SalesOrderLineTypeTable1]
                    (
                      [CompanyName] Varchar(150)
                    );

	--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = 'USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #SalesOrderLineTypeTable1
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

	--all companies process the same way
                Select  [T].[CompanyName]
                      , [O].[LineTypeCode]
                      , [O].[LineTypeDescription]
                Into    [#ResultsPoStatus]
                From    [#SalesOrderLineTypeTable1] [T]
                        Cross Join ( Select [LineTypeCode]
                                          , [LineTypeDescription]
                                     From   [#SalesOrderLineType]
                                   ) [O];

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[SalesOrderLineType]
                        ( [Company]
                        , [LineTypeCode]
                        , [LineTypeDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [LineTypeCode]
                              , [LineTypeDescription]
                              , @LastUpdated
                        From    [#ResultsPoStatus];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[SalesOrderLineType]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[SalesOrderLineType]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderLineType]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_SalesOrderLineType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderLineType]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_SalesOrderLineType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[SalesOrderLineType]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_SalesOrderLineType - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_SalesOrderLineType - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_SalesOrderLineType', NULL, NULL
GO
