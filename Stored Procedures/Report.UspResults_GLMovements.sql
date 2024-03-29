SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GLMovements]
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
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_GLMovements' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Declare @GlYearPeriod Int;

        Create Table [#YearPeriod]
            (
              [GlYear] Int
            , [GlPeriod] Int
            );

        Insert  [#YearPeriod]
                ( [GlYear]
                , [GlPeriod]
                )
                Select Distinct
                        [GT].[GlYear]
                      , [P].[Number]
                From    [SysproCompany40]..[GenTransaction] [GT]
                        Cross Join ( Select [Number]
                                     From   [dbo].[UdfResults_NumberRange](0 ,
                                                              15)
                                   ) [P];

        Create Table [#Movements]
            (
              [Company] Varchar(10) Collate Latin1_General_BIN
            , [ShortName] Varchar(250) Collate Latin1_General_BIN
            , [CompanyName] Varchar(250) Collate Latin1_General_BIN
            , [Currency] Varchar(10) Collate Latin1_General_BIN
            , [GlCode] Varchar(35) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            , [GlGroup] Varchar(10) Collate Latin1_General_BIN
            , [Movement] Numeric(20 , 2)
            , [GlPeriod] Int
            , [GlYear] Int
            , [Source] Varchar(100) Collate Latin1_General_BIN
            , [Journal] Int
            , [ReportIndex1] Varchar(35) Collate Latin1_General_BIN
            , [ReportIndex2] Varchar(35) Collate Latin1_General_BIN
            , [GLAccountTypeDesc] Varchar(250) Collate Latin1_General_BIN
            );
        Create Table [#MovementsRaw]
            (
              [Company] Varchar(10) Collate Latin1_General_BIN
            , [ShortName] Varchar(250) Collate Latin1_General_BIN
            , [CompanyName] Varchar(250) Collate Latin1_General_BIN
            , [Currency] Varchar(10) Collate Latin1_General_BIN
            , [GlCode] Varchar(35) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            , [GlGroup] Varchar(10) Collate Latin1_General_BIN
            , [Movement] Numeric(20 , 2)
            , [GlPeriod] Int
            , [GlYear] Int
            , [ReportIndex1] Varchar(35) Collate Latin1_General_BIN
            , [ReportIndex2] Varchar(35) Collate Latin1_General_BIN
            , [GLAccountTypeDesc] Varchar(250) Collate Latin1_General_BIN
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
                , [GLAccountTypeDesc]
                )
                Select  [t].[Company]
                      , [t].[ShortName]
                      , [t].[CompanyName]
                      , [t].[Currency]
                      , [t].[GlCode]
                      , [t].[Description]
                      , [t].[GlGroup]
                      , [t].[Movement]
                      , [t].[GlPeriod]
                      , [t].[GlYear]
                      , [t].[Source]
                      , [t].[Journal]
                      , [t].[ReportIndex1]
                      , [t].[ReportIndex2]
                      , [t].[GLAccountTypeDesc]
                From    ( Select    [GM].[Company]
                                  , [CN].[ShortName]
                                  , [CN].[CompanyName]
                                  , [CN].[Currency]
                                  , [GM].[GlCode]
                                  , [GM].[Description]
                                  , [GM].[GlGroup]
                                  , [Movement] = ( [GH].[BeginYearBalance] )
                                  , [GlPeriod] = 0
                                  , [GH].[GlYear]
                                  , [Source] = 'History'
                                  , [Journal] = 0
                                  , [GM].[ReportIndex1]
                                  , [GM].[ReportIndex2]
                                  , [GAT].[GLAccountTypeDesc]
                          From      [SysproCompany40].dbo.[GenMaster] As [GM]
                                    Left Join [BlackBox].[Lookups].[CompanyNames]
                                        As [CN]
                                        On [CN].[Company] = [GM].[Company]
                                    Left Join [SysproCompany40].[dbo].[GenHistory] [GH]
                                        On [GH].[Company] = [GM].[Company]
                                           And [GH].[GlCode] = [GM].[GlCode]
                                    Left Join [BlackBox].[Lookups].[GLAccountType] [GAT]
                                        On [GAT].[GLAccountType] = [GM].[AccountType]
                          Where     [GH].[GlYear] >= 2013
                          Union All
                          Select    [GM].[Company]
                                  , [CN].[ShortName]
                                  , [CN].[CompanyName]
                                  , [CN].[Currency]
                                  , [GM].[GlCode]
                                  , [GM].[Description]
                                  , [GM].[GlGroup]
                                  , [Movement] = [GT].[EntryValue]
                                  , [GT].[GlPeriod]
                                  , [GT].[GlYear]
                                  , [Source] = 'Transactions'
                                  , [GT].[Journal]
                                  , [GM].[ReportIndex1]
                                  , [GM].[ReportIndex2]
                                  , [GAT].[GLAccountTypeDesc]
                          From      [SysproCompany40]..[GenMaster] As [GM]
                                    Left Join [SysproCompany40].[dbo].[GenTransaction] [GT]
                                        On [GT].[Company] = [GM].[Company]
                                           And [GT].[GlCode] = [GM].[GlCode]
                                    Left Join [BlackBox].[Lookups].[CompanyNames]
                                        As [CN]
                                        On [CN].[Company] = [GM].[Company]
                                    Left Join [BlackBox].[Lookups].[GLAccountType] [GAT]
                                        On [GAT].[GLAccountType] = [GM].[AccountType]
                          Where     [GT].[EntryValue] <> 0
                        ) [t]
                Order By [t].[Company]
                      , [t].[GlCode]
                      , [t].[GlYear]
                      , [t].[GlPeriod];

		--Get latest Gl period
        Select  @GlYearPeriod = Max(( [M].[GlYear] * 100 ) + [M].[GlPeriod])
        From    [#Movements] [M];

        Insert  [#MovementsRaw]
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
                , [ReportIndex1]
                , [ReportIndex2]
                , [GLAccountTypeDesc]
                )
                Select  [GM].[Company]
                      , [CN].[ShortName]
                      , [CN].[CompanyName]
                      , [CN].[Currency]
                      , [GM].[GlCode]
                      , [GM].[Description]
                      , [GM].[GlGroup]
                      , [Movement] = Convert(Numeric(20 , 4) , 0)
                      , [YP].[GlPeriod]
                      , [YP].[GlYear]
                      , [GM].[ReportIndex1]
                      , [GM].[ReportIndex2]
                      , [GAT].[GLAccountTypeDesc]
                From    [SysproCompany40].dbo.[GenMaster] [GM]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                            On [CN].[Company] = [GM].[Company]
                        Cross Join [#YearPeriod] [YP]
                        Left Join [BlackBox].[Lookups].[GLAccountType] [GAT]
                            On [GAT].[GLAccountType] = [GM].[AccountType];

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
                , [GLAccountTypeDesc]
                )
                Select  [MR].[Company]
                      , [MR].[ShortName]
                      , [MR].[CompanyName]
                      , [MR].[Currency]
                      , [MR].[GlCode]
                      , [MR].[Description]
                      , [MR].[GlGroup]
                      , [MR].[Movement]
                      , [MR].[GlPeriod]
                      , [MR].[GlYear]
                      , [Source] = 'Generated'
                      , [Journal] = 0
                      , [M].[ReportIndex1]
                      , [M].[ReportIndex2]
                      , [M].[GLAccountTypeDesc]
                From    [#MovementsRaw] [MR]
                        Left Join [#Movements] [M]
                            On [M].[Company] = [MR].[Company]
                               And [M].[GlCode] = [MR].[GlCode]
                               And [M].[GlYear] = [MR].[GlYear]
                               And [M].[GlPeriod] = [MR].[GlPeriod]
                Where   [M].[Company] Is Null;

        --Remove null periods and generate
        Delete  [#Movements]
        Where   ( [GlYear] * 100 ) + [GlPeriod] > @GlYearPeriod
                Or [GlPeriod] Is Null;

		Set NoCount Off
        Select  [M].[Company]
              , [M].[ShortName]
              , [M].[CompanyName]
              , [M].[Currency]
              , [M].[GlCode]
              , [M].[Description]
              , [M].[GlGroup]
              , [M].[Movement]
              , [M].[GlPeriod]
              , [M].[GlYear]
              , [M].[Source]
              , [M].[Journal]
              , [M].[ReportIndex1]
              , [M].[ReportIndex2]
              , AccountType = [M].[GLAccountTypeDesc]
			  , [Parse1] = ParseName([M].[GlCode],1)
			  , [Parse2] = ParseName([M].[GlCode],2)
			  , [Parse3] = ParseName([M].[GlCode],3)
        From    [#Movements] [M]
        Order By [M].[ShortName]
              , [M].[GlCode]
              , [M].[GlYear] Asc
              , [M].[GlPeriod] Asc;

        Drop Table [#YearPeriod];
        Drop Table [#Movements];
        Drop Table [#MovementsRaw];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of gl movements', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_GLMovements', NULL, NULL
GO
