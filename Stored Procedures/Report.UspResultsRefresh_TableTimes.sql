SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResultsRefresh_TableTimes]
    (
      @Exec Int
    , @HoursBetweenEachRun Numeric(5 , 2)
    )
As
    Begin

--remove nocount on to speed up query
        Set NoCount On;

        Declare @LookupStart DateTime2
          , @LookupEnd DateTime2
          , @HistoryStart DateTime2
          , @HistoryEnd DateTime2;

        Declare @GeneratedUsedByNameStart Varchar(500)= 'Development > Report System Refresh > Exec: '
            + Convert(Varchar(5) , @Exec) + '; Hours between each run: '
            + Convert(Varchar(5) , @HoursBetweenEachRun) + '; Started: '
            + Convert(Varchar(24) , GetDate() , 113);

        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResultsRefresh_TableTimes' ,
            @UsedByType = 'X' , @UsedByName = @GeneratedUsedByNameStart ,
            @UsedByDb = 'BlackBox'; 



        Create Table [#Results]
            (
              [SchemaName] Varchar(100)
            , [TableName] Varchar(100)
            , [LastUpdated] DateTime2
            , [OldRowCount] Int
            , [NewRowCount] Int
            , [UpdateStart] DateTime2
            , [UpdateEnd] DateTime2
            , [OldColumnCount] Int
            , [NewColumnCount] Int
            );

--Lookups
        Begin
            Select  @LookupStart = GetDate();

	--Get Preloaded figures
            Insert  [#Results]
                    ( [SchemaName]
                    , [TableName]
                    , [LastUpdated]
                    , [OldRowCount]
                    , [NewRowCount]
                    , [UpdateStart]
                    , [UpdateEnd]
                    , [OldColumnCount]
                    , [NewColumnCount]
	                )
                    Select  [s].[name]
                          , [t].[name]
                          , [LastUpdated] = [iu].[last_user_update]
                          , [OldRowCount] = [I].[row_count]
                          , [NewRowCount] = Null
                          , [UpdateStart] = @LookupStart
                          , [UpdateEnd] = Null
                          , [OldColumnCount] = Count([c].[name])
                          , [NewColumnCount] = Null
                    From    [sys].[tables] [t]
                            Inner Join [sys].[schemas] [s]
                                On [s].[schema_id] = [t].[schema_id]
                            Inner Join [sys].[dm_db_partition_stats] As [I]
                                On [t].[object_id] = [I].[object_id]
                                   And [I].[index_id] < 2
                            Left Join [sys].[columns] [c]
                                On [c].[object_id] = [t].[object_id]
                            Left Join [sys].[dm_db_index_usage_stats] [iu]
                                On [iu].[object_id] = [t].[object_id]
                    Where   [s].[name] = 'Lookups'
                    Group By [s].[name]
                          , [t].[name]
                          , [I].[row_count]
                          , [iu].[last_user_update];

            If @Exec = 1
                Begin
	--update tables
                    Exec [Process].[UspLoad_LoadController] @HoursBetweenEachRun = @HoursBetweenEachRun;-- numeric
                End;

	--add results
            Update  [#Results]
            Set     [NewRowCount] = [t].[Row_Count]
                  , [NewColumnCount] = [t].[NewColumnCount]
            From    [#Results] [R]
                    Left Join ( Select  [SchemaName] = [s].[name]
                                      , [TableName] = [t].[name]
                                      , [Row_Count] = [I].[row_count]
                                      , [NewColumnCount] = Count([c].[name])
                                From    [sys].[tables] [t]
                                        Inner Join [sys].[schemas] [s]
                                            On [s].[schema_id] = [t].[schema_id]
                                        Inner Join [sys].[dm_db_partition_stats]
                                            As [I]
                                            On [t].[object_id] = [I].[object_id]
                                               And [I].[index_id] < 2
                                        Left Join [sys].[columns] [c]
                                            On [c].[object_id] = [t].[object_id]
                                Where   [s].[name] = 'Lookups'
                                Group By [s].[name]
                                      , [t].[name]
                                      , [I].[row_count]
                              ) [t]
                        On [t].[SchemaName] = [R].[SchemaName] Collate Latin1_General_BIN
                           And [t].[TableName] = [R].[TableName] Collate Latin1_General_BIN
            Where   [t].[Row_Count] Is Not Null;


            Select  @LookupEnd = GetDate();

            Update  [#Results]
            Set     [UpdateEnd] = @LookupEnd
            Where   [SchemaName] = 'Lookups';
        End;

--History
        Begin
            Select  @HistoryStart = GetDate();

	--Get Preloaded figures
            Insert  [#Results]
                    ( [SchemaName]
                    , [TableName]
                    , [LastUpdated]
                    , [OldRowCount]
                    , [NewRowCount]
                    , [UpdateStart]
                    , [UpdateEnd]
                    , [OldColumnCount]
                    , [NewColumnCount]
	                )
                    Select  [s].[name]
                          , [t].[name]
                          , [LastUpdated] = [iu].[last_user_update]
                          , [OldRowCount] = [I].[row_count]
                          , [NewRowCount] = Null
                          , [UpdateStart] = @LookupStart
                          , [UpdateEnd] = Null
                          , [OldColumnCount] = Count([c].[name])
                          , [NewColumnCount] = Null
                    From    [sys].[tables] [t]
                            Inner Join [sys].[schemas] [s]
                                On [s].[schema_id] = [t].[schema_id]
                            Inner Join [sys].[dm_db_partition_stats] As [I]
                                On [t].[object_id] = [I].[object_id]
                                   And [I].[index_id] < 2
                            Left Join [sys].[columns] [c]
                                On [c].[object_id] = [t].[object_id]
                            Left Join [sys].[dm_db_index_usage_stats] [iu]
                                On [iu].[object_id] = [t].[object_id]
                    Where   [s].[name] = 'History'
                    Group By [s].[name]
                          , [t].[name]
                          , [I].[row_count]
                          , [iu].[last_user_update];

            If @Exec = 1
                Begin
                    Exec [Process].[UspPopulate_HistoryTables1] @RebuildBit = 0; -- bit
	

                End;
	
            Update  [#Results]
            Set     [NewRowCount] = [t].[Row_Count]
                  , [NewColumnCount] = [t].[NewColumnCount]
            From    [#Results] [R]
                    Left Join ( Select  [SchemaName] = [s].[name]
                                      , [TableName] = [t].[name]
                                      , [Row_Count] = [I].[row_count]
                                      , [NewColumnCount] = Count(Distinct [c].[name])
                                From    [sys].[tables] [t]
                                        Inner Join [sys].[schemas] [s]
                                            On [s].[schema_id] = [t].[schema_id]
                                        Inner Join [sys].[dm_db_partition_stats]
                                            As [I]
                                            On [t].[object_id] = [I].[object_id]
                                               And [I].[index_id] < 2
                                        Left Join [sys].[columns] [c]
                                            On [c].[object_id] = [t].[object_id]
                                Where   [s].[name] = 'History'
                                Group By [s].[name]
                                      , [t].[name]
                                      , [I].[row_count]
                              ) [t]
                        On [t].[SchemaName] = [R].[SchemaName] Collate Latin1_General_BIN
                           And [t].[TableName] = [R].[TableName] Collate Latin1_General_BIN
            Where   [t].[Row_Count] Is Not Null;

            Select  @HistoryEnd = GetDate();

            Update  [#Results]
            Set     [UpdateEnd] = @HistoryEnd
            Where   [SchemaName] = 'History';
        End;

        Declare @GeneratedUsedByNameEnd Varchar(500)= 'Development > Report System Refresh > Exec: '
            + Convert(Varchar(5) , @Exec) + '; Hours between each run: '
            + Convert(Varchar(5) , @HoursBetweenEachRun) + '; Ended: '
            + Convert(Varchar(24) , GetDate() , 113);

        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResultsRefresh_TableTimes' ,
            @UsedByType = 'X' , @UsedByName = @GeneratedUsedByNameEnd ,
            @UsedByDb = 'BlackBox'; 



        Set NoCount Off;

        Select  [SchemaName]
              , [TableName]
              , [LastUpdated]
              , [OldRowCount]
              , [NewRowCount]
              , [UpdateStart]
              , [UpdateEnd]
              , [OldColumnCount]
              , [NewColumnCount]
              , [SecondsToRun] = DateDiff(Second , [UpdateStart] , [UpdateEnd])
              , [MinutesToRun] = DateDiff(Minute , [UpdateStart] , [UpdateEnd])
              , [HoursToRun] = DateDiff(Hour , [UpdateStart] , [UpdateEnd])
        From    [#Results];

        --Drop Table [#Results];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'used to refresh all the lookup and history table, in addition providing times for how long this takes', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResultsRefresh_TableTimes', NULL, NULL
GO
