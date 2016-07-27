SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_InvMaster_PartCategory]
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
                                    And [TABLE_NAME] = 'InvMaster_PartCategory' )
           )
            Begin
                Create Table [Lookups].[InvMaster_PartCategory]
                    (
                      [PartCategoryCode] Varchar(10)
                    , [PartCategoryDescription] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[PurchaseOrderStatus];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();
	--create master list of how codes affect stock
                Create Table [#PartCategoryList]
                    (
                      [PartCategory] Varchar(150)
                    , [PartCategoryName] Varchar(250)
                    );

                Insert  [#PartCategoryList]
                        ( [PartCategory]
                        , [PartCategoryName]
                        )
                        Select  [t].[PartCategory]
                              , [t].[PartCategoryName]
                        From    ( Select    [PartCategory] = 'M'
                                          , [PartCategoryName] = 'Made-in'
                                  Union
                                  Select    [PartCategory] = 'B'
                                          , [PartCategoryName] = 'Bought Out'
                                  Union
                                  Select    [PartCategory] = 'S'
                                          , [PartCategoryName] = 'Sub-contracted'
                                  Union
                                  Select    [PartCategory] = 'G'
                                          , [PartCategoryName] = 'Phantom/Ghost Part'
                                  Union
                                  Select    [PartCategory] = 'P'
                                          , [PartCategoryName] = 'Planning bill'
                                  Union
                                  Select    [PartCategory] = 'K'
                                          , [PartCategoryName] = 'Kit Part'
                                  Union
                                  Select    [PartCategory] = 'C'
                                          , [PartCategoryName] = 'Co-Product'
                                  Union
                                  Select    [PartCategory] = 'Y'
                                          , [PartCategoryName] = 'By-product'
                                  Union
                                  Select    [PartCategory] = 'N'
                                          , [PartCategoryName] = 'Notional part'
                                ) [t];


                Insert  [Lookups].[InvMaster_PartCategory]
                        ( [PartCategoryCode]
                        , [PartCategoryDescription]
                        , [LastUpdated]
                        )
                        Select  [CL].[PartCategory]
                              , [CL].[PartCategoryName]
                              , @LastUpdated
                        From    [#PartCategoryList] As [CL];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[InvMaster_PartCategory] As [cn]
                        Where   [cn].[LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[InvMaster_PartCategory] As [cn]
                        Where   [cn].[LastUpdated] <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[InvMaster_PartCategory]
                                Where   [LastUpdated] = @LastDate;
                                Print 'UspUpdate_InvMaster_PartCategory - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[InvMaster_PartCategory]
                                Where   [LastUpdated] <> @LastUpdated
                                        Or [LastUpdated] Is Null;
                                Print 'UspUpdate_InvMaster_PartCategory - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[InvMaster_PartCategory]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_InvMaster_PartCategory - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_InvMaster_PartCategory - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
