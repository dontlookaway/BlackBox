
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrders]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
Procedure to return all Purchase Order Details
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_PurchaseOrders' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvBuyer,PorMasterHdr,PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#Buyers]
            (
              [DatabaseName] Varchar(150)
            , [BuyerCode] Varchar(20)
            , [BuyerName] Varchar(50)
            );

        Create Table [#PurchaseHeader]
            (
              [DatabaseName] Varchar(150)
            , [OrderStatus] Char(1)
            , [PurchaseOrder] Varchar(20)
            , [ExchRateFixed] Char(1)
            , [Currency] Char(3)
            , [ExchangeRate] Float
            , [OrderType] Char(1)
            , [TaxStatus] Char(1)
            , [Customer] Varchar(15)
            , [PaymentTerms] Char(3)
            , [Buyer] Varchar(20)
            , [ShippingInstrs] Varchar(50)
            , [ShippingLocation] Varchar(10)
            , [SupplierClass] Varchar(10)
            , [Supplier] Varchar(15)
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            , [DateLastDocPrt] DateTime2
            , [DatePoCompleted] DateTime2
            , [EdiPoFlag] Char(1)
            , [EdiExtractFlag] Char(1)
            , [EdiActionFlag] Char(1)
            , [EdiConfirmation] Char(1)
            );

        Create Table [#PurchaseDetails]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [Line] Decimal
            , [LineType] Char(1)
            , [MStockCode] Varchar(30)
            , [MStockDes] Varchar(50)
            , [MWarehouse] Varchar(10)
            , [MOrderUom] Varchar(10)
            , [MStockingUom] Varchar(10)
            , [MOrderQty] Float
            , [MReceivedQty] Float
            , [MLatestDueDate] DateTime2
            , [MLastReceiptDate] Date
            , [MPrice] Float--DECIMAL(15,12)
            , [MForeignPrice] Float--DECIMAL(15,12)
            , [MDecimalsToPrt] Int
            , [MPriceUom] Varchar(10)
            , [MTaxCode] Char(3)
            , [MProductClass] Varchar(20)
            , [MCompleteFlag] Char(1)
            , [MJob] Varchar(20)
            , [MJobLine] Char(2)
            , [MGlCode] Varchar(35)
            , [MUserAuthReqn] Varchar(20)
            , [MRequisition] Varchar(10)
            , [MRequisitionLine] Decimal
            , [MSalesOrder] Varchar(20)
            , [MSalesOrderLine] Decimal
            , [MOrigDueDate] DateTime2
            , [MReschedDueDate] Char(1)
            , [MSubcontractOp] Decimal
            , [MInspectionReqd] Char(1)
            , [NMscChargeValue] Float
            , [CapexCode] Varchar(15)
            , [CapexLine] Decimal
            , [NComment] Varchar(100)
            );

	
	


--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
	IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
            '
		If @ActualCountOfTables=@RequiredCountOfTables
		BEGIN
		Insert #Buyers
				(BuyerCode, BuyerName, DatabaseName
				)
				Select [Buyer], [Name], DatabaseName = @DBCode
				From dbo.InvBuyer
		End
End';
        Declare @SQL2 Varchar(Max) = '
USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
	IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
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
End';
        Declare @SQL3 Varchar(Max) = '
USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
	IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'
            + --count number of tables requested (number of commas plus one)
            '
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
            + --Count of the tables requested how many exist in the db
            '
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
            + --only if the count matches (all the tables exist in the requested db) then run the script
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
End';


--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1
--Print @SQL2
--Print @SQL3


--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;

--define the results you want to return

--Placeholder to create indexes as required
        Create NonClustered Index [DiX_Buyers_DBName] On [#Buyers] ([DatabaseName],[BuyerCode]);
        Create NonClustered Index [DiX_PH_DBName] On [#PurchaseHeader] ([DatabaseName],[PurchaseOrder],[Buyer]);
        Create NonClustered Index [DiX_PD_DBName] On [#PurchaseDetails] ([DatabaseName],[PurchaseOrder]);

--script to combine base data and insert into results table
        Select  [Company] = [PH].[DatabaseName]
              , [BuyerName] = Coalesce([B].[BuyerName] , [PH].[Buyer])
              , [OrderStatus] = Coalesce([PS].[OrderStatusDescription]  Collate Latin1_General_BIN ,
                                         [PH].[OrderStatus])
              , [PH].[PurchaseOrder]
              , [PH].[ExchRateFixed]
              , [PH].[Currency]
              , [PH].[ExchangeRate]
              , [OrderType] = Coalesce([PT].[OrderTypeDescription] Collate Latin1_General_BIN ,
                                       [PH].[OrderType])
              , [TaxStatus] = Coalesce([POTS].[TaxStatusDescription] Collate Latin1_General_BIN ,
                                       [PH].[TaxStatus])
              , [PH].[Customer]
              , [PH].[PaymentTerms]
              , [PH].[ShippingInstrs]
              , [PH].[ShippingLocation]
              , [PH].[SupplierClass]
              , [PH].[Supplier]
              , [OrderEntryDate] = Cast([PH].[OrderEntryDate] As Date)
              , [OrderDueDate] = Cast([PH].[OrderDueDate] As Date)
              , [PH].[DateLastDocPrt]
              , [PH].[DatePoCompleted]
              , [PH].[EdiPoFlag]
              , [PH].[EdiExtractFlag]
              , [PH].[EdiActionFlag]
              , [PH].[EdiConfirmation]
              , [PD].[Line]
              , [PD].[LineType]
              , [PD].[MStockCode]
              , [PD].[MStockDes]
              , [PD].[MWarehouse]
              , [PD].[MOrderUom]
              , [PD].[MStockingUom]
              , [MOrderQty] = Coalesce([PD].[MOrderQty] , 0)
              , [PD].[MReceivedQty]
              , [PD].[MLatestDueDate]
              , [PD].[MLastReceiptDate]
              , [MPrice] = Coalesce([PD].[MPrice] , 0)
              , [MForeignPrice] = Coalesce([PD].[MForeignPrice] , 0)
              , [PD].[MDecimalsToPrt]
              , [PD].[MPriceUom]
              , [PD].[MTaxCode]
              , [ProductClass] = Coalesce([PC].[ProductClassDescription]  Collate Latin1_General_BIN ,
                                          Case When [PD].[MProductClass] = ''
                                               Then 'No Class'
                                               Else [PD].[MProductClass]
                                          End)
              , [MCompleteFlag] = Coalesce([MC].[MCompleteFlagDescription] Collate Latin1_General_BIN ,
                                           [PD].[MCompleteFlag])
              , [PD].[MJob]
              , [PD].[MJobLine]
              , [PD].[MGlCode]
              , [PD].[MUserAuthReqn]
              , [PD].[MRequisition]
              , [PD].[MRequisitionLine]
              , [PD].[MSalesOrder]
              , [PD].[MSalesOrderLine]
              , [PD].[MOrigDueDate]
              , [PD].[MReschedDueDate]
              , [PD].[MSubcontractOp]
              , [PD].[MInspectionReqd]
              , [NMscChargeValue] = Coalesce([PD].[NMscChargeValue] , 0)
              , [PD].[CapexCode]
              , [PD].[CapexLine]
              , [PD].[NComment]
        --Into    [#Results]
        From    [#PurchaseHeader] [PH]
                Left Join [#Buyers] [B] On [B].[DatabaseName] = [PH].[DatabaseName]
                                           And [B].[BuyerCode] = [PH].[Buyer]
                Left Join [#PurchaseDetails] [PD] On [PD].[DatabaseName] = [PH].[DatabaseName]
                                                     And [PD].[PurchaseOrder] = [PH].[PurchaseOrder]
                Left Join [Lookups].[PurchaseOrderStatus] [PS] On [PS].[Company] = [PH].[DatabaseName] Collate Latin1_General_BIN
                                                              And [PH].[OrderStatus] = [PS].[OrderStatusCode] Collate Latin1_General_BIN
                Left Join [Lookups].[PurchaseOrderType] [PT] On [PT].[Company] = [PH].[DatabaseName] Collate Latin1_General_BIN
                                                              And [PT].[OrderTypeCode] = [PH].[OrderType] Collate Latin1_General_BIN
                Left Join [Lookups].[PurchaseOrderTaxStatus] [POTS] On [POTS].[Company] = [PH].[DatabaseName] Collate Latin1_General_BIN
                                                              And [POTS].[TaxStatusCode] = [PH].[TaxStatus] Collate Latin1_General_BIN
                Left Join [Lookups].[MCompleteFlag] [MC] On [MC].[Company] = [PD].[DatabaseName] Collate Latin1_General_BIN
                                                            And [MC].[MCompleteFlagCode] = [PD].[MCompleteFlag] Collate Latin1_General_BIN
                Left Join [Lookups].[ProductClass] [PC] On [PC].[Company] = [PH].[DatabaseName] Collate Latin1_General_BIN
                                                           And [PC].[ProductClass] = [PD].[MProductClass] Collate Latin1_General_BIN;

--return results

    End;



GO
EXEC sp_addextendedproperty N'MS_Description', N'purchase order details', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_PurchaseOrders', NULL, NULL
GO
