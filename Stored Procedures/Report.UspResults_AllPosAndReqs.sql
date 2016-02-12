SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AllPosAndReqs]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group February 2016
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
            @StoredProcName = 'UspResults_AllPosAndReqs' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'AssetDepreciation,TblApTerms'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)
            , [MRequisition] Varchar(50)
            , [PurchaseOrder] Varchar(50)
            , [Line] Int
            , [MStockCode] Varchar(50)
            , [MStockDes] Varchar(200)
            , [MOrderQty] Numeric(20 , 8)
            , [MPriceUom] Varchar(10)
            , [MLatestDueDate] Date
            , [MSupCatalogue] Varchar(50)
            , [MPrice] Numeric(20 , 2)
            , [MForeignPrice] Numeric(20 , 2)
            , [MGlCode] Varchar(100)
            , [MCompleteFlag] Char(1)
            , [MProductClass] Varchar(20)
            );
        Create Table [#ReqDetail]
            (
              [DatabaseName] Varchar(150)
            , [Requisition] Varchar(50)
            , [Line] Int
            , [StockCode] Varchar(50)
            , [StockDescription] Varchar(200)
            , [OrderQty] Numeric(20 , 8)
            , [OrderUom] Varchar(10)
            , [DueDate] Date
            , [SupCatalogueNum] Varchar(50)
            , [Price] Numeric(20 , 2)
            , [GlCode] Varchar(100)
            , [Originator] Varchar(100)
            , [Buyer] Varchar(100)
            , [ReqnStatus] Varchar(150)
            , [Operator] Varchar(150)
            , [ApprovedDate] Date
            , [DateReqnRaised] Date
            , [DatePoConfirmed] Date
            , [ProductClass] Varchar(20)
            , [Supplier] Varchar(30)
            );
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(50)
            , [Buyer] Varchar(100)
            , [DatePoCompleted] Date
            , [OrderStatus] Varchar(10)
            , [Supplier] Varchar(30)
            );
	
