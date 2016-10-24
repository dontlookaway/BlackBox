SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GenTransactionSource]
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
                                    And [TABLE_NAME] = 'GenTransactionSource' )
           )
            Begin
                Create Table [Lookups].[GenTransactionSource]
                    (
                      [Source] Char(2)
                    , [SourceDesc] Varchar(250)
                    , [LastUpdated] DateTime2
                    );
            End;


        Declare @LastUpdate DateTime2 = GetDate();
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([bt].[LastUpdated])
        From    [Lookups].[GenTransactionSource] As [bt];

        If DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                         * 60 )
            Begin
                Insert  [Lookups].[GenTransactionSource]
                        ( [Source]
                        , [SourceDesc]
                        , [LastUpdated]
                        )
                        Select  *
                        From    ( Select    [Source] = 'JE'
                                          , [SourceDesc] = 'Normal Journal'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'IC'
                                          , [SourceDesc] = 'Inter-company journal'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'RV'
                                          , [SourceDesc] = 'Reversing journal'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'YE'
                                          , [SourceDesc] = 'Year end closing'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'PE'
                                          , [SourceDesc] = 'Period end journal'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'AU'
                                          , [SourceDesc] = 'Auditor''s Adjustment'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'HM'
                                          , [SourceDesc] = 'History Maintenance'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'AP'
                                          , [SourceDesc] = 'Accounts Payable'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'AR'
                                          , [SourceDesc] = 'A/R payments'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'IN'
                                          , [SourceDesc] = 'Inventory'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'GR'
                                          , [SourceDesc] = 'GRN system'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'SA'
                                          , [SourceDesc] = 'A/R Sales'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'AS'
                                          , [SourceDesc] = 'Assets'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'PA'
                                          , [SourceDesc] = 'Payroll'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'WP'
                                          , [SourceDesc] = 'Work in progress'
                                          , [LastUpdated] = @LastUpdate
                                  Union
                                  Select    [Source] = 'CS'
                                          , [SourceDesc] = 'Cash book'
                                          , [LastUpdated] = @LastUpdate
                                ) [t];


                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[GenTransactionSource]
                        Where   [LastUpdated] = @LastUpdate;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[GenTransactionSource]
                        Where   [LastUpdated] <> @LastUpdate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[GenTransactionSource]
                                Where   [LastUpdated] = @LastUpdate;
                                Print 'UspUpdate_GenTransactionSource - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[GenTransactionSource]
                                Where   [LastUpdated] <> @LastUpdate;
                                Print 'UspUpdate_GenTransactionSource - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[GenTransactionSource]
                        Where   [LastUpdated] <> @LastUpdate;
                        Print 'UspUpdate_GenTransactionSource - Update applied successfully';
                    End;
            End;
        If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates
                                                         * 60 )
            Begin
                Print 'UspUpdate_GenTransactionSource - Table was last updated at '
                    + Cast(@LastDate As Varchar(255)) + ' no update applied';
            End;
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_GenTransactionSource', NULL, NULL
GO
