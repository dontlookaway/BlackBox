SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Review].[UspResults_CurrencyRatesMissing]
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
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_CurrencyRatesMissing' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Set NoCount Off;
        If Not Exists ( Select  1
                        From    [Lookups].[CurrencyRates] [CR]
                        Where   GetDate() Between [CR].[StartDateTime]
                                          And     [CR].[EndDateTime] )
            Begin
                Select  [CurrencyStatus] = 'No current exchange rates';
            End;

    End;
GO
