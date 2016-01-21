SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_GL_Budgets]
As
    Begin
                Select  Gb.Company
                      , Gb.GlCode
                      , Budget
					  , BudgetType
					  , Period = Replace(Period,'Budget','')
                FROM SysproCompany40.dbo.GenBudgets Unpivot (Budget For Period In (Budget1	
					  , Budget2	
					  , Budget3	
					  , Budget4	
					  , Budget5	
					  , Budget6	
					  , Budget7	
					  , Budget8	
					  , Budget9	
					  , Budget10	
					  , Budget11	
					  , Budget12)) As Gb
				Where BudgetType='C'

    End
GO
