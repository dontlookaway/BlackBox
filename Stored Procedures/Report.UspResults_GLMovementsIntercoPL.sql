
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GLMovementsIntercoPL]
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
              , [DueToCo] = Right([M].[GlCode] , 2)
              , [DueToShortName] = Coalesce([CN].[ShortName] , 'Unknown')
              , [DueToCompanyName] = Coalesce([CN].[CompanyName] , 'Unknown')
              , [DateForCurrency] = Case When [M].[GlPeriod] > 12
                                         Then DateFromParts([M].[GlYear] , 11 ,
                                                            30)
                                         When [M].[GlPeriod] = 0
                                         Then DateFromParts(( [M].[GlYear] - 1 ) ,
                                                            12 , 31)
                                         Else DateAdd(Day , -1 ,
                                                      DateFromParts([M].[GlYear] ,
                                                              [M].[GlPeriod] ,
                                                              1))
                                    End
        From    [#Movements] [M]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [CN].[Company] = Right([M].[GlCode] , 2)
        Where   [M].[GlGroup] In ( 'INTERCOREV' , 'INTERCOEXP' ,
                                       'RLTYINTRCO' , 'INTINTERCO' ,
                                       'INTERCOCOS' );

    End;
GO
