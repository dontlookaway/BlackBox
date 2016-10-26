SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_WarehousesIssueFrom]
    (
      @IncludeNotes Bit
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;
        Select  @IncludeNotes = Coalesce(@IncludeNotes , 0);

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_WarehousesIssueFrom' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#WHReview]
            (
              [IssueFrom] Varchar(150)			collate latin1_general_bin
            , [Warehouse] Varchar(50)			collate latin1_general_bin
            , [Description] Varchar(150)		collate latin1_general_bin
            , [DB] Varchar(150)					collate latin1_general_bin
            , [RowType] Varchar(10)				collate latin1_general_bin
            );

        If @IncludeNotes = 1
            Begin
                Insert  [#WHReview]
                        ( [IssueFrom]
                        , [Warehouse]
                        , [Description]
                        , [DB]
                        , [RowType]
                        )
                Values  ( ''  -- IssueFrom - varchar(150)
                        , 'List of '  -- Warehouse - varchar(50)
                        , 'warehouses that '  -- Description - varchar(150)
                        , 'have not been completed with issue from data' -- DB - varchar(150)
                        , 'Notes'  -- RowType - varchar(10)
                        );
            End;


 
        Exec [BlackBox].[Process].[ExecForEachDB] @cmd = N'Use [?];
If Lower(replace(''?'',''['','''')) Like ''sysprocompany%'' And IsNumeric(Right(replace(''?'','']'',''''),1))=1
BEGIN
Insert [#WHReview]
        ( [IssueFrom]
        , [Warehouse]
        , [Description]
        , [DB]
		, [RowType]
        )
Select  [IWC].[Fax]
      , [IWC].[Warehouse]
      , [IWC].[Description]
	  , [DB] = ''?''
	  , [RowType] = ''Data''
From    [dbo].[InvWhControl] [IWC];
end';


        Set NoCount Off;
        
        Select  [WR].[Warehouse]
              , [WR].[Description]
              , [WR].[DB]
              , [WR].[RowType]
        From    [#WHReview] [WR]
        Where   [WR].[IssueFrom] Not In ( 'Y' , 'N' )
        Order By [WR].[RowType] Desc;
    End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'details of warehouse that do not have issue from completed', 'SCHEMA', N'Review', 'PROCEDURE', N'UspResults_WarehousesIssueFrom', NULL, NULL
GO
