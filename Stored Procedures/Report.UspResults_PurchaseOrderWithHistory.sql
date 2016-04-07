
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Proc [Report].[UspResults_PurchaseOrderWithHistory]
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
            @StoredProcName = 'UspResults_PurchaseOrderWithHistory' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [Line] Int
            , [LineType] Int
            , [MStockCode] Varchar(30)
            , [MStockDes] Varchar(50)
            , [MWarehouse] Varchar(10)
            , [MOrderQty] Numeric(20 , 6)
            , [MReceivedQty] Numeric(20 , 6)
            , [MCompleteFlag] Char(1)
            , [MOrderUom] Varchar(10)
            , [MLatestDueDate] Date
            , [MOrigDueDate] Date
            , [MLastReceiptDat] Date
            , [MPrice] Numeric(20 , 2)
            , [MForeignPrice] Numeric(20 , 2)
            );
        Create Table [#PorHistReceipt]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [PurchaseOrderLin] Int
            , [DateReceived] Date
            , [QtyReceived] Numeric(20 , 6)
            , [PriceReceived] Numeric(20 , 2)
            , [RejectCode] Varchar(10)
            , [Reference] Varchar(30)
            );
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [OrderStatus] Char(1)
            , [Supplier] Varchar(15)
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [StockCode] Varchar(30)
            , [Description] Varchar(50)
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [SupplierName] Varchar(50)
            );
        Create Table [#GrnDetails]
            (
              [DatabaseName] Varchar(150)
            , [Grn] Varchar(20)
            , [DebitRecGlCode] Varchar(35)
            );



--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert [#PorMasterDetail] ( [DatabaseName], [PurchaseOrder], [Line], [LineType], [MStockCode], [MStockDes], [MWarehouse], [MOrderQty], [MReceivedQty], [MCompleteFlag], [MOrderUom], [MLatestDueDate], [MOrigDueDate], [MLastReceiptDat], [MPrice], [MForeignPrice])
				SELECT [DatabaseName]=@DBCode
				 , [PMD].[PurchaseOrder]
				 , [PMD].[Line]
				 , [PMD].[LineType]
				 , [PMD].[MStockCode]
				 , [PMD].[MStockDes]
				 , [PMD].[MWarehouse]
				 , [PMD].[MOrderQty]
				 , [PMD].[MReceivedQty]
				 , [PMD].[MCompleteFlag]
				 , [PMD].[MOrderUom]
				 , [PMD].[MLatestDueDate]
				 , [PMD].[MOrigDueDate]
				 , [PMD].[MLastReceiptDat]
				 , [PMD].[MPrice]
				 , [PMD].[MForeignPrice] FROM [PorMasterDetail] As [PMD]
				Insert [#PorHistReceipt] ( [DatabaseName], [PurchaseOrder], [PurchaseOrderLin], [DateReceived], [QtyReceived], [PriceReceived], [RejectCode], [Reference])
				SELECT [DatabaseName]=@DBCode
					 , [PHR].[PurchaseOrder]
					 , [PHR].[PurchaseOrderLin]
					 , [PHR].[DateReceived]
					 , [PHR].[QtyReceived]
					 , [PHR].[PriceReceived]
					 , [PHR].[RejectCode]
					 , [PHR].[Reference] FROM [PorHistReceipt] As [PHR]
				Insert [#PorMasterHdr] ( [DatabaseName], [PurchaseOrder], [OrderStatus], [Supplier])
				SELECT [DatabaseName]=@DBCode
					 , [PMH].[PurchaseOrder]
					 , [PMH].[OrderStatus]
					 , [PMH].[Supplier] FROM [PorMasterHdr] As [PMH]
				Insert [#InvMaster] ( [DatabaseName], [StockCode], [Description])
				SELECT [DatabaseName]=@DBCode
					 , [IM].[StockCode]
					 , [IM].[Description] FROM [InvMaster] As [IM]
				Insert [#ApSupplier] ( [DatabaseName], [Supplier], [SupplierName])
				SELECT [DatabaseName]=@DBCode
					 , [AS].[Supplier]
					 , [AS].[SupplierName] FROM [ApSupplier] As [AS]
				Insert [#GrnDetails] ( [DatabaseName], [Grn], [DebitRecGlCode])
				Select  [DatabaseName] = @DBCode
					  , [GD].[Grn]
					  , [GD].[DebitRecGlCode]
				From    [GrnDetails] As [GD];
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [CompanyName] Varchar(200)
            , [Supplier] Varchar(15)
            , [SupplierName] Varchar(50)
            , [PurchaseOrder] Varchar(30)
            , [Line] Int
            , [LineType] Varchar(200)
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [Warehouse] Varchar(10)
            , [OrderQty] Numeric(20 , 6)
            , [ReceivedQty] Numeric(20 , 6)
            , [QtyOutstanding] Numeric(20 , 6)
            , [MOrderUom] Varchar(10)
            , [LatestDueDate] Date
            , [OrigDueDate] Date
            , [LastReceiptDate] Date
            , [Price] Numeric(20 , 2)
            , [ForeignPrice] Numeric(20 , 2)
            , [DateReceived] Date
            , [QtyReceived] Numeric(20 , 6)
            , [PriceReceived] Numeric(20 , 2)
            , [RejectCode] Varchar(10)
            , [Reference] Varchar(30)
            , [CompleteFlag] Char(1)
            , [OrderStatus] Varchar(150)
            , [DebitRecGlCode] Varchar(35)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [CompanyName]
                , [Supplier]
                , [SupplierName]
                , [PurchaseOrder]
                , [Line]
                , [LineType]
                , [StockCode]
                , [StockDescription]
                , [Warehouse]
                , [OrderQty]
                , [ReceivedQty]
                , [QtyOutstanding]
                , [MOrderUom]
                , [LatestDueDate]
                , [OrigDueDate]
                , [LastReceiptDate]
                , [Price]
                , [ForeignPrice]
                , [DateReceived]
                , [QtyReceived]
                , [PriceReceived]
                , [RejectCode]
                , [Reference]
                , [CompleteFlag]
                , [OrderStatus]
                , [DebitRecGlCode]
                )
                Select  [PMD].[DatabaseName]
                      , [CN].[CompanyName]
                      , [PMH].[Supplier]
                      , [AS].[SupplierName]
                      , [PMD].[PurchaseOrder]
                      , [PMD].[Line]
                      , [LineType] = [PLT].[PorLineTypeDesc]
                      , [StockCode] = [PMD].[MStockCode]
                      , [StockDescription] = Coalesce([IM].[Description] ,
                                                      [PMD].[MStockDes])
                      , [Warehouse] = [PMD].[MWarehouse]
                      , [OrderQty] = [PMD].[MOrderQty]
                      , [ReceivedQty] = [PMD].[MReceivedQty]
                      , [QtyOutstanding] = Case When [PMD].[MCompleteFlag] = 'Y'
                                                Then Convert(Numeric(20 , 6) , 0)
                                                Else [PMD].[MOrderQty]
                                                     - [PMD].[MReceivedQty]
                                           End
                      , [PMD].[MOrderUom]
                      , [LatestDueDate] = Convert(Date , [PMD].[MLatestDueDate])
                      , [OrigDueDate] = Convert(Date , [PMD].[MOrigDueDate])
                      , [LastReceiptDate] = Convert(Date , [PMD].[MLastReceiptDat])
                      , [Price] = [PMD].[MPrice]
                      , [ForeignPrice] = [PMD].[MForeignPrice]
                      , [DateReceived] = Convert(Date , [PHR].[DateReceived])
                      , [PHR].[QtyReceived]
                      , [PHR].[PriceReceived]
                      , [RejectCode] = Case When [PHR].[RejectCode] = ''
                                            Then Null
                                            Else [PHR].[RejectCode]
                                       End
                      , [PHR].[Reference]
                      , [CompleteFlag] = Case When [PMD].[MCompleteFlag] = ''
                                              Then Null
                                              Else [PMD].[MCompleteFlag]
                                         End
                      , [OrderStatus] = [POS].[OrderStatusDescription]
                      , [GD].[DebitRecGlCode]
                From    [#PorMasterDetail] As [PMD]
                        Left Join [#PorHistReceipt] As [PHR] On [PHR].[PurchaseOrder] = [PMD].[PurchaseOrder]
                                                              And [PMD].[Line] = [PHR].[PurchaseOrderLin]
                                                              And [PHR].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [#PorMasterHdr] As [PMH] On [PMH].[PurchaseOrder] = [PHR].[PurchaseOrder]
                                                              And [PMH].[DatabaseName] = [PHR].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[PurchaseOrderStatus]
                        As [POS] On [POS].[OrderStatusCode] = [PMH].[OrderStatus]
                                    And [POS].[Company] = [PMH].[DatabaseName]
                        Left Join [#InvMaster] As [IM] On [IM].[StockCode] = [PMD].[MStockCode]
                                                          And [IM].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [#ApSupplier] As [AS] On [AS].[Supplier] = [PMH].[Supplier]
                                                           And [AS].[DatabaseName] = [PMH].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[PorLineType] As [PLT] On [PLT].[PorLineType] = [PMD].[LineType]
                        Left Join [#GrnDetails] As [GD] On [PHR].[Reference] = [GD].[Grn]
                                                           And [GD].[DatabaseName] = [PHR].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [PMD].[DatabaseName];


--return results
        Select  [DatabaseName]
              , [CompanyName]
              , [Supplier]
              , [SupplierName]
              , [PurchaseOrder]
              , [Line]
              , [LineType]
              , [StockCode]
              , [StockDescription]
              , [Warehouse]
              , [OrderQty]
              , [ReceivedQty]
              , [QtyOutstanding]
              , [MOrderUom]
              , [LatestDueDate]
              , [OrigDueDate]
              , [LastReceiptDate]
              , [Price]
              , [ForeignPrice]
              , [DateReceived]
              , [QtyReceived]
              , [PriceReceived]
              , [RejectCode]
              , [Reference]
              , [CompleteFlag]
              , [OrderStatus]
              , [GlCode] = [DebitRecGlCode]
              , [GLDescription] = [GM].[Description]
        From    [#Results]
                Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [DebitRecGlCode] = [GM].[GlCode]
                                                              And [DatabaseName] = [GM].[Company];

    End;

GO
