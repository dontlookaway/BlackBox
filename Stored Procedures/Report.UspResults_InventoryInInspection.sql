
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
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvInspect]
            (
              [DatabaseName] Varchar(150)
            , [Grn] Varchar(20)
            , [Lot] Varchar(50)
            , [InspNarration] Varchar(100)
            , [StockCode] Varchar(30)
            , [PurchaseOrder] Varchar(20)
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [InspectCompleted] Char(1)
            , [DeliveryDate] Date
            , [PurchaseOrderLin] Int
            );
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)
            , [MOrderUom] Varchar(10)
            , [PurchaseOrder] Varchar(20)
            , [Line] Int
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [StockCode] Varchar(30)
            , [Description] Varchar(50)
            );


--create script to pull data from each db into the tables
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
					 , [II].[PurchaseOrderLin] FROM [InvInspect] As [II]
			End
	End';
        Declare @SQLPorMasterDetail Varchar(Max) = '
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
				Insert [#PorMasterDetail]
						( [DatabaseName]
						, [MOrderUom]
						, [PurchaseOrder]
						, [Line]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMD].[MOrderUom]
					 , [PMD].[PurchaseOrder]
					 , [PMD].[Line] FROM [PorMasterDetail] As [PMD]
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
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvInspect;
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasterDetail;
		Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Grn] Varchar(20)
            , [Lot] Varchar(50)
            , [InspNarration] Varchar(100)
            , [StockCode] Varchar(30)
            , [PurchaseOrder] Varchar(20)
            , [QtyAdvised] Numeric(20 , 8)
            , [QtyInspected] Numeric(20 , 8)
            , [QtyRejected] Numeric(20 , 8)
            , [MOrderUom] Varchar(10)
            , [InspectCompleted] Char(1)
            , [DeliveryDate] Date
            , [StockDescription] Varchar(50)
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
                , [MOrderUom]
                , [InspectCompleted]
                , [DeliveryDate]
                , [StockDescription] 
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
                      , [PMD].[MOrderUom]
                      , [II].[InspectCompleted]
                      , [II].[DeliveryDate]
                      , [IM].[Description]
                From    [#InvInspect] As [II]
                        Left  Join [#PorMasterDetail] As [PMD] On [PMD].[PurchaseOrder] = [II].[PurchaseOrder]
                                                              And [PMD].[Line] = [II].[PurchaseOrderLin]
                        Left Join [#InvMaster] As [IM] On [IM].[StockCode] = [II].[StockCode]
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
              , [R].[MOrderUom]
              , [R].[InspectCompleted]
              , [R].[DeliveryDate]
              , [R].[StockDescription]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] As [CN] On [R].[DatabaseName] = [CN].[Company];

    End;

GO
