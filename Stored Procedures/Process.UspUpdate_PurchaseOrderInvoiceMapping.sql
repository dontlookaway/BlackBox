
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_PurchaseOrderInvoiceMapping]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with PurchaseOrderInvoiceMapping details	
transaction types when relating to inventory changes
*/

--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'PurchaseOrderInvoiceMapping' )
           )
            Begin
                Create --drop --alter 
Table [Lookups].[PurchaseOrderInvoiceMapping]
                    (
                      [Company] Varchar(150)
                    , [Grn] Varchar(20)
                    , [Invoice] Varchar(20)
                    , [PurchaseOrder] Varchar(20)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[PurchaseOrderInvoiceMapping];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                    Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'GrnMatching,GrnDetails'; 

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1POIM]
                    (
                      [Company] Varchar(150)
                    , [Grn] Varchar(20)
                    , [Invoice] Varchar(20)
                    , [PurchaseOrder] Varchar(20)
                    );



--create script to pull data from each db into the tables
                Declare @Company Varchar(30) = 'All';
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
					Insert #Table1POIM
							( Company
							, Grn
							, Invoice
							, PurchaseOrder
							)
				    Select Distinct
								Company = @DBCode
							  , Grn = COALESCE(GM.Grn, GD.Grn)
							  , GM.Invoice
							  , PurchaseOrder = COALESCE(GD.PurchaseOrder, PH.PurchaseOrder)
							From
								dbo.GrnMatching GM
							Left Join dbo.GrnDetails GD
								On GD.Grn = GM.Grn
							Full Outer Join dbo.PorMasterHdr PH
								On PH.PurchaseOrder = GD.PurchaseOrder;

			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

                Insert  [Lookups].[PurchaseOrderInvoiceMapping]
                        ( [Company]
                        , [Grn]
                        , [Invoice]
                        , [PurchaseOrder]
                        , [LastUpdated]
                        )
                        Select  [Company]
                              , [Grn]
                              , [Invoice]
                              , [PurchaseOrder]
                              , @LastUpdated
                        From    [#Table1POIM];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[PurchaseOrderInvoiceMapping]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[PurchaseOrderInvoiceMapping]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderInvoiceMapping]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderInvoiceMapping - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[PurchaseOrderInvoiceMapping]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_PurchaseOrderInvoiceMapping - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[PurchaseOrderInvoiceMapping]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_PurchaseOrderInvoiceMapping - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_PurchaseOrderInvoiceMapping - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;


GO
