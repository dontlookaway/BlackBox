SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Exec Process.UspLoad_LoadController
--    @HoursBetweenEachRun = 2 -- int

CREATE Proc [Process].[UspUpdate_PurchaseOrderTaxStatus]
(@PrevCheck INT --if count is less than previous don't update
,@HoursBetweenUpdates int
)
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with amounts relating to		///
///			Purchase Order Type																	///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			15/9/2015	Chris Johnson			Initial version created																///
///			24/9/2015	Chris Johnson			Amended Results table name as was causing conflict									///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

Set NoCount On


--check if table exists and create if it doesn't
If ( Not Exists ( Select
                    *
                  From
                    INFORMATION_SCHEMA.TABLES
                  Where
                    TABLE_SCHEMA = 'Lookups'
                    And TABLE_NAME = 'PurchaseOrderTaxStatus' )
   )
    Begin
        Create --drop --alter 
Table Lookups.PurchaseOrderTaxStatus
            (
              Company VARCHAR(150)
            , TaxStatusCode CHAR(5)
            , TaxStatusDescription VARCHAR(150)
            , LastUpdated DATETIME2
            );
    End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
Declare @LastDate DATETIME2

Select @LastDate=MAX(LastUpdated)
From Lookups.PurchaseOrderTaxStatus

If @LastDate Is Null Or DATEDIFF(Hour,@LastDate,GETDATE())>@HoursBetweenUpdates
Begin
	--Set time of run
	Declare @LastUpdated DATETIME2; Select @LastUpdated=GETDATE();

	--create master list of how codes affect stock
	Create --drop --alter 
	Table #OrdersPOTax
		(
		  TaxStatusCode VARCHAR(5)
		, TaxStatusDescription VARCHAR(150)
		);

	Insert  #OrdersPOTax
	        ( TaxStatusCode
	        , TaxStatusDescription
	        )
			Select
				TaxStatusCode
			  , TaxStatusDescription
			From
				(
				  Select TaxStatusCode = 'E', TaxStatusDescription='Exempt from tax'
				  Union
				  Select TaxStatusCode = 'N', TaxStatusDescription='Taxable'
				) t;

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
	Create Table #Table1POTax
		(
		  CompanyName VARCHAR(150)
		);

	--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(Max) = '
		USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
		+ --Only query DBs beginning SysProCompany
		'
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #Table1POTax
			( CompanyName )
		Select @DBCode
		End';

	--execute script against each db, populating the base tables
	Exec sp_MSforeachdb    @SQL;

	--all companies process the same way
	Select
		CompanyName
	  , O.TaxStatusCode
	  , O.TaxStatusDescription
	Into
		#ResultsPOTaxStatus
	From
		#Table1POTax T
	Left Join #OrdersPOTax O
		On 1 = 1;

	--placeholder for anomalous results that are different to master list
	--Update #ResultsPOTaxStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

	Insert  Lookups.PurchaseOrderTaxStatus
	        ( Company
	        , TaxStatusCode
	        , TaxStatusDescription
	        , LastUpdated
	        )
			Select
				CompanyName
			  , TaxStatusCode
			  , TaxStatusDescription
			  , @LastUpdated
			From
				#ResultsPOTaxStatus;

	If @PrevCheck=1
	Begin
		Declare @CurrentCount INT, @PreviousCount INT
	
		Select @CurrentCount=COUNT(*) From Lookups.PurchaseOrderTaxStatus
		Where LastUpdated=@LastUpdated

		SELECT @PreviousCount=COUNT(*) From Lookups.PurchaseOrderTaxStatus
		Where LastUpdated<>@LastUpdated
	
		If @PreviousCount>@CurrentCount
			Begin
				Delete Lookups.PurchaseOrderTaxStatus
				Where LastUpdated=@LastUpdated
				Print 'UspUpdate_PurchaseOrderTaxStatus - Count has gone down since last run, no update applied'
				Print 'Current Count = '+CAST(@CurrentCount As VARCHAR(5))+' Previous Count = '+CAST(@PreviousCount As VARCHAR(5))
			End
		If @PreviousCount<=@CurrentCount
			Begin
				Delete Lookups.PurchaseOrderTaxStatus
				Where LastUpdated<>@LastUpdated
				Print 'UspUpdate_PurchaseOrderTaxStatus - Update applied successfully'
			End
	end
	If @PrevCheck=0
		Begin
			Delete Lookups.PurchaseOrderTaxStatus
			Where LastUpdated<>@LastUpdated
			Print 'UspUpdate_PurchaseOrderTaxStatus - Update applied successfully'
		End
	End
End
If DATEDIFF(Hour,@LastDate,GETDATE())<=@HoursBetweenUpdates
Begin
	Print 'UspUpdate_PurchaseOrderTaxStatus - Table was last updated at '+CAST(@LastDate As VARCHAR(255))+' no update applied'
End
GO
