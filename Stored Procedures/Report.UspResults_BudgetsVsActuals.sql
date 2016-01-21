SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_BudgetsVsActuals]
As 
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Function designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure to return details from General Ledger in Company 40 regarding budget and actual figures					///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			14/9/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/


    Set NoCount On;

--unpivot budget data 	
    Create Table #UnpivotBudget
        (
          [Company] VARCHAR(10) Collate Latin1_General_BIN
        , [GlCode] VARCHAR(100) Collate Latin1_General_BIN
        , [BudgetPeriod] INT
        , [Budget] NUMERIC
        , [YearBudget] NUMERIC
        );

    Insert  #UnpivotBudget
            ( Company
            , GlCode
            , BudgetPeriod
            , Budget
            , YearBudget
            )
            Select Distinct
                [ASMT].[Company]
              , [ASMT].[GlCode]
              , [BudgetPeriod] = CAST(REPLACE(ASMT.BudgetPeriod, 'Budget', '') As INT)
              , [ASMT].[Budget]
              , [YearBudget] = GB.Budget1 + GB.Budget2 + GB.Budget3
                + GB.Budget4 + GB.Budget5 + GB.Budget6 + GB.Budget7
                + GB.Budget8 + GB.Budget9 + GB.Budget10 + GB.Budget11
                + GB.Budget12
            From
                SysproCompany40.dbo.GenBudgets Unpivot ( Budget For BudgetPeriod In ( Budget1,
                                                              Budget2, Budget3,
                                                              Budget4, Budget5,
                                                              Budget6, Budget7,
                                                              Budget8, Budget9,
                                                              Budget10,
                                                              Budget11,
                                                              Budget12
                                                              ) ) As ASMT
            Left Join SysproCompany40.dbo.GenBudgets GB
                On GB.Company = ASMT.Company
                   And GB.BudgetNumber = ASMT.BudgetNumber
                   And GB.GlCode = ASMT.GlCode
            Where
                [ASMT].[BudgetType] = 'C';--Current budget only




--create list of actuals
    Create --drop --alter 
Table #Actuals
        (
          Company VARCHAR(10)
        , GlCode VARCHAR(50)
        , [GlCodeStart] VARCHAR(10)
        , [GlCodeMiddle] VARCHAR(10)
        , [GlCodeEnd] VARCHAR(10)
        , GlYear INT
        , Period1 FLOAT
        , Period2 FLOAT
        , Period3 FLOAT
        , Period4 FLOAT
        , Period5 FLOAT
        , Period6 FLOAT
        , Period7 FLOAT
        , Period8 FLOAT
        , Period9 FLOAT
        , Period10 FLOAT
        , Period11 FLOAT
        , Period12 FLOAT
        --, Period13 FLOAT
        , BeginYearBalance FLOAT
        , [YearMovement] FLOAT
        );

    Insert  #Actuals
            ( Company
            , GlCode
            , GlCodeStart
            , GlCodeMiddle
            , GlCodeEnd
            , GlYear
            , Period1
            , Period2
            , Period3
            , Period4
            , Period5
            , Period6
            , Period7
            , Period8
            , Period9
            , Period10
            , Period11
            , Period12
            , BeginYearBalance
            , YearMovement
            )
            Select
                GH.Company
              , GH.GlCode
              , [GlCodeStart] = PARSENAME(GlCode, 3)
              , [GlCodeMiddle] = PARSENAME(GlCode, 2)
              , [GlCodeEnd] = PARSENAME(GlCode, 1)
              , GH.GlYear
              , Period1 = GH.ClosingBalPer1 - GH.BeginYearBalance
              , Period2 = GH.ClosingBalPer2 - GH.ClosingBalPer1
              , Period3 = GH.ClosingBalPer3 - GH.ClosingBalPer2
              , Period4 = GH.ClosingBalPer4 - GH.ClosingBalPer3
              , Period5 = GH.ClosingBalPer5 - GH.ClosingBalPer4
              , Period6 = GH.ClosingBalPer6 - GH.ClosingBalPer5
              , Period7 = GH.ClosingBalPer7 - GH.ClosingBalPer6
              , Period8 = GH.ClosingBalPer8 - GH.ClosingBalPer7
              , Period9 = GH.ClosingBalPer9 - GH.ClosingBalPer8
              , Period10 = GH.ClosingBalPer10 - GH.ClosingBalPer9
              , Period11 = GH.ClosingBalPer11 - GH.ClosingBalPer10
              , Period12 = GH.ClosingBalPer12 - GH.ClosingBalPer11
              , GH.BeginYearBalance
              , [YearMovement] = ClosingBalPer13 - BeginYearBalance
            From
                SysproCompany40.dbo.GenHistory GH; 


