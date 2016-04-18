SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_GLMovementsPBLRevCos]
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
            @StoredProcName = 'UspResults_GLMovementsIntercoPL' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#Movements]
            (
              [Company] Varchar(10)
            , [ShortName] Varchar(250)
            , [CompanyName] Varchar(250)
            , [Currency] Varchar(10)
            , [GlCode] Varchar(35)
            , [Description] Varchar(50)
            , [GlGroup] Varchar(10)
            , [Movement] Numeric(20 , 2)
            , [GlPeriod] Int
            , [GlYear] Int
            , [Source] Varchar(100)
            , [Journal] Int
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
                )
                Exec [Report].[UspResults_GLMovements] @RedTagType = @RedTagType , -- char(1)
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
                  Where     [M].[GlGroup] = 'RESINREV' And ParseName([M].[GlCode],1)='000'
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
                          , [RevGLCode] = '101.5' + Right(ParseName([M].[GlCode] ,
                                                              2) , 4) + '.000'
                  From      [#Movements] [M]
                  Where     [M].[GlGroup] = 'RESINCOS' And ParseName([M].[GlCode],1) In ('000','001')
                ) [t]
				Order By [t].[RevGLCode], [t].[GlYear], [t].[GlPeriod];

DROP TABLE [#Movements]

    End;
GO
