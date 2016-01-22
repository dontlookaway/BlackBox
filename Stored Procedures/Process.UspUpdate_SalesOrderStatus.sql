
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Process].[UspUpdate_SalesOrderStatus]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to Purchase Order Status details
*/

        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'SalesOrderStatus' )
           )
            Begin
                Create Table [Lookups].[SalesOrderStatus]
                    (
                      [Company] Varchar(150)
                    , [OrderStatusCode] Char(5)
                    , [OrderStatusDescription] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[SalesOrderStatus];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#OrdersSalesStatus]
                    (
                      [OrderStatusCode] Varchar(5)
                    , [OrderStatusDescription] Varchar(150)
                    );

                Insert  [#OrdersSalesStatus]
                        ( [OrderStatusCode]
                        , [OrderStatusDescription]
	                    )
                        Select  [t].[OrderStatusCode]
                              , [t].[OrderStatusDescription]
                        From    ( Select    [OrderStatusCode] = '0'
                                          , [OrderStatusDescription] = 'In process'
                                  Union
                                  Select    [OrderStatusCode] = '1'
                                          , [OrderStatusDescription] = 'Open Order'
                                  Union
                                  Select    [OrderStatusCode] = '2'
                                          , [OrderStatusDescription] = 'Open Backorder'
                                  Union
                                  Select    [OrderStatusCode] = '3'
                                          , [OrderStatusDescription] = 'Released Backorder'
                                  Union
                                  Select    [OrderStatusCode] = '4'
                                          , [OrderStatusDescription] = 'In Warehouse'
                                  Union
                                  Select    [OrderStatusCode] = '8'
                                          , [OrderStatusDescription] = 'Ready to Invoice'
                                  Union
                                  Select    [OrderStatusCode] = '9'
                                          , [OrderStatusDescription] = 'Complete'
                                  Union
                                  Select    [OrderStatusCode] = '*'
                                          , [OrderStatusDescription] = 'Cancelled during entry'
                                  Union
                                  Select    [OrderStatusCode] = '\'
                                          , [OrderStatusDescription] = 'Cancelled'
                                  Union
                                  Select    [OrderStatusCode] = 'F'
                                          , [OrderStatusDescription] = 'Forward'
                                  Union
                                  Select    [OrderStatusCode] = 'S'
                                          , [OrderStatusDescription] = 'Suspense'
                                ) [t];

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1]
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
		Insert #Table1
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

	--all companies process the same way
                Select  [T].[CompanyName]
                      , [O].[OrderStatusCode]
                      , [O].[OrderStatusDescription]
                Into    [#ResultsPoStatus]
                From    [#Table1] [T]
                        Cross Join ( Select [OrderStatusCode]
                                          , [OrderStatusDescription]
                                     From   [#OrdersSalesStatus]
                                   ) [O];

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[SalesOrderStatus]
                        ( [Company]
                        , [OrderStatusCode]
                        , [OrderStatusDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [OrderStatusCode]
                              , [OrderStatusDescription]
                              , @LastUpdated
                        From    [#ResultsPoStatus];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[SalesOrderStatus]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[SalesOrderStatus]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderStatus]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_SalesOrderStatus - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderStatus]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_SalesOrderStatus - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[SalesOrderStatus]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_SalesOrderStatus - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_SalesOrderStatus - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
