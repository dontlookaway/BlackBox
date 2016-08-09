SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_SalesOrderStats]
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
            @StoredProcName = 'UspResults_SalesOrderStats' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ArCustomer,SorMaster,SorDetail,CusSorMaster+'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ArCustomer]
            (
              [DatabaseName] Varchar(150)
            , [Customer] Varchar(15)
            , [Name] Varchar(50)
            );

        Create Table [#SorMaster]
            (
              [DatabaseName] Varchar(150)
            , [CustomerPoNumber] Varchar(30)
            , [EntrySystemDate] DateTime
            , [Currency] Char(3)
            , [SalesOrder] Varchar(20)
            , [Customer] Varchar(15)
            , [DocumentType] Varchar(10)
            );

        Create Table [#SorDetail]
            (
              [DatabaseName] Varchar(150)
            , [MStockCode] Varchar(30)
            , [MStockDes] Varchar(50)
            , [MOrderQty] Numeric(20 , 8)
            , [MPrice] Numeric(20 , 8)
            , [MLineShipDate] DateTime
            , [SalesOrderLine] Int
            , [SalesOrder] Varchar(20)
            );

        Create Table [#CusSorMasterPlus]
            (
              [DatabaseName] Varchar(150)
            , [AttentionOf] Varchar(60)
            , [AcceptedDate] DateTime
            , [SalesOrder] Varchar(20)
            );



--create script to pull data from each db into the tables
        Declare @SQLArCustomer Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#ArCustomer]
						( [DatabaseName]
						, [Customer]
						, [Name]
						)
				SELECT [DatabaseName]=@DBCode
					 , [AC].[Customer]
					 , [AC].[Name] FROM [ArCustomer] [AC]
			End
	End';
        Declare @SQLSorMaster Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#SorMaster]
						( [DatabaseName]
						, [CustomerPoNumber]
						, [EntrySystemDate]
						, [Currency]
						, [SalesOrder]
						, [Customer]
						, [DocumentType]
						)
				SELECT [DatabaseName]=@DBCode
					 , [SM].[CustomerPoNumber]
					 , [SM].[EntrySystemDate]
					 , [SM].[Currency]
					 , [SM].[SalesOrder]
					 , [SM].[Customer]
					 , [SM].[DocumentType] FROM [SorMaster] [SM]
			End
	End';
        Declare @SQLSorDetail Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#SorDetail]
						( [DatabaseName]
						, [MStockCode]
						, [MStockDes]
						, [MOrderQty]
						, [MPrice]
						, [MLineShipDate]
						, [SalesOrderLine]
						, [SalesOrder]
						)
				SELECT [DatabaseName]=@DBCode
					 , [SD].[MStockCode]
					 , [SD].[MStockDes]
					 , [SD].[MOrderQty]
					 , [SD].[MPrice]
					 , [SD].[MLineShipDate]
					 , [SD].[SalesOrderLine]
					 , [SD].[SalesOrder] FROM [SorDetail] [SD]
			End
	End';
        Declare @SQLCusSorMasterPlus Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#CusSorMasterPlus]
						( [DatabaseName]
						, [AttentionOf]
						, [AcceptedDate]
						, [SalesOrder]
						)
				SELECT [DatabaseName]=@DBCode
					 , [CSMP].[AttentionOf]
					 , [CSMP].[AcceptedDate]
					 , [CSMP].[SalesOrder] FROM [CusSorMaster+] [CSMP]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLArCustomer ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLSorMaster ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLSorDetail ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLCusSorMasterPlus ,
            @SchemaTablesToCheck = @ListOfTables;


--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Customer] Varchar(15)
            , [CustomerName] Varchar(50)
            , [CustomerPoNumber] Varchar(30)
            , [Contact] Varchar(60)
            , [EntrySystemDate] DateTime
            , [AcceptedDate] DateTime
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [OrderQty] Numeric(20 , 8)
            , [Price] Numeric(20 , 8)
            , [Currency] Varchar(10)
            , [ShipDate] DateTime
            , [SalesOrder] Varchar(20)
            , [SOLine] Int
            , [DocumentType] Varchar(250)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Customer]
                , [CustomerName]
                , [CustomerPoNumber]
                , [Contact]
                , [EntrySystemDate]
                , [AcceptedDate]
                , [StockCode]
                , [StockDescription]
                , [OrderQty]
                , [Price]
                , [Currency]
                , [ShipDate]
                , [SalesOrder]
                , [SOLine]
                , [DocumentType]
                )
                Select  [AC].[DatabaseName]
                      , [AC].[Customer]
                      , [AC].[Name]
                      , [SM].[CustomerPoNumber]
                      , [Contact] = [CSM].[AttentionOf]
                      , [SM].[EntrySystemDate]
                      , [CSM].[AcceptedDate]
                      , [StockCode] = [SD].[MStockCode]
                      , [StockDescription] = [SD].[MStockDes]
                      , [OrderQty] = [SD].[MOrderQty]
                      , [Price] = [SD].[MPrice]
                      , [SM].[Currency]
                      , [ShipDate] = [SD].[MLineShipDate]
                      , [SalesOrder] = Case When IsNumeric([SM].[SalesOrder]) = 1
                                            Then Convert(Varchar(20) , Convert(Int , [SM].[SalesOrder]))
                                            Else [SM].[SalesOrder]
                                       End
                      , [SOLine] = [SD].[SalesOrderLine]
                      , [DocumentType] = [SODT].[DocumentTypeDesc]
                From    [#ArCustomer] [AC]
                        Inner Join [#SorMaster] [SM]
                            On [SM].[Customer] = [AC].[Customer]
                        Inner Join [#SorDetail] [SD]
                            On [SD].[SalesOrder] = [SM].[SalesOrder]
                        Left Join [#CusSorMasterPlus] [CSM]
                            On [CSM].[SalesOrder] = [SM].[SalesOrder]
                        Left Join [BlackBox].[Lookups].[SalesOrderDocumentType] [SODT]
                            On [SODT].[DocumentType] = [SM].[DocumentType]
                Order By [SalesOrder] Desc;

        Set NoCount Off;
--return results
        Select  [R].[DatabaseName]
              , [R].[Customer]
              , [R].[CustomerName]
              , [R].[CustomerPoNumber]
              , [R].[Contact]
              , [R].[EntrySystemDate]
              , [R].[AcceptedDate]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[OrderQty]
              , [R].[Price]
              , [R].[Currency]
              , [R].[ShipDate]
              , [R].[SalesOrder]
              , [R].[SOLine]
              , [R].[DocumentType]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [CompanyCurrency] = [CN].[Currency]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [R].[DatabaseName] = [CN].[Company];

    End;

GO