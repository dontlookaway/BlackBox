SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--'Development > Chris Johnson > GL Balances And Mvmts';

Create Proc [Report].[UspResults_MovementsTrialBalances]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
*/
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_MovementsTrialBalances' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
        Create Table [#Movements]
            (
              [Company] Varchar(50)
            , [ShortName] Varchar(250)
            , [CompanyName] Varchar(250)
            , [Currency] Varchar(10)
            , [GlCode] Varchar(50)
            , [Description] Varchar(150)
            , [GlGroup] Varchar(50)
            , [Movement] Numeric(20 , 6)
            , [GlPeriod] Int
            , [GlYear] Int
            , [Source] Varchar(100)
            , [Journal] Int
            , [ReportIndex1] Varchar(35)
            , [ReportIndex2] Varchar(35)
            , [AccountType] Varchar(250)
            , [Parse1] Varchar(50)
            , [Parse2] Varchar(50)
            , [Parse3] Varchar(50)
            );

        Create Table [#Balances]
            (
              [Company] Varchar(150)
            , [ShortName] Varchar(250)
            , [CompanyName] Varchar(250)
            , [Currency] Varchar(10)
            , [GlCode] Varchar(50)
            , [GlDescription] Varchar(150)
            , [ReportIndex1] Varchar(50)
            , [ReportIndex2] Varchar(50)
            , [GlGroup] Varchar(50)
            , [GlYear] Int
            , [ClosingBalance] Numeric(20 , 6)
            , [Debit] Numeric(20 , 6)
            , [Credit] Numeric(20 , 6)
            , [Period] Int
            , [AccountType] Varchar(250)
            , [Parse1] Varchar(50)
            , [Parse2] Varchar(50)
            , [Parse3] Varchar(50)
            );
        Insert  [#Movements]
                ( [Company]
                , [ShortName]
                , [CompanyName]
                , [Currency]
                , [GlCode]
                , [Description]
                , [GlGroup]
                , [Movement]
                , [GlPeriod]
                , [GlYear]
                , [Source]
                , [Journal]
                , [ReportIndex1]
                , [ReportIndex2]
                , [AccountType]
                , [Parse1]
                , [Parse2]
                , [Parse3]
                )
                Exec [Report].[UspResults_GLMovements] @RedTagType = @RedTagType ,
                    @RedTagUse = @RedTagUse; 
 -- varchar(500)

        Insert  [#Balances]
                ( [Company]
                , [ShortName]
                , [CompanyName]
                , [Currency]
                , [GlCode]
                , [GlDescription]
                , [ReportIndex1]
                , [ReportIndex2]
                , [GlGroup]
                , [GlYear]
                , [ClosingBalance]
                , [Debit]
                , [Credit]
                , [Period]
                , [AccountType]
                , [Parse1]
                , [Parse2]
                , [Parse3]
                )
                Exec [Report].[UspResults_TrialBalance] @RedTagType = @RedTagType ,
                    @RedTagUse = @RedTagUse; 
 -- varchar(500)

        Create NonClustered Index [tdf] On [#Balances] ([Company],[GlCode],[GlYear],[Period]);
        Create NonClustered Index [tfd] On [#Movements] ([Company],[GlCode],[GlYear],[GlPeriod]);

        Select  [B].[Company]
              , [B].[ShortName]
              , [B].[CompanyName]
              , [B].[Currency]
              , [B].[GlCode]
              , [B].[GlDescription]
              , [B].[ReportIndex1]
              , [B].[ReportIndex2]
              , [B].[GlGroup]
              , [B].[GlYear]
              , [B].[ClosingBalance]
              , [B].[Debit]
              , [B].[Credit]
              , [B].[Period]
              , [M].[Company]
              , [M].[Movement]
              , [M].[GlPeriod]
              , [M].[GlYear]
              , [M].[Source]
              , [M].[Journal]
              , [B].[AccountType]
              , [B].[Parse1]
              , [B].[Parse2]
              , [B].[Parse3]
        From    [#Balances] [B]
                Left Join [#Movements] [M]
                    On [M].[Company] = [B].[Company]
                       And [M].[GlCode] = [B].[GlCode]
                       And [M].[GlYear] = [B].[GlYear]
                       And [B].[Period] = [M].[GlPeriod];
    End;
GO
