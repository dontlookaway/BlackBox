SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GL_Actuals]
As
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			This returns the difference between the start and end of each month as it is captured in the Gen Ledger history table	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			7/9/2015	Chris Johnson			Initial version created																///
///			7/9/2015	Chris Johnson			Changed to use of udf_SplitString to define tables to return						///
///			4/1/2016	Chris Johnson			Added Movement to date for use in trial balance										///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

    Begin
        Select  Company
              , GlCode
              , Period = Cast(Replace(Period , 'Period' , '') As Int)
              , Actual
              , YearMovement
              , GlYear
			  , ClosingBalance
			  , MovementToDate
        From    ( Select    GH.Company
                          , GH.GlCode
                          , GH.GlYear
                          , Period1				= GH.ClosingBalPer1  - GH.BeginYearBalance
                          , Period2				= GH.ClosingBalPer2  - GH.ClosingBalPer1
                          , Period3				= GH.ClosingBalPer3  - GH.ClosingBalPer2
                          , Period4				= GH.ClosingBalPer4  - GH.ClosingBalPer3
                          , Period5				= GH.ClosingBalPer5  - GH.ClosingBalPer4
                          , Period6				= GH.ClosingBalPer6  - GH.ClosingBalPer5
                          , Period7				= GH.ClosingBalPer7  - GH.ClosingBalPer6
                          , Period8				= GH.ClosingBalPer8  - GH.ClosingBalPer7
                          , Period9				= GH.ClosingBalPer9  - GH.ClosingBalPer8
                          , Period10			= GH.ClosingBalPer10 - GH.ClosingBalPer9
                          , Period11			= GH.ClosingBalPer11 - GH.ClosingBalPer10
                          , Period12			= GH.ClosingBalPer12 - GH.ClosingBalPer11
                          , GH.BeginYearBalance
                          , [YearMovement]		= ClosingBalPer13    - BeginYearBalance
						  , GH.ClosingBalPer1 
						  , GH.ClosingBalPer2 
						  , GH.ClosingBalPer3 
						  , GH.ClosingBalPer4 
						  , GH.ClosingBalPer5 
						  , GH.ClosingBalPer6 
						  , GH.ClosingBalPer7 
						  , GH.ClosingBalPer8 
						  , GH.ClosingBalPer9 
						  , GH.ClosingBalPer10
						  , GH.ClosingBalPer11
						  , GH.ClosingBalPer12
                          , MovementToDate1				= GH.ClosingBalPer1  - GH.BeginYearBalance
                          , MovementToDate2				= GH.ClosingBalPer2  - GH.BeginYearBalance
                          , MovementToDate3				= GH.ClosingBalPer3  - GH.BeginYearBalance
                          , MovementToDate4				= GH.ClosingBalPer4  - GH.BeginYearBalance
                          , MovementToDate5				= GH.ClosingBalPer5  - GH.BeginYearBalance
                          , MovementToDate6				= GH.ClosingBalPer6  - GH.BeginYearBalance
                          , MovementToDate7				= GH.ClosingBalPer7  - GH.BeginYearBalance
                          , MovementToDate8				= GH.ClosingBalPer8  - GH.BeginYearBalance
                          , MovementToDate9				= GH.ClosingBalPer9  - GH.BeginYearBalance
                          , MovementToDate10			= GH.ClosingBalPer10 - GH.BeginYearBalance
                          , MovementToDate11			= GH.ClosingBalPer11 - GH.BeginYearBalance
                          , MovementToDate12			= GH.ClosingBalPer12 - GH.BeginYearBalance
                  From      SysproCompany40.dbo.GenHistory GH
                ) Actuals Unpivot ( Actual For Period In ( Period1 , Period2 ,
                                                           Period3 , Period4 ,
                                                           Period5 , Period6 ,
                                                           Period7 , Period8 ,
                                                           Period9 , Period10,
                                                           Period11, Period12 ) ) As ASMT
						Unpivot (ClosingBalance For Period2 In (ClosingBalPer1 , ClosingBalPer2 
																, ClosingBalPer3 , ClosingBalPer4 
																, ClosingBalPer5 , ClosingBalPer6 
																, ClosingBalPer7 , ClosingBalPer8 
																, ClosingBalPer9 , ClosingBalPer10
																, ClosingBalPer11, ClosingBalPer12) )As CBP
						Unpivot (MovementToDate For Period3 In (MovementToDate1, MovementToDate2	
																, MovementToDate3, MovementToDate4	
																, MovementToDate5, MovementToDate6	
																, MovementToDate7, MovementToDate8	
																, MovementToDate9, MovementToDate10
																, MovementToDate11, MovementToDate12) )As MTD
				Where Cast(Replace(Period , 'Period' , '') As Int)=Cast(Replace(Period2 , 'ClosingBalPer' , '') As Int)
				And Cast(Replace(Period , 'Period' , '') As Int)=Cast(Replace(Period3 , 'MovementToDate' , '') As Int);

--SELECT * FROM #Results As R
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of gl actual figures', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_GL_Actuals', NULL, NULL
GO
