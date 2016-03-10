
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_UnpaidAssets]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015 Stored procedure set out to query multiple databases with the same information and return it in a collated format	

--exec [Report].[UspResults_UnpaidAssets]  43
*/
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
            @StoredProcName = 'UspResults_UnpaidAssets' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;
--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApInvoice,ApJnlSummary,GrnMatching,GrnDetails,ApControl,ApJnlDistrib'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ApInvoice]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [Invoice] Varchar(50) Collate Latin1_General_BIN
            , [PostCurrency] Varchar(15) Collate Latin1_General_BIN
            , [ConvRate] Float
            , [MulDiv] Varchar(15) Collate Latin1_General_BIN
            , [MthInvBal1] Float
            , [MthInvBal2] Float
            , [MthInvBal3] Float
            , [InvoiceYear] Int
            , [InvoiceMonth] Int
            , [JournalDate] DateTime2
            , [InvoiceDate] DateTime2
            );
        Create Table [#ApJnlSummary]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [Invoice] Varchar(50) Collate Latin1_General_BIN
            , [TrnYear] Int
            , [TrnMonth] Int
            , [Journal] Int
            , [EntryNumber] Int
            );
        Create Table [#GrnMatching]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Supplier] Varchar(50) Collate Latin1_General_BIN
            , [Grn] Varchar(35) Collate Latin1_General_BIN
            , [TransactionType] Varchar(10) Collate Latin1_General_BIN
            , [Journal] Int
            , [EntryNumber] Int
            , [Invoice] Varchar(35) Collate Latin1_General_BIN
            );
        Create Table [#GrnDetails]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [MatchedValue] Float
            , [DebitRecGlCode] Varchar(35) Collate Latin1_General_BIN
            , [GrnMonth] Int
            , [GrnYear] Int
            , [Supplier] Varchar(35) Collate Latin1_General_BIN
            , [Grn] Varchar(35) Collate Latin1_General_BIN
            , [GrnSource] Varchar(50) Collate Latin1_General_BIN
            , [Journal] Int
            , [JournalEntry] Int
            );
        Create Table [#ApControl]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [FinPeriodDate] DateTime2
            );
        Create Table [#ApJnlDistrib]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [DistrValue] Float
            , [TrnMonth] Int
            , [TrnYear] Int
            , [Journal] Int
            , [EntryNumber] Int
            , [ExpenseGlCode] Varchar(35) Collate Latin1_General_BIN
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
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
				Insert [#ApInvoice]
						( [DatabaseName]
						, [Supplier]
						, [Invoice]
						, [PostCurrency]
						, [ConvRate]
						, [MulDiv]
						, [MthInvBal1]
						, [MthInvBal2]
						, [MthInvBal3]
						, [InvoiceYear]
						, [InvoiceMonth]
						, [JournalDate]
						, [InvoiceDate]
						)
				SELECT [DatabaseName]=@DBCode
					 , [ai].[Supplier]
					 , [ai].[Invoice]
					 , [ai].[PostCurrency]
					 , [ai].[ConvRate]
					 , [ai].[MulDiv]
					 , [ai].[MthInvBal1]
					 , [ai].[MthInvBal2]
					 , [ai].[MthInvBal3]
					 , [ai].[InvoiceYear]
					 , [ai].[InvoiceMonth]
					 , [ai].[JournalDate]
					 , [ai].[InvoiceDate] 
				From [ApInvoice] As [ai]
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
			Insert [#ApJnlSummary]
			        ( [DatabaseName]
			        , [Supplier]
			        , [Invoice]
			        , [TrnYear]
			        , [TrnMonth]
			        , [Journal]
			        , [EntryNumber]
			        )
			SELECT [DatabaseName]=@DBCode
                 , [ajs].[Supplier]
                 , [ajs].[Invoice]
                 , [ajs].[TrnYear]
                 , [ajs].[TrnMonth]
                 , [ajs].[Journal]
                 , [ajs].[EntryNumber] 
			FROM [ApJnlSummary] As [ajs]
			End
	End';
        Declare @SQL3 Varchar(Max) = '
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
				Insert [#GrnMatching]
						( [DatabaseName]
						, [Supplier]
						, [Grn]
						, [TransactionType]
						, [Journal]
						, [EntryNumber]
						, [Invoice]
						)
				SELECT [DatabaseName]=@DBCode
					 , [gm].[Supplier]
					 , [gm].[Grn]
					 , [gm].[TransactionType]
					 , [gm].[Journal]
					 , [gm].[EntryNumber]
					 , [gm].[Invoice]
				FROM [GrnMatching] As [gm]
			End
	End';
        Declare @SQL4 Varchar(Max) = '
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
				Insert [#GrnDetails]
						( [DatabaseName]
						, [MatchedValue]
						, [DebitRecGlCode]
						, [GrnMonth]
						, [GrnYear]
						, [Supplier]
						, [Grn]
						, [GrnSource]
						, [Journal]
						, [JournalEntry]
						)
				SELECT [DatabaseName] = @DBCode
					 , [gd].[MatchedValue]
					 , [gd].[DebitRecGlCode]
					 , [gd].[GrnMonth]
					 , [gd].[GrnYear]
					 , [gd].[Supplier]
					 , [gd].[Grn]
					 , [gd].[GrnSource]
					 , [gd].[Journal]
					 , [gd].[JournalEntry]
				FROM [GrnDetails] As [gd]
			End
	End';
        Declare @SQL5 Varchar(Max) = '
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
				Insert  [#ApControl]
						( [DatabaseName]
						, [FinPeriodDate]
						)
				Select [DatabaseName]=@DBCode
					,FinPeriodDate = DATEADD(Month, [AC1].[FinPeriod] - 1,
											CAST(CAST(FinYear As CHAR(4)) As DATETIME2))
				From
					ApControl As AC1
				Where
					CtlFlag = ''CTL''
			End
	End';
        Declare @SQL6 Varchar(Max) = '
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
				Insert [#ApJnlDistrib]
						( [DatabaseName]
						, [DistrValue]
						, [TrnMonth]
						, [TrnYear]
						, [Journal]
						, [EntryNumber]
						, [ExpenseGlCode]
						)
				SELECT [DatabaseName]=@DBCode
					 , [ajd].[DistrValue]
					 , [ajd].[TrnMonth]
					 , [ajd].[TrnYear]
					 , [ajd].[Journal]
					 , [ajd].[EntryNumber]
					 , [ajd].[ExpenseGlCode]
				FROM [ApJnlDistrib] As [ajd]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL1

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
        Exec [Process].[ExecForEachDB] @cmd = @SQL5;
        Exec [Process].[ExecForEachDB] @cmd = @SQL6;

--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table


--return results
	
--Create AP table
        Select  [ai].[Supplier]
              , [ai].[Invoice]
              , [ai].[PostCurrency]
              , [ai].[ConvRate]
              , [ai].[MulDiv]
              , [ai].[MthInvBal1]
              , [ai].[MthInvBal2]
              , [ai].[MthInvBal3]
              , [DistrValue] = [ajd].[DistrValue]
              , [ExpenseDescription] = [gm].[Description]
              , [ExpenseGlCode] = [ajd].[ExpenseGlCode]
              , [ai].[InvoiceYear]
              , [ai].[InvoiceMonth]
              , [ai].[JournalDate]
              , [ai].[InvoiceDate]
              , [PrevFiscalPeriods] = DateDiff(mm ,
                                             DateAdd(Month ,
                                                     [ajd].[TrnMonth] - 1 ,
                                                     Cast(Cast([ajd].[TrnYear] As Char(4)) As DateTime2)) ,
                                             [ApControl].[FinPeriodDate])
        Into    [#AP]
        From    [#ApInvoice] As [ai]
                Left Join [#ApJnlSummary] As [ajs] On [ajs].[Supplier] = [ai].[Supplier] Collate Latin1_General_BIN
                                                      And [ajs].[Invoice] = [ai].[Invoice] Collate Latin1_General_BIN
                Left Join [#ApJnlDistrib] As [ajd] On [ajd].[TrnYear] = [ajs].[TrnYear]
                                                      And [ajd].[TrnMonth] = [ajs].[TrnMonth]
                                                      And [ajd].[Journal] = [ajs].[Journal]
                                                      And [ajd].[EntryNumber] = [ajs].[EntryNumber]
                Left Join [SysproCompany40]..[GenMaster] As [gm] On [ajd].[ExpenseGlCode] Collate Latin1_General_BIN = [gm].[GlCode] Collate Latin1_General_BIN
                Cross Join ( Select [ac].[FinPeriodDate]
                             From   [#ApControl] As [ac]
                           ) As [ApControl]
        Where   ParseName([gm].[GlCode] , 2) In ( '11200' , '11201' , '26001' ,
                                             '26011' , '26021' , '22999' )
                Or ParseName([gm].[GlCode] , 2) Like '22%%1'
                Or ( ParseName([gm].[GlCode] , 1) = '003'
                     And ParseName([gm].[GlCode] , 2) = '49900'
                   );

--Create GRN table
        Select  [API].[Supplier]
              , [API].[Invoice]
              , [API].[PostCurrency]
              , [API].[ConvRate]
              , [API].[MulDiv]
              , [API].[MthInvBal1]
              , [API].[MthInvBal2]
              , [API].[MthInvBal3]
              , [MatchedValue] = [gd].[MatchedValue]
              , [Description] = [gmst].[Description]
              , [DebitRecGlCode] = [gd].[DebitRecGlCode]
              , [API].[InvoiceYear]
              , [API].[InvoiceMonth]
              , [API].[JournalDate]
              , [API].[InvoiceDate]
              , [PrevFiscalPeriods] = DateDiff(mm ,
                                             DateAdd(Month ,
                                                     [gd].[GrnMonth] - 1 ,
                                                     Cast(Cast([gd].[GrnYear] As Char(4)) As DateTime2)) ,
                                             [ApControl].[FinPeriodDate])
        Into    [#GRN]
        From    [SysproCompany43]..[ApInvoice] [API]
                Left Join [#GrnMatching] As [gm] On [gm].[Supplier] = [API].[Supplier] Collate Latin1_General_BIN
                                                    And [gm].[Invoice] = [API].[Invoice] Collate Latin1_General_BIN
                Left Join [#GrnDetails] As [gd] On [gd].[Supplier] = [gm].[Supplier] Collate Latin1_General_BIN
                                                   And [gd].[Grn] = [gm].[Grn] Collate Latin1_General_BIN
                                                   And [gd].[GrnSource] = [gm].[TransactionType] Collate Latin1_General_BIN
                                                   And [gd].[Journal] = [gm].[Journal]
                                                   And [gd].[JournalEntry] = [gm].[EntryNumber]
                Left Join [SysproCompany40]..[GenMaster] As [gmst] On [gd].[DebitRecGlCode] Collate Latin1_General_BIN = [gmst].[GlCode]
                Cross Join ( Select [AC1].[FinPeriodDate]
                             From   [#ApControl] As [AC1]
                           ) As [ApControl]
        Where   ParseName([gmst].[GlCode] , 2) In ( '11200' , '11201' , '26001' ,
                                             '26011' , '26021' , '22999' )
                Or ParseName([gmst].[GlCode] , 2) Like '22%%1'
                Or ( ParseName([gmst].[GlCode] , 1) = '003'
                     And ParseName([gmst].[GlCode] , 2) = '49900'
                   );

--unpivot both tables and union together
        Select  [t].[Period]
              , [t].[Supplier]
              , [t].[Invoice]
              , [t].[PostCurrency]
              , [t].[ConvRate]
              , [t].[MulDiv]
              , [t].[CompLocalAmt]
              , [t].[MthInvBal]
              , [DistrValue] = Sum([t].[DistrValue])
              , [t].[ExpenseDescription]
              , [t].[ExpenseGlCode]
              , [t].[InvoiceYear]
              , [t].[InvoiceMonth]
              , [t].[JournalDate]
              , [t].[InvoiceDate]
              , [t].[PrevFiscalPeriods]
        From    ( Select    [Period] = 'P' Collate Latin1_General_BIN
                            + Right([MthInvPeriod] , 1)
                          , [Supplier]
                          , [Invoice]
                          , [PostCurrency]
                          , [ConvRate]
                          , [MulDiv]
                          , [MthInvBal]
                          , [CompLocalAmt] = Case When [MulDiv] = 'M' Collate Latin1_General_BIN
                                                Then [MthInvBal] * [ConvRate]
                                                Else [MthInvBal] / [ConvRate]
                                           End
                          , [DistrValue]
                          , [ExpenseDescription]
                          , [ExpenseGlCode]
                          , [InvoiceYear]
                          , [InvoiceMonth]
                          , [JournalDate] = Convert(Date,[JournalDate])
                          , [InvoiceDate] = Convert(Date , [InvoiceDate])
                          , [PrevFiscalPeriods]
                  From      [#AP] Unpivot ( [MthInvBal] For [MthInvPeriod] In ( [MthInvBal1] ,
                                                              [MthInvBal2] ,
                                                              [MthInvBal3] ) ) As [ASMT]
                  Where     [MthInvBal] <> 0
                  Union All
                  Select    [Period] = 'P' Collate Latin1_General_BIN
                            + Right([MthInvPeriod] , 1)
                          , [Supplier]
                          , [Invoice]
                          , [PostCurrency]
                          , [ConvRate]
                          , [MulDiv]
                          , [MthInvBal]
                          , [CompLocalAmt] = Case When [MulDiv] = 'M' Collate Latin1_General_BIN
                                                Then [MthInvBal] * [ConvRate]
                                                Else [MthInvBal] / [ConvRate]
                                           End
                          , [MatchedValue]
                          , [Description]
                          , [DebitRecGlCode]
                          , [InvoiceYear]
                          , [InvoiceMonth]
                          , [JournalDate] = Convert(Date,[JournalDate])
                          , [InvoiceDate] = Convert(Date , [InvoiceDate])
                          , [PrevFiscalPeriods]
                  From      [#GRN] Unpivot ( [MthInvBal] For [MthInvPeriod] In ( [MthInvBal1] ,
                                                              [MthInvBal2] ,
                                                              [MthInvBal3] ) ) As [ASMT]
                  Where     [MthInvBal] <> 0
                ) [t]
        Where   [MthInvBal] <> 0
        Group By [t].[Period]
              , [t].[Supplier]
              , [t].[Invoice]
              , [t].[PostCurrency]
              , [t].[ConvRate]
              , [t].[MulDiv]
              , [t].[CompLocalAmt]
              , [t].[MthInvBal]
              , [t].[ExpenseDescription]
              , [t].[ExpenseGlCode]
              , [t].[InvoiceYear]
              , [t].[InvoiceMonth]
              , [t].[JournalDate]
              , [t].[InvoiceDate]
              , [t].[PrevFiscalPeriods];

    End;

GO
