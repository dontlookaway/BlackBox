
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Process].[UspUpdate_PurchaseOrderType]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to
Purchase Order Type
*/

        Set NoCount On;


--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'PurchaseOrderType' )
           )
            Begin
                Create Table [Lookups].[PurchaseOrderType]
                    (
                      [Company] Varchar(150)
                    , [OrderTypeCode] Char(5)
                    , [OrderTypeDescription] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[PurchaseOrderType];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of how codes affect stock
                Create Table [#OrdersPOType]
                    (
                      [OrderTypeCode] Varchar(5)
                    , [OrderTypeDescription] Varchar(150)
                    );

                Insert  [#OrdersPOType]
                        ( [OrderTypeCode]
                        , [OrderTypeDescription]
	                    )
                        Select  [t].[OrderTypeCode]
                              , [t].[OrderTypeDescription]
                        From    ( Select    [OrderTypeCode] = 'L'
                                          , [OrderTypeDescription] = 'Local'
                                  Union
                                  Select    [OrderTypeCode] = 'I'
                                          , [OrderTypeDescription] = 'Import'
                                  Union
                                  Select    [OrderTypeCode] = 'O'
                                          , [OrderTypeDescription] = 'Other'
                                ) [t];

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1POType]
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
		Insert #Table1POType
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

	--all companies process the same way
                Select  [T].[CompanyName]
                      , [O].[OrderTypeCode]
                      , [O].[OrderTypeDescription]
                Into    [#ResultsPOType]
                From    [#Table1POType] [T]
                        Left Join [#OrdersPOType] [O] On 1 = 1;

	--placeholder for anomalous results that are different to master list
	--Update #ResultsPOType
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  [Lookups].[PurchaseOrderType]
                        ( [Company]
                        , [OrderTypeCode]
                        , [OrderTypeDescription]
                        , [LastUpdated]
	                    )
                        Select  [CompanyName]
                              , [OrderTypeCode]
                              , [OrderTypeDescription]
                              , @LastUpdated
                        From    [#ResultsPOType];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[PurchaseOrderType]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[PurchaseOrderType]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderType]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderType]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[PurchaseOrderType]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_PurchaseOrderType - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_PurchaseOrderType - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
