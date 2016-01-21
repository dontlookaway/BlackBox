SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrdersHistory]
(@Company VARCHAR(Max))
--Exec [Report].[UspResults_PurchaseOrdersHistory] 43
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Procedure to return all Purchase Order Details and changes																///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			30/9/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--remove nocount on to speed up query
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'PorMasterDetail' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #PorMasterDetail
	(	DatabaseName		VARCHAR(150) Collate Latin1_General_BIN
		,DatabaseCode		VARCHAR(150) Collate Latin1_General_BIN
		,[PurchaseOrder]	VARCHAR(35) Collate Latin1_General_BIN
		,[Line]				INT
		,[StockCode]		VARCHAR(35) Collate Latin1_General_BIN
		,[StockDescription] VARCHAR(255) Collate Latin1_General_BIN
		,[MStockingUom]		VARCHAR(10) Collate Latin1_General_BIN
		,[MOrderQty]		NUMERIC(20,7)
		,[MReceivedQty]		NUMERIC(20,7)
		,[MLatestDueDate]	DATETIME2
		,[MOrigDueDate]		DATETIME2
		,[MPrice]			NUMERIC(20,3)
		,[MForeignPrice]	NUMERIC(20,3)
	)




	


--create script to pull data from each db into the tables
	Declare @SQL1 VARCHAR(max) = '
USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
--Only query DBs beginning SysProCompany
'
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'+ --only companies selected in main run, or if companies selected then all
	'
	IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'+
		--count number of tables requested (number of commas plus one)
		'
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
		--Count of the tables requested how many exist in the db
		'
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
		--only if the count matches (all the tables exist in the requested db) then run the script
		'
		If @ActualCountOfTables=@RequiredCountOfTables
		BEGIN
		Insert [#PorMasterDetail]
				( [DatabaseName]
				, [DatabaseCode]
				, [PurchaseOrder]
				, [Line]
				, [StockCode]
				, [StockDescription]
				, [MStockingUom]
				, [MOrderQty]
				, [MReceivedQty]
				, [MLatestDueDate]
				, [MOrigDueDate]
				, [MPrice]
				, [MForeignPrice]
				)
		SELECT [DatabaseName]=@DB
			 , [DatabaseCode]=@DBCode
			 , [pmd].[PurchaseOrder]
			 , [pmd].[Line]
			 , [pmd].[MStockCode]
			 , [pmd].[MStockDes]
			 , [pmd].[MStockingUom]
			 , [pmd].[MOrderQty]
			 , [pmd].[MReceivedQty]
			 , [pmd].[MLatestDueDate]
			 , [pmd].[MOrigDueDate]
			 , [pmd].[MPrice]
			 , [pmd].[MForeignPrice] 
		From [PorMasterDetail] As [pmd]
		End
End'



--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1
--Print @SQL2
--Print @SQL3


--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1

--define the results you want to return
	Create Table #Results
	(CompanyName VARCHAR(150)
	    ,[PurchaseOrder] VARCHAR(35)		
		, [Line] INT				
		, [StockCode] VARCHAR(35)
		, [StockDescription] VARCHAR(255)
		, [StockingUom] VARCHAR(10)
		, [OrderQty] NUMERIC(20,7)
		, [ReceivedQty]NUMERIC(20,7)
		, [LatestDueDate] DATETIME2
		, [OrigDueDate] DATETIME2
		, [LocalPrice] NUMERIC(20,3)
		, [ForeignPrice] NUMERIC(20,3)
		, [TransactionDescription] VARCHAR(255)
		, [SignatureDatetime] DATETIME2
		, [Operator] VARCHAR(255)
		, [Price] NUMERIC(20,3)
		, [PreviousPrice] NUMERIC(20,3)
		, [Quantity] NUMERIC(20,7)
		, [PreviousQuantity] NUMERIC(20,7)
		, [QuantityBeingReceieved] NUMERIC(20,7)
		, [Grn] VARCHAR(50)
		)

--Placeholder to create indexes as required


--script to combine base data and insert into results table
Insert [#Results]
        ( [PurchaseOrder]
        , [Line]
        , [StockCode]
        , [StockDescription]
        , [StockingUom]
        , [OrderQty]
        , [ReceivedQty]
        , [LatestDueDate]
        , [OrigDueDate]
        , [LocalPrice]
        , [ForeignPrice]
        , [TransactionDescription]
        , [SignatureDatetime]
        , [Operator]
        , [Price]
        , [PreviousPrice]
        , [Quantity]
        , [PreviousQuantity]
        , [QuantityBeingReceieved]
        , [Grn]
		, [CompanyName]
        )
Select
    [PurchaseOrder]						= COALESCE([md].[PurchaseOrder],[pmd].[PURCHASE ORDER])
  , [Line]								= COALESCE([md].[Line],[pmd].[PURCHASE ORDER LINE])
  , [StockCode]							= COALESCE([md].[StockCode],[pmd].[STOCK CODE])
  , [StockDescription]					= COALESCE([md].[StockDescription],[pmd].[STOCK DESCRIPTION])
  , [md].	[MStockingUom]
  , [md].	[MOrderQty]
  , [md].	[MReceivedQty]
  , [md].	[MLatestDueDate]
  , [md].	[MOrigDueDate]
  , [md].	[MPrice]
  , [md].	[MForeignPrice]
  , [pmd].	[TransactionDescription]
  , [pmd].	[SignatureDatetime]
  , [pmd].	[Operator]
  , [pmd].	[PRICE]
  , [pmd].	[PREVIOUS PRICE]
  , [pmd].	[QUANTITY]
  , [pmd].	[PREVIOUS QUANTITY]
  , [pmd].	[QUANTITY BEING RECEIVED]
  , [Grn]								= [pmd].[GOODS RECEIVED NUMBER]
  , [cn].	[CompanyName]
From
    #PorMasterDetail As [md]
Inner Join [BlackBox].[History].[PorMasterDetail] As [pmd]
    On [pmd].[PURCHASE ORDER] = [md].[PurchaseOrder]
       And [md].[Line] = pmd.[PURCHASE ORDER LINE]
	   And [pmd].[DatabaseName] = [md].[DatabaseName]
Left Join [Lookups].[CompanyNames] As [cn]
	On [cn].[Company]=[md].DatabaseCode
Order By [md].[PurchaseOrder] Asc,[md].[Line] Asc, [pmd].[SignatureDatetime] Desc

--return results
	SELECT [CompanyName]
         , [PurchaseOrder]
         , [Line]
         , [StockCode]
         , [StockDescription]
         , [StockingUom]
         , [OrderQty]
         , [ReceivedQty]
         , [LatestDueDate] = CAST([LatestDueDate] As DATE)
         , [OrigDueDate] = CAST([OrigDueDate] As DATE)
         , [LocalPrice]
         , [ForeignPrice]
         , [TransactionDescription]
         , [SignatureDate] = CAST([SignatureDatetime] As DATE)
		 , [SignatureTime] = CAST([SignatureDatetime] As TIME)
         , [Operator]
         , [Price]
         , [PreviousPrice]
         , [Quantity]
         , [PreviousQuantity]
         , [QuantityBeingReceieved]
         , [Grn] 
	From #Results

End





GO
