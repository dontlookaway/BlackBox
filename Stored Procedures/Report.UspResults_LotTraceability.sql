SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LotTraceability]
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
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_LotTraceability' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--remove nocount on to speed up query
        Set NoCount On;



--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'MdnMasterRep,WipMaster,CusSorMaster+'; 

--create temporary tables to be pulled from different databases, including a column to id
--[#InvInspect][#LotTransactions][#InvMaster]
        Create Table [#InvInspect]
            (
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [InspNarration] Varchar(100)			collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [GrnReceiptDate] Date					
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [TotalReceiptQty] Numeric(20 , 8)		
            );										
        Create Table [#LotTransactions]				
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [TrnDate] Date						
            , [Warehouse] Varchar(10)				collate latin1_general_bin
            , [Bin] Varchar(20)						collate latin1_general_bin
            , [Job] Varchar(20)						collate latin1_general_bin
            , [Reference] Varchar(30)				collate latin1_general_bin
            , [UnitCost] Numeric(20 , 2)			
            , [TrnQuantity] Numeric(20 , 8)			
            , [TrnValue] Numeric(20 , 8)			
            , [TrnType] Char(1)						collate latin1_general_bin
            , [JobPurchOrder] Varchar(20)			collate latin1_general_bin
            , [Customer] Varchar(15)				collate latin1_general_bin
            );										
        Create Table [#InvMaster]					
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Description] Varchar(50)				collate latin1_general_bin
            , [StockUom] Varchar(20)				collate latin1_general_bin
            , [StockCode] Varchar(30)				collate latin1_general_bin
            );										
        Create Table [#ArCustomer]					
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Customer] Varchar(15)				collate latin1_general_bin
            , [Name] Varchar(50)					collate latin1_general_bin
            );										
        Create Table [#WipMaster]					
            (										
              [DatabaseName] Varchar(150)			collate latin1_general_bin
            , [Job] Varchar(20)						collate latin1_general_bin
            , [ActCompleteDate] Date				
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
	        , [InspNarration]
	        , [Lot]
	        , [GrnReceiptDate]
	        , [StockCode]
	        , [TotalReceiptQty]
	        )
				SELECT @DBCode
			, InspNarration = Case When [II].[InspNarration] = ''''
								Then Null
								Else [II].[InspNarration]
							End
			, [II].[Lot]
			, [II].[GrnReceiptDate]
			, [II].[StockCode]
			, [II].[TotalReceiptQty] FROM [InvInspect] As [II]
			End
	End';
        Declare @SQLLotTransactions Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#LotTransactions]
		        ( [DatabaseName]
		        , [Lot]
		        , [StockCode]
		        , [TrnDate]
		        , [Warehouse]
		        , [Bin]
		        , [Job]
		        , [Reference]
		        , [UnitCost]
		        , [TrnQuantity]
		        , [TrnValue]
				, TrnType
				, [JobPurchOrder]
				, Customer
		        )
				SELECT @DBCode
					 , [LT].[Lot]
				 , [LT].[StockCode]
				 , [LT].[TrnDate]
				 , [LT].[Warehouse]
				 , [LT].[Bin]
				 , [Job] = Case When [LT].[Job] = '''' Then Null
								 Else [LT].[Job]
							End
				 , [Reference] = Case When [LT].[Reference] = '''' Then Null
									   Else [LT].[Reference]
								  End
				 , [LT].[UnitCost]
				 , [LT].[TrnQuantity]
				 , [LT].[TrnValue]
				 , [LT].TrnType 
				 , [LT].[JobPurchOrder]
				 , [LT].Customer FROM [LotTransactions] As [LT]
			End
	End';
        Declare @SQLInvMaster Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#InvMaster]
		        ( [DatabaseName]
		        , [Description]
		        , [StockUom]
		        , [StockCode]
		        )
				SELECT @DBCode
				, [IM].[Description]
				, [IM].[StockUom]
				, [IM].[StockCode] FROM [InvMaster] As [IM]
			End
	End';
        Declare @SQLArCustomer Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert  [#ArCustomer]
						( [DatabaseName]
						, [Customer]
						, [Name]
						)
				Select  @DBCode
					  , [AC].[Customer]
					  , [AC].[Name]
				From    [ArCustomer] As [AC];
			End
	End';
        Declare @SQLWipMaster Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#WipMaster]
			        ( [DatabaseName]
			        , [Job]
			        , [ActCompleteDate]
			        )
				Select  @DBCode
					,[WM].[Job]
					,[WM].[ActCompleteDate]
					From    [WipMaster] [WM];
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvInspect , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvMaster , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLLotTransactions , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLArCustomer , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLWipMaster ,
            @SchemaTablesToCheck = @ListOfTables;
		

--define the results you want to return
        Create Table [#Results]
            (
              [Company] Varchar(300)				collate latin1_general_bin
            , [SupplierLotNumber] Varchar(100)		collate latin1_general_bin
            , [Lot] Varchar(50)						collate latin1_general_bin
            , [GrnReceiptDate] Date					
            , [StockCode] Varchar(30)				collate latin1_general_bin
            , [StockDescription] Varchar(50)		collate latin1_general_bin
            , [TrnDate] Date						
            , [Warehouse] Varchar(10)				collate latin1_general_bin
            , [Bin] Varchar(20)						collate latin1_general_bin
            , [Job] Varchar(20)						collate latin1_general_bin
            , [TrnTypeDescription] Varchar(100)		collate latin1_general_bin
            , [Reference] Varchar(30)				collate latin1_general_bin
            , [TotalReceiptQty] Numeric(20 , 8)		
            , [StockUom] Varchar(20)				collate latin1_general_bin
            , [UnitCost] Numeric(20 , 2)			
            , [TrnQuantity] Numeric(20 , 8)			
            , [TrnValue] Numeric(20 , 2)			
            , [MasterJob] Varchar(30)				collate latin1_general_bin
            , [CustomerName] Varchar(50)			collate latin1_general_bin
            , [MasterJobDate] Date
            );

--Placeholder to create indexes as required
        Create Table [#LotMasterJob]
            (
              [Lot] Varchar(50)
            , [MasterJob] Varchar(30)
            , [TempLot] Varchar(50)
            , [ActCompleteDate] Date
            );

        Insert  [#LotMasterJob]
                ( [Lot]
                , [MasterJob]
                , [ActCompleteDate]
                )
                Select Distinct
                        [LT].[Lot]
                      , [LT].[JobPurchOrder]
                      , [WM].[ActCompleteDate]
                From    [#LotTransactions] As [LT]
                        Left Join [#WipMaster] [WM]
                            On [WM].[DatabaseName] = [LT].[DatabaseName]
                               And [WM].[Job] = [LT].[JobPurchOrder]
                Where   [LT].[TrnType] = 'R'
                        And [LT].[Reference] <> '';

        Create Index [LMJ] On [#LotMasterJob] ([Lot]);

		--get the lot that was issued to a kitting job
        Update  [#LotMasterJob]
        Set     [TempLot] = [LT].[Lot]
        From    [#LotMasterJob] [LMJ]
                Left Join [#LotTransactions] [LT]
                    On [LMJ].[MasterJob] = [LT].[Job]
        Where   [LMJ].[MasterJob] Like 'KN%'
                And [LT].[TrnType] = 'I';

		--use the lot that was issued to update the master job
        Update  [LMJ]
        Set     [LMJ].[MasterJob] = [LMJ2].[MasterJob]
        From    [#LotMasterJob] [LMJ]
                Left Join [#LotMasterJob] [LMJ2]
                    On [LMJ2].[Lot] = [LMJ].[TempLot]
        Where   [LMJ].[TempLot] Is Not Null;


--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Company]
                , [SupplierLotNumber]
                , [Lot]
                , [GrnReceiptDate]
                , [StockCode]
                , [StockDescription]
                , [TrnDate]
                , [Warehouse]
                , [Bin]
                , [Job]
                , [TrnTypeDescription]
                , [Reference]
                , [TotalReceiptQty]
                , [StockUom]
                , [UnitCost]
                , [TrnQuantity]
                , [TrnValue]
                , [MasterJob]
                , [CustomerName]
                , [MasterJobDate]
                )
                Select  [Company] = Coalesce([II].[DatabaseName] ,
                                             [LT].[DatabaseName])
                      , [SupplierLotNumber] = [II].[InspNarration]
                      , [Lot] = Case When IsNumeric(Coalesce([II].[Lot] ,
                                                             [LT].[Lot])) = 1
                                     Then Convert(Varchar(50) , Convert(Int , Coalesce([II].[Lot] ,
                                                              [LT].[Lot])))
                                     Else Coalesce([II].[Lot] , [LT].[Lot])
                                End
                      , [II].[GrnReceiptDate]
                      , [StockCode] = Coalesce([II].[StockCode] ,
                                               [LT].[StockCode])
                      , [StockDescription] = [IM].[Description]
                      , [TrnDate] = [LT].[TrnDate]
                      , [LT].[Warehouse]
                      , [LT].[Bin]
                      , [Job] = [LT].[Job]
                      , [TransactionType] = [LTT].[TrnTypeDescription]
                      , [Reference] = [LT].[Reference]
                      , [II].[TotalReceiptQty]
                      , [IM].[StockUom]
                      , [LT].[UnitCost]
                      , [TrnQuantity] = [LT].[TrnQuantity]
                        * [TTAM].[AmountModifier]
                      , [LT].[TrnValue]
                      , [MasterJob] = Case When IsNumeric([LMJ].[MasterJob]) = 1
                                           Then Convert(Varchar(30) , Convert(Int , [LMJ].[MasterJob]))
                                           Else [LMJ].[MasterJob]
                                      End
                      , [CustomerName] = [AC].[Name]
                      , [MasterJobDate] = [LMJ].[ActCompleteDate]
                From    [#InvInspect] As [II]
                        Full Outer Join [#LotTransactions] As [LT]
                            On [LT].[Lot] = [II].[Lot]
                                                              --And [LT].[StockCode] = [II].[StockCode]
                               And [LT].[DatabaseName] = [II].[DatabaseName]
                        Left Join [#InvMaster] As [IM]
                            On Coalesce([II].[StockCode] , [LT].[StockCode]) = [IM].[StockCode]
                               And Coalesce([II].[DatabaseName] ,
                                            [LT].[DatabaseName]) = [IM].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[LotTransactionTrnType] [LTT]
                            On [LT].[TrnType] = [LTT].[TrnType]
                        Left Join [Lookups].[TrnTypeAmountModifier] [TTAM]
                            On [LT].[DatabaseName] = [TTAM].[Company]
                               And [TTAM].[TrnType] = [LT].[TrnType]
                        Left Join [#LotMasterJob] As [LMJ]
                            On [LMJ].[Lot] = [LT].[Lot]
                        Left Join [#ArCustomer] As [AC]
                            On [AC].[Customer] = [LT].[Customer]
                               And [AC].[DatabaseName] = [LT].[DatabaseName]
                Where   Coalesce([II].[Lot] , [LT].[Lot] , '') <> ''
                Order By [SupplierLotNumber] Desc
                      , Case When IsNumeric(Coalesce([II].[Lot] , [LT].[Lot])) = 1
                             Then Convert(Varchar(50) , Convert(Int , Coalesce([II].[Lot] ,
                                                              [LT].[Lot])))
                             Else Coalesce([II].[Lot] , [LT].[Lot])
                        End Asc
                      , [LT].[TrnDate];


--return results

        Set NoCount Off;
        Select  [CN].[CompanyName]
              , [R].[Company]
              , [R].[SupplierLotNumber]
              , [R].[Lot]
              , [R].[GrnReceiptDate]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[TrnDate]
              , [Warehouse] = [W].[WarehouseDescription]
              , [R].[Bin]
              , [R].[Job]
              , [TransactionType] = [R].[TrnTypeDescription]
              , [R].[Reference]
              , [R].[TotalReceiptQty]
              , [R].[StockUom]
              , [R].[UnitCost]
              , [R].[TrnQuantity]
              , [R].[TrnValue]
              , [R].[MasterJob]
              , [R].[CustomerName]
              , [R].[MasterJobDate]
        From    [#Results] As [R]
                Left Join [Lookups].[CompanyNames] As [CN]
                    On [CN].[Company] = [R].[Company]
                Left Join [Lookups].[Warehouse] As [W]
                    On [W].[Warehouse] = [R].[Warehouse]
                       And [W].[Company] = [R].[Company];

    End;
GO
