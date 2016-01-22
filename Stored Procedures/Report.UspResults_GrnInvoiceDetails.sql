
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GrnInvoiceDetails] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
 --exec [Report].[UspResults_GrnInvoiceDetails] @Company ='10'
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'GrnMatching,GrnDetails,PorMasterDetail,ReqRouting'; 
        Declare @LoadDate DateTime2 = GetDate()
          , @IsComplete Bit;

--Create Results Table
        If Not Exists ( Select  [T].[name]
                        From    [sys].[schemas] As [S]
                                Left Join [sys].[tables] As [T] On [T].[schema_id] = [S].[schema_id]
                        Where   [S].[name] = 'Report'
                                And [T].[name] = 'GrnInvoiceDetails' )
            Begin
                Create Table [Report].[GrnInvoiceDetails]
                    (
                      [DatabaseName] Varchar(150)
                    , [Supplier] Varchar(150)
                    , [Grn] Varchar(50)
                    , [TransactionType] Varchar(5)
                    , [Journal] Int
                    , [EntryNumber] Int
                    , [Invoice] Varchar(150)
                    , [PurchaseOrder] Varchar(150)
                    , [PurchaseOrderLine] Int
                    , [Requisition] Varchar(150)
                    , [RequisitionLine] Int
                    , [GlCode] Varchar(50)
                    , [Description] Varchar(150)
                    , [MatchedValue] Decimal(15 , 3)
                    , [MatchedDate] Date
                    , [StockCode] Varchar(50)
                    , [QtyReceived] Decimal(20 , 12)
                    , [MatchedYear] Int
                    , [MatchedMonth] Int
                    , [MatchedQty] Decimal(20 , 12)
                    , [Operator] Varchar(150)
                    , [Approver] Varchar(150)
                    , [OrigReceiptDate] Date
                    , [LoadDate] DateTime2
                    );
            End;
--Create Process table - this will capture if job is incomplete
        If Not Exists ( Select  [T].[name]
                        From    [sys].[schemas] As [S]
                                Left Join [sys].[tables] As [T] On [T].[schema_id] = [S].[schema_id]
                        Where   [S].[name] = 'Process'
                                And [T].[name] = 'GrnInvoiceDetails' )
            Begin
                Create Table [Process].[GrnInvoiceDetails]
                    (
                      [LoadDate] DateTime2
                    , [IsComplete] Bit Default 0
                    , [Company] Varchar(150)
                    );
            End;

        Select  @IsComplete = [IsComplete]
              , @LoadDate = [LoadDate]
        From    [Process].[GrnInvoiceDetails]
        Where   DateDiff(Minute , [LoadDate] , @LoadDate) <= 3
                And [Company] = @Company;

