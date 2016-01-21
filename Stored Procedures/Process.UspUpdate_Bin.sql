SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Process].[UspUpdate_Bin]
(@PrevCheck INT
,@HoursBetweenUpdates int)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with Bin details				///
///			transaction types when relating to inventory changes																	///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			10/9/2015	Chris Johnson			Initial version created																///
///			14/9/2015	Chris Johnson			Amended print lines to be recognizable within load controller						///
///			24/9/2015	Chris Johnson			Amended Results table name as was causing conflict									///
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
                    And TABLE_NAME = 'Bin' )
   )
    Begin
        Create --drop --alter 
Table Lookups.Bin
            (
              Company VARCHAR(150)
            , Bin VARCHAR(150)
            , LastUpdated DATETIME2
            );
    End;



--check last time run and update if it's been longer than @HoursBetweenUpdates hours
Declare @LastDate DATETIME2

Select @LastDate=MAX(LastUpdated)
From Lookups.Bin

If @LastDate Is Null Or DATEDIFF(Hour,@LastDate,GETDATE())>@HoursBetweenUpdates
Begin
	--Set time of run
	Declare @LastUpdated DATETIME2; Select @LastUpdated=GETDATE();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'InvMovements' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #Table1
	(	Company VARCHAR(150)
	    ,Bin VARCHAR(150)
	)

--create script to pull data from each db into the tables
	Declare @Company VARCHAR(30) = 'All'
	Declare @SQL VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #Table1
					( Company, Bin)
				Select distinct @DBCode
				,Bin
				From InvMovements
			End
	End'

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL

Insert Lookups.Bin
        ( Company, Bin, LastUpdated )
SELECT Company
     , Bin
	 , @LastUpdated
	  FROM #Table1

If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.Bin
		Where LastUpdated=@LastUpdated

		Select @PreviousCount=COUNT(*) From Lookups.Bin
		Where LastUpdated<>@LastUpdated
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.Bin
				Where LastUpdated=@LastUpdated
				Print 'UspUpdate_Bin - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.Bin
				Where LastUpdated<>@LastUpdated
				Print 'UspUpdate_Bin - Update applied successfully'
			End
	End
	If @PrevCheck=0
		Begin
			Delete Lookups.Bin
			Where LastUpdated<>@LastUpdated
			Print 'UspUpdate_Bin - Update applied successfully'
		End
	End
End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_Bin - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End

GO
