SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PurchaseOrdersInvoices] ( @Company VARCHAR(Max) )
As
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			Return details of all purchase orders and invoices, highlighting where a PO is not available or was entered late		///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			21/9/2015	Chris Johnson			Initial version created																///
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
        Declare @ListOfTables VARCHAR(Max) = 'CshApPayments,ApInvoice,ApInvoicePay,PorMasterHdr,ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #CshApPayments
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , CbTrnYear INT
            , TrnMonth INT
            , Supplier VARCHAR(15) Collate Latin1_General_BIN
            , Invoice VARCHAR(35) Collate Latin1_General_BIN
            , InvoiceDate DATETIME2
            , Reference VARCHAR(60) Collate Latin1_General_BIN
            , PaymentNumber VARCHAR(35) Collate Latin1_General_BIN
            );



        Create Table #ApInvoice
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Supplier VARCHAR(15) Collate Latin1_General_BIN
            , Invoice VARCHAR(35) Collate Latin1_General_BIN
            , PaymentNumber VARCHAR(35) Collate Latin1_General_BIN
            );

       

        Create Table #ApInvoicePay
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , TrnValue FLOAT 
            , PaymentReference VARCHAR(35) Collate Latin1_General_BIN
            , Supplier VARCHAR(15) Collate Latin1_General_BIN
            , Invoice VARCHAR(35)  Collate Latin1_General_BIN
            );

        

        Create Table #PorMasterHdr
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , OrderEntryDate DATETIME2
            , PurchaseOrder VARCHAR(35) Collate Latin1_General_BIN
            );

        

        Create Table #ApSupplier
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Supplier VARCHAR(35) Collate Latin1_General_BIN
            , SupplierName VARCHAR(150) Collate Latin1_General_BIN
            );

        


        ;



--create script to pull data from each db into the tables
        Declare @SQL1 VARCHAR(Max) = '
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
				        Insert  #CshApPayments
										( DatabaseName
										, CbTrnYear
										, TrnMonth
										, Supplier
										, Invoice
										, InvoiceDate
										, Reference
										, PaymentNumber
										)
										Select
											[DatabaseName] = @DBCode
										  , CbTrnYear
										  , TrnMonth
										  , Supplier
										  , Invoice
										  , InvoiceDate
										  , Reference
										  , PaymentNumber
										From
											CshApPayments;
			End
	End';
	Declare @SQL2 VARCHAR(Max) = '
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
				 Insert  #ApInvoice
							( DatabaseName
							, Supplier
							, Invoice
							, PaymentNumber
							)
							Select
								[DatabaseName] = @DBCode
							  , Supplier
							  , Invoice
							  , PaymentNumber
							From
								ApInvoice;
			End
	End';
	Declare @SQL3 VARCHAR(Max) = '
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
				Insert  #ApInvoicePay
							( DatabaseName
							, TrnValue
							, PaymentReference
							, Supplier
							, Invoice
							)
							Select
								[DatabaseName] = @DBCode
							  , TrnValue
							  , PaymentReference
							  , Supplier
							  , Invoice
							From
								ApInvoicePay;
			End
	End';
	Declare @SQL4 VARCHAR(Max) = '
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
				Insert  #PorMasterHdr
                ( DatabaseName
                , OrderEntryDate
                , PurchaseOrder
		        )
                Select
                    [DatabaseName] = @DBCode
                  , OrderEntryDate
                  , PurchaseOrder
                From
                    PorMasterHdr;
			End
	End';
	Declare @SQL5 VARCHAR(Max) = '
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
				Insert  #ApSupplier
                ( DatabaseName
                , Supplier
                , SupplierName
		        )
                Select
                    [DatabaseName] = @DBCode
                  , Supplier
                  , SupplierName
                From
                    ApSupplier;
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
Print @SQL1
Print @SQL2
Print @SQL3
Print @SQL4
Print @SQL5

--execute script against each db, populating the base tables
        Exec sp_MSforeachdb @SQL1;
        Exec sp_MSforeachdb @SQL2;
        Exec sp_MSforeachdb @SQL3;
		Exec sp_MSforeachdb @SQL4;
		Exec sp_MSforeachdb @SQL5;

