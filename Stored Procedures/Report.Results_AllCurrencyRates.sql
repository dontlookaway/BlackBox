SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[Results_AllCurrencyRates]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016

query on currency (required to capture tags)
*/
--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'Results_AllCurrencyRates' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Select  [CR].[StartDateTime]
              , [CR].[EndDateTime]
              , [CR].[Currency]
              , [CR].[CADDivision]
              , [CR].[CHFDivision]
              , [CR].[EURDivision]
              , [CR].[GBPDivision]
              , [CR].[JPYDivision]
              , [CR].[USDDivision]
              , [CR].[CADMultiply]
              , [CR].[CHFMultiply]
              , [CR].[EURMultiply]
              , [CR].[GBPMultiply]
              , [CR].[JPYMultiply]
              , [CR].[USDMultiply]
              , [CR].[LastUpdated]
        From    [Lookups].[CurrencyRates] As [CR];
    End;
GO
