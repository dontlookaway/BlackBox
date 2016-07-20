SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LotTraceability_WithRuntimes]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_LotTraceability_WithRuntimes' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvInspect,LotTransactions,InvMaster,ArCustomer,WipLabJnl'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvInspect]
            (
              [DatabaseName] Varchar(150)
            , [InspNarration] Varchar(100)
            , [Lot] Varchar(50)
            , [GrnReceiptDate] Date
            , [StockCode] Varchar(30)
            , [TotalReceiptQty] Numeric(20 , 8)
            );
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)
            , [Lot] Varchar(50)
            , [StockCode] Varchar(30)
            , [TrnDate] Date
            , [Warehouse] Varchar(10)
            , [Bin] Varchar(20)
            , [Job] Varchar(20)
            , [Reference] Varchar(30)
            , [UnitCost] Numeric(20 , 2)
            , [TrnQuantity] Numeric(20 , 8)
            , [TrnValue] Numeric(20 , 8)
            , [TrnType] Char(1)
            , [JobPurchOrder] Varchar(20)
            , [Customer] Varchar(15)
            , [Source] Char(1)
            , [SalesOrder] Varchar(20)
            , [Bucket] Int
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [Description] Varchar(50)
            , [StockUom] Varchar(20)
            , [StockCode] Varchar(30)
            );
        Create Table [#ArCustomer]
            (
              [DatabaseName] Varchar(150)
            , [Customer] Varchar(15)
            , [Name] Varchar(50)
            );
        Create Table [#WipLabJnl]
            (
              [DatabaseName] Varchar(150)
            , [RunTime] Numeric(20 , 6)
            , [Job] Varchar(20)
            );
        Create Table [#Labour]
            (
              [Lot] Varchar(50)
            , [JobPurchOrder] Varchar(20)
            , [RunTime] Numeric(20 , 5)
            , [DatabaseName] Varchar(150)
            , [TotalLots] Int
            );

--create script to pull data from each db into the tables
        Declare @SQLInvInspect Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company)
            + ''' = ''ALL''
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
							, [II].[TotalReceiptQty] 
					FROM [InvInspect] As [II]
			End
	End';
        Declare @SQLLotTransactions Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company)
            + ''' = ''ALL''
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
					, [Customer]
					, [Source]
					, [SalesOrder]
					, [Bucket]
					)
				SELECT 
					@DBCode
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
					, [LT].Customer 
					, [LT].[Source]
					, [LT].[SalesOrder]
					, [LT].[Bucket]
				FROM [LotTransactions] As [LT]
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
				SELECT 
						@DBCode
						, [IM].[Description]
						, [IM].[StockUom]
						, [IM].[StockCode] 
				FROM [InvMaster] As [IM]
			End
	End';
        Declare @SQLArCustomer Varchar(Max) = 'USE [?];
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
        Declare @SQLWipLabJnl Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#WipLabJnl]
						( [DatabaseName] , [RunTime] , [Job] )
				SELECT @DBCode
					 , [WLJ].[RunTime]
					 , [WLJ].[Job] 
				FROM [WipLabJnl] [WLJ]
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvInspect ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvMaster ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLLotTransactions ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLArCustomer ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLWipLabJnl ,
            @SchemaTablesToCheck = @ListOfTables;

--define the results to return
        Create Table [#Results]
            (
              [Company] Varchar(300)
            , [SupplierLotNumber] Varchar(100)
            , [Lot] Varchar(50)
            , [GrnReceiptDate] Date
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [TrnDate] Date
            , [Warehouse] Varchar(10)
            , [Bin] Varchar(20)
            , [Job] Varchar(20)
            , [TrnTypeDescription] Varchar(100)
            , [Reference] Varchar(30)
            , [TotalReceiptQty] Numeric(20 , 8)
            , [StockUom] Varchar(20)
            , [UnitCost] Numeric(20 , 2)
            , [TrnQuantity] Numeric(20 , 8)
            , [TrnValue] Numeric(20 , 2)
            , [MasterJob] Varchar(30)
            , [CustomerName] Varchar(50)
            , [TranRank] Int
            );

--Placeholder to create indexes as required
        Create Table [#LotMasterJob]
            (
              [Lot] Varchar(50)
            , [MasterJob] Varchar(30)
            , [TempLot] Varchar(50)
            , [DatabaseName] Varchar(150)
            );

        Insert  [#LotMasterJob]
                ( [Lot]
                , [MasterJob]
                , [DatabaseName]
                )
                Select Distinct
                        [LT].[Lot]
                      , [LT].[JobPurchOrder]
                      , [LT].[DatabaseName]
                From    [#LotTransactions] As [LT]
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

		--List of work
        Insert  [#Labour]
                ( [Lot]
                , [JobPurchOrder]
                , [RunTime]
                , [DatabaseName]
                )
                Select  [Lot] = Case When IsNumeric([lt].[Lot]) = 1
                                     Then Convert(Varchar(50) , Convert(Int , [lt].[Lot]))
                                     Else [lt].[Lot]
                                End
                      , [lt].[JobPurchOrder]
                      , [RunTime] = Sum([wlj].[RunTime])
                      , [lt].[DatabaseName]
                From    ( Select Distinct
                                    [Lot]
                                  , [JobPurchOrder]
                                  , [DatabaseName]
                          From      [#LotTransactions]
                          Where     [Source] = 'J'
                        ) As [lt]
                        Left Join [#WipLabJnl] As [wlj]
                            On [wlj].[Job] = [lt].[JobPurchOrder]
                               And [wlj].[DatabaseName] = [lt].[DatabaseName]
                Group By [lt].[Lot]
                      , [lt].[JobPurchOrder]
                      , [lt].[DatabaseName];

        Update  [#Labour]
        Set     [TotalLots] = [TL]
        From    [#Labour] As [l2]
                Left Join ( Select  [l].[JobPurchOrder]
                                  , [l].[DatabaseName]
                                  , [TL] = Count(Distinct [l].[Lot])
                            From    [#Labour] As [l]
                            Group By [l].[JobPurchOrder]
                                  , [l].[DatabaseName]
                          ) [t]
                    On [t].[JobPurchOrder] = [l2].[JobPurchOrder]
                       And [t].[DatabaseName] = [l2].[DatabaseName];

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
                , [TranRank]
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
                      , [LT].[TrnQuantity] * [TTAM].[AmountModifier]
                      , [LT].[TrnValue]
                      , [MasterJob] = Case When IsNumeric([LMJ].[MasterJob]) = 1
                                           Then Convert(Varchar(30) , Convert(Int , [LMJ].[MasterJob]))
                                           Else [LMJ].[MasterJob]
                                      End
                      , [CustomerName] = [AC].[Name]
                      , [TranRank] = Dense_Rank() Over ( Partition By [LT].[Lot] Order By [LT].[TrnDate] Asc, [LT].[SalesOrder] Asc, [LT].[Bucket] Asc )
                From    [#InvInspect] As [II]
                        Full Outer Join [#LotTransactions] As [LT]
                            On [LT].[Lot] = [II].[Lot]
                               And [LT].[DatabaseName] = [II].[DatabaseName]
                        Left Join [#InvMaster] As [IM]
                            On Coalesce([II].[StockCode] , [LT].[StockCode]) = [IM].[StockCode]
                               And Coalesce([II].[DatabaseName] ,
                                            [LT].[DatabaseName]) = [IM].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[LotTransactionTrnType] [LTT]
                            On [LT].[TrnType] = [LTT].[TrnType]
                        Left Join [#LotMasterJob] As [LMJ]
                            On [LMJ].[Lot] = [LT].[Lot]
                               And [LMJ].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [#ArCustomer] As [AC]
                            On [AC].[Customer] = [LT].[Customer]
                               And [AC].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [Lookups].[TrnTypeAmountModifier] [TTAM]
                            On [TTAM].[TrnType] = [LT].[TrnType]
                               And [TTAM].[Company] = [LT].[DatabaseName]
                Where   Coalesce([II].[Lot] , [LT].[Lot] , '') <> ''
                Order By [SupplierLotNumber] Desc
                      , Case When IsNumeric(Coalesce([II].[Lot] , [LT].[Lot])) = 1
                             Then Convert(Varchar(50) , Convert(Int , Coalesce([II].[Lot] ,
                                                              [LT].[Lot])))
                             Else Coalesce([II].[Lot] , [LT].[Lot])
                        End Asc
                      , [LT].[TrnDate];

        Set NoCount Off;
--return results
        Select  [CN].[CompanyName]
              , [CN].[ShortName]
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
              , [RunTime] = Coalesce([L].[RunTime] , 0)
        From    [#Results] As [R]
                Left Join [Lookups].[CompanyNames] As [CN]
                    On [CN].[Company] = [R].[Company]
                Left Join [Lookups].[Warehouse] As [W]
                    On [W].[Warehouse] = [R].[Warehouse]
                       And [W].[Company] = [R].[Company]
                Left Join [#Labour] [L]
                    On [L].[JobPurchOrder] = [R].[MasterJob]
                       And [L].[Lot] = [R].[Lot]
                       And [L].[DatabaseName] = [R].[Company];
                       --And [R].[TranRank] = 1
        /*Where   [R].[TrnTypeDescription] In ( 'Receipt of lot qty' ,
                                              'Issue to a job' ,
                                              'Transfer of lot qty' ,
                                              'Adjustment to lot qty' ,
                                              'Dispatch note' );*/

        Select  *
        From    [#Labour] [L];

        Select  *
        From    [#Results] [R];
    End;
GO
