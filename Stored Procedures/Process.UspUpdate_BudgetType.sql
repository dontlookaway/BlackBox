SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_BudgetType]
(@PrevCheck INT
,@HoursBetweenUpdates int)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with Budget Types			///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			16/10/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

--remove nocount on to speed up query
Set NoCount On

--check if table exists and create if it doesn't
If ( Not Exists ( Select
                    *
                  From
                    INFORMATION_SCHEMA.TABLES
                  Where
                    TABLE_SCHEMA = 'Lookups'
                    And TABLE_NAME = 'BudgetType' )
   )
    Begin
        Create --drop --alter 
Table Lookups.BudgetType
            (BudgetType CHAR(1)
			,BudgetTypeDesc VARCHAR(250)
            , LastUpdated DATETIME2
            );
    End;


Declare @LastUpdate DATETIME2 =GETDATE()
Declare @LastDate DATETIME2

SELECT @LastDate=MAX([bt].[LastUpdated]) FROM [Lookups].[BudgetType] As [bt]

Insert Lookups.[BudgetType]
        ( [BudgetType]
        , [BudgetTypeDesc]
        , [LastUpdated]
        )
SELECT [BudgetType]='C'
     , [BudgetTypeDesc]='Current Year'
     , [LastUpdated]=@LastUpdate
Insert Lookups.[BudgetType]
        ( [BudgetType]
        , [BudgetTypeDesc]
        , [LastUpdated]
        )
SELECT [BudgetType]='N'
     , [BudgetTypeDesc]='Next Year'
     , [LastUpdated]=@LastUpdate
Insert Lookups.[BudgetType]
        ( [BudgetType]
        , [BudgetTypeDesc]
        , [LastUpdated]
        )
SELECT [BudgetType]='A'
     , [BudgetTypeDesc]='Alternate Budget'
     , [LastUpdated]=@LastUpdate

If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.BudgetType
		Where LastUpdated=@LastUpdate

		Select @PreviousCount=COUNT(*) From Lookups.BudgetType
		Where LastUpdated<>@LastUpdate
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.BudgetType
				Where LastUpdated=@LastUpdate
				Print 'UspUpdate_BudgetType - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.BudgetType
				Where LastUpdated<>@LastUpdate
				Print 'UspUpdate_BudgetType - Update applied successfully'
			End
	End
	If @PrevCheck=0
		Begin
			Delete Lookups.BudgetType
			Where LastUpdated<>@LastUpdate
			Print 'UspUpdate_BudgetType - Update applied successfully'
		End
	End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_BudgetType - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End

GO
