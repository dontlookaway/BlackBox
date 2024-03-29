SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GLMovementsPBLRevCos]
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
            @StoredProcName = 'UspResults_GLMovementsPBLRevCos' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

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
            , [ReportIndex1] Varchar(100) Collate Latin1_General_BIN
            , [ReportIndex2] Varchar(100) Collate Latin1_General_BIN
            , [AccountType] Varchar(100) Collate Latin1_General_BIN
            , [Parse1] Varchar(100) Collate Latin1_General_BIN
            , [Parse2] Varchar(100) Collate Latin1_General_BIN
            , [Parse3] Varchar(100) Collate Latin1_General_BIN
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
              , [t].[RevGLCode]
              , [RevGLDescription] = [GM].[Description]
        From    ( Select    [M].[Company]
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
                          , [RevGLCode] = [M].[GlCode]
                  From      [#Movements] [M]
                  Where     [M].[GlCode] In ( '101.50000.000' ,
                                              '101.50005.000' ,
                                              '101.50010.000' ,
                                              '101.50015.000' ,
                                              '101.50020.000' ,
                                              '101.50025.000' ,
                                              '101.50030.000' ,
                                              '101.50035.000' ,
                                              '101.50040.000' ,
                                              '101.50050.000' ,
                                              '101.50050.001' ,
                                              '101.50055.000' ,
                                              '101.50095.000' ,
                                              '101.50095.001' )
                  Union All
                  Select    [M].[Company]
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
                          , [RevGLCode] = Case When [M].[GlCode] = '101.60050.100'
                                               Then '101.50050.001'
                                               When [M].[GlCode] = '101.60095.002'
                                               Then '101.50095.001'
                                               Else '101.5'
                                                    + Right(ParseName([M].[GlCode] ,
                                                              2) , 4) + '.000'
                                          End
                  From      [#Movements] [M]
                  Where     [M].[GlCode] In ( '101.60000.000' ,
                                              '101.60000.001' ,
                                              '101.60005.000' ,
                                              '101.60005.001' ,
                                              '101.60010.000' ,
                                              '101.60010.000' ,
                                              '101.60015.000' ,
                                              '101.60015.001' ,
                                              '101.60020.000' ,
                                              '101.60020.001' ,
                                              '101.60025.000' ,
                                              '101.60025.001' ,
                                              '101.60030.000' ,
                                              '101.60030.001' ,
                                              '101.60035.000' ,
                                              '101.60035.001' ,
                                              '101.60040.000' ,
                                              '101.60040.001' ,
                                              '101.60050.000' ,
                                              '101.60050.001' ,
                                              '101.60050.100' ,
                                              '101.60055.000' ,
                                              '101.60055.001' ,
                                              '101.60095.000' ,
                                              '101.60095.001' ,
                                              '101.60095.002' )
                ) [t]
                Left Join [SysproCompany40].[dbo].[GenMaster] [GM]
                    On [t].[RevGLCode] = [GM].[GlCode]
        Order By [t].[RevGLCode]
              , [t].[GlYear]
              , [t].[GlPeriod];

        Drop Table [#Movements];

    End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'PBL Revenue and Cost of Sales', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_GLMovementsPBLRevCos', NULL, NULL
GO
