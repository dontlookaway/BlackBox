SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Deployment script for SP
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			22/9/2015	Chris Johnson			Initial version created																///
///			28/9/2015	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			SP to be created																										///
///			> Report.UspResults_PurchaseOrderChanges																				///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Rollback script																											///
///			Drop Proc  Report.UspResults_PurchaseOrderChanges																		///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

CREATE Proc [Report].[UspResults_PurchaseOrderChanges]
(@Company VARCHAR(Max))
--Exec  [Report].[UspResults_PurchaseOrderChanges] 10
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			22/9/2015	Chris Johnson			Initial version created																///
///			28/9/2015	Chris Johnson			Added company name																	///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			11/01/2016	Chris Johnson			Updated field names as per changes to report history								///
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
Set NoCount On

--grab and unpivot all audit tables in BlackBox History Tables
--Exec Process.UspPopulate_HistoryTables
--    @RebuildBit = 0 --set to 1 to recreate all tables and re-enter all details


--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'PorMasterHdr' 

--create temporary tables to be pulled from different databases, including a column to id
	CREATE TABLE #PorMasterHdr
	(	DatabaseName VARCHAR(150)
	    ,PurchaseOrder VARCHAR(35)
		, OrderEntryDate DATETIME2
		, OrderDueDate DATETIME2
	)



  


--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(max) = '
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
	End'

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL

--define the results you want to return
	Create --drop --alter 
Table #Results
    (
      ItemKey VARCHAR(150)
    , PurchaseOrder VARCHAR(35)
    , Line VARCHAR(35)
    , OrderEntryDate DATETIME2
    , OrderDueDate DATETIME2
    , DatabaseName VARCHAR(150)
    , TransactionDescription VARCHAR(200)
    , SignatureDatetime DATETIME2
    , Operator VARCHAR(50)
    , PreviousPrice FLOAT
    , Price FLOAT
    , PreviousForeignPrice FLOAT
    , ForeignPrice FLOAT
    , PreviousQuantity FLOAT
    , Quantity FLOAT
    , OrderUnitOfMeasure VARCHAR(15)
    , PriceDiff FLOAT
    , PriceDiffPercent FLOAT
    , ForeignPriceDiff FLOAT
    , ForeignPriceDiffPercent FLOAT
    , QuantityDiff FLOAT
    , QuantityDiffPercent FLOAT
    , LineForeignValue FLOAT
    , PrevLineForeignValue FLOAT
    , LineLocalValue FLOAT
    , PrevLineLocalValue FLOAT
	, CompanyName VARCHAR(255)
    );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	Insert #Results
        ( ItemKey
        , PurchaseOrder
        , Line
        , OrderEntryDate
        , OrderDueDate
        , DatabaseName
        , TransactionDescription
        , SignatureDatetime
        , Operator
        , PreviousPrice
        , Price
        , PreviousForeignPrice
        , ForeignPrice
        , PreviousQuantity
        , Quantity
        , OrderUnitOfMeasure
        , PriceDiff
        , PriceDiffPercent
        , ForeignPriceDiff
        , ForeignPriceDiffPercent
        , QuantityDiff
        , QuantityDiffPercent
        , LineForeignValue
        , PrevLineForeignValue
        , LineLocalValue
        , PrevLineLocalValue
		, [CompanyName]
        )
Select
    PD.ItemKey
  , PurchaseOrder = PD.[PURCHASEORDER]
  , Line = PARSENAME(REPLACE(PD.ItemKey, '     ', '.'), 1)
  , PM.OrderEntryDate
  , PM.OrderDueDate
  , PD.DatabaseName
  , PD.TransactionDescription
  , PD.[SignatureDateTime]
  , PD.Operator
  , PD.[PREVIOUSPRICE]
  , PD.PRICE
  , PD.[PREVIOUSFOREIGNPRICE]
  , PD.[FOREIGNPRICE]
  , PD.[PREVIOUSQUANTITY]
  , PD.QUANTITY
  , PD.[ORDERUNITOFMEASURE]
  , PriceDiff = ABS(PD.[PREVIOUSPRICE] - PD.PRICE)
  , PriceDiffPercent = Case When COALESCE(PD.[PREVIOUSPRICE], 0) = 0 Then 1
                            Else ABS(PD.[PREVIOUSPRICE] - PD.PRICE)
                                 / PD.[PREVIOUSPRICE]
                       End
  , ForeignPriceDiff = ABS(PD.[PREVIOUSFOREIGNPRICE] - PD.[FOREIGNPRICE])
  , ForeignPriceDiffPercent = Case When COALESCE(PD.[PREVIOUSFOREIGNPRICE],
                                                 0) = 0 Then 1
                                   Else ABS(PD.[PREVIOUSFOREIGNPRICE]
                                            - PD.[FOREIGNPRICE])
                                        / PD.[PREVIOUSFOREIGNPRICE]
                              End
  , QuantityDiff = ABS(PD.[PREVIOUSQUANTITY] - PD.QUANTITY)
  , QuantityDiffPercent = Case When COALESCE(PD.[PREVIOUSQUANTITY], 0) = 0
                               Then 1
                               Else ABS(PD.[PREVIOUSQUANTITY] - PD.QUANTITY)
                                    / PD.[PREVIOUSQUANTITY]
                          End
  , LineForeignValue = ( PD.QUANTITY * PD.[FOREIGNPRICE] )
  , PrevLineForeignValue = ( PD.[PREVIOUSQUANTITY]
                             * PD.[PREVIOUSFOREIGNPRICE] )
  , LineLocalValue = ( PD.QUANTITY * PD.PRICE )
  , PrevLineLocalValue = ( PD.[PREVIOUSQUANTITY] * PD.[PREVIOUSPRICE] )
  , [cn].[CompanyName]
From
    History.PorMasterDetail PD
Inner Join #PorMasterHdr PM
    On PD.[PURCHASEORDER] = PM.PurchaseOrder Collate Latin1_General_BIN
	And PM.DatabaseName = PD.DatabaseName Collate Latin1_General_BIN
Left Join [Lookups].[CompanyNames] As [cn] 
	On 'SysproCompany'+[cn].[Company]=[PD].[DatabaseName] Collate Latin1_General_BIN
Where
    TransactionDescription In ( 'PO Change purchase order merchandise line' --,'PO Add purchase order merchandise line' 
								)
    --And PD.Ranking = 1 --latest change
Order By
    PM.OrderEntryDate Desc;

	

--return results
	SELECT ItemKey
         , PurchaseOrder
         , Line
         , OrderEntryDate = cast(OrderEntryDate as date)
         , OrderDueDate = CAST(OrderDueDate as date)
         , Company = REPLACE(DatabaseName,'SysproCompany','')
         , [CompanyName]
         , SignatureDatetime
         , Operator
         , PreviousPrice
         , Price
         , PreviousForeignPrice
         , ForeignPrice
         , PreviousQuantity
         , Quantity
         , OrderUnitOfMeasure
         , PriceDiff
         , PriceDiffPercent
         , ForeignPriceDiff
         , ForeignPriceDiffPercent = ForeignPriceDiffPercent*100 -- crystal does not handle decimal percentages
         , QuantityDiff
         , QuantityDiffPercent = QuantityDiffPercent*100
         , LineForeignValue = coalesce(LineForeignValue,ForeignPrice)
         , PrevLineForeignValue = coalesce(PrevLineForeignValue,PreviousForeignPrice) --take into account POs without a quantity
         , LineLocalValue = coalesce(LineLocalValue,Price)
         , PrevLineLocalValue  = coalesce(PrevLineLocalValue,PreviousPrice)
From #Results

End


GO
