SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_BudgetType]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin
--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'BudgetType' )
           )
            Begin
                Create Table [Lookups].[BudgetType]
                    (
                      [BudgetType] Char(1)			collate latin1_general_bin
                    , [BudgetTypeDesc] Varchar(250)	collate latin1_general_bin
                    , [LastUpdated] DateTime2
                    );
            End;


        Declare @LastUpdate DateTime2 = GetDate();
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([bt].[LastUpdated])
        From    [Lookups].[BudgetType] As [bt];

        If DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                      * 60 )
            Begin
                Insert  [Lookups].[BudgetType]
                        ( [BudgetType]
                        , [BudgetTypeDesc]
                        , [LastUpdated]
                        )
                        Select  [BudgetType] = 'C'
                              , [BudgetTypeDesc] = 'Current Year'
                              , [LastUpdated] = @LastUpdate;
                Insert  [Lookups].[BudgetType]
                        ( [BudgetType]
                        , [BudgetTypeDesc]
                        , [LastUpdated]
                        )
                        Select  [BudgetType] = 'N'
                              , [BudgetTypeDesc] = 'Next Year'
                              , [LastUpdated] = @LastUpdate;
                Insert  [Lookups].[BudgetType]
                        ( [BudgetType]
                        , [BudgetTypeDesc]
                        , [LastUpdated]
                        )
                        Select  [BudgetType] = 'A'
                              , [BudgetTypeDesc] = 'Alternate Budget'
                              , [LastUpdated] = @LastUpdate;

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[BudgetType]
                        Where   [LastUpdated] = @LastUpdate;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[BudgetType]
                        Where   [LastUpdated] <> @LastUpdate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[BudgetType]
                                Where   [LastUpdated] = @LastUpdate;
                                Print 'UspUpdate_BudgetType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[BudgetType]
                                Where   [LastUpdated] <> @LastUpdate;
                                Print 'UspUpdate_BudgetType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[BudgetType]
                        Where   [LastUpdated] <> @LastUpdate;
                        Print 'UspUpdate_BudgetType - Update applied successfully';
                    End;
            End;
        If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates
                                                       * 60 )
            Begin
                Print 'UspUpdate_BudgetType - Table was last updated at '
                    + Cast(@LastDate As Varchar(255)) + ' no update applied';
            End;
    End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_BudgetType', NULL, NULL
GO
