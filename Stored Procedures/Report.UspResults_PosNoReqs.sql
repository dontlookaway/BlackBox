SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PosNoReqs]
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
            @StoredProcName = 'UspResults_PosNoReqs' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterHdr,PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [MRequisition] Varchar(10)
            );
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [OrderStatus] Char(1)
            , [Supplier] Varchar(15)
            , [OrderEntryDate] Date
            , [OrderDueDate] Date
            , [DatePoCompleted] Date
            , [Buyer] Varchar(20)
            , [CancelledFlag] Char(1)
            );


	

--create script to pull data from each db into the tables
        Declare @SQLPorMasterDetail Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#PorMasterDetail]
						( [DatabaseName]
						, [PurchaseOrder]
						, [MRequisition]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMD].[PurchaseOrder]
					 , [PMD].[MRequisition] FROM [PorMasterDetail] [PMD]
			End
	End';
        Declare @SQLPorMasterHdr Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#PorMasterHdr]
						( [DatabaseName]
						, [PurchaseOrder]
						, [OrderStatus]
						, [Supplier]
						, [OrderEntryDate]
						, [OrderDueDate]
						, [DatePoCompleted]
						, [Buyer]
						, [CancelledFlag]
						)
				SELECT [DatabaseName]=@DBCode
					 , [PMH].[PurchaseOrder]
					 , [PMH].[OrderStatus]
					 , [PMH].[Supplier]
					 , [PMH].[OrderEntryDate]
					 , [PMH].[OrderDueDate]
					 , [PMH].[DatePoCompleted]
					 , [PMH].[Buyer]
					 , [PMH].[CancelledFlag]
				FROM [PorMasterHdr] [PMH]
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLPorMasterDetail ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLPorMasterHdr ,
            @SchemaTablesToCheck = @ListOfTables;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(20)
            , [OrderStatus] Varchar(150)
            , [Supplier] Varchar(15)
            , [OrderEntryDate] Date
            , [OrderDueDate] Date
            , [DatePoCompleted] Date
            , [Buyer] Varchar(20)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [PurchaseOrder]
                , [OrderStatus]
                , [Supplier]
                , [OrderEntryDate]
                , [OrderDueDate]
                , [DatePoCompleted]
                , [Buyer]
                )
                Select  [PMH].[DatabaseName]
                      , [PMH].[PurchaseOrder]
                      , [OrderStatus] = [POS].[OrderStatusDescription]
                      , [PMH].[Supplier]
                      , [PMH].[OrderEntryDate]
                      , [PMH].[OrderDueDate]
                      , [PMH].[DatePoCompleted]
                      , [PMH].[Buyer]
                From    [#PorMasterDetail] [PMD]
                        Inner Join [#PorMasterHdr] [PMH]
                            On [PMH].[PurchaseOrder] = [PMD].[PurchaseOrder]
                               And [PMH].[DatabaseName] = [PMD].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[PurchaseOrderStatus] [POS]
                            On [PMH].[OrderStatus] = [POS].[OrderStatusCode]
                               And [POS].[Company] = [PMH].[DatabaseName]
                Where   Coalesce([PMH].[CancelledFlag] , 'N') <> 'Y'
                Group By [PMH].[DatabaseName]
                      , [PMH].[PurchaseOrder]
                      , [POS].[OrderStatusDescription]
                      , [PMH].[Supplier]
                      , [PMH].[OrderEntryDate]
                      , [PMH].[OrderDueDate]
                      , [PMH].[DatePoCompleted]
                      , [PMH].[Buyer]
                Having  Count(Distinct Case When Coalesce([PMD].[MRequisition] ,
                                                          '') = '' Then Null
                                            Else [PMD].[MRequisition]
                                       End) = 0;

        Set NoCount Off;
--return results
        Select  [DatabaseName]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [PurchaseOrder]
              , [OrderStatus]
              , [Supplier]
              , [OrderEntryDate]
              , [OrderDueDate]
              , [DatePoCompleted]
              , [Buyer] = Case When [Buyer] = '' Then Null
                               Else [Buyer]
                          End
        From    [#Results]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [DatabaseName] = [CN].[Company];

    End;

GO
