SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_ArInvoicePayTrnType]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'ArInvoicePayTrnType' )
           )
            Begin
                Create Table [Lookups].[ArInvoicePayTrnType]
                    (
                      [TrnType] Char(1) Collate Latin1_General_BIN
                    , [TrnTypeDesc] Varchar(250) Collate Latin1_General_BIN
                    , [LastUpdated] DateTime2
                    );
            End;


        Declare @LastUpdate DateTime2 = GetDate();
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([bt].[LastUpdated])
        From    [Lookups].[ArInvoicePayTrnType] As [bt];
        If DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                        * 60 )
            Begin
                Insert  [Lookups].[ArInvoicePayTrnType]
                        ( [TrnType]
                        , [TrnTypeDesc]
                        , [LastUpdated]
                        )
                        Select  [t].[TrnType]
                              , [t].[TrnTypeDesc]
                              , [LastUpdated] = @LastUpdate
                        From    ( Select    [TrnType] = 'A'
                                          , [TrnTypeDesc] = 'Adjustment'
                                  Union
                                  Select    [TrnType] = 'C'
                                          , [TrnTypeDesc] = 'Credit memo'
                                  Union
                                  Select    [TrnType] = 'D'
                                          , [TrnTypeDesc] = 'Debit memo'
                                  Union
                                  Select    [TrnType] = 'P'
                                          , [TrnTypeDesc] = 'Payment'
                                  Union
                                  Select    [TrnType] = 'V'
                                          , [TrnTypeDesc] = 'Exchange rate revaluation'
                                  Union
                                  Select    [TrnType] = 'T'
                                          , [TrnTypeDesc] = 'Tax relief adjustment'
                                ) [t];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[ArInvoicePayTrnType]
                        Where   [LastUpdated] = @LastUpdate;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[ArInvoicePayTrnType]
                        Where   [LastUpdated] <> @LastUpdate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[ArInvoicePayTrnType]
                                Where   [LastUpdated] = @LastUpdate;
                                Print 'UspUpdate_ArInvoicePayTrnType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[ArInvoicePayTrnType]
                                Where   [LastUpdated] <> @LastUpdate;
                                Print 'UspUpdate_ArInvoicePayTrnType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[ArInvoicePayTrnType]
                        Where   [LastUpdated] <> @LastUpdate;
                        Print 'UspUpdate_ArInvoicePayTrnType - Update applied successfully';
                    End;
            End;
        If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates
                                                         * 60 )
            Begin
                Print 'UspUpdate_ArInvoicePayTrnType - Table was last updated at '
                    + Cast(@LastDate As Varchar(255)) + ' no update applied';
            End;
    End;	
GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_ArInvoicePayTrnType', NULL, NULL
GO
