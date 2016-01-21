SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Process].[UspUpdate_InvMaster_PartCategory]
    (
      @PrevCheck INT --if count is less than previous don't update
    , @HoursBetweenUpdates INT
    )
As --exec  [Process].[UspUpdate_InvMaster_PartCategory] 0,-1
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with Company Names		///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			28/9/2015	Chris Johnson			Initial version created																///
///			19/11/2015	Chris Johnson			Added company 21																	///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

        Set NoCount On;

        Print 1;
--check if table exists and create if it doesn't
        If ( Not Exists ( Select
                            *
                          From
                            INFORMATION_SCHEMA.TABLES
                          Where
                            TABLE_SCHEMA = 'Lookups'
                            And TABLE_NAME = 'InvMaster_PartCategory' )
           )
            Begin
                Print 2;
                Create --drop --alter 
				Table Lookups.InvMaster_PartCategory
                    (
                      PartCategoryCode Varchar(10)
					  ,PartCategoryDescription Varchar(150)
					  ,LastUpdated DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DATETIME2;

        Print 3;
        Select
            @LastDate = MAX(LastUpdated)
        From
            Lookups.PurchaseOrderStatus;

        If @LastDate Is Null
            Or DATEDIFF(Hour, @LastDate, GETDATE()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DATETIME2;
                Select
                    @LastUpdated = GETDATE();
                Print 4;
	--create master list of how codes affect stock
                Create --drop --alter 
	Table [#PartCategoryList]
                    (
                      PartCategory VARCHAR(150)
                    , PartCategoryName VARCHAR(250)
                    );

                Print 5;
                Insert  [#PartCategoryList]
                        ( [PartCategory]
                        , [PartCategoryName]
                        )
                        Select
                            PartCategory
                          , PartCategoryName
                        From
                            (
                              Select
                                PartCategory = 'M'
                              , PartCategoryName = 'Made-in'
                              Union
                              Select
                                PartCategory = 'B'
                              , PartCategoryName = 'Bought Out'
                              Union
                              Select
                                PartCategory = 'S'
                              , PartCategoryName = 'Sub-contracted'
                              Union
                              Select
                                PartCategory = 'G'
                              , PartCategoryName = 'Phantom/Ghost Part'
                              Union
                              Select
                                PartCategory = 'P'
                              , PartCategoryName = 'Planning bill'
                              Union
                              Select
                                PartCategory = 'K'
                              , PartCategoryName = 'Kit Part'
                              Union
                              Select
                                PartCategory = 'C'
                              , PartCategoryName = 'Co-Product'
                              Union
                              Select
                                PartCategory = 'Y'
                              , PartCategoryName = 'By-product'
                              Union
                              Select
                                PartCategory = 'N'
                              , PartCategoryName = 'Notional part'

                            ) t;

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
	--create script to pull data from each db into the tables

					
	--all companies process the same way


	--placeholder for anomalous results that are different to master list
	--Update #ResultsPoStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  [Lookups].[InvMaster_PartCategory]
                        ( [PartCategoryCode]
                        , [PartCategoryDescription]
						, LastUpdated
                        )

                        Select
                            CL.PartCategory
                          , CL.PartCategoryName
                          , @LastUpdated
                        From
                            #PartCategoryList As CL;

                If @PrevCheck = 1
                    Begin
                        Declare
                            @CurrentCount INT
                          , @PreviousCount INT;
	
                        Select
                            @CurrentCount = COUNT(*)
                        From
                            Lookups.[InvMaster_PartCategory] As [cn]
                        Where
                            LastUpdated = @LastUpdated;

                        Select
                            @PreviousCount = COUNT(*)
                        From
                            Lookups.[InvMaster_PartCategory] As [cn]
                        Where
                            LastUpdated <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete
                                    Lookups.[InvMaster_PartCategory]
                                Where
                                    LastUpdated = @LastDate;
                                Print 'UspUpdate_InvMaster_PartCategory - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + CAST(@CurrentCount As VARCHAR(5))
                                    + ' Previous Count = '
                                    + CAST(@PreviousCount As VARCHAR(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete
                                    Lookups.[InvMaster_PartCategory]
                                Where
                                    LastUpdated <> @LastUpdated
                                    Or [LastUpdated] Is Null;
                                Print 'UspUpdate_InvMaster_PartCategory - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete
                            Lookups.[InvMaster_PartCategory]
                        Where
                            LastUpdated <> @LastUpdated;
                        Print 'UspUpdate_InvMaster_PartCategory - Update applied successfully';
                    End;
            End;
    End;
    If DATEDIFF(Hour, @LastDate, GETDATE()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_InvMaster_PartCategory - Table was last updated at '
                + CAST(@LastDate As VARCHAR(255)) + ' no update applied';
        End;
GO
