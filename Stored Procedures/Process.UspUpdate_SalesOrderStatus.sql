SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create Proc [Process].[UspUpdate_SalesOrderStatus]
    (
      @PrevCheck INT --if count is less than previous don't update
    , @HoursBetweenUpdates INT
    )
As
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to		///
///			Purchase Order Status details																	///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			29/9/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

        Set NoCount On;


--check if table exists and create if it doesn't
        If ( Not Exists ( Select
                            *
                          From
                            INFORMATION_SCHEMA.TABLES
                          Where
                            TABLE_SCHEMA = 'Lookups'
                            And TABLE_NAME = 'SalesOrderStatus' )
           )
            Begin
                Create --drop --alter 
Table Lookups.SalesOrderStatus
                    (
                      Company VARCHAR(150)
                    , OrderStatusCode CHAR(5)
                    , OrderStatusDescription VARCHAR(150)
                    , LastUpdated DATETIME2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DATETIME2;

        Select
            @LastDate = MAX(LastUpdated)
        From
            Lookups.SalesOrderStatus;

        If @LastDate Is Null
            Or DATEDIFF(Hour, @LastDate, GETDATE()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DATETIME2;
                    Select
                        @LastUpdated = GETDATE();

	--create master list of how codes affect stock
                Create --drop --alter 
	Table #OrdersSalesStatus
                    (
                      OrderStatusCode VARCHAR(5)
                    , OrderStatusDescription VARCHAR(150)
                    );

                Insert  #OrdersSalesStatus
                        ( OrderStatusCode
                        , OrderStatusDescription
	                    )
                        Select
                            OrderStatusCode
                          , OrderStatusDescription
                        From
                            (
                              Select
                                OrderStatusCode = '0'
                              , OrderStatusDescription = 'In process'
                              Union
                              Select
                                OrderStatusCode = '1'
                              , OrderStatusDescription = 'Open Order'
                              Union
                              Select
                                OrderStatusCode = '2'
                              , OrderStatusDescription = 'Open Backorder'
                              Union
                              Select
                                OrderStatusCode = '3'
                              , OrderStatusDescription = 'Released Backorder'
                              Union
                              Select
                                OrderStatusCode = '4'
                              , OrderStatusDescription = 'In Warehouse'
                              Union
                              Select
                                OrderStatusCode = '8'
                              , OrderStatusDescription = 'Ready to Invoice'
                              Union
                              Select
                                OrderStatusCode = '9'
                              , OrderStatusDescription = 'Complete'
                              Union
                              Select
                                OrderStatusCode = '*'
                              , OrderStatusDescription = 'Cancelled during entry'
							  Union
                              Select
                                OrderStatusCode = '\'
                              , OrderStatusDescription = 'Cancelled'
                              Union
                              Select
                                OrderStatusCode = 'F'
                              , OrderStatusDescription = 'Forward'
                              Union
                              Select
                                OrderStatusCode = 'S'
                              , OrderStatusDescription = 'Suspense'
                            ) t;

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table #Table1
                    (
                      CompanyName VARCHAR(150)
                    );

	--create script to pull data from each db into the tables
                Declare @SQL VARCHAR(Max) = '
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
                Exec sp_MSforeachdb
                    @SQL;

	--all companies process the same way
                Select
                    CompanyName
                  , O.OrderStatusCode
                  , O.OrderStatusDescription
                Into
                    #ResultsPoStatus
                From
                    #Table1 T
                Cross Join (SELECT [OrderStatusCode]
                                 , [OrderStatusDescription] FROM  #OrdersSalesStatus) O;

	--placeholder for anomalous results that are different to master list
	--Update #ResultsPoStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  Lookups.SalesOrderStatus
                        ( Company
                        , OrderStatusCode
                        , OrderStatusDescription
                        , LastUpdated
	                    )
                        Select
                            CompanyName
                          , OrderStatusCode
                          , OrderStatusDescription
                          , @LastUpdated
                        From
                            #ResultsPoStatus;

                If @PrevCheck = 1
                    Begin
                        Declare
                            @CurrentCount INT
                          , @PreviousCount INT;
	
                        Select
                            @CurrentCount = COUNT(*)
                        From
                            Lookups.SalesOrderStatus
                        Where
                            LastUpdated = @LastUpdated;

                        Select
                            @PreviousCount = COUNT(*)
                        From
                            Lookups.SalesOrderStatus
                        Where
                            LastUpdated <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete
                                    Lookups.SalesOrderStatus
                                Where
                                    LastUpdated = @LastUpdated;
                                Print 'UspUpdate_SalesOrderStatus - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + CAST(@CurrentCount As VARCHAR(5))
                                    + ' Previous Count = '
                                    + CAST(@PreviousCount As VARCHAR(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete
                                    Lookups.SalesOrderStatus
                                Where
                                    LastUpdated <> @LastUpdated;
                                Print 'UspUpdate_SalesOrderStatus - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete
                            Lookups.SalesOrderStatus
                        Where
                            LastUpdated <> @LastUpdated;
                        Print 'UspUpdate_SalesOrderStatus - Update applied successfully';
                    End;
            End;
    End;
    If DATEDIFF(Hour, @LastDate, GETDATE()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_SalesOrderStatus - Table was last updated at '
                + CAST(@LastDate As VARCHAR(255)) + ' no update applied';
        End;
GO
