
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_BudgetsActuals]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016
*/

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_BudgetsActuals' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#Budgets]
            (
              [Company] Varchar(10)
            , [GlCode] Varchar(100)
            , [Budget] Numeric(20 , 2)
            , [BudgetType] Char(1)
            , [Period] Int
            );
        Create Table [#Actuals]
            (
              [Company] Varchar(10)
            , [GlCode] Varchar(50)
            , [Period] Int
            , [Actual] Numeric(20 , 2)
            , [YearMovement] Numeric(20 , 2)
            , [GlYear] Int
            , [ClosingBalance] Numeric(20 , 2)
            , [MovementToDate] Numeric(20 , 2)
            );
        Create Table [#BudgetsActuals]
            (
              [CompanyGlCode] Varchar(150)
            , [Period] Int
            , [Budget] Numeric(20 , 2)
            , [Actual] Numeric(20 , 2)
            , [GlYear] Int
            , [LineType] Varchar(50)
            , [ClosingBalance] Numeric(20 , 2)
            , [MovementToDate] Numeric(20 , 2)
            , [Company] Varchar(10)
            );

        Insert  [#Budgets]
                ( [Company]
                , [GlCode]
                , [Budget]
                , [BudgetType]
                , [Period]
                )
                Exec [BlackBox].[Report].[UspResults_GL_Budgets];
        Insert  [#Actuals]
                ( [Company]
                , [GlCode]
                , [Period]
                , [Actual]
                , [YearMovement]
                , [GlYear]
                , [ClosingBalance]
                , [MovementToDate]
                )
                Exec [Report].[UspResults_GL_Actuals];
        Insert  [#BudgetsActuals]
                ( [CompanyGlCode]
                , [Period]
                , [Budget]
                , [Actual]
                , [GlYear]
                , [LineType]
                , [ClosingBalance]
                , [MovementToDate]
                , [Company]
                )
                Select  [t].[CompanyGlCode]
                      , [t].[Period]
                      , [t].[Budget]
                      , [t].[Actual]
                      , [t].[GlYear]
                      , [t].[LineType]
                      , [t].[ClosingBalance]
                      , [t].[MovementToDate]
                      , [t].[Company]
                From    ( Select    [CompanyGlCode] = [A].[GlCode]
                                  , [A].[Period]
                                  , [Budget] = 0
                                  , [A].[Actual]
                                  , [A].[GlYear]
                                  , [LineType] = 'Actual'
                                  , [A].[ClosingBalance]
                                  , [A].[MovementToDate]
                                  , [A].[Company]
                          From      [#Actuals] As [A]
                          Union
                          Select    [CompanyGlCode] = [B].[GlCode]
                                  , [B].[Period]
                                  , [B].[Budget]
                                  , [Actual] = 0
                                  , [GlYear] = Year(GetDate())
                                  , [LineType] = 'Budget'
                                  , [ClosingBalance] = 0
                                  , [MovementToDate] = 0
                                  , [B].[Company]
                          From      [#Budgets] As [B]
                        ) [t];

        Select  [BA].[CompanyGlCode]
              , [BA].[Period]
              , [BA].[Budget]
              , [BA].[Actual]
              , [BA].[GlYear]
              , [BA].[LineType]
              , [BA].[ClosingBalance]
              , [BA].[MovementToDate]
              , [BA].[Company]
              , [GM].[Description]
              , [GlGroup] = Case When [GM].[GlGroup] = '' Then Null
                                 Else [GM].[GlGroup]
                            End
              , [CN].[CompanyName]
              , [ReportIndex2] = Case When [GM].[ReportIndex2] = '' Then Null
                                      When [BA].[Company] = '10'
                                      Then 'Co. 10 ' + [GM].[ReportIndex2]
                                      Else [GM].[ReportIndex2]
                                 End
              , [CN].[Currency]
              , [CR].[CADMultiply]
              , [CR].[GBPMultiply]
              , [CR].[USDMultiply]
              , [CR].[EURMultiply]
              , [CR].[CHFMultiply]
              , [GAT].[GLAccountTypeDesc]
              , [RIUM].[Map]
              , [RIUM].[IsSummary]
              , [GroupMap1] = [LGM].[Map1]
              , [GroupMap2] = [LGM].[Map2]
              , [GroupMap3] = [LGM].[Map3]
        From    [#BudgetsActuals] As [BA]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [GM].[Company] = [BA].[Company]
                                                              And [GM].[GlCode] = [BA].[CompanyGlCode]
                Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [BA].[Company]
                Left Join [Lookups].[CurrencyRates] As [CR] On [CR].[Currency] = [CN].[Currency]
                                                              And GetDate() Between [CR].[StartDateTime]
                                                              And
                                                              [CR].[EndDateTime]
                Left Join [BlackBox].[Lookups].[GLAccountType] As [GAT] On [GM].[AccountType] = [GAT].[GLAccountType]
				Left Join [BlackBox].[Lookups].[LedgerGroupMaps] As [LGM] On [LGM].[GlGroup] = [GM].[GlGroup]
                Left Join [Lookups].[ReportIndexUserMaps] As [RIUM] On [RIUM].[ReportIndex2] = Case
                                                              When [GM].[ReportIndex2] = ''
                                                              Then Null
                                                              When [BA].[Company] = '10'
                                                              Then 'Co. 10 '
                                                              + [GM].[ReportIndex2]
                                                              Else [GM].[ReportIndex2]
                                                              End;

    End;
GO
