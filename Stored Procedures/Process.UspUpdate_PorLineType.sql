SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create Proc [Process].[UspUpdate_PorLineType]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with PorLineType details	transaction types when relating to inventory changes
*/

--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'PorLineType' )
           )
            Begin
                Create Table [Lookups].[PorLineType]
                    (
                      [PorLineType] Int
                    , [PorLineTypeDesc] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;



--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[PorLineType];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'InvMovements'; 

                Insert  [Lookups].[PorLineType]
                        ( [PorLineType]
                        , [LastUpdated]
                        , [PorLineTypeDesc]
                        )
                        Select  [t].[PorLineType]
                              , [LastUpdated] = @LastUpdated
                              , [t].[PorLineTypeDesc]
                        From    ( Select    [PorLineType] = 1
                                          , [PorLineTypeDesc] = 'Stocked line'
                                  Union
                                  Select    [PorLineType] = 4
                                          , [PorLineTypeDesc] = 'Freight line'
                                  Union
                                  Select    [PorLineType] = 5
                                          , [PorLineTypeDesc] = 'Other charges'
                                  Union
                                  Select    [PorLineType] = 6
                                          , [PorLineTypeDesc] = 'CommentLine'
                                  Union
                                  Select    [PorLineType] = 7
                                          , [PorLineTypeDesc] = 'Non-Stocked line'
                                ) [t];
                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[PorLineType]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[PorLineType]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[PorLineType]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_PorLineType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[PorLineType]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_PorLineType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[PorLineType]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_PorLineType - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_PorLineType - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;

GO
