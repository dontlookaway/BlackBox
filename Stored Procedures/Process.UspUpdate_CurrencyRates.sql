SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Process].[UspUpdate_CurrencyRates]
--Exec [Process].[UspUpdate_CurrencyRates] @PrevCheck =0, @HoursBetweenUpdates =-1
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )

--Exec Report.UspResults_CurrencyRates
As /*
/////////////////////////////////////////////////////////////////////////////////////////////
/////	Written by Chris Johnson - Prometic Biosciences Ltd								/////
/////	Stored procedure to grab currency rates and unpivot them						/////
/////																					/////
/////																					/////
/////																					/////
/////	Date			Amended By		Description										/////
/////	14/01/2016		Chris Johnson	Original version written						/////
/////	15/01/2016		Chris Johnson	Added grab of CHF from Co. 10					/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////	##/##/####		Enter Name														/////
/////////////////////////////////////////////////////////////////////////////////////////////
*/

    Begin
        Set NoCount On;

        Declare @MaxRank Int;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'CurrencyRates' )
           )
            Begin
                Create Table [Lookups].[CurrencyRates]
                    (
                      [StartDateTime] DateTime
                    , [EndDateTime] DateTime
                    , [Currency] Varchar(10)
                    , [CADDivision] Numeric(12 , 7)
                    , [CHFDivision] Numeric(12 , 7)
                    , [EURDivision] Numeric(12 , 7)
                    , [GBPDivision] Numeric(12 , 7)
                    , [JPYDivision] Numeric(12 , 7)
                    , [USDDivision] Numeric(12 , 7)
                    , [CADMultiply] Numeric(12 , 7)
                    , [CHFMultiply] Numeric(12 , 7)
                    , [EURMultiply] Numeric(12 , 7)
                    , [GBPMultiply] Numeric(12 , 7)
                    , [JPYMultiply] Numeric(12 , 7)
                    , [USDMultiply] Numeric(12 , 7)
                    , [LastUpdated] DateTime2
                    );
            End;

--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([CR].[LastUpdated])
        From    [Lookups].[CurrencyRates] As [CR];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

