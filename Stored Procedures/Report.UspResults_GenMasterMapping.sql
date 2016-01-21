SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GenMasterMapping]
(@Company VARCHAR(Max))
--Exec [Report].[UspResults_GenMasterMapping] @Company='10'
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			14/10/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
Set NoCount On

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #GenMaster
	(	[Company] VARCHAR(150) Collate Latin1_General_BIN
	    ,[GlCode] VARCHAR(150) Collate Latin1_General_BIN
		,[Description] VARCHAR(255) Collate Latin1_General_BIN
	)
	Print 1
	Insert [#GenMaster]
	        ( [Company]
	        , [GlCode]
	        , [Description]
	        )
	SELECT   [gm].[Company]
			,[gm].[GlCode]
			,[gm].[Description]
	 FROM [SysproCompany40]..[GenMaster] As [gm]
	 Where  [gm].[Company]=@Company
		And [gm].[GlCode] Not In ('FORCED','RETAINED')



--define the results you want to return
	Create Table #Results
	(  [GlCode]				VARCHAR(150)
     , [Company]			VARCHAR(150)
     , [GlStart]			VARCHAR(3)
     , [GlMid]				VARCHAR(5)
     , [Mid1]				VARCHAR(3)
     , [Mid2]				VARCHAR(2)
     , [GlEnd]				VARCHAR(3)
     , [MappingDescription] VARCHAR(255)
     , [LedgerDescription]	VARCHAR(255)
     , [Mapping1]			VARCHAR(255)
     , [Mapping2]			VARCHAR(255)
     , [Mapping3]			VARCHAR(255)
     , [Mapping4]			VARCHAR(255)
     , [Mapping5]			VARCHAR(255)
     , [Status]				VARCHAR(255))

	 Print 2
--script to combine base data and insert into results table
	Insert #Results
	        (  [GlCode]
			 , [Company]
			 , [GlStart]
			 , [GlMid]
			 , [Mid1]
			 , [Mid2]
			 , [GlEnd]
			 , [MappingDescription]
			 , [LedgerDescription]
			 , [Mapping1]
			 , [Mapping2]
			 , [Mapping3]
			 , [Mapping4]
			 , [Mapping5]
			 , [Status] )
	Select  
		 [GlCode]				= COALESCE([gm].[GlCode]	,[gm2].[GlCode])
	   , [Company]				= COALESCE(gm.[Company]		,[gm2].[Company])
       , [GlStart]				= coalesce([gm2].[GlStart]	,PARSENAME([gm].[GlCode],3))
       , [GlMid]				= coalesce([gm2].[GlMid]	,PARSENAME([gm].[GlCode],2))
       , [Mid1]					= coalesce([gm2].[Mid1]		,LEFT((PARSENAME([gm].[GlCode],2)),3))
       , [Mid2]					= coalesce([gm2].[Mid2]		,Right((PARSENAME([gm].[GlCode],2)),2))
       , [GlEnd]				= coalesce([gm2].[GlEnd]	,PARSENAME([gm].[GlCode],1))
       , [MappingDescription]	= [gm2].[GlDescription]
	   , [LedgerDescription]	= [gm] .[Description]
       , [Mapping1]				= [gm2].[Mapping1]
       , [Mapping2]				= [gm2].[Mapping2]
       , [Mapping3]				= [gm2].[Mapping3]
       , [Mapping4]				= [gm2].[Mapping4]
       , [Mapping5]				= [gm2].[Mapping5] 
	   , [Status]				= Case	When [gm] .[GlCode] Is     Null Then 'Map does not have value in General Ledger' Collate Latin1_General_BIN
										When [gm2].[GlCode] Is     Null Then 'Ledger code does not have a map' Collate Latin1_General_BIN
										When [gm2].[GlDescription] <>[gm] .[Description] Then 'Map description does not match GL description' Collate Latin1_General_BIN
										When [gm] .[GlCode] Is Not Null 
										And  [gm2].[GlCode] Is Not Null	Then 'Map Available' Collate Latin1_General_BIN
								  End
From [#GenMaster] As [gm]
		Full Outer Join [Lookups].[GLMapping] As [gm2] 
						On  [gm2].[Company] = [gm].[Company] 
						And [gm2].[GlCode]  = [gm].[GlCode]

--return results
	SELECT [GlCode]
         , [Company]
         , [GlStart]
         , [GlMid]
         , [Mid1]
         , [Mid2]
         , [GlEnd]
         , [MappingDescription]
         , [LedgerDescription]
         , [Mapping1]
         , [Mapping2]
         , [Mapping3]
         , [Mapping4]
         , [Mapping5]
         , [Status] 
	From #Results

End

GO
