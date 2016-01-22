
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_GlAccountCode]
(@PrevCheck INT --if count is less than previous don't update
,@HoursBetweenUpdates int
)
As
Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to	Purchase Order Status details
*/

Set NoCount On


--check if table exists and create if it doesn't
If ( Not Exists ( Select
                    *
                  From
                    INFORMATION_SCHEMA.TABLES
                  Where
                    TABLE_SCHEMA = 'Lookups'
                    And TABLE_NAME = 'GlAccountCode' )
   )
    Begin
        Create Table Lookups.GlAccountCode
            (
              Company VARCHAR(150)
            , GlAccountCode CHAR(5)
            , GlAccountDescription VARCHAR(150)
            , LastUpdated DATETIME2
            );
    End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
Declare @LastDate DATETIME2

Select @LastDate=MAX(LastUpdated)
From Lookups.GlAccountCode

If @LastDate Is Null Or DATEDIFF(Hour,@LastDate,GETDATE())>@HoursBetweenUpdates
Begin
	--Set time of run
	Declare @LastUpdated DATETIME2; Select @LastUpdated=GETDATE();

	--create master list of how codes affect stock
	Create Table #OrdersGlAccountCode
		(
		  GlAccountCode VARCHAR(5)
		, GlAccountDescription VARCHAR(150)
		);

	Insert  #OrdersGlAccountCode
	        ( GlAccountCode
	        , GlAccountDescription
	        )
			Select
				GlAccountCode
			  , GlAccountDescription
			From
				(
				  Select GlAccountCode = 'M', GlAccountDescription='Merchandise expense'
				  Union
				  Select GlAccountCode = 'F', GlAccountDescription='Freight-in expense'
				  Union
				  Select GlAccountCode = 'O', GlAccountDescription='Other expense'
				) t;

	--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(Max) = '
		USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
		+ --Only query DBs beginning SysProCompany
		'
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #Table1
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
	--Exec [Process].[ExecForEachDB] @cmd =    @SQL;

	--all companies process the same way
	Select
		CompanyName='40'
	  , O.GlAccountCode
	  , O.GlAccountDescription
	Into
		#ResultsGlAccountCode
	From
		 #OrdersGlAccountCode O
		

	--placeholder for anomalous results that are different to master list
	--Update #ResultsGlAccountCode
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

	Insert  Lookups.GlAccountCode
	        ( Company
	        , GlAccountCode
	        , GlAccountDescription
	        , LastUpdated
	        )
			Select
				CompanyName
			  , GlAccountCode
			  , GlAccountDescription
			  , @LastUpdated
			From
				#ResultsGlAccountCode;

	If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.GlAccountCode
		Where LastUpdated=@LastUpdated

		SELECT @PreviousCount=COUNT(*) From Lookups.GlAccountCode
		Where LastUpdated<>@LastUpdated
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.GlAccountCode
				Where LastUpdated=@LastUpdated
				Print 'UspUpdate_GlAccountCode - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.GlAccountCode
				Where LastUpdated<>@LastUpdated
				Print 'UspUpdate_GlAccountCode - Update applied successfully'
			End
	end
	If @PrevCheck=0
		Begin
			Delete Lookups.GlAccountCode
			Where LastUpdated<>@LastUpdated
			Print 'UspUpdate_GlAccountCode - Update applied successfully'
		End
	End
End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_GlAccountCode - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End
GO
