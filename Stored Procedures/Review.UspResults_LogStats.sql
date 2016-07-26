SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_LogStats]
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
            @StoredProcName = 'UspResults_LogStats' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
        Select  [RTL].[TagID]
              , [RTL].[StoredProcDb]
              , [RTL].[StoredProcSchema]
              , [RTL].[StoredProcName]
              , [UsedByType] = [RTUBT].[UsedByDescription]
              , [RTL].[UsedByName]
              , [RTL].[UsedByDb]
              , [ReportHour] = DateName(Hour , [RTL].[TagDatetime])
              , [ReportDay] = DateName(Weekday , [RTL].[TagDatetime])
              , [TagDatetime] = Convert(DateTime , ( Left(Convert(Varchar(255) , [RTL].[TagDatetime]) ,
                                                          18) + '0' ))
              , [DaysSinceReportRun] = DateDiff(Day , [RTL].[TagDatetime] ,
                                                GetDate())
        From    [BlackBox].[History].[RedTagLogs] [RTL]
                Left Join [Lookups].[RedTagsUsedByType] [RTUBT]
                    On [RTUBT].[UsedByType] = [RTL].[UsedByType]
        Order By [RTL].[TagID] Desc;
    End;
GO
