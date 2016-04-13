SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_GeneralLedgerControlStats]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group April 2016
*/

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_GeneralLedgerControlStats' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Select  [CN].[CompanyName]
              , [CN].[ShortName]
              , [CN].[Currency]
              , [GC].[Company]
              , [GC].[GlYear]
              , [GC].[GlPeriod]
              , [GC].[CurBalAsset]
              , [GC].[CurBalLiability]
              , [GC].[CurBalCapital]
              , [GC].[CurBalRevenue]
              , [GC].[CurBalExpense]
              , [GC].[OldestYearDet]
              , [GC].[CurYrPrdEnd1]
              , [GC].[CurYrPrdEnd2]
              , [GC].[CurYrPrdEnd3]
              , [GC].[CurYrPrdEnd4]
              , [GC].[CurYrPrdEnd5]
              , [GC].[CurYrPrdEnd6]
              , [GC].[CurYrPrdEnd7]
              , [GC].[CurYrPrdEnd8]
              , [GC].[CurYrPrdEnd9]
              , [GC].[CurYrPrdEnd10]
              , [GC].[CurYrPrdEnd11]
              , [GC].[CurYrPrdEnd12]
              , [GC].[CurYrPrdEnd13]
              , [GC].[CurYrPrdEnd14]
              , [GC].[CurYrPrdEnd15]
              , [GC].[PrvYrPrdEnd1]
              , [GC].[PrvYrPrdEnd2]
              , [GC].[PrvYrPrdEnd3]
              , [GC].[PrvYrPrdEnd4]
              , [GC].[PrvYrPrdEnd5]
              , [GC].[PrvYrPrdEnd6]
              , [GC].[PrvYrPrdEnd7]
              , [GC].[PrvYrPrdEnd8]
              , [GC].[PrvYrPrdEnd9]
              , [GC].[PrvYrPrdEnd10]
              , [GC].[PrvYrPrdEnd11]
              , [GC].[PrvYrPrdEnd12]
              , [GC].[PrvYrPrdEnd13]
              , [GC].[PrvYrPrdEnd14]
              , [GC].[PrvYrPrdEnd15]
              , [GC].[AuthoriseJournals]
        From    [SysproCompany40].[dbo].[GenControl] [GC]
                Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                    On [CN].[Company] = [GC].[Company];
    End;

GO
