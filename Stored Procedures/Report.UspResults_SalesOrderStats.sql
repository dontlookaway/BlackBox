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
        Declare @ListOfTables Varchar(Max) = 'ArCustomer,SorMaster,SorDetail,GenJournalDetail,CusSorMaster+'; 

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
            , [LastInvoice] Varchar(20)
            , [ShipAddress5] Varchar(40)
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
        Create Table [#GenJournalDetail]
            (
              [DatabaseName] Varchar(150)
            , [SubModArInvoice] Varchar(20)
            , [Reference] Varchar(50)
            , [EntryDate] Date
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
						, [LastInvoice]
						, [ShipAddress5]
						)
				SELECT [DatabaseName]=@DBCode
					 , [SM].[CustomerPoNumber]
					 , [SM].[EntrySystemDate]
					 , [SM].[Currency]
					 , [SM].[SalesOrder]
					 , [SM].[Customer]
					 , [SM].[DocumentType]
					 , [LastInvoice]
					 , [ShipAddress5]
				FROM [SorMaster] [SM]
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
        Declare @SQLGenJournalDetail Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
			Insert [#GenJournalDetail]
			        ( [DatabaseName]
			        , [SubModArInvoice]
			        , [Reference]
			        , [EntryDate]
			        )
			Select Distinct 
					[DatabaseName]=@DBCode
					, [SubModArInvoice]
					, [Reference]
					, [EntryDate]
			From    [dbo].[GenJournalDetail]
			Where   [Reference] = ''Invoice''
			And [SubModArInvoice] <> ''''
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
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLGenJournalDetail ,
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
            , [LastInvoice] Varchar(20)
            , [ProFormaDate] DateTime
            , [Country] Varchar(40)
            , [InvoiceEntryDate] Date
            );

--Placeholder to create indexes as required
        Create Table [#ProformaDates]
            (
              [DatabaseName] Varchar(150)
            , [ProFormaDate] DateTime2
            , [SalesOrder] Varchar(20)
            );   
	
        Insert  [#ProformaDates]
                ( [DatabaseName]
                , [ProFormaDate]
                , [SalesOrder]
                )
                Select  [DatabaseName] = Replace(Upper([SM2].[DatabaseName]) ,
                                                 'SYSPROCOMPANY' , '')
                      , [ProFormaDate] = Max([SM2].[SignatureDateTime])
                      , [SM2].[SALESORDER]
                From    [History].[SorMaster] [SM2]
                        Inner Join [Lookups].[ProformaDocTypes] [PDT]
                            On [PDT].[DOCUMENTFORMAT] = [SM2].[DOCUMENTFORMAT]
                               And [PDT].[DOCUMENTTYPE] = [SM2].[DOCUMENTTYPE]
                Group By Replace(Upper([SM2].[DatabaseName]) , 'SYSPROCOMPANY' ,
                                 '')
                      , [SM2].[SALESORDER];

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
                , [LastInvoice]
                , [ProFormaDate]
                , [Country]
                , [InvoiceEntryDate] 
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
                      , [LastInvoice] = Case When IsNumeric([SM].[LastInvoice]) = 1
                                             Then Convert(Varchar(20) , Convert(BigInt , [SM].[LastInvoice]))
                                             Else [SM].[LastInvoice]
                                        End
                      , [PD].[ProFormaDate]
                      , [Country] = Case When [SM].[ShipAddress5] = ''
                                         Then Null
                                         Else [SM].[ShipAddress5]
                                    End
                      , [GJD].[EntryDate]
                From    [#ArCustomer] [AC]
                        Inner Join [#SorMaster] [SM]
                            On [SM].[Customer] = [AC].[Customer]
                        Inner Join [#SorDetail] [SD]
                            On [SD].[SalesOrder] = [SM].[SalesOrder]
                        Left Join [#CusSorMasterPlus] [CSM]
                            On [CSM].[SalesOrder] = [SM].[SalesOrder]
                        Left Join [BlackBox].[Lookups].[SalesOrderDocumentType] [SODT]
                            On [SODT].[DocumentType] = [SM].[DocumentType]
                        Left Join [#ProformaDates] [PD]
                            On [PD].[DatabaseName] = [SM].[DatabaseName]
                               And [PD].[SalesOrder] = [SM].[SalesOrder]
                        Left Join [#GenJournalDetail] [GJD]
                            On [SM].[LastInvoice] = [GJD].[SubModArInvoice]
                               And [GJD].[DatabaseName] = [SM].[DatabaseName]
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
              , [R].[LastInvoice]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [CompanyCurrency] = [CN].[Currency]
              , [R].[ProFormaDate]
              , [R].[Country]
              , [R].[InvoiceEntryDate]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [R].[DatabaseName] = [CN].[Company];

    End;

GO
