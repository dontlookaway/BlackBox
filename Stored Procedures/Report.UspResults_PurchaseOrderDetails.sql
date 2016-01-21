SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrderDetails]
(@Company VARCHAR(Max))
--exec [Report].[UspResults_PurchaseOrderDetails] 43
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
///			30/9/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
Set NoCount on

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'PorMasterHdr,PorMasterDetail,ReqDetail,ReqHeader,ApSupplier' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #PorMasterHdr
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[PurchaseOrder] VARCHAR(50) Collate Latin1_General_BIN
		,[OrderEntryDate] DATETIME2
		,[OrderDueDate] DATETIME2
		,[Supplier] VARCHAR(50) Collate Latin1_General_BIN
		,[DeliveryName] VARCHAR(100) Collate Latin1_General_BIN
		,[DeliveryAddr1] VARCHAR(155) Collate Latin1_General_BIN
		,[Currency] VARCHAR(10) Collate Latin1_General_BIN
		,[OrderStatus] VARCHAR(10) Collate Latin1_General_BIN
	)
	CREATE TABLE #PorMasterDetail
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
		,[PurchaseOrder] VARCHAR(50) Collate Latin1_General_BIN
	    ,[Line] INT
		,[MStockCode] VARCHAR(50) Collate Latin1_General_BIN
		,[MSupCatalogue] VARCHAR(150) Collate Latin1_General_BIN
		,[MGlCode] VARCHAR(50) Collate Latin1_General_BIN
		,[MStockDes] VARCHAR(150) Collate Latin1_General_BIN
		,[MOrderUom] VARCHAR(10) Collate Latin1_General_BIN
		,[MPrice] NUMERIC(20,3)
		,[MForeignPrice] NUMERIC(20,3)
		,[MOrderQty] NUMERIC(20,7)
		,[MRequisition] VARCHAR(50) Collate Latin1_General_BIN
		,[MRequisitionLine] INT
	)
		CREATE TABLE #ReqDetail
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	,[Buyer] VARCHAR(100) Collate Latin1_General_BIN
	,[Originator] VARCHAR(100) Collate Latin1_General_BIN
	,[ReasonForReqn] VARCHAR(500) Collate Latin1_General_BIN
	,[Operator] VARCHAR(150) Collate Latin1_General_BIN
	,[Requisition] VARCHAR(50) Collate Latin1_General_BIN
	,[Line] INT
	)
		CREATE TABLE #ReqHeader
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
	    ,[DateReqnRaised] DATETIME2
		,[Requisition] VARCHAR(50) Collate Latin1_General_BIN
	)
		CREATE TABLE #ApSupplier
	(	DatabaseName VARCHAR(150) Collate Latin1_General_BIN
		,[Supplier] VARCHAR(50) Collate Latin1_General_BIN
	    ,[SupplierName] VARCHAR(150) Collate Latin1_General_BIN
		,[MerchGlCode] VARCHAR(50) Collate Latin1_General_BIN
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
				Insert [#PorMasterHdr]
						( [DatabaseName]
						, [PurchaseOrder]
						, [OrderEntryDate]
						, [OrderDueDate]
						, [Supplier]
						, [DeliveryName]
						, [DeliveryAddr1]
						, [Currency]
						,[OrderStatus] 
						)
				SELECT [DatabaseName]=@DBCode
					 , [pmh].[PurchaseOrder]
					 , [pmh].[OrderEntryDate]
					 , [pmh].[OrderDueDate]
					 , [pmh].[Supplier]
					 , [pmh].[DeliveryName]
					 , [pmh].[DeliveryAddr1]
					 , [pmh].[Currency]
					 ,[OrderStatus]  
				From [PorMasterHdr] As [pmh]
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
				Insert [#PorMasterDetail]
						( [DatabaseName]
						, [PurchaseOrder]
						, [Line]
						, [MStockCode]
						, [MSupCatalogue]
						, [MGlCode]
						, [MStockDes]
						, [MOrderUom]
						, [MPrice]
						, [MForeignPrice]
						, [MOrderQty]
						, [MRequisition]
						, [MRequisitionLine]
						)
				SELECT [DatabaseName]=@DBCode
					 , [pmd].[PurchaseOrder]
					 , [pmd].[Line]
					 , [pmd].[MStockCode]
					 , [pmd].[MSupCatalogue]
					 , [pmd].[MGlCode]
					 , [pmd].[MStockDes]
					 , [pmd].[MOrderUom]
					 , [pmd].[MPrice]
					 , [pmd].[MForeignPrice]
					 , [pmd].[MOrderQty]
					 , [pmd].[MRequisition]
					 , [pmd].[MRequisitionLine] 
				FROM [PorMasterDetail] As [pmd]
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
				Insert [#ReqDetail]
						( [DatabaseName]
						, [Buyer]
						, [Originator]
						, [ReasonForReqn]
						, [Operator]
						, [Requisition]
						, [Line]
						)
				SELECT [DatabaseName]=@DBCode
					 , [rd].[Buyer]
					 , [rd].[Originator]
					 , [rd].[ReasonForReqn]
					 , [rd].[Operator]
					 , [rd].[Requisition]
					 , [rd].[Line] 
				FROM [ReqDetail] As [rd]
			End
	End'
	Declare @SQL4 VARCHAR(max) = '
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
				Insert [#ReqHeader]
						( [DatabaseName]
						, [DateReqnRaised]
						, [Requisition]
						)
				SELECT [DatabaseName]=@DBCode
					 , [rh].[DateReqnRaised]
					 , [rh].[Requisition] 
				FROM [ReqHeader] As [rh]
			End
	End'

	Declare @SQL5 VARCHAR(max) = '
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
				Insert [#ApSupplier]
						( [DatabaseName]
						, [Supplier]
						, [SupplierName]
						, [MerchGlCode]
						)
				SELECT [DatabaseName]=@DBCode
					 , [as].[Supplier]
					 , [as].[SupplierName]
					 , [as].[MerchGlCode]	
				From [ApSupplier] As [as]
			End
	End'
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1
	Exec sp_MSforeachdb @SQL2
	Exec sp_MSforeachdb @SQL3
	Exec sp_MSforeachdb @SQL4
	Exec sp_MSforeachdb @SQL5
	--Exec sp_MSforeachdb @SQL

--define the results you want to return
    Create Table #PurchaseOrderDetailsResults
        (
          [PurchaseOrder] VARCHAR(50)
        , [OrderEntryDate] DATETIME2
        , [OrderDueDate] DATETIME2
        , [Supplier] VARCHAR(50)
        , [DeliveryName] VARCHAR(50)
        , [DeliveryAddr1] VARCHAR(150)
        , [Currency] VARCHAR(5)
        , [DateReqnRaised] DATETIME
        , [Requisition] VARCHAR(50)
        , [Line] INT
        , [StockCode] VARCHAR(50)
        , [SupCatalogue] VARCHAR(150)
        , [GlCode] VARCHAR(50)
        , [StockDes] VARCHAR(150)
        , [OrderUom] VARCHAR(10)
        , [Price] NUMERIC(20, 3)
        , [ForeignPrice] NUMERIC(20, 3)
        , [OrderQty] NUMERIC(20, 7)
        , [Buyer] VARCHAR(50)
        , [Originator] VARCHAR(150)
        , [ReasonForReqn] VARCHAR(255)
        , [ReqOperator] VARCHAR(150)
        , [SupplierName] VARCHAR(150)
        , [MerchGlCode] VARCHAR(50)
        , [CompanyName] VARCHAR(150)
		, [OrderStatus] VARCHAR(250)
        );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert #PurchaseOrderDetailsResults
	        ( [PurchaseOrder]
	        , [OrderEntryDate]
	        , [OrderDueDate]
	        , [Supplier]
	        , [DeliveryName]
	        , [DeliveryAddr1]
	        , [Currency]
	        , [DateReqnRaised]
	        , [Requisition]
	        , [Line]
	        , [StockCode]
	        , [SupCatalogue]
	        , [GlCode]
	        , [StockDes]
	        , [OrderUom]
	        , [Price]
	        , [ForeignPrice]
	        , [OrderQty]
	        , [Buyer]
	        , [Originator]
	        , [ReasonForReqn]
	        , [ReqOperator]
	        , [SupplierName]
	        , [MerchGlCode]
	        , [CompanyName]
			, [OrderStatus]
	        )
	Select
		[pmh].[PurchaseOrder]
	  , [pmh].[OrderEntryDate]
	  , [pmh].[OrderDueDate]
	  , [pmh].[Supplier]
	  , [pmh].[DeliveryName]
	  , [pmh].[DeliveryAddr1]
	  , [pmh].[Currency]
	  , [rh].[DateReqnRaised]
	  , [rh].[Requisition]
	  , [pmd].[Line]
	  , [pmd].[MStockCode]
	  , [pmd].[MSupCatalogue]
	  , [pmd].[MGlCode]
	  , [pmd].[MStockDes]
	  , [pmd].[MOrderUom]
	  , [pmd].[MPrice]
	  , [pmd].[MForeignPrice]
	  , [pmd].[MOrderQty]
	  , [rd].[Buyer]
	  , [rd].[Originator]
	  , [rd].[ReasonForReqn]
	  , ReqOperator = REPLACE([rd].[Operator], '.', ' ')
	  , [as].[SupplierName]
	  , [as].[MerchGlCode]
	  , [cn].[CompanyName]
	  , [pos].[OrderStatusDescription]
	From
		[#PorMasterHdr] As [pmh]
	Left Join [#PorMasterDetail] As [pmd]
		On [pmd].[PurchaseOrder] = [pmh].[PurchaseOrder]
	Left Join [#ReqDetail] As [rd]
		On pmd.[MRequisition] = [rd].[Requisition]
		   And [pmd].[MRequisitionLine] = rd.[Line]
	Left Join [#ReqHeader] As [rh]
		On [rh].[Requisition] = [rd].[Requisition]
	Left Join [#ApSupplier] As [as]
		On [as].[Supplier] = [pmh].[Supplier]
	Left Join [BlackBox].[Lookups].[CompanyNames] As [cn]
		On [cn].[Company] = [pmh].[DatabaseName]
	Left Join [BlackBox].[Lookups].[PurchaseOrderStatus] As [pos]
		On [pos].[Company] = pmh.[DatabaseName]
		And pos.[OrderStatusCode]=pmh.[OrderStatus];

	

--return results
	SELECT [PurchaseOrder]
         , [OrderEntryDate] = CAST([OrderEntryDate] As DATE)
         , [OrderDueDate] = CAST([OrderDueDate] As DATE)
         , [Supplier]
         , [DeliveryName]
         , [DeliveryAddr1]
         , [Currency]
         , [DateReqnRaised] = CAST([DateReqnRaised] As DATE)
         , [Requisition]
         , [Line]
         , [StockCode]
         , [SupCatalogue]
         , [GlCode]
         , [StockDes]
         , [OrderUom]
         , [Price]
         , [ForeignPrice]
         , [OrderQty]
         , [Buyer]
         , [Originator]
         , [ReasonForReqn]
         , [ReqOperator]
         , [SupplierName]
         , [MerchGlCode]
         , [CompanyName] 
		 , [OrderStatus]
	From #PurchaseOrderDetailsResults

--Tidy up 
drop table #ApSupplier;
drop table #PorMasterDetail;
drop table #PorMasterHdr;
drop table #ReqDetail
drop table #ReqHeader
drop table #PurchaseOrderDetailsResults

End

GO
