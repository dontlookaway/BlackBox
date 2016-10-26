SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_BudgetsVsActuals]
As /*Function designed by Chris Johnson, Prometic Group September 2015										
Stored procedure to return details from General Ledger in Company 40 regarding budget and actual figures*/


    Set NoCount On;

--unpivot budget data 	
    Create Table [#UnpivotBudget]
        (
          [Company] Varchar(10) Collate Latin1_General_BIN
        , [GlCode] Varchar(100) Collate Latin1_General_BIN
        , [BudgetPeriod] Int
        , [Budget] Numeric
        , [YearBudget] Numeric
        );

    Insert  [#UnpivotBudget]
            ( [Company]
            , [GlCode]
            , [BudgetPeriod]
            , [Budget]
            , [YearBudget]
            )
            Select Distinct
                    [ASMT].[Company]
                  , [ASMT].[GlCode]
                  , [BudgetPeriod] = Cast(Replace([ASMT].[BudgetPeriod] , 'Budget' ,
                                                  '') As Int)
                  , [ASMT].[Budget]
                  , [YearBudget] = [GB].[Budget1] + [GB].[Budget2] + [GB].[Budget3]
                    + [GB].[Budget4] + [GB].[Budget5] + [GB].[Budget6] + [GB].[Budget7]
                    + [GB].[Budget8] + [GB].[Budget9] + [GB].[Budget10] + [GB].[Budget11]
                    + [GB].[Budget12]
            From    [SysproCompany40].[dbo].[GenBudgets] Unpivot ( [Budget] For [BudgetPeriod] In ( [Budget1] ,
                                                              [Budget2] ,
                                                              [Budget3] ,
                                                              [Budget4] ,
                                                              [Budget5] ,
                                                              [Budget6] ,
                                                              [Budget7] ,
                                                              [Budget8] ,
                                                              [Budget9] ,
                                                              [Budget10] ,
                                                              [Budget11] ,
                                                              [Budget12] ) ) As [ASMT]
                    Left Join [SysproCompany40].[dbo].[GenBudgets] [GB]
                        On [GB].[Company] = [ASMT].[Company]
                           And [GB].[BudgetNumber] = [ASMT].[BudgetNumber]
                           And [GB].[GlCode] = [ASMT].[GlCode]
            Where   [ASMT].[BudgetType] = 'C';--Current budget only




--create list of actuals
    Create Table [#Actuals]
        (
          [Company] Varchar(10)			collate latin1_general_bin
        , [GlCode] Varchar(50)			collate latin1_general_bin
        , [GlCodeStart] Varchar(10)		collate latin1_general_bin
        , [GlCodeMiddle] Varchar(10)	collate latin1_general_bin
        , [GlCodeEnd] Varchar(10)		collate latin1_general_bin
        , [GlYear] Int
        , [Period1] Float
        , [Period2] Float
        , [Period3] Float
        , [Period4] Float
        , [Period5] Float
        , [Period6] Float
        , [Period7] Float
        , [Period8] Float
        , [Period9] Float
        , [Period10] Float
        , [Period11] Float
        , [Period12] Float
        --, Period13 FLOAT
        , [BeginYearBalance] Float
        , [YearMovement] Float
        );

    Insert  [#Actuals]
            ( [Company]
            , [GlCode]
            , [GlCodeStart]
            , [GlCodeMiddle]
            , [GlCodeEnd]
            , [GlYear]
            , [Period1]
            , [Period2]
            , [Period3]
            , [Period4]
            , [Period5]
            , [Period6]
            , [Period7]
            , [Period8]
            , [Period9]
            , [Period10]
            , [Period11]
            , [Period12]
            , [BeginYearBalance]
            , [YearMovement]
            )
            Select  [GH].[Company]
                  , [GH].[GlCode]
                  , [GlCodeStart] = ParseName([GH].[GlCode] , 3)
                  , [GlCodeMiddle] = ParseName([GH].[GlCode] , 2)
                  , [GlCodeEnd] = ParseName([GH].[GlCode] , 1)
                  , [GH].[GlYear]
                  , [Period1] = [GH].[ClosingBalPer1] - [GH].[BeginYearBalance]
                  , [Period2] = [GH].[ClosingBalPer2] - [GH].[ClosingBalPer1]
                  , [Period3] = [GH].[ClosingBalPer3] - [GH].[ClosingBalPer2]
                  , [Period4] = [GH].[ClosingBalPer4] - [GH].[ClosingBalPer3]
                  , [Period5] = [GH].[ClosingBalPer5] - [GH].[ClosingBalPer4]
                  , [Period6] = [GH].[ClosingBalPer6] - [GH].[ClosingBalPer5]
                  , [Period7] = [GH].[ClosingBalPer7] - [GH].[ClosingBalPer6]
                  , [Period8] = [GH].[ClosingBalPer8] - [GH].[ClosingBalPer7]
                  , [Period9] = [GH].[ClosingBalPer9] - [GH].[ClosingBalPer8]
                  , [Period10] = [GH].[ClosingBalPer10] - [GH].[ClosingBalPer9]
                  , [Period11] = [GH].[ClosingBalPer11] - [GH].[ClosingBalPer10]
                  , [Period12] = [GH].[ClosingBalPer12] - [GH].[ClosingBalPer11]
                  , [GH].[BeginYearBalance]
                  , [YearMovement] = [GH].[ClosingBalPer13] - [GH].[BeginYearBalance]
            From    [SysproCompany40].[dbo].[GenHistory] [GH]; 


--Generate Monthly Actual Amounts by unpivoting data
    Create Table [#MonthlyAmounts]
        (
          [Company] Varchar(10)					Collate Latin1_General_BIN
        , [GlCode] Varchar(100)					Collate Latin1_General_BIN
        , [GlCodeStart] Varchar(10)				Collate Latin1_General_BIN
        , [GlCodeMiddle] Varchar(100)			Collate Latin1_General_BIN
        , [GlCodeEnd] Varchar(10)				Collate Latin1_General_BIN
        , [GlDeptCode] As Left([GlCodeEnd] , 1) Collate Latin1_General_BIN--VARCHAR(10) Collate Latin1_General_BIN
        , [GlYear] Int
        , [Period] As Cast(Replace([BudgetPeriod] , 'Period' , '') As Int)
        , [BudgetPeriod] Varchar(15)			collate latin1_general_bin
        , [Movement] Float
        , [YearMovement] Float
        );

    Insert  [#MonthlyAmounts]
            ( [Company]
            , [GlCode]
            , [GlCodeStart]
            , [GlCodeMiddle]
            , [GlCodeEnd]
            --, GlDeptCode
            , [GlYear]
            , [BudgetPeriod]
            , [Movement]
            , [YearMovement]
            )
            Select  [Company]
                  , [GlCode]
                  , [GlCodeStart]
                  , [GlCodeMiddle]
                  , [GlCodeEnd]
              --, [GlDeptCode] = LEFT(GlCodeEnd, 1)
                  , [GlYear]
                  , [BudgetPeriod]
                  , [Movement] = [Actual]
                  , [YearMovement]
            From    [#Actuals] Unpivot ( [Actual] For [BudgetPeriod] In ( [Period1] ,
                                                              [Period2] ,
                                                              [Period3] ,
                                                              [Period4] ,
                                                              [Period5] ,
                                                              [Period6] ,
                                                              [Period7] ,
                                                              [Period8] ,
                                                              [Period9] ,
                                                              [Period10] ,
                                                              [Period11] ,
                                                              [Period12] ) ) As [ASMT]
    Option  ( Recompile );

--define result set
    Create Table [#Results]
        (
          [Company] Varchar(10)						collate latin1_general_bin
        , [GlCode] Varchar(100)						collate latin1_general_bin
        , [GlYear] Varchar(10)						collate latin1_general_bin
        , [Period] Int								
        , [Budget] Float							
        , [YTDBudget] Float							
        , [YearBudget] Float						
        , [Movement] Float							
        , [YTDMovement] Float						
        , [YearMovement] Float						
        , [ReportIndex2] Varchar(500)				collate latin1_general_bin
        , [Description] Varchar(150)				collate latin1_general_bin
        , [Department] Varchar(150)					collate latin1_general_bin
        , [DepartmentDescription] Varchar(150)		collate latin1_general_bin
        , [PreviousYear] Varchar(20)				collate latin1_general_bin
        , [ReportYear] Int							
        , [GlCodeStart] Varchar(25)					collate latin1_general_bin
        , [GlCodeMiddle] Varchar(25)				collate latin1_general_bin
        , [GlCodeEnd] Varchar(25)					collate latin1_general_bin
        );

    Insert  [#Results]
            ( [Company]
            , [GlCode]
            , [GlYear]
            , [Period]
            , [Budget]
            , [YTDBudget]
            , [YearBudget]
            , [Movement]
            , [YTDMovement]
            , [YearMovement]
            , [ReportIndex2]
            , [Description]
            , [Department]
            , [DepartmentDescription]
            , [PreviousYear]
            , [ReportYear]
            , [GlCodeStart]
            , [GlCodeMiddle]
            , [GlCodeEnd]
            )
            Select  [M].[Company]
                  , [M].[GlCode]
                  , [M].[GlYear]
                  , [Period] = Coalesce([B].[BudgetPeriod] , [M].[Period])
                  , [Budget] = Coalesce([B].[Budget] , 0)
                  , [YTDBudget] = Coalesce([B].[Budget] , 0)
                  , [YearBudget] = Coalesce([B].[YearBudget] , 0)
                  , [M].[Movement]
                  , [YTDMovement] = [M].[Movement]
                  , [M].[YearMovement]
                  , [G].[ReportIndex2]
                  , [G].[Description]
                  , [Department] = Substring([M].[GlCode] , 11 , 1)
                  , [DepartmentDescription] = ''
                  , [PreviousYear] = '???'
                  , [M].[GlYear] As [ReportYear]
                  , Cast([M].[GlCodeStart] As Int)
                  , Cast([M].[GlCodeMiddle] As Int)
                  , Cast([M].[GlCodeEnd] As Int)
            From    [#UnpivotBudget] As [B]
                    Right Join [#MonthlyAmounts] As [M]
                        On [B].[Company] = [M].[Company]
                           And [B].[GlCode] = [M].[GlCode]
                           And [B].[BudgetPeriod] = [M].[Period]
                    Inner Join [SysproCompany40].[dbo].[GenMaster] As [G]
                        On [G].[Company] = [M].[Company]
                           And [G].[GlCode] = [M].[GlCode]
            Where   IsNumeric([M].[GlCodeEnd]) = 1;
        

--Return result set
    Select  [Company]
          , [GlCode]
          , [GlYear]
          , [Period]
          , [Budget]
          , [YTDBudget]
          , [YearBudget]
          , [Movement]
          , [YTDMovement]
          , [YearMovement]
          , [ReportIndex2]
          , [Description]
          , [Department]
          , [DepartmentDescription]
      --, PreviousYear
          , [ReportYear]
          , [GlCodeStart]
          , [GlCodeMiddle]
          , [GlCodeEnd]
    From    [#Results];

GO
EXEC sp_addextendedproperty N'MS_Description', N'budgets vs actuals from GL', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_BudgetsVsActuals', NULL, NULL
GO