--Generate Monthly Actual Amounts by unpivoting data
    Create Table #MonthlyAmounts
        (
          [Company] VARCHAR(10) Collate Latin1_General_BIN
        , [GlCode] VARCHAR(100) Collate Latin1_General_BIN
        , [GlCodeStart] VARCHAR(10) Collate Latin1_General_BIN
        , [GlCodeMiddle] VARCHAR(100) Collate Latin1_General_BIN
        , [GlCodeEnd] VARCHAR(10) Collate Latin1_General_BIN
        , [GlDeptCode] As LEFT(GlCodeEnd, 1) Collate Latin1_General_BIN--VARCHAR(10) Collate Latin1_General_BIN
        , GlYear INT
        , Period As CAST(REPLACE(BudgetPeriod, 'Period', '') As INT)
		, BudgetPeriod varchar(15)
        , [Movement] FLOAT
        , [YearMovement] FLOAT
        );

    Insert  #MonthlyAmounts
            ( Company
            , GlCode
            , GlCodeStart
            , GlCodeMiddle
            , GlCodeEnd
            --, GlDeptCode
            , GlYear
            , BudgetPeriod
            , Movement
            , YearMovement
            )
            Select
                Company
              , GlCode
              , GlCodeStart
              , GlCodeMiddle
              , GlCodeEnd
              --, [GlDeptCode] = LEFT(GlCodeEnd, 1)
              , GlYear
              , BudgetPeriod
              , Movement = Actual
              , YearMovement
            From
                #Actuals Unpivot ( Actual For BudgetPeriod In ( Period1,
                                                              Period2, Period3,
                                                              Period4, Period5,
                                                              Period6, Period7,
                                                              Period8, Period9,
                                                              Period10,
                                                              Period11,
                                                              Period12
                                                              ) ) As ASMT
															  OPTION (RECOMPILE) ;

--define result set
    Create --drop
Table #Results
        (
          Company VARCHAR(10)
        , GlCode VARCHAR(100)
        , GlYear VARCHAR(10)
        , Period INT
        , Budget FLOAT
        , YTDBudget FLOAT
        , YearBudget FLOAT
        , Movement FLOAT
        , YTDMovement FLOAT
        , YearMovement FLOAT
        , ReportIndex2 VARCHAR(500)
        , Description VARCHAR(150)
        , Department VARCHAR(150)
        , DepartmentDescription VARCHAR(150)
        , [PreviousYear] VARCHAR(20)
        , ReportYear INT
        , GlCodeStart VARCHAR(25)
        , GlCodeMiddle VARCHAR(25)
        , GlCodeEnd VARCHAR(25)
        );

    Insert  #Results
            ( Company
            , GlCode
            , GlYear
            , Period
            , Budget
            , YTDBudget
            , YearBudget
            , Movement
            , YTDMovement
            , YearMovement
            , ReportIndex2
            , Description
            , Department
            , DepartmentDescription
            , PreviousYear
            , ReportYear
            , GlCodeStart
            , GlCodeMiddle
            , GlCodeEnd
            )
            Select
                M.Company
              , M.GlCode
              , M.GlYear
              , Period = COALESCE(B.BudgetPeriod, M.Period)
              , Budget = COALESCE(B.Budget, 0)
              , YTDBudget = COALESCE(B.Budget, 0)
              , YearBudget = COALESCE(B.YearBudget, 0)
              , M.Movement
              , YTDMovement = M.Movement
              , M.YearMovement
              , G.ReportIndex2
              , G.Description
              , Department = SUBSTRING(M.GlCode, 11, 1)
              , DepartmentDescription = COALESCE(D.DepartmentName, '')
              , [PreviousYear] = '???'
              , M.GlYear As ReportYear
              , CAST(GlCodeStart As INT)
              , CAST(GlCodeMiddle As INT)
              , CAST(GlCodeEnd As INT)
            From
                #UnpivotBudget As B
            Right Join #MonthlyAmounts As M
                On B.Company = M.Company
                   And B.GlCode = M.GlCode
                   And B.BudgetPeriod = M.Period
            Inner Join SysproCompany40.dbo.GenMaster As G
                On G.Company = M.Company
                   And G.GlCode = M.GlCode
            Left Outer Join BlackBox.Lookups.LedgerDepts D
                On M.Company = D.Company
                   And M.[GlDeptCode] = D.Department
            Where
                ISNUMERIC(GlCodeEnd) = 1;
        

--Return result set
    Select
        Company
      , GlCode
      , GlYear
      , Period
      , Budget
      , YTDBudget
      , YearBudget
      , Movement
      , YTDMovement
      , YearMovement
      , ReportIndex2
      , Description
      , Department
      , DepartmentDescription
      --, PreviousYear
      , ReportYear
      , GlCodeStart
      , GlCodeMiddle
      , GlCodeEnd
    From
        #Results;

GO
