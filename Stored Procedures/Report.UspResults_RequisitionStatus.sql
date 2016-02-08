
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_RequisitionStatus]
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
List of all requisitions and their statuses
--Exec [Report].[UspResults_RequisitionStatus]    @Company = '10' -- varchar(max)
*/
        Set NoCount Off;
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

	--Red tag
    Declare @RedTagDB Varchar(255)= Db_Name();
    Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
        @StoredProcSchema = 'Report' , @StoredProcName = 'UspResults_RequisitionStatus' ,
        @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
        @UsedByDb = @RedTagDB;


--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ReqHeader,ReqDetail,ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ReqHeader]
            (
              [DatabaseName] Varchar(150)
            , [Requisition] Varchar(35)
            );
        Create Table [#ReqDetail]
            (
              [DatabaseName] Varchar(150)
            , [Buyer] Varchar(20)
            , [CurrentHolder] Varchar(20)
            , [DateReqnRaised] DateTime2
            , [DueDate] DateTime2
            , [Line] Int
            , [OrderQty] Numeric(20 , 6)
            , [Originator] Varchar(20)
            , [Price] Numeric(18 , 3)
            , [StockCode] Varchar(35)
            , [StockDescription] Varchar(150)
            , [SupCatalogueNum] Varchar(50)
            , [ReqnStatus] Varchar(10)
            , [Requisition] Varchar(35)
            , [Supplier] Varchar(35)
            );
        Create Table [#ApSupplier]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(35)
            , [SupplierName] Varchar(150)
            );

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
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
				Insert #ReqHeader
			        ( DatabaseName, Requisition )
			SELECT DatabaseName  = @DBCode
                 , Requisition FROM ReqHeader

			Insert #ReqDetail
			        ( DatabaseName, Buyer
			        , CurrentHolder, DateReqnRaised
			        , DueDate, Line
			        , OrderQty, Originator
			        , Price, StockCode
			        , StockDescription, SupCatalogueNum
			        , ReqnStatus, Requisition
			        , Supplier
			        )
			SELECT DatabaseName = @DBCode
                 , Buyer, CurrentHolder
                 , DateReqnRaised, DueDate
                 , Line, OrderQty
                 , Originator, Price
                 , StockCode, StockDescription
                 , SupCatalogueNum, ReqnStatus
                 , Requisition, Supplier FROM ReqDetail

			Insert #ApSupplier
			        ( DatabaseName, Supplier, SupplierName)
			SELECT DatabaseName = @DBCode, Supplier, SupplierName FROM ApSupplier
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

        If Len(@SQL) > 2000
            Begin
                Print Len(@SQL);
            End;
        If Len(@SQL) <= 2000
            Begin
                Exec [Process].[ExecForEachDB] @cmd = @SQL;
            End;
--execute script against each db, populating the base tables
        

--define the results you want to return
        Create Table [#ResultsReqStatus]
            (
              [DatabaseName] Varchar(150)
            , [SupplierName] Varchar(150)
            , [Buyer] Varchar(150)
            , [CurrentHolder] Varchar(150)
            , [DateReqnRaised] DateTime2
            , [DueDate] DateTime2
            , [Line] Varchar(10)
            , [OrderQty] Float
            , [Originator] Varchar(150)
            , [Price] Numeric(20 , 3)
            , [ReqStatus] Varchar(150)
            , [StockCode] Varchar(35)
            , [StockDescription] Varchar(150)
            , [SupCatalogueNum] Varchar(50)
            , [Requisition] Varchar(35)
            , [CompanyName] Varchar(150)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#ResultsReqStatus]
                ( [DatabaseName]
                , [SupplierName]
                , [Buyer]
                , [CurrentHolder]
                , [DateReqnRaised]
                , [DueDate]
                , [Line]
                , [OrderQty]
                , [Originator]
                , [Price]
                , [ReqStatus]
                , [StockCode]
                , [StockDescription]
                , [SupCatalogueNum]
                , [Requisition]
                , [CompanyName]
                )
                Select  [RH].[DatabaseName]
                      , [s].[SupplierName]
                      , [rd].[Buyer]
                      , [rd].[CurrentHolder]
                      , [rd].[DateReqnRaised]
                      , [rd].[DueDate]
                      , [rd].[Line]
                      , [rd].[OrderQty]
                      , [rd].[Originator]
                      , [rd].[Price]
                      , [ReqStatus] = [RS].[ReqnStatusDescription]
                      , [rd].[StockCode]
                      , [rd].[StockDescription]
                      , [rd].[SupCatalogueNum]
                      , [RH].[Requisition]
                      , [cn].[CompanyName]
                From    [#ReqHeader] [RH]
                        Inner Join [#ReqDetail] [rd] On [rd].[Requisition] = [RH].[Requisition]
                                                        And [rd].[DatabaseName] = [RH].[DatabaseName]
                        Left Join [#ApSupplier] [s] On [s].[Supplier] = [rd].[Supplier]
                                                       And [s].[DatabaseName] = [rd].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[ReqnStatus] [RS] On [RS].[ReqnStatusCode] = [rd].[ReqnStatus] Collate Latin1_General_BIN
                                                              And [RS].[Company] = [rd].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [cn].[Company] = [RH].[DatabaseName] Collate Latin1_General_BIN;

--return results
        Select  [Company] = [DatabaseName]
              , [SupplierName]
              , [Buyer] = Case When [Buyer] = '' Then 'Blank'
                               Else Coalesce([Buyer] , 'Blank')
                          End
              , [CurrentHolder]
              , [DateReqnRaised] = Cast([DateReqnRaised] As Date)
              , [DueDate] = Cast([DueDate] As Date)
              , [Line]
              , [OrderQty]
              , [Originator]
              , [Price]
              , [ReqStatus] = Coalesce([ReqStatus] , 'No Status')
              , [StockCode]
              , [StockDescription]
              , [SupCatalogueNum]
              , [Requisition]
              , [CompanyName]
        From    [#ResultsReqStatus];

    End;

GO
