SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrders]
(@Company VARCHAR(Max))
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Procedure to return all Purchase Order Details																			///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			15/9/2015	Chris Johnson			Initial version created																///
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

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'InvBuyer,PorMasterHdr,PorMasterDetail' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #Buyers
	(	DatabaseName VARCHAR(150)
	    ,BuyerCode VARCHAR(20)
		,BuyerName VARCHAR(50)
	)

	CREATE --drop --alter 
	TABLE #PurchaseHeader
	(DatabaseName VARCHAR(150)
	    ,OrderStatus CHAR(1)
		,PurchaseOrder VARCHAR(20)
		,ExchRateFixed CHAR(1)
		,Currency CHAR(3)
		,ExchangeRate FLOAT
		,OrderType CHAR(1)
		,TaxStatus CHAR(1)
		,Customer VARCHAR(15)
		,PaymentTerms CHAR(3)
		,Buyer VARCHAR(20)
		,ShippingInstrs VARCHAR(50)
		,ShippingLocation VARCHAR(10)
		,SupplierClass VARCHAR(10)
		,Supplier VARCHAR(15)
		,OrderEntryDate DATETIME2
		,OrderDueDate DATETIME2
		,DateLastDocPrt DATETIME2
		,DatePoCompleted DATETIME2
		,EdiPoFlag CHAR(1)
		,EdiExtractFlag CHAR(1)
		,EdiActionFlag CHAR(1)
		,EdiConfirmation CHAR(1)
	)

		CREATE --drop --alter 
	TABLE #PurchaseDetails
	(DatabaseName VARCHAR(150)
	 ,PurchaseOrder VARCHAR(20)
     , Line DECIMAL
     , LineType CHAR(1)
     , MStockCode  VARCHAR(30)
     , MStockDes VARCHAR(50)
     , MWarehouse VARCHAR(10)
     , MOrderUom VARCHAR(10)
     , MStockingUom VARCHAR(10)
     , MOrderQty FLOAT
     , MReceivedQty FLOAT
     , MLatestDueDate DATETIME2
     , MLastReceiptDate DATE
     , MPrice FLOAT--DECIMAL(15,12)
     , MForeignPrice FLOAT--DECIMAL(15,12)
     , MDecimalsToPrt INT
     , MPriceUom VARCHAR(10)
     , MTaxCode CHAR(3)
     , MProductClass VARCHAR(20)
     , MCompleteFlag CHAR(1)
     , MJob VARCHAR(20)
     , MJobLine CHAR(2)
     , MGlCode VARCHAR(35)
     , MUserAuthReqn VARCHAR(20)
     , MRequisition VARCHAR(10)
     , MRequisitionLine DECIMAL
     , MSalesOrder VARCHAR(20)
     , MSalesOrderLine DECIMAL
     , MOrigDueDate DATETIME2
     , MReschedDueDate CHAR(1)
     , MSubcontractOp DECIMAL
     , MInspectionReqd CHAR(1)
     , NMscChargeValue FLOAT
     , CapexCode VARCHAR(15)
     , CapexLine DECIMAL
     , NComment VARCHAR(100)
	)

	
	


--create script to pull data from each db into the tables
	Declare @SQL1 VARCHAR(max) = '
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
		Insert #Buyers
				(BuyerCode, BuyerName, DatabaseName
				)
				Select [Buyer], [Name], DatabaseName = @DBCode
				From dbo.InvBuyer
		End
End'

Declare @SQL2 VARCHAR(max) = '
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
		Insert #PurchaseHeader
					( DatabaseName, OrderStatus, PurchaseOrder
					, ExchRateFixed, Currency, ExchangeRate
					, OrderType, TaxStatus, Customer
					, PaymentTerms, Buyer, ShippingInstrs
					, ShippingLocation, SupplierClass, Supplier
					, OrderEntryDate, OrderDueDate, DateLastDocPrt
					, DatePoCompleted, EdiPoFlag, EdiExtractFlag
					, EdiActionFlag, EdiConfirmation
					)
					SELECT 
						DatabaseName = @DBCode, OrderStatus, PurchaseOrder
						,ExchRateFixed, Currency, ExchangeRate
						,OrderType, TaxStatus, Customer
						,PaymentTerms, Buyer, ShippingInstrs
						,ShippingLocation, SupplierClass, Supplier
						,OrderEntryDate, OrderDueDate, DateLastDocPrt
						,DatePoCompleted, EdiPoFlag, EdiExtractFlag
						,EdiActionFlag, EdiConfirmation
				FROM PorMasterHdr
		End
End'

Declare @SQL3 VARCHAR(max) = '
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
		Insert #PurchaseDetails
				( DatabaseName, PurchaseOrder, Line
				, LineType, MStockCode, MStockDes
				, MWarehouse, MOrderUom, MStockingUom
				, MOrderQty, MReceivedQty, MLatestDueDate
				, MLastReceiptDate, MPrice, MForeignPrice
				, MDecimalsToPrt, MPriceUom, MTaxCode
				, MProductClass, MCompleteFlag, MJob
				, MJobLine, MGlCode, MUserAuthReqn
				, MRequisition, MRequisitionLine, MSalesOrder
				, MSalesOrderLine, MOrigDueDate, MReschedDueDate
				, MSubcontractOp, MInspectionReqd, NMscChargeValue
				, CapexCode, CapexLine, NComment
				)
			SELECT 
			DatabaseName = @DBCode, PurchaseOrder, Line
				, LineType, MStockCode, MStockDes
				, MWarehouse, MOrderUom, MStockingUom
				, MOrderQty, MReceivedQty, MLatestDueDate
				, MLastReceiptDat, MPrice, MForeignPrice
				, MDecimalsToPrt, MPriceUom, MTaxCode
				, MProductClass, MCompleteFlag, MJob
				, MJobLine, MGlCode, MUserAuthReqn
				, MRequisition, MRequisitionLine, MSalesOrder
				, MSalesOrderLine, MOrigDueDate
				, MReschedDueDate, MSubcontractOp
				, MInspectionReqd, NMscChargeValue
				, CapexCode, CapexLine, NComment
		From PorMasterDetail

		End
