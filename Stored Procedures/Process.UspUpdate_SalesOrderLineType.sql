SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create Proc [Process].[UspUpdate_SalesOrderLineType]
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
                            And TABLE_NAME = 'SalesOrderLineType' )
           )
            Begin
                Create --drop --alter 
Table Lookups.SalesOrderLineType
                    (
                      Company VARCHAR(150)
                    , LineTypeCode CHAR(5)
                    , LineTypeDescription VARCHAR(150)
                    , LastUpdated DATETIME2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DATETIME2;

        Select
            @LastDate = MAX(LastUpdated)
        From
            Lookups.SalesOrderLineType;

        If @LastDate Is Null
            Or DATEDIFF(Hour, @LastDate, GETDATE()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DATETIME2;
                    Select
                        @LastUpdated = GETDATE();

	--create master list of how codes affect stock
                Create --drop --alter 
	Table #SalesOrderLineType
                    (
                      LineTypeCode VARCHAR(5)
                    , LineTypeDescription VARCHAR(150)
                    );

                Insert  #SalesOrderLineType
                        ( LineTypeCode
                        , LineTypeDescription
	                    )
                        Select
                            LineTypeCode
                          , LineTypeDescription
                        From
                            (
                              Select
                                LineTypeCode = '1'
                              , LineTypeDescription = 'Stocked Merchandise'
                              Union
                              Select
                                LineTypeCode = '4'
                              , LineTypeDescription = 'Freight'
                              Union
                              Select
                                LineTypeCode = '5'
                              , LineTypeDescription = 'Miscellaneous Charges'
                              Union
                              Select
                                LineTypeCode = '6'
                              , LineTypeDescription = 'Comment Line'
                              Union
                              Select
                                LineTypeCode = '7'
                              , LineTypeDescription = 'Non-stocked Merchandise'
                            
                            ) t;

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table #SalesOrderLineTypeTable1
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
		Insert #SalesOrderLineTypeTable1
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
                Exec sp_MSforeachdb
                    @SQL;

	--all companies process the same way
                Select
                    CompanyName
                  , O.LineTypeCode
                  , O.LineTypeDescription
                Into
                    #ResultsPoStatus
                From
                    #SalesOrderLineTypeTable1 T
                Cross Join (SELECT [LineTypeCode]
                                 , [LineTypeDescription] FROM  #SalesOrderLineType) O;

	--placeholder for anomalous results that are different to master list
	--Update #ResultsPoStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  Lookups.SalesOrderLineType
                        ( Company
                        , LineTypeCode
                        , LineTypeDescription
                        , LastUpdated
	                    )
                        Select
                            CompanyName
                          , LineTypeCode
                          , LineTypeDescription
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
                            Lookups.SalesOrderLineType
                        Where
                            LastUpdated = @LastUpdated;

                        Select
                            @PreviousCount = COUNT(*)
                        From
                            Lookups.SalesOrderLineType
                        Where
                            LastUpdated <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete
                                    Lookups.SalesOrderLineType
                                Where
                                    LastUpdated = @LastUpdated;
                                Print 'UspUpdate_SalesOrderLineType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + CAST(@CurrentCount As VARCHAR(5))
                                    + ' Previous Count = '
                                    + CAST(@PreviousCount As VARCHAR(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete
                                    Lookups.SalesOrderLineType
                                Where
                                    LastUpdated <> @LastUpdated;
                                Print 'UspUpdate_SalesOrderLineType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete
                            Lookups.SalesOrderLineType
                        Where
                            LastUpdated <> @LastUpdated;
                        Print 'UspUpdate_SalesOrderLineType - Update applied successfully';
                    End;
            End;
    End;
    If DATEDIFF(Hour, @LastDate, GETDATE()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_SalesOrderLineType - Table was last updated at '
                + CAST(@LastDate As VARCHAR(255)) + ' no update applied';
        End;
GO
