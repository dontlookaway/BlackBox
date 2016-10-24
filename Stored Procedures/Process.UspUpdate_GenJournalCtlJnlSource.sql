SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GenJournalCtlJnlSource]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin


--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'GenJournalCtlJnlSource' )
           )
            Begin
                Create Table [Lookups].[GenJournalCtlJnlSource]
                    (
                      [GenJournalCtlJnlSource] Char(2)
                    , [GenJournalCtlJnlSourceDesc] Varchar(250)
                    , [LastUpdated] DateTime2
                    );
            End;


        Declare @LastUpdate DateTime2 = GetDate();
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([bt].[LastUpdated])
        From    [Lookups].[GenJournalCtlJnlSource] As [bt];
        If DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                        * 60 )
            Begin
                Insert  [Lookups].[GenJournalCtlJnlSource]
                        ( [GenJournalCtlJnlSource]
                        , [GenJournalCtlJnlSourceDesc]
                        , [LastUpdated]
                        )
                        Select  [t].[GenJournalCtlJnlSource]
                              , [t].[GenJournalCtlJnlSourceDesc]
                              , [LastUpdated] = @LastUpdate
                        From    ( Select    [GenJournalCtlJnlSource] = 'AP'
                                          , [GenJournalCtlJnlSourceDesc] = 'Accounts Payable'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'AR'
                                          , [GenJournalCtlJnlSourceDesc] = 'Accounts Receivable'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'AS'
                                          , [GenJournalCtlJnlSourceDesc] = 'Assets/Assets Register'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'GR'
                                          , [GenJournalCtlJnlSourceDesc] = 'Grn/Grn Matching'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'IN'
                                          , [GenJournalCtlJnlSourceDesc] = 'Inventory'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'SA'
                                          , [GenJournalCtlJnlSourceDesc] = 'Sales'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'WP'
                                          , [GenJournalCtlJnlSourceDesc] = 'Work in Progress'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'PA'
                                          , [GenJournalCtlJnlSourceDesc] = 'Payroll'
                                  Union
                                  Select    [GenJournalCtlJnlSource] = 'CS'
                                          , [GenJournalCtlJnlSourceDesc] = 'Cashbook'
                                ) [t];


                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[GenJournalCtlJnlSource]
                        Where   [LastUpdated] = @LastUpdate;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[GenJournalCtlJnlSource]
                        Where   [LastUpdated] <> @LastUpdate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[GenJournalCtlJnlSource]
                                Where   [LastUpdated] = @LastUpdate;
                                Print 'UspUpdate_GenJournalCtlJnlSource - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[GenJournalCtlJnlSource]
                                Where   [LastUpdated] <> @LastUpdate;
                                Print 'UspUpdate_GenJournalCtlJnlSource - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[GenJournalCtlJnlSource]
                        Where   [LastUpdated] <> @LastUpdate;
                        Print 'UspUpdate_GenJournalCtlJnlSource - Update applied successfully';
                    End;
            End;
        If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates
                                                         * 60 )
            Begin
                Print 'UspUpdate_GenJournalCtlJnlSource - Table was last updated at '
                    + Cast(@LastDate As Varchar(255)) + ' no update applied';
            End;
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_GenJournalCtlJnlSource', NULL, NULL
GO
