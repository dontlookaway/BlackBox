
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrderChanges]
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
--Exec  [Report].[UspResults_PurchaseOrderChanges] 10
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
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_PurchaseOrderChanges' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--grab and unpivot all audit tables in BlackBox History Tables

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'PorMasterHdr'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#PorMasterHdr]
            (
              [DatabaseName] Varchar(150)
            , [PurchaseOrder] Varchar(35)
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            );

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
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
					Insert #PorMasterHdr
							( DatabaseName
							, PurchaseOrder
							, OrderEntryDate
							, OrderDueDate
							)
					SELECT DatabaseName = @DB
						 , PurchaseOrder
						 , OrderEntryDate
						 , OrderDueDate FROM PorMasterHdr
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)


--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#Results]
            (
              [ItemKey] Varchar(150)
            , [PurchaseOrder] Varchar(35)
            , [Line] Varchar(35)
            , [OrderEntryDate] DateTime2
            , [OrderDueDate] DateTime2
            , [DatabaseName] Varchar(150)
            , [TransactionDescription] Varchar(200)
            , [SignatureDatetime] DateTime2
            , [Operator] Varchar(50)
            , [PreviousPrice] Float
            , [Price] Float
            , [PreviousForeignPrice] Float
            , [ForeignPrice] Float
            , [PreviousQuantity] Float
            , [Quantity] Float
            , [OrderUnitOfMeasure] Varchar(15)
            , [PriceDiff] Float
            , [PriceDiffPercent] Float
            , [ForeignPriceDiff] Float
            , [ForeignPriceDiffPercent] Float
            , [QuantityDiff] Float
            , [QuantityDiffPercent] Float
            , [LineForeignValue] Float
            , [PrevLineForeignValue] Float
            , [LineLocalValue] Float
            , [PrevLineLocalValue] Float
            , [CompanyName] Varchar(255)
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [ItemKey]
                , [PurchaseOrder]
                , [Line]
                , [OrderEntryDate]
                , [OrderDueDate]
                , [DatabaseName]
                , [TransactionDescription]
                , [SignatureDatetime]
                , [Operator]
                , [PreviousPrice]
                , [Price]
                , [PreviousForeignPrice]
                , [ForeignPrice]
                , [PreviousQuantity]
                , [Quantity]
                , [OrderUnitOfMeasure]
                , [PriceDiff]
                , [PriceDiffPercent]
                , [ForeignPriceDiff]
                , [ForeignPriceDiffPercent]
                , [QuantityDiff]
                , [QuantityDiffPercent]
                , [LineForeignValue]
                , [PrevLineForeignValue]
                , [LineLocalValue]
                , [PrevLineLocalValue]
                , [CompanyName]
                )
                Select  [PD].[ItemKey]
                      , [PurchaseOrder] = [PD].[PURCHASEORDER]
                      , [Line] = ParseName(Replace([PD].[ItemKey] , '     ' ,
                                                   '.') , 1)
                      , [PM].[OrderEntryDate]
                      , [PM].[OrderDueDate]
                      , [PD].[DatabaseName]
                      , [PD].[TransactionDescription]
                      , [PD].[SignatureDateTime]
                      , [PD].[Operator]
                      , [PD].[PREVIOUSPRICE]
                      , [PD].[PRICE]
                      , [PD].[PREVIOUSFOREIGNPRICE]
                      , [PD].[FOREIGNPRICE]
                      , [PD].[PREVIOUSQUANTITY]
                      , [PD].[QUANTITY]
                      , [PD].[ORDERUNITOFMEASURE]
                      , [PriceDiff] = Abs([PD].[PREVIOUSPRICE] - [PD].[PRICE])
                      , [PriceDiffPercent] = Case When Coalesce([PD].[PREVIOUSPRICE] ,
                                                              0) = 0 Then 1
                                                  Else Abs([PD].[PREVIOUSPRICE]
                                                           - [PD].[PRICE])
                                                       / [PD].[PREVIOUSPRICE]
                                             End
                      , [ForeignPriceDiff] = Abs([PD].[PREVIOUSFOREIGNPRICE]
                                                 - [PD].[FOREIGNPRICE])
                      , [ForeignPriceDiffPercent] = Case When Coalesce([PD].[PREVIOUSFOREIGNPRICE] ,
                                                              0) = 0 Then 1
                                                         Else Abs([PD].[PREVIOUSFOREIGNPRICE]
                                                              - [PD].[FOREIGNPRICE])
                                                              / [PD].[PREVIOUSFOREIGNPRICE]
                                                    End
                      , [QuantityDiff] = Abs([PD].[PREVIOUSQUANTITY]
                                             - [PD].[QUANTITY])
                      , [QuantityDiffPercent] = Case When Coalesce([PD].[PREVIOUSQUANTITY] ,
                                                              0) = 0 Then 1
                                                     Else Abs([PD].[PREVIOUSQUANTITY]
                                                              - [PD].[QUANTITY])
                                                          / [PD].[PREVIOUSQUANTITY]
                                                End
                      , [LineForeignValue] = ( [PD].[QUANTITY]
                                               * [PD].[FOREIGNPRICE] )
                      , [PrevLineForeignValue] = ( [PD].[PREVIOUSQUANTITY]
                                                   * [PD].[PREVIOUSFOREIGNPRICE] )
                      , [LineLocalValue] = ( [PD].[QUANTITY] * [PD].[PRICE] )
                      , [PrevLineLocalValue] = ( [PD].[PREVIOUSQUANTITY]
                                                 * [PD].[PREVIOUSPRICE] )
                      , [cn].[CompanyName]
                From    [History].[PorMasterDetail] [PD]
                        Inner Join [#PorMasterHdr] [PM] On [PD].[PURCHASEORDER] = [PM].[PurchaseOrder] Collate Latin1_General_BIN
                                                           And [PM].[DatabaseName] = [PD].[DatabaseName] Collate Latin1_General_BIN
                        Left Join [Lookups].[CompanyNames] As [cn] On 'SysproCompany'
                                                              + [cn].[Company] = [PD].[DatabaseName] Collate Latin1_General_BIN
                Where   [PD].[TransactionDescription] In (
                        'PO Change purchase order merchandise line' )
                Order By [PM].[OrderEntryDate] Desc;

	

--return results
        Select  [ItemKey]
              , [PurchaseOrder]
              , [Line]
              , [OrderEntryDate] = Cast([OrderEntryDate] As Date)
              , [OrderDueDate] = Cast([OrderDueDate] As Date)
              , [Company] = Replace([DatabaseName] , 'SysproCompany' , '')
              , [CompanyName]
              , [SignatureDatetime]
              , [Operator]
              , [PreviousPrice]
              , [Price]
              , [PreviousForeignPrice]
              , [ForeignPrice]
              , [PreviousQuantity]
              , [Quantity]
              , [OrderUnitOfMeasure]
              , [PriceDiff]
              , [PriceDiffPercent]
              , [ForeignPriceDiff]
              , [ForeignPriceDiffPercent] = [ForeignPriceDiffPercent] * 100 -- crystal does not handle decimal percentages
              , [QuantityDiff]
              , [QuantityDiffPercent] = [QuantityDiffPercent] * 100
              , [LineForeignValue] = Coalesce([LineForeignValue] ,
                                              [ForeignPrice])
              , [PrevLineForeignValue] = Coalesce([PrevLineForeignValue] ,
                                                  [PreviousForeignPrice]) --take into account POs without a quantity
              , [LineLocalValue] = Coalesce([LineLocalValue] , [Price])
              , [PrevLineLocalValue] = Coalesce([PrevLineLocalValue] ,
                                                [PreviousPrice])
        From    [#Results];

    End;


GO
