SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_ApSupplier]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin
--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'ApSupplier' )
           )
            Begin
                Create Table [Lookups].[ApSupplier]
                    (
                      [Company] Varchar(150)
                    , [Supplier] Varchar(150)
                    , [SupplierName] Varchar(150)
                    , [LastUpdated] DateTime2
					, [ActivePOFlag] bit
                    );
            End;

--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[ApSupplier];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'ApSupplier'; 

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1Supplier]
                    (
                      [Company] Varchar(150)
                    , [Supplier] Varchar(150)
                    , [SupplierName] Varchar(150)
					, [ActivePOFlag] bit
                    );

--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
			BEGIN
				Insert #Table1Supplier
					( Company, Supplier, [SupplierName], [ActivePOFlag])
				Select @DBCode
				,[APS].Supplier
				,[APS].[SupplierName]
				, [ActivePOFlag] = Max(Case When [PMD].[PurchaseOrder] Is Null Then 0
                                Else 1
                           End)
From    [dbo].[ApSupplier] [APS]
        Left Join [dbo].[PorMasterHdr] [PMH]
            On [PMH].[Supplier] = [APS].[Supplier]
               And [PMH].[CancelledFlag] <> ''Y''
               And [PMH].[DatePoCompleted] Is Null
        Left Join [dbo].[PorMasterDetail] [PMD]
            On [PMD].[PurchaseOrder] = [PMH].[PurchaseOrder]
               And [PMD].[MOrderQty] <> [PMD].[MReceivedQty]
Group By [APS].[Supplier]
      , [APS].[SupplierName];
End
';

--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
                    @SchemaTablesToCheck = @ListOfTables;

                Insert  [Lookups].[ApSupplier]
                        ( [Company]
                        , [Supplier]
                        , [LastUpdated]
                        , [SupplierName]
						, [ActivePOFlag]
                        )
                        Select  [Company]
                              , [Supplier]
                              , @LastUpdated
                              , [SupplierName]
							  , [ActivePOFlag]
                        From    [#Table1Supplier];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[ApSupplier]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[ApSupplier]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[ApSupplier]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_ApSupplier - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[ApSupplier]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_ApSupplier - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[ApSupplier]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_ApSupplier - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_ApSupplier - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;



GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_ApSupplier', NULL, NULL
GO
