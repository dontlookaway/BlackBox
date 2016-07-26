SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_ProcsMostRun]
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
            @StoredProcName = 'UspResults_ProcsMostRun' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#ProcsRun_NonDev]
            (
              [ProcName] Varchar(500)
            , [SchemaName] Varchar(150)
            , [RunTime] DateTime
            , [SPs] Int
            );


        Insert  [#ProcsRun_NonDev]
                ( [ProcName]
                , [SchemaName]
                , [RunTime]
                , [SPs]
                )
                Select  [RTL].[StoredProcName]
                      , [RTL].[StoredProcSchema]
                      , [RunTime] = Convert(DateTime , ( Left(Convert(Varchar(255) , [RTL].[TagDatetime]) ,
                                                              18) + '0' ))
                      , [SPs] = Count([RTL].[TagID])
                From    [BlackBox].[History].[RedTagLogs] [RTL]
                        Left Join [Lookups].[RedTagsUsedByType] [RTUBT]
                            On [RTUBT].[UsedByType] = [RTL].[UsedByType]
                Where   [RTL].[UsedByName] Not Like 'Development%'
                        And [RTL].[UsedByName] Not Like 'Chris Johnson%'
                Group By Convert(DateTime , ( Left(Convert(Varchar(255) , [RTL].[TagDatetime]) ,
                                                   18) + '0' ))
                      , [RTL].[StoredProcName]
                      , [RTL].[StoredProcSchema];

        Set NoCount Off;	
        Select  [RR].[ProcName]
              , [RR].[SchemaName]
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
                                                              GetDate()) < 1
                                               Then [RR].[RunTime]
                                               Else Null
                                          End)
              , [1MonthPlus] = Count(Distinct Case When DateDiff(Month ,
                                                              [RR].[RunTime] ,
                                                              GetDate()) >= 1
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
                                                        GetDate()) < 1
                                      Then [RR].[RunTime]
                                      Else Null
                                 End) * 2--1 month
                + Count(Distinct Case When DateDiff(Month , [RR].[RunTime] ,
                                                    GetDate()) >= 1
                                      Then [RR].[RunTime]
                                      Else Null
                                 End)--1month plus
        From    [#ProcsRun_NonDev] [RR]
        Group By [RR].[ProcName]
              , [RR].[SchemaName]
        Order By [Ranking] Desc;

        Set NoCount On;
        Drop Table [#ProcsRun_NonDev];
    End;
GO
