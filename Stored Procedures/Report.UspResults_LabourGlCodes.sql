
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LabourGlCodes]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
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
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_LabourGlCodes' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

        Select  [GlMonth] = DateAdd(Month , [gjd].[GlPeriod] - 1 ,
                                  DateAdd(Year , [gjd].[GlYear] - 2000 ,
                                          Cast('2000-01-01' As Date)))
              , [gjd].[GlYear]
              , [gjd].[GlPeriod]
              , [Job] = [gjd].[SubModJob]
              , [EntryDate] = Cast([gjd].[EntryDate] As Date)
              , [gjd].[Journal]
              , [gjd].[GlCode]
              , [gm2].[Description]
              , [Comment] = Case When [gjd].[Comment] = '' Then Null
                                 Else [gjd].[Comment]
                            End
              , [JournalValue] = [gjd].[EntryValue]
                * Case When [gjd].[EntryType] = 'D' Then 1
                       When [gjd].[EntryType] = 'C' Then -1
                       Else 0
                  End
              , [gm].[Mapping1]
              , [gm].[Mapping2]
              , [gm].[Mapping3]
              , [gm].[Mapping4]
              , [gm].[Mapping5]
              , [FixedOhRate] = Cast(Null As Numeric(20 , 7))
              , [VariableOhRate] = Cast(Null As Numeric(20 , 7))
              , [WorkCentre] = Cast(Null As Varchar(150))
              , [Employee] = Cast(Null As Varchar(150))
              , [RunTime] = Cast(Null As Numeric(20 , 7))
              , [RunTimeRate] = Cast(Null As Numeric(20 , 7))
              , [SetUpTime] = Cast(Null As Numeric(20 , 7))
              , [SetUpRate] = Cast(Null As Numeric(20 , 7))
              , [StartUpTime] = Cast(Null As Numeric(20 , 7))
              , [StartUpRate] = Cast(Null As Numeric(20 , 7))
              , [TeardownTime] = Cast(Null As Numeric(20 , 7))
              , [TeardownRate] = Cast(Null As Numeric(20 , 7))
              , [LabourValue] = Cast(Null As Numeric(20 , 7))
        From    [SysproCompany10]..[GenJournalDetail] As [gjd]
                Left Join [Lookups].[GLMapping] As [gm] On [gm].[GlCode] = [gjd].[GlCode]
                                                           And [gm].[Company] = '10'
                Left Join [SysproCompany40]..[GenMaster] As [gm2] On [gm2].[GlCode] = [gjd].[GlCode]
                                                              And [gm2].[Company] = '10'
        Union All
        Select  [GlMonth] = DateAdd(Month , [wlj].[GlPeriod] - 1 ,
                                  DateAdd(Year , [wlj].[GlYear] - 2000 ,
                                          Cast('2000-01-01' As Date)))
              , [wlj].[GlYear]
              , [wlj].[GlPeriod]
              , [wlj].[Job]
              , [EntryDate] = Cast([wlj].[EntryDate] As Date)
              , [wlj].[Journal]
              , [GlCode] = 'Labour'
              , [Description] = Null
              , [Comment] = Null
              , [JournalValue] = Null
              , [Mapping1] = 'Labour'
              , [Mapping2] = 'Labour'
              , [Mapping3] = 'Labour'
              , [Mapping4] = 'Labour'
              , [Mapping5] = 'Labour'
              , [wlj].[FixedOhRate]
              , [wlj].[VariableOhRate]
              , [wlj].[WorkCentre]
              , [wlj].[Employee]
              , [RunTime] = Sum([wlj].[RunTime])
              , [wlj].[RunTimeRate]
              , [SetUpTime] = Sum([wlj].[SetUpTime])
              , [wlj].[SetUpRate]
              , [StartUpTime] = Sum([wlj].[StartUpTime])
              , [wlj].[StartUpRate]
              , [TeardownTime] = Sum([wlj].[TeardownTime])
              , [wlj].[TeardownRate]
              , [LabourValue] = Sum([wlj].[LabourValue])
        From    [SysproCompany10]..[WipLabJnl] As [wlj]
        Group By DateAdd(Month , [wlj].[GlPeriod] - 1 ,
                         DateAdd(Year , [wlj].[GlYear] - 2000 ,
                                 Cast('2000-01-01' As Date)))
              , Cast([EntryDate] As Date)
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
        Order By [GlMonth] Desc;

    End;

GO
