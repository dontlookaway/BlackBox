SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [Report].[UspResults_GenLedgerMvts_JournalHoursCo10]
 ( @GLCode VARCHAR(35) )
 /*
#/#/#/#/#////////////////////////////////////////////////////////////////////////#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#// Created Template 8/10/2015 Chris Johnson, Prometic					/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//	Initial version created 8/10/2015									/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#//																		/#/#/#/#/#/#/
#/#/#/#/#////////////////////////////////////////////////////////////////////////#/#/#/#/#/#/
*/
As
    Begin
    
	--If code isn't entered, use the 
        Select @GLCode = COALESCE(@GLCode ,'101.11010.101')


        Select
            gm.[GlCode]
          , [gm].[Description]
        Into
            #Glname
        From
            [SysproCompany40]..[GenMaster] As [gm]
        Where
            [gm].[GlCode] = @GLCode;

        Set NoCount On;
        Select
            gjd.[GlYear]
          , gjd.[GlPeriod]
          , gjd.[Journal]
          , gjd.[EntryType]
          , Multiplier = Case When gjd.[EntryType] = 'D' Then 1
                              Else -1
                         End
          , gjd.[GlCode]
          , gjd.[SubModStock]
          , gjd.[Comment]
          , gjd.[EntryValue]
          , gjd.[Reference]
          , gjd.[EntryDate]
          , gjd.[TransactionDate]
          , gjd.[SubModTransDesc]
          , gjd.[SubModJournal]
        Into
            [#Jnl]
        From
            [SysproCompany10]..[GenJournalDetail] gjd
        Where
            gjd.[GlCode] = @GLCode
            And gjd.EntryPosted = 'Y'
        Order By
            [EntryDate] Desc;

--Total Check
        Declare
            @JNL NUMERIC(20, 2)
          , @Ledge NUMERIC(20, 2);
        Select
            @JNL = SUM([j].[EntryValue] * [j].[Multiplier])
        From
            [#Jnl] As [j];

        Select
            @Ledge = [gm].[CurrentBalance]
        From
            [SysproCompany40]..[GenMaster] As [gm]
        Where
            [gm].[GlCode] = @GLCode;

        Print @JNL;
        Print @Ledge;

        If @JNL = @Ledge
            Begin
                Select Distinct
                    [gjd].[Journal]
                  , [gjd].[SubModJob]
                Into
                    #JobList
                From
                    [SysproCompany10]..[GenJournalDetail] As [gjd];

--List of values per journal
                Select
                    [j].[GlCode]
                  , [Reference]
                  , [SubModStock]
                  , [j].[SubModJournal]
                  , [j].[Journal]
                  , FakePeriod = YEAR([EntryDate]) * 100 + MONTH([EntryDate])
                  , Value = SUM([j].[EntryValue] * [j].[Multiplier])
                Into
                    #Refs
                From
                    #Jnl j
                Group By
                    YEAR([EntryDate]) * 100 + MONTH([EntryDate])
                  , [Reference]
                  , [j].[GlCode]
                  , [SubModStock]
                  , [j].[SubModJournal]
                  , [j].[Journal];

--number of hours per sub jrn
                Select
                    [SubModJournal] = [jl].[Journal]
                  , TotRuns = SUM([wlj].[RunTime])
                Into
                    #Jobhrs
                From
                    [#JobList] As [jl]
                Left Join [SysproCompany10]..[WipLabJnl] As [wlj]
                    On [wlj].[Job] = [jl].[SubModJob]
                Group By
                    [jl].[Journal]
                Having
                    SUM([wlj].[RunTime]) > 0;

--return results
                Select
                    GLDescription = [gn].[Description]
                  , [r].[GlCode]
                  , Stock = Case When [SubModStock] = '' Then Null
                                 Else [SubModStock]
                            End
                  , [r].[Journal]
                  , [r].[SubModJournal]
                  , [r].[FakePeriod]
                  , [r].[Value]
                  , RunTime = SUM([j].[TotRuns])
                From
                    [#Refs] As [r]
                Left Join [#Jobhrs] As [j]
                    On [j].[SubModJournal] = [r].[SubModJournal]
                Left Join #Glname As gn
                    On [gn].[GlCode] = [r].[GlCode]
                Group By
                    [r].[FakePeriod]
                  , [r].[Value]
                  , [r].[GlCode]
                  , Case When [SubModStock] = '' Then Null
                         Else [SubModStock]
                    End
                  , [r].[SubModJournal]
                  , [r].[Journal]
                  , [gn].[Description]
                Order By
                    [r].[Journal];

--tidy up
        
                Drop Table [#Refs];
                Drop Table [#JobList];
                Drop Table [#Jobhrs];
            End;

        Drop Table [#Jnl];
        Drop Table #Glname;
    End;
GO
