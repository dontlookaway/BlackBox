SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GLMovementsCenter]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    , @GLStart Int
    , @GLEnd Int
    )
As
    Begin
/*Current Assets*/
        Select  @GLStart = Coalesce(@GLStart , 0);
        Select  @GLEnd = Coalesce(@GLEnd , 0);

        Set NoCount On;

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
            );
        Create Table [#MovementsRaw]
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
								  , [Source]='History'
                          From      [SysproCompany40]..[GenMaster] As [GM]
                                    Left Join [BlackBox].[Lookups].[CompanyNames]
                                        As [CN]
                                        On [CN].[Company] = [GM].[Company]
                                    Left Join [SysproCompany40].[dbo].[GenHistory] [GH]
                                        On [GH].[Company] = [GM].[Company]
                                           And [GH].[GlCode] = [GM].[GlCode]
                          Where     [GH].[GlYear] >= 2013
                                    And Convert(Int , ParseName([GM].[GlCode] ,
                                                              2)) Between @GLStart
                                                              And
                                                              @GLEnd
                          Union
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
								  , [Source]='Transactions'
                          From      [SysproCompany40]..[GenMaster] As [GM]
                                    Left Join [SysproCompany40].[dbo].[GenTransaction] [GT]
                                        On [GT].[Company] = [GM].[Company]
                                           And [GT].[GlCode] = [GM].[GlCode]
                                    Left Join [BlackBox].[Lookups].[CompanyNames]
                                        As [CN]
                                        On [CN].[Company] = [GM].[Company]
                          Where     Convert(Int , ParseName([GM].[GlCode] , 2)) Between @GLStart
                                                              And
                                                              @GLEnd
	And [GT].[EntryValue]>0
                        ) [t]
                Order By [t].[Company]
                      , [t].[GlCode]
                      , [t].[GlYear]
                      , [t].[GlPeriod];

        /*Insert  [#Movements]
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
					  , Source = 'Generated'
                From    [SysproCompany40]..[GenMaster] [GM]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                            On [CN].[Company] = [GM].[Company]
                        Cross Join [#YearPeriod] [YP]
                Where   Convert(Int , ParseName([GM].[GlCode] , 2)) Between @GLStart
                                                              And
                                                              @GLEnd
                        And [GM].[GlCode]
                        + Convert(Varchar(10) , [YP].[GlYear])
                        + Convert(Varchar(10) , [YP].[GlPeriod]) Not In (
                        Select  [M].[GlCode]
                                + Convert(Varchar(10) , [M].[GlYear])
                                + Convert(Varchar(10) , [M].[GlPeriod])
                        From    [#Movements] [M] );*/

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
                From    [SysproCompany40]..[GenMaster] [GM]
                        Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                            On [CN].[Company] = [GM].[Company]
                        Cross Join [#YearPeriod] [YP]
                Where   Convert(Int , ParseName([GM].[GlCode] , 2)) Between @GLStart
                                                              And
                                                              @GLEnd;

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
					  , [Source]='Generated'
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
