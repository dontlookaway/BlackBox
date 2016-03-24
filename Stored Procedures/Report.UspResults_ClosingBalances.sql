SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_ClosingBalances]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016
*/

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ClosingBalances' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Create Table [#UnpivotAmounts]
            (
              [Company] Varchar(10)
            , [GlCode] Varchar(35)
            , [GlYear] Int
            , [Period] Int
            , [StartYearDateForExRates] DateTime2
            , [ClosingBalance] Numeric(20 , 2)
            , [MonthOffset] As Case When [Period] >= 12 Then 12
                                    Else [Period]
                               End--Period 13,14,15 should be the same as 12
            , [DateForExRates] As Case When DateAdd(Month ,
                                                    ( Case When [Period] >= 12
                                                           Then 12
                                                           Else [Period]
                                                      End ) ,
                                                    [StartYearDateForExRates]) > GetDate()
                                       Then GetDate()
                                       Else DateAdd(Month ,
                                                    ( Case When [Period] >= 12
                                                           Then 12
                                                           Else [Period]
                                                      End ) ,
                                                    [StartYearDateForExRates])
                                  End
            );

        Insert  [#UnpivotAmounts]
                ( [Company]
                , [GlCode]
                , [GlYear]
                , [Period]
                , [StartYearDateForExRates]
                , [ClosingBalance]
                )
                Select  [Company]
                      , [GlCode]
                      , [GlYear]
                      , [Period] = Convert(Int , Replace([Period] ,
                                                         'ClosingBalPer' , ''))
                      , [StartYearDateForExRates] = DateFromParts(Cast([GlYear] As Int) ,
                                                              1 , 20)
                      , [ClosingBalance]
                From    [SysproCompany40].[dbo].[GenHistory] Unpivot
( [ClosingBalance] For [Period] In ( [ClosingBalPer1] , [ClosingBalPer2] ,
                                     [ClosingBalPer3] , [ClosingBalPer4] ,
                                     [ClosingBalPer5] , [ClosingBalPer6] ,
                                     [ClosingBalPer7] , [ClosingBalPer8] ,
                                     [ClosingBalPer9] , [ClosingBalPer10] ,
                                     [ClosingBalPer11] , [ClosingBalPer12] ,
                                     [ClosingBalPer13] , [ClosingBalPer14] ,
                                     [ClosingBalPer15] ) )As [CBP]
                Where   [GlCode] Not In ( 'FORCED' , 'RETAINED' );

        Select  [UA].[Company]
              , [CN].[CompanyName]
              , [DueTo] = [CN2].[CompanyName]
              , [GM].[GlGroup]
              , [UA].[GlCode]
              , [GlDescription] = [GM].[Description]
              , [UA].[GlYear]
              , [UA].[Period]
              , [UA].[ClosingBalance]
              , [UA].[DateForExRates]
              , [LocalCurrency] = [CN].[Currency]
              , [MultiplyRateCAD] = Convert(Numeric(16 , 4) , [CR].[CADMultiply])
              , [RateEffectiveFrom] = [CR].[StartDateTime]
              , [CADClosingBalance] = [UA].[ClosingBalance]
                * Convert(Numeric(16 , 4) , [CR].[CADMultiply])
              , [RateNotes] = 'Date for ex rates is the start of the year, plus the number of months for the period (for example period 1, will use the date of the 20th Feb), when this date is in the future, the current date will be used in it''s place'
        From    [#UnpivotAmounts] As [UA]
                Left Join [Lookups].[CompanyNames] As [CN] On [CN].[Company] = [UA].[Company]
                Left Join [Lookups].[CurrencyRates] As [CR] On [CR].[Currency] = [CN].[Currency]
                                                              And [UA].[DateForExRates] Between [CR].[StartDateTime]
                                                              And
                                                              [CR].[EndDateTime]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [GM].[Company] = [UA].[Company]
                                                              And [GM].[GlCode] = [UA].[GlCode]
                Left Join [Lookups].[CompanyNames] As [CN2] On [CN2].[Company] = Right([UA].[GlCode] ,
                                                              2)
        Where   Upper(Left([GM].[GlGroup] , 3)) = 'ADV'
                Or Upper(Left([GM].[GlGroup] , 5)) = 'LTDUE';

        Drop Table [#UnpivotAmounts];

    End;
GO
