SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GenTransactionSource]
(@PrevCheck INT
,@HoursBetweenUpdates int)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with GenTransaction Source	///
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
                    And TABLE_NAME = 'GenTransactionSource' )
   )
    Begin
        Create --drop --alter 
Table Lookups.GenTransactionSource
            (Source CHAR(2)
			,SourceDesc VARCHAR(250)
            , LastUpdated DATETIME2
            );
    End;


Declare @LastUpdate DATETIME2 =GETDATE()
Declare @LastDate DATETIME2

SELECT @LastDate=MAX([bt].[LastUpdated]) FROM [Lookups].[GenTransactionSource] As [bt]

Insert Lookups.[GenTransactionSource]
        ( [Source]
        , [SourceDesc]
        , [LastUpdated]
        )
SELECT * FROM 
(SELECT [Source]='JE'
     , [SourceDesc]='Normal Journal'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='IC'
     , [SourceDesc]='Inter-company journal'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='RV'
     , [SourceDesc]='Reversing journal'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='YE'
     , [SourceDesc]='Year end closing'
     , [LastUpdated]=@LastUpdate	 
Union
SELECT [Source]='PE'
     , [SourceDesc]='Period end journal'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='AU'
     , [SourceDesc]='Auditor''s Adjustment'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='HM'
     , [SourceDesc]='History Maintenance'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='AP'
     , [SourceDesc]='Accounts Payable'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='AR'
     , [SourceDesc]='A/R payments'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='IN'
     , [SourceDesc]='Inventory'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='GR'
     , [SourceDesc]='GRN system'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='SA'
     , [SourceDesc]='A/R Sales'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='AS'
     , [SourceDesc]='Assets'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='PA'
     , [SourceDesc]='Payroll'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='WP'
     , [SourceDesc]='Work in progress'
     , [LastUpdated]=@LastUpdate
Union
SELECT [Source]='CS'
     , [SourceDesc]='Cash book'
     , [LastUpdated]=@LastUpdate
	 ) t


If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.GenTransactionSource
		Where LastUpdated=@LastUpdate

		Select @PreviousCount=COUNT(*) From Lookups.GenTransactionSource
		Where LastUpdated<>@LastUpdate
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.GenTransactionSource
				Where LastUpdated=@LastUpdate
				Print 'UspUpdate_GenTransactionSource - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.GenTransactionSource
				Where LastUpdated<>@LastUpdate
				Print 'UspUpdate_GenTransactionSource - Update applied successfully'
			End
	End
	If @PrevCheck=0
		Begin
			Delete Lookups.GenTransactionSource
			Where LastUpdated<>@LastUpdate
			Print 'UspUpdate_GenTransactionSource - Update applied successfully'
		End
	End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_GenTransactionSource - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End

GO