--if there are no started procs then grab data and store locally
        If @IsComplete Is Null
            Begin
                Insert  [Process].[GrnInvoiceDetails]
                        ( [LoadDate]
                        , [IsComplete]
                        , [Company]
                        )
                Values  ( @LoadDate
                        , 0
                        , @Company
                        );

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#GrnMatching]
                    (
                      [DatabaseName] Varchar(150)
                    , [Supplier] Varchar(150)
                    , [Grn] Varchar(50)
                    , [TransactionType] Varchar(5)
                    , [Journal] Int
                    , [EntryNumber] Int
                    , [Invoice] Varchar(50)
                    , [MatchedValue] Decimal(15 , 2)
                    , [MatchedDate] DateTime2
                    , [MatchedYear] Int
                    , [MatchedMonth] Int
                    , [MatchedQty] Decimal(20 , 12)
                    );
                Create Table [#GrnDetails]
                    (
                      [DatabaseName] Varchar(150)
                    , [PurchaseOrder] Varchar(20)
                    , [PurchaseOrderLin] Int
                    , [DebitRecGlCode] Varchar(50)
                    , [StockCode] Varchar(30)
                    , [QtyReceived] Decimal(25 , 8)
                    , [Supplier] Varchar(150)
                    , [Grn] Varchar(25)
                    , [GrnSource] Varchar(150)
                    , [Journal] Int
                    , [JournalEntry] Int
                    , [OrigReceiptDate] Date
                    );
                Create Table [#PorMasterDetail]
                    (
                      [DatabaseName] Varchar(150)
                    , [MRequisition] Varchar(50)
                    , [MRequisitionLine] Int
                    , [PurchaseOrder] Varchar(50)
                    , [Line] Int
                    );
                Create Table [#ReqRouting]
                    (
                      [DatabaseName] Varchar(150)
                    , [Requisition] Varchar(10)
                    , [RequisitionLine] Int
                    , [Operator] Varchar(150)
                    );
                Create Table [#ReqDetails]
                    (
                      [Requisition] Varchar(10)
                    , [UserCode] Varchar(20)
                    , [DatabaseName] Varchar(150)
                    , [Line] Int
                    );

--create script to pull data from each db into the tables
                Declare @SQL1a Varchar(Max) = '
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
				Insert #GrnMatching
			        ( DatabaseName
			        , Supplier
			        , Grn
			        , TransactionType
			        , Journal
			        , EntryNumber
			        , Invoice
			        , MatchedValue
			        , MatchedDate
			        , MatchedYear
			        , MatchedMonth
			        , MatchedQty
			        )
				Select DatabaseName = @DBCode
			        , Supplier
			        , Grn
			        , TransactionType
			        , Journal
			        , EntryNumber
			        , Invoice
			        , MatchedValue
			        , MatchedDate
			        , MatchedYear
			        , MatchedMonth
			        , MatchedQty
					From GrnMatching
			End
	End';
                Declare @SQL1b Varchar(Max) = '
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
			Insert #GrnDetails
			        ( DatabaseName, PurchaseOrder, PurchaseOrderLin, DebitRecGlCode, StockCode, QtyReceived, Supplier, Grn, GrnSource, Journal, JournalEntry, [OrigReceiptDate] )
			SELECT DatabaseName = @DBCode
                 , PurchaseOrder
                 , PurchaseOrderLin
                 , DebitRecGlCode
                 , StockCode
                 , QtyReceived
                 , Supplier
                 , Grn
                 , GrnSource
                 , Journal
                 , JournalEntry
				 , [OrigReceiptDate]  FROM GrnDetails
			End
	End';
                Declare @SQL2 Varchar(Max) = '
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
				Insert #PorMasterDetail
			        ( DatabaseName
			        , MRequisition
			        , MRequisitionLine
			        , PurchaseOrder
			        , Line
			        )
				SELECT DatabaseName = @DBCode
					 , MRequisition
					 , MRequisitionLine
					 , PurchaseOrder
					 , Line FROM PorMasterDetail

				Insert #ReqRouting
			        ( DatabaseName
			        , Requisition
			        , RequisitionLine
			        , Operator
			        )
				SELECT DatabaseName = @DBCode
                 , Requisition
                 , RequisitionLine
                 , Operator FROM ReqRouting
				 where Operator  <> ''''
			End
	End';
                Declare @SQLReq Varchar(Max) = '
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
		Insert  [#ReqDetails] ( [DatabaseName], [Requisition], [Line], [UserCode])
        Select  DatabaseName = @DBCode
		, [Requisition]
		, [Line] 
		, [UserCode]
        From    [ReqDetail];
			End
	End';


--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1a
--Print @SQL1b
--Print @SQL2

--execute script against each db, populating the base tables
                Print 'A';
                Exec [Process].[ExecForEachDB] @cmd = @SQL1a;
                Print 'B';
                Exec [Process].[ExecForEachDB] @cmd = @SQL1b;
                Print 'C';
                Exec [Process].[ExecForEachDB] @cmd = @SQL2;
                Print 'D';
                Exec [Process].[ExecForEachDB] @cmd = @SQLReq;
                Print 'Run';
--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table
                Insert  [Report].[GrnInvoiceDetails]
                        ( [DatabaseName]
                        , [Supplier]
                        , [Grn]
                        , [TransactionType]
                        , [Journal]
                        , [EntryNumber]
                        , [Invoice]
                        , [PurchaseOrder]
                        , [PurchaseOrderLine]
                        , [Requisition]
                        , [RequisitionLine]
                        , [GlCode]
                        , [Description]
                        , [MatchedValue]
                        , [MatchedDate]
                        , [StockCode]
                        , [QtyReceived]
                        , [MatchedYear]
                        , [MatchedMonth]
                        , [MatchedQty]
                        , [Operator]
                        , [Approver]
                        , [OrigReceiptDate]
                        , [LoadDate]
                        )
                        Select  @Company
                              , [GM].[Supplier]
                              , [GM].[Grn]
                              , [GM].[TransactionType]
                              , [GM].[Journal]
                              , [GM].[EntryNumber]
                              , [GM].[Invoice]
                              , [GD].[PurchaseOrder]
                              , [GD].[PurchaseOrderLin]
                              , [PD].[MRequisition]
                              , [PD].[MRequisitionLine]
                              , [GD].[DebitRecGlCode]
                              , [GMS].[Description]
                              , [GM].[MatchedValue]
                              , [GM].[MatchedDate]
                              , [GD].[StockCode]
                              , [GD].[QtyReceived]
                              , [GM].[MatchedYear]
                              , [GM].[MatchedMonth]
                              , [GM].[MatchedQty]
                              , [RR].[Operator]
                              , [Approver] = [RD].[UserCode]
                              , [GD].[OrigReceiptDate]
                              , @LoadDate
                        From    [#GrnMatching] [GM]
                                Inner Join [#GrnDetails] [GD] On [GM].[Supplier] = [GD].[Supplier]
                                                              And [GM].[Grn] = [GD].[Grn]
                                                              And [GM].[TransactionType] = [GD].[GrnSource]
                                                              And [GM].[Journal] = [GD].[Journal]
                                                              And [GM].[EntryNumber] = [GD].[JournalEntry]
                                                              And [GD].[DatabaseName] = [GM].[DatabaseName]
                                Inner Join [SysproCompany40].[dbo].[GenMaster] [GMS] On [GMS].[GlCode] = [GD].[DebitRecGlCode] Collate Latin1_General_BIN
                                Inner Join [#PorMasterDetail] [PD] On [GD].[PurchaseOrder] = [PD].[PurchaseOrder]
                                                              And [GD].[PurchaseOrderLin] = [PD].[Line]
                                                              And [PD].[DatabaseName] = [GD].[DatabaseName]
                                Left Outer Join [#ReqRouting] [RR] On [RR].[Requisition] = [PD].[MRequisition]
                                                              And [RR].[RequisitionLine] = [PD].[MRequisitionLine]
                                                              And [RR].[DatabaseName] = [PD].[DatabaseName]
                                Left Join [#ReqDetails] As [RD] On [RD].[Requisition] = [RR].[Requisition]
                                                              And [RD].[Line] = [RR].[RequisitionLine]
                                                              And [RD].[DatabaseName] = [RR].[DatabaseName];

                Update  [Process].[GrnInvoiceDetails]
                Set     [IsComplete] = 1
                Where   [LoadDate] = @LoadDate
                        And [Company] = @Company;

                Set @IsComplete = 1;
            End;


        While @IsComplete < 1
            Begin
                WaitFor Delay '00:00:01';
                Select  @IsComplete = [GID].[IsComplete]
                From    [Process].[GrnInvoiceDetails] As [GID]
                Where   [GID].[Company] = @Company
                        And [GID].[LoadDate] = @LoadDate;
            End;


--return results
        Select  [Company] = [GID].[DatabaseName]
              , [GID].[Supplier]
              , [GID].[Grn]
              , [GID].[TransactionType]
              , [GID].[Journal]
              , [GID].[EntryNumber]
              , [GID].[Invoice]
              , [GID].[PurchaseOrder]
              , [GID].[PurchaseOrderLine]
              , [GID].[Requisition]
              , [GID].[RequisitionLine]
              , [GID].[GlCode]
              , [GID].[Description]
              , [GID].[MatchedValue]
              , [GID].[MatchedDate]
              , [GID].[StockCode]
              , [GID].[QtyReceived]
              , [GID].[MatchedYear]
              , [GID].[MatchedMonth]
              , [GID].[MatchedQty]
              , [GID].[Operator]
              , [GID].[Approver]
              , [GID].[OrigReceiptDate]
        From    [Report].[GrnInvoiceDetails] As [GID]
        Where   [GID].[LoadDate] = @LoadDate
                And [GID].[DatabaseName] = @Company;

    End;

GO
