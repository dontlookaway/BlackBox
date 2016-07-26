SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_LastUpdatedTimes]
    (
      @MinutesToCheck int
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;
        Select  @MinutesToCheck = Coalesce(@MinutesToCheck , 30);

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_LastUpdatedTimes' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


        Declare @TableWithSchema Varchar(500)
          , @SqlScript NVarchar(Max)
          , @cmd NVarchar(Max);

        Create Table [#TablesNotUpdated]
            (
              [TableName] Varchar(500)
            , [LastUpdated] DateTime2
            );

        Declare [Tables] Cursor
        For
            Select  Distinct
                    [Tables] = QuoteName([S].[name]) + '.'
                    + QuoteName([T].[name])--,[C].[name]
            From    [sys].[columns] [C]
                    Inner Join [sys].[tables] [T]
                        On [T].[object_id] = [C].[object_id]
                    Inner Join [sys].[schemas] [S]
                        On [S].[schema_id] = [T].[schema_id]
            Where   Lower([C].[name]) = 'lastupdated'
            Order By [Tables] Asc;

        Open [Tables];
    
        Fetch Next From [Tables] Into @TableWithSchema;
 --Get first database to execute against

        While @@fetch_status = 0 --when fetch is successful
            Begin
                Set @cmd = 'Insert [#TablesNotUpdated]
								( [TableName] , [LastUpdated] )
								SELECT ''' + @TableWithSchema
                    + ''',Max([LastUpdated]) FROM ' + @TableWithSchema;
                Exec ( @cmd );


                Fetch Next From [Tables] Into @TableWithSchema;--Get next database to execute against
            End;

        Close [Tables];
        Deallocate [Tables];

        Set NoCount Off;
        Select  [TNU].[TableName]
              , [TNU].[LastUpdated]
              , [MinutesSinceRun] = DateDiff(Minute , [TNU].[LastUpdated] ,
                                           GetDate())
										   ,Test = @MinutesToCheck
        From    [#TablesNotUpdated] [TNU]
        Where   DateDiff(Minute , [TNU].[LastUpdated] , GetDate()) > @MinutesToCheck;
        Set NoCount On;
        Drop Table [#TablesNotUpdated];
    End;
GO