--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150)
            , TrnYear int
			,  TrnMonth int
			,  Supplier VARCHAR(35)
			,  SupplierName VARCHAR(150)
			,  Invoice VARCHAR(35)
			,  InvoiceDate DATETIME2
			,  Reference VARCHAR(60)
			,  PaymentNumber VARCHAR(35)
			,  TrnValue NUMERIC(18,3)
			,  PaymentReference VARCHAR(35)
			,  PurchaseOrder VARCHAR(35)
			,  OrderEntryDate DATETIME2
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  #Results
                ( DatabaseName
                , TrnYear
                , TrnMonth
                , Supplier
                , SupplierName
                , Invoice
                , InvoiceDate
                , Reference
                , PaymentNumber
                , TrnValue
                , PaymentReference
                , PurchaseOrder
                , OrderEntryDate
                )
                Select
					  CP.DatabaseName
					, CP.CbTrnYear
					, CP.TrnMonth
					, CP.Supplier
					, SP.SupplierName
					, CP.Invoice
					, CP.InvoiceDate
					, CP.Reference
					, CP.PaymentNumber
					, AIP.TrnValue
					, AIP.PaymentReference
					, PMO.PurchaseOrder
					, PHR.OrderEntryDate
					
        From
            #CshApPayments CP
        Left Join #ApInvoice AP
            On AP.DatabaseName = CP.DatabaseName
			And AP.Supplier = CP.Supplier
               And AP.Invoice = CP.Invoice
               And AP.PaymentNumber = CP.PaymentNumber
        Left Join #ApInvoicePay AIP
            On AIP.DatabaseName = AP.DatabaseName
			And AIP.Supplier = AP.Supplier
               And AIP.Invoice = AP.Invoice
        Left Join BlackBox.Lookups.PurchaseOrderInvoiceMapping PMO
            On PMO.Invoice = CP.Invoice Collate Latin1_General_BIN
               And PMO.Company = CP.DatabaseName
        Left Join #PorMasterHdr PHR
            On PHR.DatabaseName = AIP.DatabaseName
				And PHR.PurchaseOrder = PMO.PurchaseOrder
        Left Join #ApSupplier SP
            On SP.Supplier = CP.Supplier
			Group By CP.DatabaseName
					, CP.CbTrnYear --group added as there are multiple GRNs on PMO
					, CP.TrnMonth
					, CP.Supplier
					, SP.SupplierName
					, CP.Invoice
					, CP.InvoiceDate
					, CP.Reference
					, CP.PaymentNumber
					, AIP.TrnValue
					, AIP.PaymentReference
					, PMO.PurchaseOrder
					, PHR.OrderEntryDate

--return results
        Select
            Company = DatabaseName
          , TrnYear
          , TrnMonth
          , Supplier
          , SupplierName
          , Invoice
          , InvoiceDate = CAST(InvoiceDate As DATE)
          , Reference
          , PaymentNumber 
		  --= Case When ISNUMERIC(COALESCE(PaymentNumber,'I'))=0 Then PaymentNumber 
				--					When ISNUMERIC(PaymentNumber)=1 Then CONVERT(VARCHAR(25),CONVERT(bigINT,PaymentNumber))
				--												Else PaymentNumber End
          , TrnValue = coalesce(TrnValue,0)
          , PaymentReference = Case When ISNUMERIC(COALESCE(PaymentReference,'I'))=0 Then PaymentReference 
									When ISNUMERIC(PaymentReference)=1 Then CONVERT(VARCHAR(25),CONVERT(bigINT,PaymentReference))
																Else PaymentReference End
          , PurchaseOrder = Case When ISNUMERIC(COALESCE(PurchaseOrder,'I'))=0 Then PurchaseOrder 
									When ISNUMERIC(PurchaseOrder)=1 Then CONVERT(VARCHAR(25),CONVERT(bigINT,PurchaseOrder))
																Else PurchaseOrder End
          , OrderEntryDate = CAST(OrderEntryDate As DATE)
		  , [Status] = Case When PurchaseOrder Is Null
									Then 'No purchase order'
									When OrderEntryDate Is Null
									Then 'Unknown entry date'
									When OrderEntryDate >= InvoiceDate
									Then 'Purchase Order raised post receipt of invoice'
									else 'Purchase Order raised on time'
								End
        From
            #Results;

    End;

GO
