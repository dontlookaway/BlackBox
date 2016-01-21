SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResultsRefresh_TableTimes]
(@Exec INT)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure update all history and lookup tables and return results about how long this takes to run
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			23/9/2015	Chris Johnson			Initial version created																///
///			11/01/2016	Chris Johnson			Amended to use new history SP														///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

--remove nocount on to speed up query
Set NoCount On

Declare
    @LookupStart DATETIME2
  , @LookupEnd DATETIME2
  , @HistoryStart DATETIME2
  , @HistoryEnd DATETIME2;

Create --drop --alter 
Table #Results
    (
      SchemaName VARCHAR(100)
    , TableName VARCHAR(100)
    , LastUpdated DATETIME2
    , OldRowCount INT
    , NewRowCount INT
    , UpdateStart DATETIME2
    , UpdateEnd DATETIME2
    , OldColumnCount INT
    , NewColumnCount INT
    );

--Lookups
Begin
    Select
        @LookupStart = GETDATE();

	--Get Preloaded figures
    Insert  #Results
            ( SchemaName
            , TableName
            , LastUpdated
            , OldRowCount
            , NewRowCount
            , UpdateStart
            , UpdateEnd
            , OldColumnCount
            , NewColumnCount
	        )
            Select
                s.name
              , t.name
              , LastUpdated = iu.last_user_update
              , OldRowCount = I.row_count
              , NewRowCount = Null
              , UpdateStart = @LookupStart
              , UpdateEnd = Null
              , OldColumnCount = COUNT(c.name)
              , NewColumnCount = Null
            From
                sys.tables t
            Inner Join sys.schemas s
                On s.schema_id = t.schema_id
            Inner Join sys.dm_db_partition_stats As I
                On t.object_id = I.object_id
                   And I.index_id < 2
            Left Join sys.columns c
                On c.object_id = t.object_id
            Left Join sys.dm_db_index_usage_stats iu
                On iu.object_id = t.object_id
            Where
                s.name = 'Lookups'
            Group By
                s.name
              , t.name
              , I.row_count
              , iu.last_user_update;

If @Exec=1
BEGIN
	--update tables
    Exec Process.UspLoad_LoadController
        @HoursBetweenEachRun = 1;-- int    
END

	--add results
    Update
        #Results
    Set
        NewRowCount = t.Row_Count
      , NewColumnCount = t.NewColumnCount
    From
        #Results R
    Left Join (
                Select
                    SchemaName = s.name
                  , TableName = t.name
                  , Row_Count = I.row_count
                  , NewColumnCount = COUNT(c.name)
                From
                    sys.tables t
                Inner Join sys.schemas s
                    On s.schema_id = t.schema_id
                Inner Join sys.dm_db_partition_stats As I
                    On t.object_id = I.object_id
                       And I.index_id < 2
                Left Join sys.columns c
                    On c.object_id = t.object_id
                Where
                    s.name = 'Lookups'
                Group By
                    s.name
                  , t.name
                  , I.row_count
              ) t
        On t.SchemaName = R.SchemaName Collate Latin1_General_BIN
           And t.TableName = R.TableName Collate Latin1_General_BIN
		 Where t.Row_Count Is Not Null;


    Select
        @LookupEnd = GETDATE();

    Update
        #Results
    Set
        UpdateEnd = @LookupEnd
    Where
        SchemaName = 'Lookups';
End;

--History
Begin
    Select
        @HistoryStart = GETDATE();

	--Get Preloaded figures
    Insert  #Results
            ( SchemaName
            , TableName
            , LastUpdated
            , OldRowCount
            , NewRowCount
            , UpdateStart
            , UpdateEnd
            , OldColumnCount
            , NewColumnCount
	        )
            Select
                s.name
              , t.name
              , LastUpdated = iu.last_user_update --iu.last_user_update
              , OldRowCount = I.row_count
              , NewRowCount = Null
              , UpdateStart = @LookupStart
              , UpdateEnd = Null
              , OldColumnCount = COUNT(c.name)
              , NewColumnCount = Null
            From
                sys.tables t
            Inner Join sys.schemas s
                On s.schema_id = t.schema_id
            Inner Join sys.dm_db_partition_stats As I
                On t.object_id = I.object_id
                   And I.index_id < 2
            Left Join sys.columns c
                On c.object_id = t.object_id
            Left Join sys.dm_db_index_usage_stats iu
                On iu.object_id = t.object_id
            Where
                s.name = 'History'
            Group By
                s.name
              , t.name
              , I.row_count
              , iu.last_user_update;

If @Exec=1
BEGIN
    	--update tables
    --Exec Process.UspPopulate_HistoryTables
    --    @RebuildBit = 0; -- bit
	Exec [Process].[UspPopulate_HistoryTables1]
		@RebuildBit = 0 -- bit
	

END
	
    Update
        #Results
    Set
        NewRowCount = t.Row_Count
      , NewColumnCount = t.NewColumnCount
    From
        #Results R
    Left Join (
                Select
                    SchemaName = s.name
                  , TableName = t.name
                  , Row_Count = I.row_count
                  , NewColumnCount = COUNT(Distinct c.name)
                From
                    sys.tables t
                Inner Join sys.schemas s
                    On s.schema_id = t.schema_id
                Inner Join sys.dm_db_partition_stats As I
                    On t.object_id = I.object_id
                       And I.index_id < 2
                Left Join sys.columns c
                    On c.object_id = t.object_id
                Where
                    s.name = 'History'
                Group By
                    s.name
                  , t.name
                  , I.row_count
              ) t
        On t.SchemaName = R.SchemaName Collate Latin1_General_BIN
           And t.TableName = R.TableName Collate Latin1_General_BIN
		   Where t.Row_Count Is Not Null;

    Select
        @HistoryEnd = GETDATE();

    Update
        #Results
    Set
        UpdateEnd = @HistoryEnd
    Where
        SchemaName = 'History';
End;


Select
    SchemaName
  , TableName
  , LastUpdated
  , OldRowCount
  , NewRowCount
  , UpdateStart
  , UpdateEnd
  , OldColumnCount
  , NewColumnCount
  ,	SecondsToRun = DATEDIFF(Second,UpdateStart,UpdateEnd)
  ,	MinutesToRun = DATEDIFF(Minute,UpdateStart,UpdateEnd)
  ,	HoursToRun = DATEDIFF(Hour,UpdateStart,UpdateEnd)
From
    #Results;

Drop Table #Results;

End

GO
