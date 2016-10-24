SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[Results_BudgetTest]
    (
      @TransJournal VARCHAR(150)
    )
As 
--exec Report.Results_BudgetTest @TransJournal  = 'Journal'
--exec Report.Results_BudgetTest @TransJournal  = 'Trans'
    Begin
--Declare @TransJournal VARCHAR(150) = 'Journal';

--Budget Data
        Select
            [bt].[BudgetTypeDesc]
          , [GB].[BudgetNumber]
          , [GB].[Company]
          , [GB].[DateLastModified]
          , [GB].[GlCode]
          , [GB].[Budget1]
          , [GB].[Budget2]
          , [GB].[Budget3]
          , [GB].[Budget4]
          , [GB].[Budget5]
          , [GB].[Budget6]
          , [GB].[Budget7]
          , [GB].[Budget8]
          , [GB].[Budget9]
          , [GB].[Budget10]
          , [GB].[Budget11]
          , [GB].[Budget12]
          , [GB].[Budget13]
          , [GB].[Budget14]
          , [GB].[Budget15]
        Into
            #Budgets
        From
            [SysproCompany40].dbo.GenBudgets GB
        Left Join [BlackBox].[Lookups].[BudgetType] As [bt]
            On [bt].[BudgetType] = [GB].[BudgetType]
        Where
            [Company] = '10'
        Order By
            [bt].[BudgetTypeDesc];

