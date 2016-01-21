SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE --drop
--exec
Proc [Process].[UspLoad_LoadController]
(@HoursBetweenEachRun INT)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to execute all update stored procs				///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			10/9/2015	Chris Johnson			Initial version created																///
///			14/9/2015	Chris Johnson			Added variable to allow changes to when data is filled in							///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
Set NoCount on 
--find all procedures that need to be updated
	Create --drop --alter 
	TABLE #ProcsToRun
	( PID INT Identity (1,1)
		,SchemaName VARCHAR(150)
		,ProcName VARCHAR(150)
	)

	Insert #ProcsToRun
			(SchemaName, ProcName )
	Select s.name
	,p.name
	FROM sys.procedures p
	Left Join sys.schemas s On s.schema_id = p.schema_id
	Where s.name = 'Process'
	And p.name Like 'UspUpdate%'

	Declare @MaxProcs INT, @CurrentProc INT =1

	Select @MaxProcs=MAX(PID)
	From #ProcsToRun

	Declare @SQL VARCHAR(Max), @SchemaName VARCHAR(150), @ProcName VARCHAR(150)

	--run through each procedure, not caring if the count changes and only updating if there have been more than 23 hours since the last run
	While @CurrentProc<=@MaxProcs
	Begin
			SELECT @SchemaName = SchemaName
				,@ProcName=ProcName
			 FROM #ProcsToRun
			Where PID=@CurrentProc

			Select @SQL = @SchemaName+'.'+@ProcName+' @PrevCheck = 0,@HoursBetweenUpdates = '+CAST(@HoursBetweenEachRun As VARCHAR(5))
			--Print @SQL
			Exec (@SQL)
		Set @CurrentProc=@CurrentProc+1
	End
end
GO
