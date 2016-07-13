SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Review].[UspResults_CompanyDuplicates]
    (
      @IncludeNotes Bit
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
	Set NoCount On
    Select  @IncludeNotes = Coalesce(@IncludeNotes , 0);

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_CompanyDuplicates' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#CpReview]
            (
              [Company] Varchar(150)
            , [CompanyName] Varchar(250)
            , [ShortName] Varchar(250)
            , [RecordCount] Int
			, RowType Varchar(50)
            );

		If @IncludeNotes=1
		BEGIN
		    Insert [#CpReview]
		            ( [Company]
		            , [CompanyName]
		            , [ShortName]
		            , [RecordCount]
		            , [RowType]
		            )
		    Values  ( 'List of '  -- Company - varchar(150)
		            , 'companies that have been'  -- CompanyName - varchar(250)
		            , 'duplicated in lookup table'  -- ShortName - varchar(250)
		            , 2  -- RecordCount - int
		            , 'Notes'  -- RowType - varchar(50)
		            )
		END

		Insert [#CpReview]
		        ( [Company]
		        , [CompanyName]
		        , [ShortName]
		        , [RecordCount]
		        , [RowType]
		        )
        Select  [CN].[Company]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [RecordCount] = Count(1)
			  , RowType ='Data'
        From    [Lookups].[CompanyNames] [CN]
        Group By [CN].[Company]
              , [CN].[CompanyName]
              , [CN].[ShortName]
        Having  Count(1) > 1;

		SELECT [CR].[Company]
             , [CR].[CompanyName]
             , [CR].[ShortName]
             , [CR].[RecordCount]
             , [CR].[RowType] 
		From [#CpReview] [CR]
		Order By [CR].[RowType] Desc
    End;
GO
