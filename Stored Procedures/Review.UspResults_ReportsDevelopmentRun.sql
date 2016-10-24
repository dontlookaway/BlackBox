SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_ReportsDevelopmentRun]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_ReportsDevelopmentRun' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#ReportRuns_NonDev]
            (
              [ReportName] Varchar(500)
            , [ReportType] Varchar(150)
            , [RunTime] DateTime
            , [SPs] Int
            );


        Insert  [#ReportRuns_NonDev]
                ( [ReportName]
                , [ReportType]
                , [RunTime]
                , [SPs]
                )
                Select  [RTL].[UsedByName]
                      , [RTUBT].[UsedByDescription]
                      , [RunTime] = Convert(DateTime , ( Left(Convert(Varchar(255) , [RTL].[TagDatetime]) ,
                                                              18) + '0' ))
                      , [SPs] = Count([RTL].[TagID])
                From    [BlackBox].[History].[RedTagLogs] [RTL]
                        Left Join [Lookups].[RedTagsUsedByType] [RTUBT]
                            On [RTUBT].[UsedByType] = [RTL].[UsedByType]
                Where   [RTL].[UsedByName] Like 'Development%'
                        Or [RTL].[UsedByName] Like 'Chris Johnson%'
                Group By Convert(DateTime , ( Left(Convert(Varchar(255) , [RTL].[TagDatetime]) ,
                                                   18) + '0' ))
                      , [RTL].[UsedByName]
                      , [RTUBT].[UsedByDescription];

        Set NoCount Off;	
        Select  [RR].[ReportName]
              , [RR].[ReportType]
              , [24Hours] = Count(Distinct Case When DateDiff(Day ,
                                                              [RR].[RunTime] ,
                                                              GetDate()) <= 1
                                                Then [RR].[RunTime]
                                                Else Null
                                           End)
              , [7Days] = Count(Distinct Case When DateDiff(Day ,
                                                            [RR].[RunTime] ,
                                                            GetDate()) Between 2 And 7
                                              Then [RR].[RunTime]
                                              Else Null
                                         End)
              , [1Month] = Count(Distinct Case When DateDiff(Day ,
                                                             [RR].[RunTime] ,
                                                             GetDate()) > 7
                                                    And DateDiff(Month ,
                                                              [RR].[RunTime] ,
                                                              GetDate()) <= 1
                                               Then [RR].[RunTime]
                                               Else Null
                                          End)
              , [1MonthPlus] = Count(Distinct Case When DateDiff(Month ,
                                                              [RR].[RunTime] ,
                                                              GetDate()) > 1
                                                   Then [RR].[RunTime]
                                                   Else Null
                                              End)
              , [TotalRuns] = Count(Distinct [RR].[RunTime])
              , [Ranking] = Count(Distinct Case When DateDiff(Day ,
                                                              [RR].[RunTime] ,
                                                              GetDate()) <= 1
                                                Then [RR].[RunTime]
                                                Else Null
                                           End) * 4--24Hours
                + Count(Distinct Case When DateDiff(Day , [RR].[RunTime] ,
                                                    GetDate()) Between 2 And 7
                                      Then [RR].[RunTime]
                                      Else Null
                                 End) * 3--1 week
                + Count(Distinct Case When DateDiff(Day , [RR].[RunTime] ,
                                                    GetDate()) > 7
                                           And DateDiff(Month , [RR].[RunTime] ,
                                                        GetDate()) <= 1
                                      Then [RR].[RunTime]
                                      Else Null
                                 End) * 2--1 month
                + Count(Distinct Case When DateDiff(Month , [RR].[RunTime] ,
                                                    GetDate()) > 1
                                      Then [RR].[RunTime]
                                      Else Null
                                 End)--1month plus
        From    [#ReportRuns_NonDev] [RR]
        Group By [RR].[ReportName]
              , [RR].[ReportType]
        Order By [Ranking] Desc;

        Set NoCount On;
        Drop Table [#ReportRuns_NonDev];
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'details of reports in development run', 'SCHEMA', N'Review', 'PROCEDURE', N'UspResults_ReportsDevelopmentRun', NULL, NULL
GO
