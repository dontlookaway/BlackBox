
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrdersHistory] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
Procedure to return all Purchase Order Details and changes
--Exec [Report].[UspResults_PurchaseOrdersHistory] 43
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterDetail]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [DatabaseCode] Varchar(150) Collate Latin1_General_BIN
            , [PurchaseOrder] Varchar(35) Collate Latin1_General_BIN
            , [Line] Int
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [StockDescription] Varchar(255) Collate Latin1_General_BIN
            , [MStockingUom] Varchar(10) Collate Latin1_General_BIN
            , [MOrderQty] Numeric(20 , 7)
            , [MReceivedQty] Numeric(20 , 7)
            , [MLatestDueDate] DateTime2
            , [MOrigDueDate] DateTime2
            , [MPrice] Numeric(20 , 3)
            , [MForeignPrice] Numeric(20 , 3)
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1
--Print @SQL2
--Print @SQL3

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;

--define the results you want to return
        Create Table [#Results]
            (
              [CompanyName] Varchar(150)
            , [PurchaseOrder] Varchar(35)
            , [Line] Int
            , [StockCode] Varchar(35)
            , [StockDescription] Varchar(255)
            , [StockingUom] Varchar(10)
            , [OrderQty] Numeric(20 , 7)
            , [ReceivedQty] Numeric(20 , 7)
            , [LatestDueDate] DateTime2
            , [OrigDueDate] DateTime2
            , [LocalPrice] Numeric(20 , 3)
            , [ForeignPrice] Numeric(20 , 3)
            , [TransactionDescription] Varchar(255)
            , [SignatureDatetime] DateTime2
            , [Operator] Varchar(255)
            , [Price] Numeric(20 , 3)
            , [PreviousPrice] Numeric(20 , 3)
            , [Quantity] Numeric(20 , 7)
            , [PreviousQuantity] Numeric(20 , 7)
            , [QuantityBeingReceieved] Numeric(20 , 7)
            , [Grn] Varchar(50)
            );

--Placeholder to create indexes as required


--script to combine base data and insert into results table
        Insert  [#Results]
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
                Select  [PurchaseOrder] = Coalesce([md].[PurchaseOrder] ,
                                                   [pmd].[PURCHASE ORDER])
                      , [Line] = Coalesce([md].[Line] ,
                                          [pmd].[PURCHASE ORDER LINE])
                      , [StockCode] = Coalesce([md].[StockCode] ,
                                               [pmd].[STOCK CODE])
                      , [StockDescription] = Coalesce([md].[StockDescription] ,
                                                      [pmd].[STOCK DESCRIPTION])
                      , [md].[MStockingUom]
                      , [md].[MOrderQty]
                      , [md].[MReceivedQty]
                      , [md].[MLatestDueDate]
                      , [md].[MOrigDueDate]
                      , [md].[MPrice]
                      , [md].[MForeignPrice]
                      , [pmd].[TransactionDescription]
                      , [pmd].[SignatureDateTime]
                      , [pmd].[Operator]
                      , [pmd].[PRICE]
                      , [pmd].[PREVIOUS PRICE]
                      , [pmd].[QUANTITY]
                      , [pmd].[PREVIOUS QUANTITY]
                      , [pmd].[QUANTITY BEING RECEIVED]
                      , [Grn] = [pmd].[GOODS RECEIVED NUMBER]
                      , [cn].[CompanyName]
                From    [#PorMasterDetail] As [md]
                        Inner Join [BlackBox].[History].[PorMasterDetail] As [pmd] On [pmd].[PURCHASEORDER] = [md].[PurchaseOrder]
                                                              And [md].[Line] = [pmd].[PURCHASEORDERLINE]
                                                              And [pmd].[DatabaseName] = [md].[DatabaseName]
                        Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company] = [md].[DatabaseCode]
                Order By [md].[PurchaseOrder] Asc
                      , [md].[Line] Asc
                      , [pmd].[SignatureDateTime] Desc;

--return results
        Select  [CompanyName]
              , [PurchaseOrder]
              , [Line]
              , [StockCode]
              , [StockDescription]
              , [StockingUom]
              , [OrderQty]
              , [ReceivedQty]
              , [LatestDueDate] = Cast([LatestDueDate] As Date)
              , [OrigDueDate] = Cast([OrigDueDate] As Date)
              , [LocalPrice]
              , [ForeignPrice]
              , [TransactionDescription]
              , [SignatureDate] = Cast([SignatureDatetime] As Date)
              , [SignatureTime] = Cast([SignatureDatetime] As Time)
              , [Operator]
              , [Price]
              , [PreviousPrice]
              , [Quantity]
              , [PreviousQuantity]
              , [QuantityBeingReceieved]
              , [Grn]
        From    [#Results];

    End;





GO
