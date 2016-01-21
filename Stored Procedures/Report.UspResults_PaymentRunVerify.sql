SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_PaymentRunVerify] ( @Company VARCHAR(Max) )
--Exec [Report].[UspResults_PaymentRunVerify]  10
As
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
Stored procedure for Payment run verify
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			15/9/2015	Chris Johnson			Initial version created																///
///			28/9/2015	Chris Johnson			Added company name to final report													///
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
        Declare @ListOfTables VARCHAR(Max) = 'ApInvoice,ApJnlSummary,ApJnlDistrib,ApPayRunDet,ApPayRunHdr'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create --drop --alter 
	Table #ApInvoice
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(15)
            , Invoice VARCHAR(20)
            , PostCurrency CHAR(3)
            , ConvRate FLOAT
            , MulDiv CHAR(1)
            , MthInvBal1 FLOAT
            , InvoiceYear INT
            , InvoiceMonth INT
            , JournalDate DATETIME2
            , InvoiceDate DATETIME2
            );

        Create --drop --alter 
	Table #ApJnlSummary
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(15)
            , Invoice VARCHAR(20)
            , TrnYear INT
            , TrnMonth INT
            , Journal INT
            , EntryNumber INT
            );

        Create --drop --alter 
	Table #ApJnlDistrib
            (
              DatabaseName VARCHAR(150)
            , DistrValue FLOAT
            , ExpenseGlCode VARCHAR(35)
            , TrnYear INT
            , TrnMonth INT
            , Journal INT
            , EntryNumber INT
            );

        Create --drop --alter 
	Table #ApPayRunDet
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(15)
            , Invoice VARCHAR(20)
            , Cheque VARCHAR(15)
            , ChequeDate DATETIME2
            , InvoiceDate DATETIME2
            , NetPayValue FLOAT
            , DueDate DATETIME2
            , InvoiceType CHAR(1)
            , PostValue FLOAT
            , PostCurrency CHAR(3)
            , PostConvRate FLOAT
            , PostMulDiv CHAR(1)
            , SupplierName VARCHAR(50)
            , PaymentNumber VARCHAR(15)
            );

        Create --drop --alter 
	Table #ApPayRunHdr
            (
              DatabaseName VARCHAR(150)
            , PaymentNumber VARCHAR(15)
            , Bank VARCHAR(15)
            , PaymentDate DATETIME2
            , PayYear INT
            , PayMonth INT
            , Operator VARCHAR(20)
            , ChRegister FLOAT
            );
	
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
					Insert #ApInvoice
								( DatabaseName
								, Supplier
								, Invoice
								, PostCurrency
								, ConvRate
								, MulDiv
								, MthInvBal1
								, InvoiceYear
								, InvoiceMonth
								, JournalDate
								, InvoiceDate
								)
					SELECT @DBCode
							  , Supplier
							  , Invoice
							  , PostCurrency
							  , ConvRate
							  , MulDiv
							  , MthInvBal1
							  , InvoiceYear
							  , InvoiceMonth
							  , JournalDate
							  , InvoiceDate	 FROM ApInvoice

					Insert #ApJnlSummary
							( DatabaseName
							, Supplier
							, Invoice
							, TrnYear
							, TrnMonth
							, Journal
							, EntryNumber
							)
					SELECT @DBCode
							,Supplier
							,Invoice
							,TrnYear
							,TrnMonth
							,Journal
							,EntryNumber
					 FROM ApJnlSummary
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
						Insert #ApJnlDistrib
								( DatabaseName
								, DistrValue
								, ExpenseGlCode
								, TrnYear
								, TrnMonth
								, Journal
								, EntryNumber
								)
						SELECT @DBCode
								,DistrValue
								,ExpenseGlCode
								,TrnYear
								,TrnMonth
								,Journal
								,EntryNumber
						 FROM ApJnlDistrib

						 Insert #ApPayRunDet
								( DatabaseName
								, Supplier
								, Invoice
								, Cheque
								, ChequeDate
								, InvoiceDate
								, NetPayValue
								, DueDate
								, InvoiceType
								, PostValue
								, PostCurrency
								, PostConvRate
								, PostMulDiv
								, SupplierName
								, PaymentNumber
								)
						SELECT @DBCode
								,Supplier
								,Invoice
								,Cheque
								,ChequeDate
								,InvoiceDate
								,NetPayValue
								,DueDate
								,InvoiceType
								,PostValue
								,PostCurrency
								,PostConvRate
								,PostMulDiv
								,SupplierName
								,PaymentNumber
						FROM ApPayRunDet
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
				Insert #ApPayRunHdr
							( DatabaseName
							, PaymentNumber
							, Bank
							, PaymentDate
							, PayYear
							, PayMonth
							, Operator
							, ChRegister
							)
				SELECT @DBCode
							, PaymentNumber
							, Bank
							, PaymentDate
							, PayYear
							, PayMonth
							, Operator
							, ChRegister
				FROM ApPayRunHdr		
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec sp_MSforeachdb
            @SQL1;
        Exec sp_MSforeachdb
            @SQL2;
        Exec sp_MSforeachdb
            @SQL3;

