
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GenJournalCtlJnlSource]
(@PrevCheck INT
,@HoursBetweenUpdates int)
As
Begin


--remove nocount on to speed up query
Set NoCount On

--check if table exists and create if it doesn't
If ( Not Exists ( Select
                    *
                  From
                    INFORMATION_SCHEMA.TABLES
                  Where
                    TABLE_SCHEMA = 'Lookups'
                    And TABLE_NAME = 'GenJournalCtlJnlSource' )
   )
    Begin
        Create Table Lookups.GenJournalCtlJnlSource
            (GenJournalCtlJnlSource CHAR(2)
			,GenJournalCtlJnlSourceDesc VARCHAR(250)
            , LastUpdated DATETIME2
            );
    End;


Declare @LastUpdate DATETIME2 =GETDATE()
Declare @LastDate DATETIME2

SELECT @LastDate=MAX([bt].[LastUpdated]) FROM [Lookups].[GenJournalCtlJnlSource] As [bt]

Insert Lookups.[GenJournalCtlJnlSource]
        ( [GenJournalCtlJnlSource]
        , [GenJournalCtlJnlSourceDesc]
        , [LastUpdated]
        )
SELECT [GenJournalCtlJnlSource]
     , [GenJournalCtlJnlSourceDesc]
     , [LastUpdated]=@LastUpdate FROM 
(Select [GenJournalCtlJnlSource] ='AP'
     , [GenJournalCtlJnlSourceDesc] = 'Accounts Payable'
Union
Select [GenJournalCtlJnlSource] ='AR'
     , [GenJournalCtlJnlSourceDesc] = 'Accounts Receivable'
Union
Select [GenJournalCtlJnlSource] ='AS'
     , [GenJournalCtlJnlSourceDesc] = 'Assets/Assets Register'
Union
Select [GenJournalCtlJnlSource] ='GR'
     , [GenJournalCtlJnlSourceDesc] = 'Grn/Grn Matching'
Union
Select [GenJournalCtlJnlSource] ='IN'
     , [GenJournalCtlJnlSourceDesc] = 'Inventory'
Union
Select [GenJournalCtlJnlSource] ='SA'
     , [GenJournalCtlJnlSourceDesc] = 'Sales'
Union
Select [GenJournalCtlJnlSource] ='WP'
     , [GenJournalCtlJnlSourceDesc] = 'Work in Progress'
Union
Select [GenJournalCtlJnlSource] ='PA'
     , [GenJournalCtlJnlSourceDesc] = 'Payroll'
Union
Select [GenJournalCtlJnlSource] ='CS'
     , [GenJournalCtlJnlSourceDesc] = 'Cashbook'
) t


If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.GenJournalCtlJnlSource
		Where LastUpdated=@LastUpdate

		Select @PreviousCount=COUNT(*) From Lookups.GenJournalCtlJnlSource
		Where LastUpdated<>@LastUpdate
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.GenJournalCtlJnlSource
				Where LastUpdated=@LastUpdate
				Print 'UspUpdate_GenJournalCtlJnlSource - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.GenJournalCtlJnlSource
				Where LastUpdated<>@LastUpdate
				Print 'UspUpdate_GenJournalCtlJnlSource - Update applied successfully'
			End
	End
	If @PrevCheck=0
		Begin
			Delete Lookups.GenJournalCtlJnlSource
			Where LastUpdated<>@LastUpdate
			Print 'UspUpdate_GenJournalCtlJnlSource - Update applied successfully'
		End
	End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_GenJournalCtlJnlSource - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End

GO
