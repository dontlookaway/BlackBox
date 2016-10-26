SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_InventoryInInspection]
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
            @StoredProcName = 'UspResults_InventoryInInspection' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvInspect,InvMaster,PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvInspect]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Grn] Varchar(20) Collate Latin1_General_BIN
            , [Lot] Varchar(50) Collate Latin1_General_BIN
            , [InspNarration] Varchar(100) Collate Latin1_General_BIN
            , [StockCode] Varchar(30) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20) Collate Latin1_General_BIN
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [InspectCompleted] Char(1) Collate Latin1_General_BIN
            , [DeliveryDate] Date
            , [PurchaseOrderLin] Int
            , [GrnReceiptDate] Date
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [MStockingUom] Varchar(10) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20) Collate Latin1_General_BIN
            , [Line] Int
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [StockCode] Varchar(30) Collate Latin1_General_BIN
            , [Description] Varchar(50) Collate Latin1_General_BIN
            );


--create script to pull data from each db into the tables
        Declare @SQLInvInspect Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#InvInspect]
						( [DatabaseName]
						, [Grn]
						, [Lot]
						, [InspNarration]
						, [StockCode]
						, [PurchaseOrder]
						, [QtyAdvised]
						, [QtyInspected]
						, [QtyRejected]
						, [InspectCompleted]
						, [DeliveryDate]
						, [PurchaseOrderLin]
						, [GrnReceiptDate]
						)
				SELECT [DatabaseName]=@DBCode
					 , [II].[Grn]
					 , [II].[Lot]
					 , [II].[InspNarration]
					 , [II].[StockCode]
					 , [II].[PurchaseOrder]
					 , [II].[QtyAdvised]
					 , [II].[QtyInspected]
					 , [II].[QtyRejected]
					 , [II].[InspectCompleted]
					 , [II].[DeliveryDate]
					 , [II].[PurchaseOrderLin] 
					 , [II].[GrnReceiptDate]
				FROM [InvInspect] As [II]
			End
	End';
        Declare @SQLPorMasterDetail Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#PorMasterDetail]
						( [DatabaseName]
						, [MStockingUom]
						, [PurchaseOrder]
						, [Line]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMD].[MStockingUom]
					 , [PMD].[PurchaseOrder]
					 , [PMD].[Line] 
				FROM [PorMasterDetail] As [PMD]
			End
	End';
        Declare @SQLInvMaster Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#InvMaster]
						( [DatabaseName]
						, [StockCode]
						, [Description]
						)
				SELECT [DatabaseName]=@DBCode
					 , [IM].[StockCode]
					 , [IM].[Description] FROM [InvMaster] As [IM]
			End
	End';


--Enable this function to check script changes (try to run script directly against db manually)

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvInspect ,
            @SchemaTablesToCheck = @ListOfTables; 

        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLPorMasterDetail , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;

        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvMaster , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Grn] Varchar(20) Collate Latin1_General_BIN
            , [Lot] Varchar(50) Collate Latin1_General_BIN
            , [InspNarration] Varchar(100) Collate Latin1_General_BIN
            , [StockCode] Varchar(30) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(20) Collate Latin1_General_BIN
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [MStockingUom] Varchar(10) Collate Latin1_General_BIN
            , [InspectCompleted] Char(1) Collate Latin1_General_BIN
            , [DeliveryDate] Date
            , [StockDescription] Varchar(50) Collate Latin1_General_BIN
            , [ReceiptDate] Date
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Grn]
                , [Lot]
                , [InspNarration]
                , [StockCode]
                , [PurchaseOrder]
                , [QtyAdvised]
                , [QtyInspected]
                , [QtyRejected]
                , [MStockingUom]
                , [InspectCompleted]
                , [DeliveryDate]
                , [StockDescription]
                , [ReceiptDate] 
                )
                Select  [II].[DatabaseName]
                      , [II].[Grn]
                      , [II].[Lot]
                      , [II].[InspNarration]
                      , [II].[StockCode]
                      , [II].[PurchaseOrder]
                      , [II].[QtyAdvised]
                      , [II].[QtyInspected]
                      , [II].[QtyRejected]
                      , [PMD].[MStockingUom]
                      , [II].[InspectCompleted]
                      , [II].[DeliveryDate]
                      , [IM].[Description]
                      , [ReceiptDate] = [II].[GrnReceiptDate]
                From    [#InvInspect] As [II]
                        Left  Join [#PorMasterDetail] As [PMD]
                            On [PMD].[PurchaseOrder] = [II].[PurchaseOrder]
                               And [PMD].[Line] = [II].[PurchaseOrderLin]
                        Left Join [#InvMaster] As [IM]
                            On [IM].[StockCode] = [II].[StockCode]
                               And [IM].[DatabaseName] = [II].[DatabaseName]
                Where   Coalesce([II].[InspectCompleted] , 'N') <> 'Y';

--return results
        Select  [R].[DatabaseName]
              , [CN].[CompanyName]
              , [Grn] = Case When IsNumeric([R].[Grn]) = 1
                             Then Convert(Varchar(20) , Convert(Int , [R].[Grn]))
                             Else [R].[Grn]
                        End
              , [Lot] = Case When IsNumeric([R].[Lot]) = 1
                             Then Convert(Varchar(20) , Convert(Int , [R].[Lot]))
                             Else [R].[Lot]
                        End
              , [R].[InspNarration]
              , [R].[StockCode]
              , [PurchaseOrder] = Case When IsNumeric([R].[PurchaseOrder]) = 1
                                       Then Convert(Varchar(20) , Convert(Int , [R].[PurchaseOrder]))
                                       Else [R].[PurchaseOrder]
                                  End
              , [R].[QtyAdvised]
              , [R].[QtyInspected]
              , [R].[QtyRejected]
              , [MOrderUom] = [R].[MStockingUom]
              , [R].[InspectCompleted]
              , [R].[DeliveryDate]
              , [R].[StockDescription]
              , [R].[ReceiptDate]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] As [CN]
                    On [R].[DatabaseName] = [CN].[Company];

    End;

GO
