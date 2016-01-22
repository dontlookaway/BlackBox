
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LabourGlCodes] ( @Company VARCHAR(Max) )
As 
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--Exec [Report].[UspResults_LabourGlCodes]  @Company ='10'
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'AssetDepreciation,TblApTerms'; 

        Select
            GlMonth = DATEADD(Month, GlPeriod - 1,
                              DATEADD(Year, [gjd].[GlYear] - 2000,
                                      CAST('2000-01-01' As DATE)))
          , [gjd].[GlYear]
          , [gjd].[GlPeriod]
          , Job = [gjd].[SubModJob]
          , [EntryDate] = CAST([gjd].[EntryDate] As DATE)
          , [gjd].[Journal]
          , [gjd].[GlCode]
          , [gm2].[Description]
          , [Comment] = Case When	 [gjd].[Comment]='' Then Null Else [gjd].[Comment] End
          , JournalValue = [gjd].[EntryValue]
            * Case When [gjd].[EntryType] = 'D' Then 1
                   When [gjd].[EntryType] = 'C' Then -1
                   Else 0
              End
          , [gm].[Mapping1]
          , [gm].[Mapping2]
          , [gm].[Mapping3]
          , [gm].[Mapping4]
          , [gm].[Mapping5]
          , FixedOhRate = CAST(Null As NUMERIC(20, 7))
          , VariableOhRate = CAST(Null As NUMERIC(20, 7))
          , WorkCentre = CAST(Null As VARCHAR(150))
          , Employee = CAST(Null As VARCHAR(150))
          , RunTime = CAST(Null As NUMERIC(20, 7))
          , RunTimeRate = CAST(Null As NUMERIC(20, 7))
          , SetUpTime = CAST(Null As NUMERIC(20, 7))
          , SetUpRate = CAST(Null As NUMERIC(20, 7))
          , StartUpTime = CAST(Null As NUMERIC(20, 7))
          , StartUpRate = CAST(Null As NUMERIC(20, 7))
          , TeardownTime = CAST(Null As NUMERIC(20, 7))
          , TeardownRate = CAST(Null As NUMERIC(20, 7))
          , LabourValue = CAST(Null As NUMERIC(20, 7))
        From
            [SysproCompany10]..[GenJournalDetail] As [gjd]
        Left Join [Lookups].[GLMapping] As [gm]
            On [gm].[GlCode] = [gjd].[GlCode]
               And [gm].[Company] = '10'
        Left Join [SysproCompany40]..[GenMaster] As [gm2]
            On [gm2].[GlCode] = [gjd].[GlCode]
               And [gm2].[Company] = '10'
        Union All
        Select
            GlMonth = DATEADD(Month, GlPeriod - 1,
                              DATEADD(Year, [GlYear] - 2000,
                                      CAST('2000-01-01' As DATE)))
          , [wlj].[GlYear]
          , [wlj].[GlPeriod]
          , [Job]
          , [EntryDate] = CAST([EntryDate] As DATE)
          , Journal
          , GlCode = 'Labour'
          , Description = Null
          , Comment = Null
          , JournalValue = Null
          , Mapping1 = 'Labour'
          , Mapping2 = 'Labour'
          , Mapping3 = 'Labour'
          , Mapping4 = 'Labour'
          , Mapping5 = 'Labour'
          , [wlj].[FixedOhRate]
          , [wlj].[VariableOhRate]
          , [wlj].WorkCentre
          , [wlj].[Employee]
          , [RunTime] = SUM([wlj].[RunTime])
          , [wlj].[RunTimeRate]
          , [SetUpTime] = SUM([wlj].[SetUpTime])
          , [wlj].[SetUpRate]
          , [StartUpTime] = SUM([wlj].[StartUpTime])
          , [wlj].[StartUpRate]
          , [TeardownTime] = SUM([wlj].[TeardownTime])
          , [wlj].[TeardownRate]
          , [LabourValue] = SUM([wlj].[LabourValue])
        From
            [SysproCompany10]..[WipLabJnl] As [wlj]
        Group By
            DATEADD(Month, GlPeriod - 1,
                    DATEADD(Year, [GlYear] - 2000, CAST('2000-01-01' As DATE)))
          , CAST([EntryDate] As DATE)
          , [wlj].[GlPeriod]
          , [wlj].[GlYear]
          , [wlj].[Journal]
          , [wlj].[Employee]
          , [wlj].[RunTimeRate]
          , [wlj].[SetUpRate]
          , [wlj].[StartUpRate]
          , [wlj].[TeardownRate]
          , [wlj].[FixedOhRate]
          , [wlj].[VariableOhRate]
          , [wlj].[WorkCentre]
          , [wlj].[Job]
        Order By
            GlMonth Desc;

    End;

GO
