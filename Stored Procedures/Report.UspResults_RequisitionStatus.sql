SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_RequisitionStatus] ( @Company VARCHAR(Max) )
As
--Exec [Report].[UspResults_RequisitionStatus]    @Company = '10' -- varchar(max)
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			List of all requisitions and their statuses																				///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			24/9/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'ReqHeader,ReqDetail,ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #ReqHeader
            (
              DatabaseName VARCHAR(150)
            , Requisition VARCHAR(35)
            );

        Create Table #ReqDetail
            (
              DatabaseName VARCHAR(150)
            , Buyer VARCHAR(20)
            , CurrentHolder VARCHAR(20)
            , DateReqnRaised DATETIME2
            , DueDate DATETIME2
            , Line INT
            , OrderQty NUMERIC(20, 6)
            , Originator VARCHAR(20)
            , Price NUMERIC(18, 3)
            , StockCode VARCHAR(35)
            , StockDescription VARCHAR(150)
            , SupCatalogueNum VARCHAR(50)
            , ReqnStatus VARCHAR(10)
            , Requisition VARCHAR(35)
            , Supplier VARCHAR(35)
            );

        Create Table #ApSupplier
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(35)
            , SupplierName VARCHAR(150)
            );

			
	



--create script to pull data from each db into the tables
        Declare @SQL VARCHAR(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
            + --Only query DBs beginning SysProCompany
            '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'
            + --only companies selected in main run, or if companies selected then all
            '
		IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
            + UPPER(@Company) + ''' = ''ALL''
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

        If LEN(@SQL) > 2000
            Begin
                Print LEN(@SQL);
            End;
        If LEN(@SQL) <= 2000
            Begin
                Exec sp_MSforeachdb
                    @SQL;
            End;
--execute script against each db, populating the base tables
        

--define the results you want to return
        Create --drop --alter 
        Table #ResultsReqStatus
            (
              DatabaseName VARCHAR(150)
            , SupplierName VARCHAR(150)
            , Buyer VARCHAR(150)
            , CurrentHolder VARCHAR(150)
            , DateReqnRaised DATETIME2
            , DueDate DATETIME2
            , Line VARCHAR(10)
            , OrderQty FLOAT
            , Originator VARCHAR(150)
            , Price NUMERIC(20, 3)
            , ReqStatus VARCHAR(150)
            , StockCode VARCHAR(35)
            , StockDescription VARCHAR(150)
            , SupCatalogueNum VARCHAR(50)
            , Requisition VARCHAR(35)
			, CompanyName VARCHAR(150)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  #ResultsReqStatus
                ( DatabaseName
                , SupplierName
                , Buyer
                , CurrentHolder
                , DateReqnRaised
                , DueDate
                , Line
                , OrderQty
                , Originator
                , Price
                , ReqStatus
                , StockCode
                , StockDescription
                , SupCatalogueNum
                , Requisition
				, [CompanyName]
                )
                Select
                    RH.DatabaseName
                  , s.SupplierName
                  , rd.Buyer
                  , rd.CurrentHolder
                  , rd.DateReqnRaised
                  , rd.DueDate
                  , rd.Line
                  , rd.OrderQty
                  , rd.Originator
                  , rd.Price
                  , ReqStatus = RS.ReqnStatusDescription
                  , rd.StockCode
                  , rd.StockDescription
                  , rd.SupCatalogueNum
                  , RH.Requisition
				  , [cn].[CompanyName]
                From
                    #ReqHeader RH
                Inner Join #ReqDetail rd
                    On rd.Requisition = RH.Requisition
                       And rd.DatabaseName = [RH].[DatabaseName]
                Left Join #ApSupplier s
                    On s.Supplier = rd.Supplier
                       And s.DatabaseName = rd.DatabaseName
                Left Join BlackBox.Lookups.ReqnStatus RS
                    On RS.ReqnStatusCode = rd.ReqnStatus Collate Latin1_General_BIN
                       And RS.Company = rd.DatabaseName Collate Latin1_General_BIN
				Left JOIN  [BlackBox].[Lookups].[CompanyNames] As [cn] 
					On [cn].[Company] =  RH.DatabaseName Collate Latin1_General_BIN
                --Where
                --    rd.DateReqnRaised Between GETDATE() - 365 And GETDATE();

--return results
        Select
            Company = DatabaseName
          , SupplierName
          , Buyer
          , CurrentHolder
          , DateReqnRaised = CAST(DateReqnRaised As DATE)
          , DueDate  = CAST(DueDate As DATE)
          , Line
          , OrderQty
          , Originator
          , Price
          , ReqStatus = coalesce(ReqStatus,'No Status')
          , StockCode
          , StockDescription
          , SupCatalogueNum
          , Requisition
		  , [CompanyName]
        From 
            #ResultsReqStatus;

    End;

GO