--Create table to capture currencies
                Create Table [#MasterCurrencyTable]
                    (
                      [JnlDate] Date
                    , [StartDateTime] DateTime
                    , [EndDateTime] DateTime
                    , [USD] Float
                    , [JPY] Float
                    , [EUR] Float
                    , [GBP] Float
                    , [CAD] Float
                    , [CHF] Float
                    , [JnlRank] Int
                    );


--Grab 
                Insert  [#MasterCurrencyTable]
                        ( [JnlDate]
                        , [StartDateTime]
                        , [EndDateTime]
                        , [USD]
                        , [JPY]
                        , [EUR]
                        , [GBP]
                        , [CAD]
                        --, [JnlRank]
                        )
                        Select  [JnlDate]
                              , [StartDateTime] = [JnlDateTime]
                              , [EndDateTime] = Null
                              , [USD]
                              , [JPY]
                              , [EUR]
                              , [GBP]
                              , [CAD] = 1.000000
                              --, Rank() Over ( Order By [JnlDateTime] Asc )
                        From    ( Select    [TCAJ].[JnlDate]
                                          , [JnlDateTime] = DateAdd(Hour ,
                                                              Cast(Left([TCAJ].[JnlTime] ,
                                                              2) As Int) ,
                                                              [TCAJ].[JnlDate])
                                          , [TCAJ].[Currency]
                                          , [TCAJ].[ColumnName]
		--,[TCAJ].[Before]
                                          , [ExchangeRate] = Cast([TCAJ].[After] As Float)
                                  From      [SysproCompany40].[dbo].[TblCurAmendmentJnl]
                                            As [TCAJ]
                                  Where     [TCAJ].[ColumnName] = 'BuyExchangeRate'
                                ) [t] Pivot ( Max([ExchangeRate]) For [Currency] In ( [USD] ,
                                                              [JPY] , [EUR] ,
                                                              [GBP] ) ) [t];

		--Get Swiss francs from co. 10
                Insert  [#MasterCurrencyTable]
                        ( [JnlDate]
                        , [StartDateTime]
                        , [EndDateTime]
                        , [USD]
                        , [JPY]
                        , [EUR]
                        , [GBP]
                        , [CAD]
                        , [CHF]
			        --, [JnlRank]
			            )
                        Select  [JnlDateTime]
                              , [StartDateTime] = [JnlDateTime]
                              , [EndDateTime] = Null
                              , [USD] = [CAD] / [USD]
                              , [JPY] = [CAD] / [JPY]
                              , [EUR] = [CAD] / [EUR]
                              , [GBP] = [CAD]
                              , [CAD] = [CAD] / [CAD]
                              , [CHF] = [CAD] / [CHF]
                          --, Rank() Over ( Order By [JnlDateTime] Asc )
                        From    ( Select    [JnlDateTime] = [TCAJ].[JnlDate]
                                          , [TCAJ].[Currency]
                                          , [TCAJ].[ColumnName]
                                          , [ExchangeRate] = Cast([TCAJ].[After] As Float)
                                  From      [SysproCompany10].[dbo].[TblCurAmendmentJnl]
                                            As [TCAJ]
                                  Where     [TCAJ].[ColumnName] = 'BuyExchangeRate'
                                ) [t] Pivot ( Max([ExchangeRate]) For [Currency] In ( [USD] ,
                                                              [JPY] , [EUR] ,
                                                              [GBP] , [CHF] ,
                                                              [CAD] ) ) [t]
                        Where   [CHF] Is Not Null
                                And [CAD] / [CAD] Is Not Null
                        Order By [t].[JnlDateTime] Asc;

--Add rank
                Update  [#MasterCurrencyTable]
                Set     [JnlRank] = [MCTb].[Ranking]
                From    [#MasterCurrencyTable] As [MCT]
                        Inner Join ( Select [MCTa].[StartDateTime]
                                          , [Ranking] = Rank() Over ( Order By [MCTa].[StartDateTime] )
                                     From   [#MasterCurrencyTable] As [MCTa]
                                   ) As [MCTb] On [MCTb].[StartDateTime] = [MCT].[StartDateTime];

 --Set End Dates
                Update  [MCT]
                Set     [MCT].[EndDateTime] = DateAdd(Second , -1 ,
                                                      [MCT2].[StartDateTime])
                From    [#MasterCurrencyTable] As [MCT]
                        Left Join [#MasterCurrencyTable] As [MCT2] On [MCT2].[JnlRank] = [MCT].[JnlRank]
                                                              + 1;

 --Back fill null currencies by grabbing the next available rate
                Update  [#MasterCurrencyTable]
                Set     [JPY] = ( Select Top 1
                                            [MCT2].[JPY]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] > [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[JPY] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[JPY] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [USD] = ( Select Top 1
                                            [MCT2].[USD]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] > [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[USD] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[USD] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [EUR] = ( Select Top 1
                                            [MCT2].[EUR]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] > [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[EUR] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[EUR] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [GBP] = ( Select Top 1
                                            [MCT2].[GBP]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] > [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[GBP] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[GBP] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [CHF] = ( Select Top 1
                                            [MCT2].[CHF]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] > [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[CHF] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[CHF] Is Null;
--forward fill null currency by grabbing the last available rate
                Update  [#MasterCurrencyTable]
                Set     [JPY] = ( Select Top 1
                                            [MCT2].[JPY]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] < [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[JPY] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[JPY] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [USD] = ( Select Top 1
                                            [MCT2].[USD]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] < [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[USD] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[USD] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [EUR] = ( Select Top 1
                                            [MCT2].[EUR]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] < [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[EUR] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[EUR] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [GBP] = ( Select Top 1
                                            [MCT2].[GBP]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] < [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[GBP] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[GBP] Is Null;
                Update  [#MasterCurrencyTable]
                Set     [CHF] = ( Select Top 1
                                            [MCT2].[CHF]
                                  From      [#MasterCurrencyTable] As [MCT2]
                                  Where     [MCT2].[StartDateTime] < [#MasterCurrencyTable].[StartDateTime]
                                            And [MCT2].[CHF] Is Not Null
                                  Order By  [MCT2].[StartDateTime] Asc
                                )
                Where   [#MasterCurrencyTable].[CHF] Is Null;


--get the latest rank to determine which row doesn't have an end date
                Select  @MaxRank = Max([MCT].[JnlRank])
                From    [#MasterCurrencyTable] As [MCT];

--For the latest row, set the end date to tomorrow
                Update  [#MasterCurrencyTable]
                Set     [EndDateTime] = GetDate() + 1
                Where   [JnlRank] = @MaxRank
                        And [EndDateTime] Is Null;

                Insert  [Lookups].[CurrencyRates]
                        ( [StartDateTime]
                        , [EndDateTime]
                        , [Currency]
                        , [CADDivision]
                        , [EURDivision]
                        , [GBPDivision]
                        , [JPYDivision]
                        , [USDDivision]
                        , [CHFDivision]
                        , [CADMultiply]
                        , [EURMultiply]
                        , [GBPMultiply]
                        , [JPYMultiply]
                        , [USDMultiply]
                        , [CHFMultiply]
                        , [LastUpdated]
                        )
                        Select  [t].[StartDateTime]
                              , [t].[EndDateTime]
                              , [t].[Currency]
                              , [CADDivision] = [t].[CAD]
                              , [EURDivision] = [t].[EUR]
                              , [GBPDivision] = [t].[GBP]
                              , [JPYDivision] = [t].[JPY]
                              , [USDDivision] = [t].[USD]
                              , [CHFDivision] = [t].[CHF]
                              , [CADMultiply] = 1 / [t].[CAD]
                              , [EURMultiply] = 1 / [t].[EUR]
                              , [GBPMultiply] = 1 / [t].[GBP]
                              , [JPYMultiply] = 1 / [t].[JPY]
                              , [USDMultiply] = 1 / [t].[USD]
                              , [CHFMultiply] = 1 / [t].[CHF]
                              , @LastUpdated
                        From    ( Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'CAD'
                                          , [MCT].[USD]
                                          , [MCT].[JPY]
                                          , [MCT].[EUR]
                                          , [MCT].[GBP]
                                          , [MCT].[CAD]
                                          , [MCT].[CHF]
                                  From      [#MasterCurrencyTable] As [MCT]
                                  Union All
                                  Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'USD'
                                          , [MCT].[USD] / [MCT].[USD]
                                          , [MCT].[JPY] / [MCT].[USD]
                                          , [MCT].[EUR] / [MCT].[USD]
                                          , [MCT].[GBP] / [MCT].[USD]
                                          , [MCT].[CAD] / [MCT].[USD]
                                          , [MCT].[CHF] / [MCT].[USD]
                                  From      [#MasterCurrencyTable] As [MCT]
                                  Union All
                                  Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'JPY'
                                          , [MCT].[USD] / [MCT].[JPY]
                                          , [MCT].[JPY] / [MCT].[JPY]
                                          , [MCT].[EUR] / [MCT].[JPY]
                                          , [MCT].[GBP] / [MCT].[JPY]
                                          , [MCT].[CAD] / [MCT].[JPY]
                                          , [MCT].[CHF] / [MCT].[JPY]
                                  From      [#MasterCurrencyTable] As [MCT]
                                  Union All
                                  Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'EUR'
                                          , [MCT].[USD] / [MCT].[EUR]
                                          , [MCT].[JPY] / [MCT].[EUR]
                                          , [MCT].[EUR] / [MCT].[EUR]
                                          , [MCT].[GBP] / [MCT].[EUR]
                                          , [MCT].[CAD] / [MCT].[EUR]
                                          , [MCT].[CHF] / [MCT].[EUR]
                                  From      [#MasterCurrencyTable] As [MCT]
                                  Union All
                                  Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'GBP'
                                          , [MCT].[USD] / [MCT].[GBP]
                                          , [MCT].[JPY] / [MCT].[GBP]
                                          , [MCT].[EUR] / [MCT].[GBP]
                                          , [MCT].[GBP] / [MCT].[GBP]
                                          , [MCT].[CAD] / [MCT].[GBP]
                                          , [MCT].[CHF] / [MCT].[GBP]
                                  From      [#MasterCurrencyTable] As [MCT]
                                  Union All
                                  Select    [MCT].[JnlDate]
                                          , [MCT].[StartDateTime]
                                          , [MCT].[EndDateTime]
                                          , [Currency] = 'CHF'
                                          , [MCT].[USD] / [MCT].[CHF]
                                          , [MCT].[JPY] / [MCT].[CHF]
                                          , [MCT].[EUR] / [MCT].[CHF]
                                          , [MCT].[GBP] / [MCT].[CHF]
                                          , [MCT].[CAD] / [MCT].[CHF]
                                          , [MCT].[CHF] / [MCT].[CHF]
                                  From      [#MasterCurrencyTable] As [MCT]
                                ) [t]
                        Order By [t].[JnlDate] Asc
                              , [t].[StartDateTime] Asc
                              , [t].[Currency] Asc;

                Drop Table [#MasterCurrencyTable];
                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[CurrencyRates]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[CurrencyRates]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[CurrencyRates]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_CurrencyRates - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[CurrencyRates]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_CurrencyRates - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[CurrencyRates]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_CurrencyRates - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_CurrencyRates - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