--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150)
            , Supplier VARCHAR(15)
            , Invoice VARCHAR(20)
            , PostCurrency CHAR(3)
            , ConvRate FLOAT
            , MulDiv CHAR(1)
            , MthInvBal FLOAT
            , CompLocalAmt DECIMAL(10, 2)
            , DistrValue FLOAT
            , Description VARCHAR(50)
            , ExpenseGlCode VARCHAR(35)
            , InvoiceYear INT
            , InvoiceMonth INT
            , JournalDate DATETIME2
            , InvoiceDate DATETIME2
            , PaymentNumber INT
            , Bank VARCHAR(15)
            , PaymentDate DATETIME2
            , PayYear INT
            , PayMonth INT
            , Operator VARCHAR(20)
            , ChRegister FLOAT
            , Cheque VARCHAR(15)
            , ChequeDate DATETIME2
            --, InvoiceDate DATETIME2
            , InvNetPayValue DECIMAL(15, 3)
            , DueDate DATETIME2
            , InvoiceType CHAR(1)
            , PostValue DECIMAL(15, 3)
            , PostConvRate FLOAT
            , PostMulDiv CHAR(1)
            , SupplierName VARCHAR(50)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
        Insert  #Results
                ( DatabaseName
                , Supplier
                , Invoice
                , PostCurrency
                , ConvRate
                , MulDiv
                , MthInvBal
                , CompLocalAmt
                , DistrValue
                , Description
                , ExpenseGlCode
                , InvoiceYear
                , InvoiceMonth
                , JournalDate
                , InvoiceDate
                , PaymentNumber
                , Bank
                , PaymentDate
                , PayYear
                , PayMonth
                , Operator
                , ChRegister
                , Cheque
                , ChequeDate
                , InvNetPayValue
                , DueDate
                , InvoiceType
                , PostValue
                , PostConvRate
                , PostMulDiv
                , SupplierName
	            )
                Select
					AI.DatabaseName
                   , AI.Supplier
                  , AI.Invoice
                  , AI.PostCurrency
                  , AI.ConvRate
                  , AI.MulDiv
                  , MthInvBal = AI.MthInvBal1
                  , CompLocalAmt = CAST(Case When AI.MulDiv = 'M'
                                             Then AI.MthInvBal1 * AI.ConvRate
                                             Else AI.MthInvBal1 / AI.ConvRate
                                        End As DECIMAL(10, 2))
                  , DistrValue = SUM(AJD.DistrValue)
                  , GM.Description
                  , ExpenseGlCode = Case When AJD.ExpenseGlCode = '' Then Null
                                         Else AJD.ExpenseGlCode
                                    End
                  , AI.InvoiceYear
                  , AI.InvoiceMonth
                  , AI.JournalDate
                  , AI.InvoiceDate
                  , APH.PaymentNumber
                  , APH.Bank
                  , APH.PaymentDate
                  , APH.PayYear
                  , APH.PayMonth
                  , APH.Operator
                  , APH.ChRegister
                  , APD.Cheque
                  , APD.ChequeDate
                  , InvNetPayValue = APD.NetPayValue
                  , APD.DueDate
                  , APD.InvoiceType
                  , APD.PostValue
                  , APD.PostConvRate
                  , APD.PostMulDiv
                  , APD.SupplierName
                From
                    #ApInvoice AI
                Left Join #ApJnlSummary AJS With ( NoLock )
                    On AI.Supplier = AJS.Supplier
                       And AI.Invoice = AJS.Invoice
                       And AJS.DatabaseName = AI.DatabaseName
                Left Join #ApJnlDistrib AJD With ( NoLock )
                    On AJD.TrnYear = AJS.TrnYear
                       And AJD.TrnMonth = AJS.TrnMonth
                       And AJD.Journal = AJS.Journal
                       And AJD.EntryNumber = AJS.EntryNumber
                       And AJD.DatabaseName = AJS.DatabaseName
                Left Join SysproCompany40.dbo.GenMaster GM
                    On GM.GlCode = AJD.ExpenseGlCode Collate Latin1_General_BIN
                Inner Join #ApPayRunDet APD
                    On APD.Supplier = AI.Supplier
                       And APD.Invoice = AI.Invoice
                       And APD.DatabaseName = AI.DatabaseName
                Left Join #ApPayRunHdr APH
                    On APH.PaymentNumber = APD.PaymentNumber
                       And APH.PaymentNumber = APD.PaymentNumber
                Group By
                    AI.DatabaseName
                   , AJD.TrnYear
                  , AJD.TrnMonth
                  , Case When AJD.ExpenseGlCode = '' Then Null
                         Else AJD.ExpenseGlCode
                    End
                  , GM.Description
                  , AJS.Supplier
                  , AJS.Invoice
                  , AI.Supplier
                  , AI.Invoice
                  , AI.PostCurrency
                  , AI.ConvRate
                  , AI.MulDiv
                  , AI.MthInvBal1
                  , CAST(Case When AI.MulDiv = 'M'
                              Then AI.MthInvBal1 * AI.ConvRate
                              Else AI.MthInvBal1 / AI.ConvRate
                         End As DECIMAL(10, 2))
                  , AI.InvoiceYear
                  , AI.InvoiceMonth
                  , AI.JournalDate
                  , AI.InvoiceDate
                  , APH.PaymentNumber
                  , APH.Bank
                  , APH.PaymentDate
                  , APH.PayYear
                  , APH.PayMonth
                  , APH.Operator
                  , APH.ChRegister
                  , APD.Cheque
                  , APD.ChequeDate
                  , APD.InvoiceDate
                  , APD.NetPayValue
                  , APD.DueDate
                  , APD.InvoiceType
                  , APD.PostValue
                  , APD.PostCurrency
                  , APD.PostConvRate
                  , APD.PostMulDiv
                  , APD.SupplierName;

--return results
        Select
            Company = DatabaseName
          , Supplier
          , Invoice
          , PostCurrency
          , ConvRate
          , MulDiv
          , MthInvBal
          , CompLocalAmt
          , DistrValue
          , Description
          , ExpenseGlCode
          , InvoiceYear
          , InvoiceMonth
          , JournalDate = CONVERT(DATE,JournalDate)
          , PaymentNumber
          , Bank
          , PaymentDate = CONVERT(DATE,PaymentDate)
          , PayYear
          , PayMonth
          , Operator
          , ChRegister
          , Cheque
          , ChequeDate = CONVERT(DATE,ChequeDate)
          , InvoiceDate = CONVERT(DATE,InvoiceDate)
          , InvNetPayValue
          , DueDate = CONVERT(DATE,DueDate)
          , InvoiceType
          , PostValue
          , PostConvRate
          , PostMulDiv
          , SupplierName
		  ,[cn].[CompanyName]
        From
            #Results R
		Left Join [Lookups].[CompanyNames] As [cn] On [cn].[Company]=[R].[DatabaseName] Collate Latin1_General_BIN
			;

    End;


GO
