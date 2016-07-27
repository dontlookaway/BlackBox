SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_PurchaseOrderStatus]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Numeric(5,2)
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to	Purchase Order Status details
*/

        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'PurchaseOrderStatus' )
           )
            Begin
                Create Table [Lookups].[PurchaseOrderStatus]
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
        From    [Lookups].[PurchaseOrderStatus];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > (@HoursBetweenUpdates*60)
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                    Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#OrdersPOStatus]
                    (
                      [OrderStatusCode] Varchar(5)
                    , [OrderStatusDescription] Varchar(150)
                    );

                Insert  [#OrdersPOStatus]
                        ( [OrderStatusCode]
                        , [OrderStatusDescription]
	                    )
                        Select  [t].[OrderStatusCode]
                              , [t].[OrderStatusDescription]
                        From    ( Select    [OrderStatusCode] = '0'
                                          , [OrderStatusDescription] = 'In process'
                                  Union
                                  Select    [OrderStatusCode] = '1'
                                          , [OrderStatusDescription] = 'Ready to print'
                                  Union
                                  Select    [OrderStatusCode] = '4'
                                          , [OrderStatusDescription] = 'Order printed'
                                  Union
                                  Select    [OrderStatusCode] = '9'
                                          , [OrderStatusDescription] = 'Completed'
                                  Union
                                  Select    [OrderStatusCode] = '*'
                                          , [OrderStatusDescription] = 'Cancelled'
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
                        Left Join [#OrdersPOStatus] [O] On 1 = 1;

	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[PurchaseOrderStatus]
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
                        From    [Lookups].[PurchaseOrderStatus]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[PurchaseOrderStatus]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderStatus]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderStatus - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderStatus]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderStatus - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[PurchaseOrderStatus]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_PurchaseOrderStatus - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= (@HoursBetweenUpdates*60)
        Begin
            Print 'UspUpdate_PurchaseOrderStatus - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
