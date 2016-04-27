SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_TrialBalance]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
/*
Template designed by Chris Johnson, Prometic Group April 2016
*/
    Begin
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_TrialBalance' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Select  [GH].[Company]
              , [CN].[ShortName]
              , [CN].[CompanyName]
              , [CN].[Currency]
              , [GH].[GlCode]
              , [GlDescription] = [GM].[Description]
              , [ReportIndex1] = Case When [GM].[ReportIndex1] = '' Then Null
                                      Else [GM].[ReportIndex1]
                                 End
              , [ReportIndex2] = Case When [GM].[ReportIndex2] = '' Then Null
                                      Else [GM].[ReportIndex2]
                                 End
              , [GM].[GlGroup]
              , [GH].[GlYear]
              , [GH].[ClosingBalance]
              , [Debit] = Case When [GH].[ClosingBalance] > 0
                               Then [GH].[ClosingBalance]
                               Else 0
                          End
              , [Credit] = Case When [GH].[ClosingBalance] < 0
                                Then [GH].[ClosingBalance]
                                Else 0
                           End
              , [Period] = Case When [GH].[Period] = 'BeginYearBalance' Then 0
                                Else Convert(Smallint , Replace([GH].[Period] ,
                                                              'ClosingBalPer' ,
                                                              ''))
                           End
        From    [SysproCompany40].[dbo].[GenHistory] Unpivot ( [ClosingBalance] For [Period] In ( [BeginYearBalance] ,
                                                              [ClosingBalPer1] ,
                                                              [ClosingBalPer2] ,
                                                              [ClosingBalPer3] ,
                                                              [ClosingBalPer4] ,
                                                              [ClosingBalPer5] ,
                                                              [ClosingBalPer6] ,
                                                              [ClosingBalPer7] ,
                                                              [ClosingBalPer8] ,
                                                              [ClosingBalPer9] ,
                                                              [ClosingBalPer10] ,
                                                              [ClosingBalPer11] ,
                                                              [ClosingBalPer12] ,
                                                              [ClosingBalPer13] ,
                                                              [ClosingBalPer14] ,
                                                              [ClosingBalPer15] ) ) As [GH]
                Left Join [SysproCompany40].[dbo].[GenMaster] [GM]
                    On [GM].[Company] = [GH].[Company]
                       And [GM].[GlCode] = [GH].[GlCode]
                Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                    On [CN].[Company] = [GH].[Company];
    End;
GO