--create script to pull data from each db into the tables
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
	        , [MRequisition]
	        , [PurchaseOrder]
	        , [Line]
	        , [MStockCode]
	        , [MStockDes]
	        , [MOrderQty]
	        , [MPriceUom]
	        , [MLatestDueDate]
	        , [MSupCatalogue]
	        , [MPrice]
	        , [MForeignPrice]
	        , [MGlCode]
	        , [MCompleteFlag]
	        , [MProductClass]
	        )
	SELECT [DatabaseName]=@DBCode
         , [PMD].[MRequisition]
         , [PMD].[PurchaseOrder]
         , [PMD].[Line]
         , [PMD].[MStockCode]
         , [PMD].[MStockDes]
         , [PMD].[MOrderQty]
         , [PMD].[MPriceUom]
         , [PMD].[MLatestDueDate]
         , [PMD].[MSupCatalogue]
         , [PMD].[MPrice]
         , [PMD].[MForeignPrice]
         , [PMD].[MGlCode]
         , [PMD].[MCompleteFlag]
         , [PMD].[MProductClass] FROM [PorMasterDetail] As [PMD]
			End
	End';
        Declare @SQLReqDetail Varchar(Max) = '
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
					Insert [#ReqDetail]
	        ( [DatabaseName]
	        , [Requisition]
	        , [Line]
	        , [StockCode]
	        , [StockDescription]
	        , [OrderQty]
	        , [OrderUom]
	        , [DueDate]
	        , [SupCatalogueNum]
	        , [Price]
	        , [GlCode]
	        , [Originator]
	        , [Buyer]
	        , [ReqnStatus]
	        , [Operator]
	        , [ApprovedDate]
	        , [DateReqnRaised]
	        , [DatePoConfirmed]
	        , [ProductClass]
	        , [Supplier]
	        )
	SELECT [DatabaseName]=@DBCode
         , [RD].[Requisition]
         , [RD].[Line]
         , [RD].[StockCode]
         , [RD].[StockDescription]
         , [RD].[OrderQty]
         , [RD].[OrderUom]
         , [RD].[DueDate]
         , [RD].[SupCatalogueNum]
         , [RD].[Price]
         , [RD].[GlCode]
         , [RD].[Originator]
         , [RD].[Buyer]
         , [RD].[ReqnStatus]
         , [RD].[Operator]
         , [RD].[ApprovedDate]
         , [RD].[DateReqnRaised]
         , [RD].[DatePoConfirmed]
         , [RD].[ProductClass]
         , [RD].[Supplier] FROM [ReqDetail] As [RD]
			End
	End';
        Declare @SQLPorMasterHdr Varchar(Max) = '
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
					Insert [#PorMasterHdr]
	        ( [DatabaseName]
	        , [PurchaseOrder]
	        , [Buyer]
	        , [DatePoCompleted]
	        , [OrderStatus]
	        , [Supplier]
	        )
	SELECT [DatabaseName]=@DBCode
         , [PMH].[PurchaseOrder]
         , [PMH].[Buyer]
         , [PMH].[DatePoCompleted]
         , [PMH].[OrderStatus]
         , [PMH].[Supplier] FROM [PorMasterHdr] As [PMH]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasterDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLReqDetail;
        Exec [Process].[ExecForEachDB] @cmd = @SQLPorMasterHdr;

--define the results you want to return
        Create Table [#Results]
            (
              [Requisition] Varchar(50)
                      , [PurchaseOrder] Varchar(50)
                      , [Line] Int
                      , [StockCode] Varchar(50)
                      , [ProjectName] Varchar(50)
                      , [OriginalStockCode] Varchar(50)
                      , [StockDescription] Varchar(200)
                      , [OrderQty] Numeric(20,8)
                      , [OrderUom] Varchar(10)
                      , [DueDate] Date
                      , [SupCatalogueNum] Varchar(100)
                      , [Price] Numeric(20,2)
                      , [MForeignPrice] Numeric(20,2)
                      , [ProductClass] Varchar(250)
                      , [GlCode] Varchar(200)
                      , [GlDescription] Varchar(200)
                      , [GlGroup] Varchar(20)
                      , [Originator] Varchar(150)
                      , [OriginatorName] Varchar(150)
                      , [Buyer] Varchar(150)
                      , [ReqnStatus] Varchar(100)
                      , [Supplier] Varchar(100)
                      , [DatePoConfirmed] Date
                      , [DatePoCompleted] Date
                      , [RequisitionOperator] Varchar(150)
                      , [ApprovedDate] Date
                      , [DateRequisitionnRaised] Date
                      , [PurchaseOrders] bit
                      , [OpenRequisitions] bit
                      , [POStatus] Varchar(20)
                      , [Capex] Varchar(20)
                      , [DeptCode] char(5)
                      , [OrderStatus] Varchar(150)
                      , [OrderStatusDescription] Varchar(250)
                      , [MCompleteFlag] Char(1)
                      , [CompanyName] Varchar(200)
                      , [Currency] Varchar(10)
                      , [CADDivision] Float
                      , [CADMultiply] Float
                      , [StartDateTime] DateTime2
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Requisition]
                , [PurchaseOrder]
                , [Line]
                , [StockCode]
                , [ProjectName]
                , [OriginalStockCode]
                , [StockDescription]
                , [OrderQty]
                , [OrderUom]
                , [DueDate]
                , [SupCatalogueNum]
                , [Price]
                , [MForeignPrice]
                , [ProductClass]
                , [GlCode]
                , [GlDescription]
                , [GlGroup]
                , [Originator]
                , [OriginatorName]
                , [Buyer]
                , [ReqnStatus]
                , [Supplier]
                , [DatePoConfirmed]
                , [DatePoCompleted]
                , [RequisitionOperator]
                , [ApprovedDate]
                , [DateRequisitionnRaised]
                , [PurchaseOrders]
                , [OpenRequisitions]
                , [POStatus]
                , [Capex]
                , [DeptCode]
                , [OrderStatus]
                , [OrderStatusDescription]
                , [MCompleteFlag]
                , [CompanyName]
                , [Currency]
                , [CADDivision]
                , [CADMultiply]
                , [StartDateTime]
                )
                Select  [Requisition] = Coalesce(Case When [PMD].[MRequisition] = ''
                                                      Then Null
                                                      Else [PMD].[MRequisition]
                                                 End , [RD].[Requisition])
                      , [PMD].[PurchaseOrder]
                      , [Line] = Coalesce([PMD].[Line] , [RD].[Line])
                      , [StockCode] = Case When [PC].[ProductClassDescription] = 'Raw Materials'
                                           Then Coalesce([PMD].[MStockCode] ,
                                                         [RD].[StockCode])
                                           Else Null
                                      End
                      , [ProjectName] = Case When Replace(Lower(Coalesce([PMD].[MStockCode] ,
                                                              [RD].[StockCode])) ,
                                                          ' ' , '') In (
                                                  'area51' , 'itproject' )
                                             Then Coalesce([PMD].[MStockCode] ,
                                                           [RD].[StockCode])
                                             Else Null
                                        End
                      , [OriginalStockCode] = Coalesce([PMD].[MStockCode] ,
                                                       [RD].[StockCode])
                      , [StockDescription] = Coalesce([PMD].[MStockDes] ,
                                                      [RD].[StockDescription])
                      , [OrderQty] = Coalesce([PMD].[MOrderQty] ,
                                              [RD].[OrderQty])
                      , [OrderUom] = Lower(Coalesce([PMD].[MPriceUom] ,
                                                    [RD].[OrderUom]))
                      , [DueDate] = Convert(Date , Coalesce([PMD].[MLatestDueDate] ,
                                                            [RD].[DueDate]))
                      , [SupCatalogueNum] = Coalesce(Case When [PMD].[MSupCatalogue] = ''
                                                          Then Null
                                                          Else [PMD].[MSupCatalogue]
                                                     End ,
                                                     Case When [RD].[SupCatalogueNum] = ''
                                                          Then Null
                                                          Else [RD].[SupCatalogueNum]
                                                     End)
                      , [Price] = Coalesce([PMD].[MPrice] , [RD].[Price])
                      , [PMD].[MForeignPrice]
                      , [ProductClass] = [PC].[ProductClassDescription]
                      , [GlCode] = Coalesce([PMD].[MGlCode] , [RD].[GlCode])
                      , [GlDescription] = [GM].[Description]
                      , [GM].[GlGroup]
                      , [RD].[Originator]
                      , [OriginatorName] = 'TBC'
                      , [Buyer] = Coalesce(Case When [PMH].[Buyer] = ''
                                                Then Null
                                                Else [PMH].[Buyer]
                                           End ,
                                           Case When [RD].[Buyer] = ''
                                                Then Null
                                                Else [RD].[Buyer]
                                           End)
                      , [RD].[ReqnStatus]
                      , [Supplier] = Coalesce([PMH].[Supplier] ,
                                              [RD].[Supplier])
                      , [DatePoConfirmed] = Convert(Date , [RD].[DatePoConfirmed])
                      , [DatePoCompleted] = Convert(Date , [PMH].[DatePoCompleted])
                      , [RequisitionOperator] = [RD].[Operator]
                      , [ApprovedDate] = Convert(Date , [RD].[ApprovedDate])
                      , [DateRequisitionnRaised] = Convert(Date , [RD].[DateReqnRaised])
                      , [PurchaseOrders] = Case When [PMD].[PurchaseOrder] Is Null
                                                Then 0
                                                Else 1
                                           End
                      , [OpenRequisitions] = Case When [PMD].[PurchaseOrder] Is Null
                                                  Then 1
                                                  Else 0
                                             End
                      , [POStatus] = Case When [PMH].[DatePoCompleted] Is Null
                                          Then 'Open'
                                          Else 'Closed'
                                     End
                      , [Capex] = Case When Substring([GM].[GlCode] , 5 , 5) = '22999'
                                       Then 'Capex'
                                       Else Null
                                  End
                      , [DeptCode] = Substring([GM].[GlCode] , 5 , 5)
                      , [PMH].[OrderStatus]
                      , [POS].[OrderStatusDescription]
                      , [PMD].[MCompleteFlag]
                      , [CN].[CompanyName]
                      , [CR].[Currency]
                      , [CR].[CADDivision]
                      , [CR].[CADMultiply]
                      , [CR].[StartDateTime]
                From    [#PorMasterDetail] As [PMD]
                        Full Outer Join [#ReqDetail] As [RD] On [RD].[Requisition] = [PMD].[MRequisition]
                                                              And [RD].[Line] = [PMD].[Line]
															  And [RD].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [#PorMasterHdr] As [PMH] On [PMH].[PurchaseOrder] = [PMD].[PurchaseOrder]
															And [PMH].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [GM].[GlCode] = Coalesce([PMD].[MGlCode] ,
                                                              [RD].[GlCode])
                        Left Join [BlackBox].[Lookups].[ProductClass] As [PC] On [PC].[ProductClass] = Coalesce([PMD].[MProductClass] ,
                                                              [RD].[ProductClass])
                                                              And [PC].[Company] = Coalesce(PMD.[DatabaseName],RD.[ProductClass])
                        Left Join [BlackBox].[Lookups].[PurchaseOrderStatus]
                        As [POS] On [POS].[OrderStatusCode] = [PMH].[OrderStatus]
                                    And [POS].[Company] = PMH.[DatabaseName]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = Coalesce([PMH].[DatabaseName],[RD].[DatabaseName])
                        Left Join [BlackBox].[Lookups].[CurrencyRates] As [CR] On [CR].[Currency] = [CN].[Currency]
                                                              And GetDate() Between [CR].[StartDateTime]
																			And [CR].[EndDateTime]
                Where   Coalesce([PMD].[MPrice] , [RD].[Price]) <> 0;

--return results
        Select  [Requisition] = Case When IsNumeric([Requisition])=1 Then Convert(Varchar(50),Convert(Int,[Requisition])) Else Null End
              , [PurchaseOrder] = Case When IsNumeric([PurchaseOrder])=1 Then Convert(Varchar(50),Convert(Int,[PurchaseOrder])) Else Null End
              , [Line]
              , [StockCode]
              , [ProjectName]
              , [OriginalStockCode]
              , [StockDescription]
              , [OrderQty]
              , [OrderUom]
              , [DueDate]
              , [SupCatalogueNum]
              , [Price]
              , [MForeignPrice]
              , [ProductClass]
              , [GlCode]
              , [GlDescription]
              , [GlGroup]
              , [Originator]
              , [OriginatorName]
              , [Buyer]
              , [ReqnStatus]
              , [Supplier]
              , [DatePoConfirmed]
              , [DatePoCompleted]
              , [RequisitionOperator]
              , [ApprovedDate]
              , [DateRequisitionnRaised]
              , [PurchaseOrders]
              , [OpenRequisitions]
              , [POStatus]
              , [Capex]
              , [DeptCode]
              , [OrderStatus]
              , [OrderStatusDescription]
              , [MCompleteFlag]
              , [CompanyName]
              , [Currency]
              , [CADDivision]
              , [CADMultiply]
              , [StartDateTime]
        From    [#Results]
Order By PurchaseOrder Asc, [Line] Asc

--Project list (non PBL)
SELECT [GD].[PurchaseOrder]
, [GD].[PurchaseOrderLin]
, [GAC].[Description]

 From [10.100.125.61].[SysproCompany41].[dbo].[GrnDetails] As [GD]
Left Join [10.100.125.61].[SysproCompany41].[dbo].[GenJournalDetail] As [GJD] On [GJD].[Journal] = [GD].[Journal]
Left Join [10.100.125.61].[SysproCompany41].[dbo].[GenAnalysisTrn] As [GAT] On [GAT].[AnalysisEntry] = [GJD].[AnalysisEntry]
Left join [10.100.125.61].[SysproCompany41].[dbo].[GenAnalysisCode] As GAC On [GAT].[AnalysisCode1]=[GAC].[AnalysisCode] And [GAC].[AnalysisType]=1
Where [GAC].[Description] Is Not Null
    End;

GO
