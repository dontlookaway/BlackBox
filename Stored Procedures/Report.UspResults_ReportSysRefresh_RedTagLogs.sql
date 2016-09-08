SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ReportSysRefresh_RedTagLogs]
    (
      @DatePart Varchar(500)
    , @StartPeriod DateTime
    , @EndPeriod DateTime
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;
        Set @DatePart = Lower(@DatePart);
        
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ReportSysRefresh_RedTagLogs' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#TranRanks]
            (
              [TagID] Int
            , [TagDatetime] DateTime2
            , [StoredProcDb] Varchar(255)
            , [StoredProcSchema] Varchar(255)
            , [StoredProcName] Varchar(255)
            , [UsedByName] Varchar(500)
            , [UsedByDb] Varchar(255)
            , [TranRank] BigInt
            );
        Create Table [#ListOfRuns]
            (
              [StartDate] DateTime
            , [EndDate] DateTime
            , [SecondsToRun] BigInt
            );
	

--create script to pull data from each db into the tables
        Insert  [#TranRanks]
                ( [TagID]
                , [TagDatetime]
                , [StoredProcDb]
                , [StoredProcSchema]
                , [StoredProcName]
                , [UsedByName]
                , [UsedByDb]
                , [TranRank]
                )
                Select  [RTL].[TagID]
                      , [RTL].[TagDatetime]
                      , [RTL].[StoredProcDb]
                      , [RTL].[StoredProcSchema]
                      , [RTL].[StoredProcName]
                      , [RTL].[UsedByName]
                      , [RTL].[UsedByDb]
                      , [TranRank] = Rank() Over ( Order By [RTL].[TagID] Desc )
                From    [History].[RedTagLogs] [RTL]
                Where   [RTL].[UsedByName] Like 'Development > Report System Refresh >%'
                        And [RTL].[TagDatetime] Between @StartPeriod
                                                And     @EndPeriod
                Order By [RTL].[TagID] Desc;

        Insert  [#ListOfRuns]
                ( [StartDate]
                , [EndDate]
                , [SecondsToRun]
                )
                Select  [StartDate] = Convert(DateTime , [T].[TagDatetime])
                      , [EndDate] = Convert(DateTime , [T2].[TagDatetime])
                      , [SecondsToRun] = DateDiff(Second , [T].[TagDatetime] ,
                                                  [T2].[TagDatetime])
                From    [#TranRanks] [T]
                        Left Join [#TranRanks] [T2]
                            On [T2].[TranRank] = [T].[TranRank] - 1
                Where   [T].[UsedByName] Like '%Started%';





--define the results you want to return
        Create Table [#Results]
            (
              [DatePartTime] DateTime
            , [DatePartName] Varchar(255)
            , [CountOfStarts] BigInt
            , [AvgSecondsToRun] BigInt
            , [MaxSecondsToRun] BigInt
            , [MinSecondsToRun] BigInt
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table


        If @DatePart = 'hour'
            Begin
                Insert  [#Results]
                        ( [DatePartTime]
                        , [DatePartName]
                        , [CountOfStarts]
                        , [AvgSecondsToRun]
                        , [MaxSecondsToRun]
                        , [MinSecondsToRun]
                        )
                        Select  [DatePartTime] = DateAdd(Hour ,
                                                         DateDiff(Hour , 0 ,
                                                              [T].[StartDate]) ,
                                                         0)
                              , [DatePartName] = 'Hour'
                              , [CountOfStarts] = Count(Distinct [T].[StartDate])
                              , [AvgSecondsToRun] = Avg([T].[SecondsToRun])
                              , [MaxSecondsToRun] = Max([T].[SecondsToRun])
                              , [MinSecondsToRun] = Min([T].[SecondsToRun])
                        From    [#ListOfRuns] [T]
                        Group By DateAdd(Hour ,
                                         DateDiff(Hour , 0 , [T].[StartDate]) ,
                                         0);
            End;
        If @DatePart = 'day'
            Begin
                Insert  [#Results]
                        ( [DatePartTime]
                        , [DatePartName]
                        , [CountOfStarts]
                        , [AvgSecondsToRun]
                        , [MaxSecondsToRun]
                        , [MinSecondsToRun]
                        )
                        Select  [DatePartTime] = DateAdd(Day ,
                                                         DateDiff(Day , 0 ,
                                                              [T].[StartDate]) ,
                                                         0)
                              , [DatePartName] = 'Day'
                              , [CountOfStarts] = Count(Distinct [T].[StartDate])
                              , [AvgSecondsToRun] = Avg([T].[SecondsToRun])
                              , [MaxSecondsToRun] = Max([T].[SecondsToRun])
                              , [MinSecondsToRun] = Min([T].[SecondsToRun])
                        From    [#ListOfRuns] [T]
                        Group By DateAdd(Day ,
                                         DateDiff(Day , 0 , [T].[StartDate]) ,
                                         0);
            End;
        If @DatePart = 'week'
            Begin
                Insert  [#Results]
                        ( [DatePartTime]
                        , [DatePartName]
                        , [CountOfStarts]
                        , [AvgSecondsToRun]
                        , [MaxSecondsToRun]
                        , [MinSecondsToRun]
                        )
                        Select  [DatePartTime] = DateAdd(Week ,
                                                         DateDiff(Week , 0 ,
                                                              [T].[StartDate]) ,
                                                         0)
                              , [DatePartName] = 'Week'
                              , [CountOfStarts] = Count(Distinct [T].[StartDate])
                              , [AvgSecondsToRun] = Avg([T].[SecondsToRun])
                              , [MaxSecondsToRun] = Max([T].[SecondsToRun])
                              , [MinSecondsToRun] = Min([T].[SecondsToRun])
                        From    [#ListOfRuns] [T]
                        Group By DateAdd(Week ,
                                         DateDiff(Week , 0 , [T].[StartDate]) ,
                                         0);
            End;
        If @DatePart = 'month'
            Begin
                Insert  [#Results]
                        ( [DatePartTime]
                        , [DatePartName]
                        , [CountOfStarts]
                        , [AvgSecondsToRun]
                        , [MaxSecondsToRun]
                        , [MinSecondsToRun]
                        )
                        Select  [DatePartTime] = DateAdd(Month ,
                                                         DateDiff(Month , 0 ,
                                                              [T].[StartDate]) ,
                                                         0)
                              , [DatePartName] = 'Month'
                              , [CountOfStarts] = Count(Distinct [T].[StartDate])
                              , [AvgSecondsToRun] = Avg([T].[SecondsToRun])
                              , [MaxSecondsToRun] = Max([T].[SecondsToRun])
                              , [MinSecondsToRun] = Min([T].[SecondsToRun])
                        From    [#ListOfRuns] [T]
                        Group By DateAdd(Month ,
                                         DateDiff(Month , 0 , [T].[StartDate]) ,
                                         0);
            End;
        If @DatePart = 'year'
            Begin
                Insert  [#Results]
                        ( [DatePartTime]
                        , [DatePartName]
                        , [CountOfStarts]
                        , [AvgSecondsToRun]
                        , [MaxSecondsToRun]
                        , [MinSecondsToRun]
                        )
                        Select  [DatePartTime] = DateAdd(Year ,
                                                         DateDiff(Year , 0 ,
                                                              [T].[StartDate]) ,
                                                         0)
                              , [DatePartName] = 'Year'
                              , [CountOfStarts] = Count(Distinct [T].[StartDate])
                              , [AvgSecondsToRun] = Avg([T].[SecondsToRun])
                              , [MaxSecondsToRun] = Max([T].[SecondsToRun])
                              , [MinSecondsToRun] = Min([T].[SecondsToRun])
                        From    [#ListOfRuns] [T]
                        Group By DateAdd(Year ,
                                         DateDiff(Year , 0 , [T].[StartDate]) ,
                                         0);
            End;


        Set NoCount Off;
--return results
        Select  [DatePartTime]
              , [DatePartName]
              , [CountOfStarts]
              , [AvgSecondsToRun]
              , [MaxSecondsToRun]
              , [MinSecondsToRun]
        From    [#Results];

    End;

GO
