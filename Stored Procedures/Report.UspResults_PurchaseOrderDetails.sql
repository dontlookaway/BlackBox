
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrderDetails] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--exec [Report].[UspResults_PurchaseOrderDetails] 43
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterHdr,PorMasterDetail,ReqDetail,ReqHeader,ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(50) Collate Latin1_General_BIN
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [DeliveryName] Varchar(100) Collate Latin1_General_BIN
            , [DeliveryAddr1] Varchar(155) Collate Latin1_General_BIN
            , [Currency] Varchar(10) Collate Latin1_General_BIN
            , [OrderStatus] Varchar(10) Collate Latin1_General_BIN
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(50) Collate Latin1_General_BIN
            , [Line] Int
            , [MStockCode] Varchar(50) Collate Latin1_General_BIN
            , [MSupCatalogue] Varchar(150) Collate Latin1_General_BIN
            , [MGlCode] Varchar(50) Collate Latin1_General_BIN
            , [MStockDes] Varchar(150) Collate Latin1_General_BIN
            , [MOrderUom] Varchar(10) Collate Latin1_General_BIN
            , [MPrice] Numeric(20 , 3)
            , [MForeignPrice] Numeric(20 , 3)
            , [MOrderQty] Numeric(20 , 7)
            , [MRequisition] Varchar(50) Collate Latin1_General_BIN
            , [MRequisitionLine] Int
            );
        Create Table [#ReqDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Buyer] Varchar(100) Collate Latin1_General_BIN
            , [Originator] Varchar(100) Collate Latin1_General_BIN
            , [ReasonForReqn] Varchar(500) Collate Latin1_General_BIN
            , [Operator] Varchar(150) Collate Latin1_General_BIN
            , [Requisition] Varchar(50) Collate Latin1_General_BIN
            , [Line] Int
            );
        Create Table [#ReqHeader]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [DateReqnRaised] DateTime2
            , [Requisition] Varchar(50) Collate Latin1_General_BIN
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [SupplierName] Varchar(150) Collate Latin1_General_BIN
            , [MerchGlCode] Varchar(50) Collate Latin1_General_BIN
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
	End';
        Declare @SQL2 Varchar(Max) = '
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
	End';
        Declare @SQL3 Varchar(Max) = '
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
	End';
        Declare @SQL4 Varchar(Max) = '
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
	End';
        Declare @SQL5 Varchar(Max) = '
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
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
        Exec [Process].[ExecForEachDB] @cmd = @SQL5;

--define the results you want to return
        Create Table [#PurchaseOrderDetailsResults]
            (
              [PurchaseOrder] Varchar(50)
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            , [Supplier] Varchar(50)
            , [DeliveryName] Varchar(50)
            , [DeliveryAddr1] Varchar(150)
            , [Currency] Varchar(5)
            , [DateReqnRaised] DateTime
            , [Requisition] Varchar(50)
            , [Line] Int
            , [StockCode] Varchar(50)
            , [SupCatalogue] Varchar(150)
            , [GlCode] Varchar(50)
            , [StockDes] Varchar(150)
            , [OrderUom] Varchar(10)
            , [Price] Numeric(20 , 3)
            , [ForeignPrice] Numeric(20 , 3)
            , [OrderQty] Numeric(20 , 7)
            , [Buyer] Varchar(50)
            , [Originator] Varchar(150)
            , [ReasonForReqn] Varchar(255)
            , [ReqOperator] Varchar(150)
            , [SupplierName] Varchar(150)
            , [MerchGlCode] Varchar(50)
            , [CompanyName] Varchar(150)
            , [OrderStatus] Varchar(250)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#PurchaseOrderDetailsResults]
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
                Select  [pmh].[PurchaseOrder]
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
                      , [ReqOperator] = Replace([rd].[Operator] , '.' , ' ')
                      , [as].[SupplierName]
                      , [as].[MerchGlCode]
                      , [cn].[CompanyName]
                      , [pos].[OrderStatusDescription]
                From    [#PorMasterHdr] As [pmh]
                        Left Join [#PorMasterDetail] As [pmd] On [pmd].[PurchaseOrder] = [pmh].[PurchaseOrder]
                        Left Join [#ReqDetail] As [rd] On [pmd].[MRequisition] = [rd].[Requisition]
                                                          And [pmd].[MRequisitionLine] = [rd].[Line]
                        Left Join [#ReqHeader] As [rh] On [rh].[Requisition] = [rd].[Requisition]
                        Left Join [#ApSupplier] As [as] On [as].[Supplier] = [pmh].[Supplier]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [cn].[Company] = [pmh].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[PurchaseOrderStatus]
                        As [pos] On [pos].[Company] = [pmh].[DatabaseName]
                                    And [pos].[OrderStatusCode] = [pmh].[OrderStatus];

	

--return results
        Select  [PurchaseOrder]
              , [OrderEntryDate] = Cast([OrderEntryDate] As Date)
              , [OrderDueDate] = Cast([OrderDueDate] As Date)
              , [Supplier]
              , [DeliveryName]
              , [DeliveryAddr1]
              , [Currency]
              , [DateReqnRaised] = Cast([DateReqnRaised] As Date)
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
        From    [#PurchaseOrderDetailsResults];

--Tidy up 
        Drop Table [#ApSupplier];
        Drop Table [#PorMasterDetail];
        Drop Table [#PorMasterHdr];
        Drop Table [#ReqDetail];
        Drop Table [#ReqHeader];
        Drop Table [#PurchaseOrderDetailsResults];

    End;

GO
