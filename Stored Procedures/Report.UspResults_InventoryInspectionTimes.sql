
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_InventoryInspectionTimes]
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
            @StoredProcName = 'UspResults_InventoryInspectionTimes' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'GrnDetails,InvInspect'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterDetail]
            (
              [DB] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [Line] Int
            , [MPrice] Numeric(20 , 2)
            );
        Create Table [#InvInspect]
            (
              [DB] Varchar(150)
            , [Lot] Varchar(50)
            , [Grn] Varchar(20)
            , [DeliveryDate] Date
            , [GrnReceiptDate] Date
            , [InspNarration] Varchar(100)
            , [ExpiryDate] Date
            , [StockCode] Varchar(30)
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyAccepted] Numeric(20 , 8)
            , [QtyScrapped] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [InspectCompleted] Char(1)
            , [Supplier] Varchar(15)
            , [PurchaseOrder] Varchar(20)
            , [PurchaseOrderLin] Int
            , [SupDelNote] Varchar(50)
            );
        Create Table [#InvInspectDet]
            (
              [DB] Varchar(150)
            , [TrnDate] Date
            , [Grn] Varchar(20)
            , [Lot] Varchar(50)
            , [TrnType] Char(1)
            );
        Create Table [#InvMaster]
            (
              [DB] Varchar(150)
            , [StockCode] Varchar(30)
            , [InspectionFlag] Char(1)
            , [TraceableType] Char(1)
            , [Description] Varchar(50)
            , [StockUom] Varchar(10)
            );

--create script to pull data from each db into the tables
        Declare @SQLGrnDetails Varchar(Max) = '
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
				Insert [#GrnDetails]
					( [DB]
					, [Grn]
					, [Supplier]
					, [OrigReceiptDate]
					, [PurchaseOrder]
					, [PurchaseOrderLin]
					, [StockCode]
					, [StockDescription]
					, [SupCatalogueNum]
					, [QtyReceived]
					, [QtyUom]
					)
			SELECT [DB]=@DBCode
				 , [GD].[Grn]
				 , [GD].[Supplier]
				 , [GD].[OrigReceiptDate]
				 , [GD].[PurchaseOrder]
				 , [GD].[PurchaseOrderLin]
				 , [GD].[StockCode]
				 , [GD].[StockDescription]
				 , [GD].[SupCatalogueNum]
				 , [GD].[QtyReceived]
				 , [GD].[QtyUom] FROM [GrnDetails] As [GD]
			End
	End';
        Declare @SQLInvInspect Varchar(Max) = '
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
				Insert [#InvInspect]
						( [DB]
						, [Lot]
						, [Grn]
						, [DeliveryDate]
						, [GrnReceiptDate]
						, [InspNarration]
						, [ExpiryDate]
						, [StockCode]
						, [QtyAdvised]
						, [QtyInspected]
						, [QtyAccepted]
						, [QtyScrapped]
						, [QtyRejected]
						, [InspectCompleted]
						)
				SELECT [DB]=@DBCode
					 , [II].[Lot]
					 , [II].[Grn]
					 , [II].[DeliveryDate]
					 , [II].[GrnReceiptDate]
					 , [II].[InspNarration]
					 , [II].[ExpiryDate]
					 , [II].[StockCode]
					 , [II].[QtyAdvised]
					 , [II].[QtyInspected]
					 , [II].[QtyAccepted]
					 , [II].[QtyScrapped]
					 , [II].[QtyRejected]
					 , [II].[InspectCompleted] FROM [InvInspect] As [II]
			End
	End';
        Declare @SQLInvMaster Varchar(Max) = '
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
				Insert [#InvMaster]
						( [DB]
						, [StockCode]
						, [InspectionFlag]
						, [TraceableType]
						)
				SELECT [DB]=@DBCode
					 , [IM].[StockCode]
					 , [IM].[InspectionFlag] 
					 , [TraceableType]
				FROM [InvMaster] As [IM]
			End
	End';
        Declare @SQLInvInspectDet Varchar(Max) = '
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
				Insert [#InvInspectDet]
						( [DB]
						, [TrnDate]
						, [Grn]
						, [Lot]
						, [TrnType]
						)
				SELECT [DB]=@DBCode
					 , [IID].[TrnDate]
					 , [IID].[Grn]
					 , [IID].[Lot]
					 , [IID].[TrnType] FROM [InvInspectDet] As [IID]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLGrnDetails;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvInspect;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvInspectDet;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;

--define the results you want to return
        Create Table [#Results]
            (
              [Grn] Varchar(20)
            , [Lot] Varchar(50)
            , [Supplier] Varchar(15)
            , [OrigReceiptDate] Date
            , [PurchaseOrder] Varchar(20)
            , [PurchaseOrderLine] Int
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [SupCatalogueNum] Varchar(50)
            , [QtyUom] Varchar(10)
            , [DeliveryDate] Date
            , [GrnReceiptDate] Date
            , [SupplierLot] Varchar(100)
            , [ExpiryDate] Date
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyAccepted] Numeric(20 , 8)
            , [QtyScrapped] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [InspectCompleted] Char(1)
            , [TrnDate] Date
            , [WorkingDaysToApprove] Int
            , [DatabaseName] Varchar(150)
            , [Price] Numeric(20 , 2)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Grn]
                , [Lot]
                , [Supplier]
                , [OrigReceiptDate]
                , [PurchaseOrder]
                , [PurchaseOrderLine]
                , [StockCode]
                , [StockDescription]
                , [SupCatalogueNum]
                , [QtyUom]
                , [DeliveryDate]
                , [GrnReceiptDate]
                , [SupplierLot]
                , [ExpiryDate]
                , [QtyAdvised]
                , [QtyInspected]
                , [QtyAccepted]
                , [QtyScrapped]
                , [QtyRejected]
                , [InspectCompleted]
                , [TrnDate]
                , [WorkingDaysToApprove]
                , [DatabaseName]
                , [Price]
                )
                Select  [II].[Grn]
                      , [II].[Lot]
                      , [II].[Supplier]
                      , [II].[DeliveryDate]
                      , [II].[PurchaseOrder]
                      , [II].[PurchaseOrderLin]
                      , [II].[StockCode]
                      , [IM].[Description]
                      , [II].[SupDelNote]
                      , [IM].[StockUom]
                      , [II].[DeliveryDate]
                      , [II].[GrnReceiptDate]
                      , [SupplierLot] = [II].[InspNarration]
                      , [II].[ExpiryDate]
                      , [II].[QtyAdvised]
                      , [II].[QtyInspected]
                      , [II].[QtyAccepted]
                      , [II].[QtyScrapped]
                      , [II].[QtyRejected]
                      , [InspectCompleted] = Case When Coalesce([II].[InspectCompleted] ,
                                                              '') = ''
                                                  Then 'N'
                                                  Else [II].[InspectCompleted]
                                             End
                      , [IID].[TrnDate]
                      , [WorkingDaysToApprove] = [BlackBox].[Process].[Udf_WorkingDays]([II].[DeliveryDate] ,
                                                              Coalesce([IID].[TrnDate] ,
                                                              GetDate()) ,
                                                              'UK')
                      , [II].[DB]
                      , [PMD].[MPrice]
                From    [#InvInspect] As [II]
                        Left Join [#InvInspectDet] As [IID] On [IID].[Grn] = [II].[Grn]
                                                              And [IID].[Lot] = [II].[Lot]
                                                              And [IID].[TrnType] = 'A'
                                                              And [IID].[DB] = [II].[DB]
                        Left Join [#InvMaster] As [IM] On [IM].[StockCode] = [II].[StockCode]
                                                          And [IM].[DB] = [II].[DB]
                        Left Join [#PorMasterDetail] As [PMD] On [PMD].[PurchaseOrder] = [II].[PurchaseOrder]
                                                              And [PMD].[Line] = [II].[PurchaseOrderLin]
                                                              And [PMD].[DB] = [II].[DB]
                Where   [IM].[InspectionFlag] = 'Y'
                        And [IM].[TraceableType] = 'T';
--return results
        Select  [CN].[CompanyName]
              , [R].[Grn]
              , [R].[Lot]
              , [R].[Supplier]
              , [R].[OrigReceiptDate]
              , [R].[PurchaseOrder]
              , [R].[PurchaseOrderLine]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[SupCatalogueNum]
              , [R].[Price]
              , [R].[QtyUom]
              , [R].[DeliveryDate]
              , [R].[GrnReceiptDate]
              , [R].[SupplierLot]
              , [R].[ExpiryDate]
              , [R].[QtyAdvised]
              , [R].[QtyInspected]
              , [R].[QtyAccepted]
              , [R].[QtyScrapped]
              , [R].[QtyRejected]
              , [R].[InspectCompleted]
              , [CompletedDate] = [R].[TrnDate]
              , [R].[WorkingDaysToApprove]
              , [ReportStatus] = Case When [R].[InspectCompleted] = 'N'
                                      Then 'Still awaiting inspection'
                                      When [R].[WorkingDaysToApprove] <= 1
                                      Then '1 day or less'
                                      When [R].[WorkingDaysToApprove] <= 5
                                      Then '5 days or less'
                                      When [R].[WorkingDaysToApprove] <= 10
                                      Then '10 days or less'
                                      When [R].[WorkingDaysToApprove] <= 15
                                      Then '15 days or less'
                                      Else 'More than 15 days'
                                 End
              , [DeliveryYear] = Year([R].[DeliveryDate])
              , [DeliveryMonth] = Month([R].[DeliveryDate])
              , [DeliveryQuarter] = Ceiling(Month([R].[DeliveryDate]) / 3.0)
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] As [CN] On [CN].[Company] = [R].[DatabaseName];

    End;

GO
