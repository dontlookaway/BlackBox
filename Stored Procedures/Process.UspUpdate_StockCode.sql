SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_StockCode]
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
                                    And [TABLE_NAME] = 'StockCode' )
           )
            Begin
                Create Table [Lookups].[StockCode]
                    (
                      [Company] Varchar(150)
                    , [StockCode] Varchar(150)
                    , [StockDescription] Varchar(150)
                    , [PartCategory] Varchar(5)
                    , [ActivePOFlag] Bit
                    , [LastUpdated] DateTime2
                    );
            End;

--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[StockCode];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'InvMaster'; 

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1StockCode]
                    (
                      [Company] Varchar(150)
                    , [StockCode] Varchar(150)
                    , [StockDescription] Varchar(150)
                    , [PartCategory] Varchar(5)
                    , [ActivePOFlag] Bit
                    );

--create script to pull data from each db into the tables
                Declare @Company Varchar(30) = 'All';
                Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
                    + Upper(@Company)
                    + ''' = ''ALL''
			BEGIN
				Insert #Table1StockCode
					( Company, StockCode, [StockDescription],[PartCategory], [ActivePOFlag])
				Select @DBCode
				,StockCode
				,[Description]
				,[PartCategory]
				, [ActivePOFlag] = Max(Case When [PMH].[PurchaseOrder] Is Null Then 0
                                Else 1
                           End)
				From InvMaster
        Left Join [dbo].[PorMasterDetail] [PMD]
            On PMD.[MStockCode]=[StockCode]
               And [PMD].[MOrderQty] <> [PMD].[MReceivedQty]
        Left Join [dbo].[PorMasterHdr] [PMH]
            On [PMD].[PurchaseOrder] = [PMH].[PurchaseOrder] 
               And [PMH].[CancelledFlag] <> ''Y''
               And [PMH].[DatePoCompleted] Is Null
Group By [StockCode]
       , [Description]
       , [PartCategory]
			End
	End';

--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
                    @SchemaTablesToCheck = @ListOfTables;

                Insert  [Lookups].[StockCode]
                        ( [Company]
                        , [StockCode]
                        , [LastUpdated]
                        , [StockDescription]
                        , [PartCategory]
                        , [ActivePOFlag]
                        )
                        Select  [Company]
                              , [StockCode]
                              , @LastUpdated
                              , [StockDescription]
                              , [PartCategory]
                              , [ActivePOFlag]
                        From    [#Table1StockCode];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[StockCode]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[StockCode]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[StockCode]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_StockCode - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[StockCode]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_StockCode - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[StockCode]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_StockCode - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_StockCode - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;


GO
