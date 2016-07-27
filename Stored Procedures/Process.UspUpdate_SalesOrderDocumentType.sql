SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_SalesOrderDocumentType]
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
                                    And [TABLE_NAME] = 'SalesOrderDocumentType' )
           )
            Begin
                Create Table [Lookups].[SalesOrderDocumentType]
                    (
                      [DocumentType] Varchar(10)
                    , [DocumentTypeDesc] Varchar(250)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[SalesOrderDocumentType];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();
	--create master list of how codes affect stock
                Create Table [#SalesOrderDocumentType]
                    (
                      [DocumentType] Varchar(10) Collate Latin1_General_BIN
                    , [DocumentTypeDescription] Varchar(250)
                    );

                Insert  [#SalesOrderDocumentType]
                        ( [DocumentType]
                        , [DocumentTypeDescription]
                        )
                        Select  [t].[DocumentType]
                              , [t].[DocumentTypeDescription]
                        From    ( Select    [DocumentType] = 'B'
                                          , [DocumentTypeDescription] = 'Billing'
                                  Union
                                  Select    [DocumentType] = 'O'
                                          , [DocumentTypeDescription] = 'Order'
                                  Union
                                  Select    [DocumentType] = 'C'
                                          , [DocumentTypeDescription] = 'Credit Note'
                                  Union
                                  Select    [DocumentType] = 'D'
                                          , [DocumentTypeDescription] = 'Debit Note'
                                ) [t];


					
	--placeholder for anomalous results that are different to master list

                Insert  [Lookups].[SalesOrderDocumentType]
                        ( [DocumentType]
                        , [DocumentTypeDesc]
                        , [LastUpdated]
	                    )
                        Select  [SODT].[DocumentType]
                              , [SODT].[DocumentTypeDescription]
                              , @LastUpdated
                        From    [#SalesOrderDocumentType] [SODT];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[SalesOrderDocumentType] As [cn]
                        Where   [cn].[LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[SalesOrderDocumentType] As [cn]
                        Where   [cn].[LastUpdated] <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderDocumentType]
                                Where   [LastUpdated] = @LastDate;
                                Print 'UspUpdate_SalesOrderDocumentType - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[SalesOrderDocumentType]
                                Where   [LastUpdated] <> @LastUpdated
                                        Or [LastUpdated] Is Null;
                                Print 'UspUpdate_SalesOrderDocumentType - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[SalesOrderDocumentType]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_SalesOrderDocumentType - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_SalesOrderDocumentType - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