--Pick up either Transactions from 40 or journal details
        If @TransJournal = 'Trans'
            Begin
	--Transactions
                Select
                    [gt].[GlYear]
                  , [gts].[SourceDesc]
                  , [GlCode]
                  , [gt].[Journal]
                  , [gt].[Reference]
                  , [gt].[Comment]
                  , [gt].[JnlDate]
				  , [EntryPosted] = Null
                  , [Period1] = [gt].[1]
                  , [Period2] = [gt].[2]
                  , [Period3] = [gt].[3]
                  , [Period4] = [gt].[4]
                  , [Period5] = [gt].[5]
                  , [Period6] = [gt].[6]
                  , [Period7] = [gt].[7]
                  , [Period8] = [gt].[8]
                  , [Period9] = [gt].[9]
                  , [Period10] = [gt].[10]
                  , [Period11] = [gt].[11]
                  , [Period12] = [gt].[12]
                  , [Period13] = [gt].[13]
                  , [Period14] = [gt].[14]
                  , [Period15] = [gt].[15]
                Into
                    #Transpivoted
                From
                    [SysproCompany40].[dbo].[GenTransaction] Pivot ( SUM([EntryValue]) For [GlPeriod] In ( [1],
                                                              [2], [3], [4],
                                                              [5], [6], [7],
                                                              [8], [9], [10],
                                                              [11], [12], [13],
                                                              [14], [15] ) ) As [gt]
                Left Join [BlackBox].[Lookups].[GenTransactionSource] As [gts]
                    On [gts].[Source] = [gt].[Source]
                Where
                    [Journal] = 2726;

                Select
                    [BudgetTypeDesc] = COALESCE([BudgetTypeDesc],
                                                'No Budget')
                  , [BudgetNumber]
                  , [b].[Company]
                  , [b].[DateLastModified]
                  , [GlCode] = COALESCE([b].[GlCode], [t].[GlCode])
                  , [gm].[Description]
                  , [t].[GlYear]
                  , [t].[SourceDesc]
                  , [t].[Journal]
                  , [Reference] = Case When [t].[Reference] = '' Then Null
                                       Else [t].[Reference]
                                  End
                  , [Comment] = Case When [t].[Comment] = '' Then Null
                                     Else [t].[Comment]
                                End
				  , [EntryPosted]= null
                  , [t].[JnlDate]
                  , [Budget1]  =coalesce([Budget1] ,0)
                  , [Period1]  =coalesce([Period1] ,0)
                  , [Budget2]  =coalesce([Budget2] ,0)
                  , [Period2]  =coalesce([Period2] ,0)
                  , [Budget3]  =coalesce([Budget3] ,0)
                  , [Period3]  =coalesce([Period3] ,0)
                  , [Budget4]  =coalesce([Budget4] ,0)
                  , [Period4]  =coalesce([Period4] ,0)
                  , [Budget5]  =coalesce([Budget5] ,0)
                  , [Period5]  =coalesce([Period5] ,0)
                  , [Budget6]  =coalesce([Budget6] ,0)
                  , [Period6]  =coalesce([Period6] ,0)
                  , [Budget7]  =coalesce([Budget7] ,0)
                  , [Period7]  =coalesce([Period7] ,0)
                  , [Budget8]  =coalesce([Budget8] ,0)
                  , [Period8]  =coalesce([Period8] ,0)
                  , [Budget9]  =coalesce([Budget9] ,0)
                  , [Period9]  =coalesce([Period9] ,0)
                  , [Budget10] =coalesce([Budget10],0)
                  , [Period10] =coalesce([Period10],0)
                  , [Budget11] =coalesce([Budget11],0)
                  , [Period11] =coalesce([Period11],0)
                  , [Budget12] =coalesce([Budget12],0)
                  , [Period12] =coalesce([Period12],0)
                  , [Budget13] =coalesce([Budget13],0)
                  , [Period13] =coalesce([Period13],0)
                  , [Budget14] =coalesce([Budget14],0)
                  , [Period14] =coalesce([Period14],0)
                  , [Budget15] =coalesce([Budget15],0)
                  , [Period15] =coalesce([Period15],0)
                From
                    [#Budgets] As [b]
                Full Outer Join [#Transpivoted] As [t]
                    On [b].[GlCode] = [t].[GlCode]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [gm]
                    On [gm].[GlCode] = COALESCE([b].[GlCode], [t].[GlCode])
                Union
                Select
                    [BudgetTypeDesc]
                  , [BudgetNumber]
                  , [b].[Company]
                  , [b].[DateLastModified]
                  , [GlCode] = [b].[GlCode]
                  , [gm].[Description]
                  , [GlYear] = Null
                  , [SourceDesc] = Null
                  , [Journal] = Null
                  , [Reference] = Null
                  , [Comment] = Null
				  , [EntryPosted]= null
                  , [JnlDate] = Null
                  , [Budget1]  =coalesce([Budget1] ,0)
                  , [Period1]  =null
                  , [Budget2]  =coalesce([Budget2] ,0)
                  , [Period2]  =null
                  , [Budget3]  =coalesce([Budget3] ,0)
                  , [Period3]  =null
                  , [Budget4]  =coalesce([Budget4] ,0)
                  , [Period4]  =null
                  , [Budget5]  =coalesce([Budget5] ,0)
                  , [Period5]  =null
                  , [Budget6]  =coalesce([Budget6] ,0)
                  , [Period6]  =null
                  , [Budget7]  =coalesce([Budget7] ,0)
                  , [Period7]  =null
                  , [Budget8]  =coalesce([Budget8] ,0)
                  , [Period8]  =null
                  , [Budget9]  =coalesce([Budget9] ,0)
                  , [Period9]  =null
                  , [Budget10] =coalesce([Budget10],0)
                  , [Period10] =null
                  , [Budget11] =coalesce([Budget11],0)
                  , [Period11] =null
                  , [Budget12] =coalesce([Budget12],0)
                  , [Period12] =null
                  , [Budget13] =coalesce([Budget13],0)
                  , [Period13] =null
                  , [Budget14] =coalesce([Budget14],0)
                  , [Period14] =null
                  , [Budget15] =coalesce([Budget15],0)
                  , [Period15] =null
                From
                    [#Budgets] As [b]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [gm]
                    On [gm].[GlCode] = [b].[GlCode];

                Drop Table [#Budgets];
                Drop Table [#Transpivoted];
            End;
        If @TransJournal = 'Journal'
            Begin
                Select
                    [EntryValue] = [gjd].[EntryValue]
                    * Case When gjd.[EntryType] = 'D' Then 1
                           When gjd.[EntryType] = 'C' Then -1
                           Else 0
                      End
                  , [gjd].[GlCode]
                  , [gjd].[Journal]
                  , [gjd].[GlPeriod]
                  , [gjd].[GlYear]
				  , [gjd].[EntryPosted]
                  , [gts].[SourceDesc]
                  , JnlDate = [gjd].[EntryDate]
                  , [Reference] = Case When [gjd].[Reference] = '' Then Null
                                       Else [gjd].[Reference]
                                  End
                  , [Comment] = Case When [gjd].[Comment] = '' Then Null
                                     Else [gjd].[Comment]
                                End
                Into
                    #JD_raw
                From
                    [SysproCompany10]..[GenJournalDetail] gjd
                Left Join [BlackBox].[Lookups].[GenTransactionSource] As [gts]
                    On [gts].[Source] = [gjd].[Source];
                Select
                    GlCode
                  , [GlYear]
                  , [JnlDate]
                  , [Journal]
                  , [SourceDesc]
                  , Reference
                  , Comment
				  , [EntryPosted]
                  , Period1 = [1]
                  , Period2 = [2]
                  , Period3 = [3]
                  , Period4 = [4]
                  , Period5 = [5]
                  , Period6 = [6]
                  , Period7 = [7]
                  , Period8 = [8]
                  , Period9 = [9]
                  , Period10 = [10]
                  , Period11 = [11]
                  , Period12 = [12]
                  , Period13 = [13]
                  , Period14 = [14]
                  , Period15 = [15]
                Into
                    #JournalDetail
                From
                    [#JD_raw] Pivot ( SUM([EntryValue]) For [GlPeriod] In ( [1],
                                                              [2], [3], [4],
                                                              [5], [6], [7],
                                                              [8], [9], [10],
                                                              [11], [12], [13],
                                                              [14], [15] ) ) As [jr];
                Select
                    [BudgetTypeDesc] = COALESCE([BudgetTypeDesc],
                                                'No Budget')
                  , [BudgetNumber]
                  , [b].[Company]
                  , [b].[DateLastModified]
                  , [GlCode] = COALESCE([b].[GlCode], [t].[GlCode])
                  , [gm].[Description]
                  , [t].[GlYear]
                  , [t].[SourceDesc]
                  , [t].[Journal]
                  , [Reference] = Case When [t].[Reference] = '' Then Null
                                       Else [t].[Reference]
                                  End
                  , [Comment] = Case When [t].[Comment] = '' Then Null
                                     Else [t].[Comment]
                                End
				  , [t].[EntryPosted] 
                  , [t].[JnlDate]
                  , [Budget1]  = coalesce([Budget1]	,0)
                  , [Period1]  = coalesce([Period1]	,0)
                  , [Budget2]  = coalesce([Budget2]	,0)
                  , [Period2]  = coalesce([Period2]	,0)
                  , [Budget3]  = coalesce([Budget3]	,0)
                  , [Period3]  = coalesce([Period3]	,0)
                  , [Budget4]  = coalesce([Budget4]	,0)
                  , [Period4]  = coalesce([Period4]	,0)
                  , [Budget5]  = coalesce([Budget5]	,0)
                  , [Period5]  = coalesce([Period5]	,0)
                  , [Budget6]  = coalesce([Budget6]	,0)
                  , [Period6]  = coalesce([Period6]	,0)
                  , [Budget7]  = coalesce([Budget7]	,0)
                  , [Period7]  = coalesce([Period7]	,0)
                  , [Budget8]  = coalesce([Budget8]	,0)
                  , [Period8]  = coalesce([Period8]	,0)
                  , [Budget9]  = coalesce([Budget9]	,0)
                  , [Period9]  = coalesce([Period9]	,0)
                  , [Budget10] = coalesce([Budget10],0)
                  , [Period10] = coalesce([Period10],0)
                  , [Budget11] = coalesce([Budget11],0)
                  , [Period11] = coalesce([Period11],0)
                  , [Budget12] = coalesce([Budget12],0)
                  , [Period12] = coalesce([Period12],0)
                  , [Budget13] = coalesce([Budget13],0)
                  , [Period13] = coalesce([Period13],0)
                  , [Budget14] = coalesce([Budget14],0)
                  , [Period14] = coalesce([Period14],0)
                  , [Budget15] = coalesce([Budget15],0)
                  , [Period15] = coalesce([Period15],0)
                From
                    [#Budgets] As [b]
                Full Outer Join [#JournalDetail] As [t]
                    On [b].[GlCode] = t.[GlCode]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [gm]
                    On [gm].[GlCode] = COALESCE([b].[GlCode], [t].[GlCode])
                Union
                Select
                    [BudgetTypeDesc]
                  , [BudgetNumber]
                  , [b].[Company]
                  , [b].[DateLastModified]
                  , [GlCode] = [b].[GlCode]
                  , [gm].[Description]
                  , [GlYear] = Null
                  , [SourceDesc] = Null
                  , [Journal] = Null
                  , [Reference] = Null
                  , [Comment] = Null
				  , [EntryPosted]= null
                  , [JnlDate] = Null
                  , [Budget1]  =coalesce([Budget1] ,0)
                  , [Period1]  =null
                  , [Budget2]  =coalesce([Budget2] ,0)
                  , [Period2]  =null
                  , [Budget3]  =coalesce([Budget3] ,0)
                  , [Period3]  =null
                  , [Budget4]  =coalesce([Budget4] ,0)
                  , [Period4]  =null
                  , [Budget5]  =coalesce([Budget5] ,0)
                  , [Period5]  =null
                  , [Budget6]  =coalesce([Budget6] ,0)
                  , [Period6]  =null
                  , [Budget7]  =coalesce([Budget7] ,0)
                  , [Period7]  =null
                  , [Budget8]  =coalesce([Budget8] ,0)
                  , [Period8]  =null
                  , [Budget9]  =coalesce([Budget9] ,0)
                  , [Period9]  =null
                  , [Budget10] =coalesce([Budget10],0)
                  , [Period10] =null
                  , [Budget11] =coalesce([Budget11],0)
                  , [Period11] =null
                  , [Budget12] =coalesce([Budget12],0)
                  , [Period12] =null
                  , [Budget13] =coalesce([Budget13],0)
                  , [Period13] =null
                  , [Budget14] =coalesce([Budget14],0)
                  , [Period14] =null
                  , [Budget15] =coalesce([Budget15],0)
                  , [Period15] =null
                From
                    [#Budgets] As [b]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [gm]
                    On [gm].[GlCode] = [b].[GlCode];

                Drop Table [#Budgets];
                Drop Table [#JD_raw];
                Drop Table [#JournalDetail];
            End;
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'unused procedure', 'SCHEMA', N'Report', 'PROCEDURE', N'Results_BudgetTest', NULL, NULL
GO