End'


--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1
--Print @SQL2
--Print @SQL3


--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1
	Exec sp_MSforeachdb @SQL2
	Exec sp_MSforeachdb @SQL3

--define the results you want to return
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required
create NonClustered Index DiX_Buyers_DBName On #Buyers (DatabaseName,BuyerCode)
Create NonClustered Index DiX_PH_DBName On #PurchaseHeader (DatabaseName,PurchaseOrder,Buyer)
Create NonClustered Index DiX_PD_DBName On #PurchaseDetails (DatabaseName,PurchaseOrder)

--script to combine base data and insert into results table
Select 
		Company					= PH.DatabaseName
	   , BuyerName				= COALESCE(B.BuyerName,PH.Buyer)
       , OrderStatus			= COALESCE(PS.OrderStatusDescription  Collate Latin1_General_BIN,PH.OrderStatus)
       , PH.PurchaseOrder
       , PH.ExchRateFixed
       , PH.Currency
       , PH.ExchangeRate
       , OrderType				= COALESCE(PT.OrderTypeDescription Collate Latin1_General_BIN,PH.OrderType)
       , TaxStatus				= COALESCE(POTS.TaxStatusDescription Collate Latin1_General_BIN,PH.TaxStatus)
       , PH.Customer
       , PH.PaymentTerms
       , PH.ShippingInstrs
       , PH.ShippingLocation
       , PH.SupplierClass
       , PH.Supplier
       , OrderEntryDate			= CAST(PH.OrderEntryDate As DATE)
       , OrderDueDate			= CAST(PH.OrderDueDate As	DATE)
       , PH.DateLastDocPrt
       , PH.DatePoCompleted
       , PH.EdiPoFlag
       , PH.EdiExtractFlag
       , PH.EdiActionFlag
       , PH.EdiConfirmation
       , PD.Line
       , PD.LineType
       , PD.MStockCode
       , PD.MStockDes
       , PD.MWarehouse
       , PD.MOrderUom
       , PD.MStockingUom
       , MOrderQty				= COALESCE(PD.MOrderQty,0)
       , PD.MReceivedQty
       , PD.MLatestDueDate
       , PD.MLastReceiptDate
       , MPrice					= COALESCE(PD.MPrice,0)
       , MForeignPrice			= COALESCE(PD.MForeignPrice,0)
       , PD.MDecimalsToPrt
       , PD.MPriceUom
       , PD.MTaxCode
       , ProductClass			= COALESCE(PC.ProductClassDescription  Collate Latin1_General_BIN, Case When PD.MProductClass = '' Then 'No Class'Else PD.MProductClass End)
       , MCompleteFlag			= COALESCE(MC.MCompleteFlagDescription Collate Latin1_General_BIN,PD.MCompleteFlag)
       , PD.MJob
       , PD.MJobLine
       , PD.MGlCode
       , PD.MUserAuthReqn
       , PD.MRequisition
       , PD.MRequisitionLine
       , PD.MSalesOrder
       , PD.MSalesOrderLine
       , PD.MOrigDueDate
       , PD.MReschedDueDate
       , PD.MSubcontractOp
       , PD.MInspectionReqd
       , NMscChargeValue		= COALESCE(PD.NMscChargeValue,0)
       , PD.CapexCode
       , PD.CapexLine
       , PD.NComment
	   Into #Results
From #PurchaseHeader PH
Left Join #Buyers B On B.DatabaseName = PH.DatabaseName 
					And B.BuyerCode=PH.Buyer
Left Join #PurchaseDetails PD On PD.DatabaseName = PH.DatabaseName
					And PD.PurchaseOrder = PH.PurchaseOrder
Left Join Lookups.PurchaseOrderStatus PS On PS.Company=PH.DatabaseName Collate Latin1_General_BIN
											And PH.OrderStatus=PS.OrderStatusCode Collate Latin1_General_BIN
Left Join Lookups.PurchaseOrderType PT On PT.Company=PH.DatabaseName Collate Latin1_General_BIN
											And PT.OrderTypeCode=PH.OrderType Collate Latin1_General_BIN
Left Join Lookups.PurchaseOrderTaxStatus POTS On POTS.Company = PH.DatabaseName Collate Latin1_General_BIN
											And POTS.TaxStatusCode=PH.TaxStatus Collate Latin1_General_BIN
Left Join Lookups.MCompleteFlag MC On MC.Company = PD.DatabaseName Collate Latin1_General_BIN
											And MC.MCompleteFlagCode=PD.MCompleteFlag Collate Latin1_General_BIN
Left Join Lookups.ProductClass PC On PC.Company = PH.DatabaseName Collate Latin1_General_BIN
											And PC.ProductClass=PD.MProductClass Collate Latin1_General_BIN

--return results
	Select * From #Results

End


GO
