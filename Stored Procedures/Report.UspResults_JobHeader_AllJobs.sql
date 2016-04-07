
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobHeader_AllJobs]
    (
      @Company Varchar(Max)
    , @StartDateText Varchar(50)
    , @EndDateText Varchar(50)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
*/
    Begin

        Declare @StartDate Date
          , @EndDate Date;
        Select  @StartDate = Cast(@StartDateText As Date);
        Select  @EndDate = Cast(@EndDateText As Date);

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
            @StoredProcName = 'UspResults_JobHeader_AllJobs' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'WipMaster,InvMaster,InvMovements,WipLabJnl,SorContractPrice'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#WipMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Job] Varchar(35) Collate Latin1_General_BIN
            , [JobDescription] Varchar(150) Collate Latin1_General_BIN
            , [JobClassification] Varchar(10) Collate Latin1_General_BIN
            , [ProducedStockCode] Varchar(35) Collate Latin1_General_BIN
            , [ProducedStockDescription] Varchar(150)
                Collate Latin1_General_BIN
            , [UomFlag] Char(1)
            , [JobTenderDate] DateTime2
            , [JobDeliveryDate] DateTime2
            , [JobStartDate] DateTime2
            , [ActCompleteDate] DateTime2
            , [Complete] Char(1)
            , [QtyManufactured] Float
            , [SalesOrder] Varchar(35) Collate Latin1_General_BIN
            , [SellingPrice] Float
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [StockCode] Varchar(35) Collate Latin1_General_BIN
            , [StockUom] Varchar(10) Collate Latin1_General_BIN
            , [CostUom] Varchar(10) Collate Latin1_General_BIN
            , [OtherUom] Varchar(10) Collate Latin1_General_BIN
            , [AlternateUom] Varchar(10) Collate Latin1_General_BIN
            , [IssMultLotsFlag] Char(1)
            );
        Create Table [#InvMovementsSummary]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Job] Varchar(50) Collate Latin1_General_BIN
            , [MaterialValue] Numeric(20 , 7)
            );
        Create Table [#WipLabJnlSummary]
            (
              [DatabaseName] Varchar(500) Collate Latin1_General_BIN
            , [Job] Varchar(50) Collate Latin1_General_BIN
            , [LabourValue] Numeric(20 , 7)
            , [TimeTotal] Numeric(20 , 7)
            );
        Create Table [#LotsHeader]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [JobPurchOrder] Varchar(50) Collate Latin1_General_BIN
            , [Lot] Varchar(50) Collate Latin1_General_BIN
            );
        Create Table [#SalesSummary]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [Job] Varchar(50) Collate Latin1_General_BIN
            , [SellingValue] Numeric(20 , 7)
            , [RemovedValue] Numeric(20 , 7)
            );
        Create Table [#SorContractPrice]
            (
              [DatabaseName] Varchar(150) Collate Latin1_General_BIN
            , [StockCode] Varchar(50) Collate Latin1_General_BIN
            , [StartDate] DateTime2
            , [ExpiryDate] DateTime2
            , [MaxFixedPrice] Numeric(20 , 7)
            , [MinFixedPrice] Numeric(20 , 7)
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
				Insert #WipMaster
						( DatabaseName
						, Job
						, JobDescription
						, JobClassification
						, ProducedStockCode
						, ProducedStockDescription
						, UomFlag
						, JobTenderDate
						, JobDeliveryDate
						, JobStartDate
						, ActCompleteDate
						, Complete
						, QtyManufactured
						, SalesOrder
						, SellingPrice
						)
				SELECT DatabaseName =@DBCode
					 , Job
					 , JobDescription
					 , JobClassification
					 , StockCode
					 , StockDescription
					 , UomFlag
					 , JobTenderDate
					 , JobDeliveryDate
					 , JobStartDate
					 , ActCompleteDate
					 , Complete
					 , QtyManufactured
					 , SalesOrder
					 , SellingPrice
					  FROM WipMaster
				Where cast(JobStartDate as Date) between '''
            + Cast(@StartDate As Varchar(50)) + '''
												And '''
            + Cast(@EndDate As Varchar(50)) + '''
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
			Insert #InvMaster
			    ( DatabaseName
			    , StockCode
			    , StockUom
			    , CostUom
			    , OtherUom
			    , AlternateUom
			    , IssMultLotsFlag
			    )
			SELECT DatabaseName =@DBCode
             , StockCode
             , StockUom
             , CostUom
             , OtherUom
             , AlternateUom
             , IssMultLotsFlag FROM InvMaster
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
			Insert  [#InvMovementsSummary]
					( [DatabaseName]
					, [Job]
					, [MaterialValue]
					)
			Select
				DatabaseName = @DBCode
			  , IM.Job
			  , MaterialValue = SUM(IM.TrnValue * TT.AmountModifier)
			From
				InvMovements IM
			Left Join BlackBox.Lookups.TrnTypeAmountModifier TT
				On TT.TrnType = IM.TrnType Collate Latin1_General_BIN
				   And TT.Company = @DBCode
			Inner Join #WipMaster W on IM.Job =W.Job
					and W.DatabaseName = @DBCode
			Where
				[IM].[TrnType] <> ''R''
			Group By
				IM.Job
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
			Insert  [#WipLabJnlSummary]
					( [DatabaseName]
					, [Job]
					, [LabourValue]
					, TimeTotal
					)
					Select
						@DBCode 
					  , WJL.Job
					  , LabourValue = SUM(WJL.LabourValue)
					  , TimeTotal = SUM( coalesce(WJL.[RunTime]		,0)
										+coalesce(WJL.[SetUpTime]	,0)
										+coalesce(WJL.[StartUpTime]	,0)
										+coalesce(WJL.[TeardownTime],0)
									)
					From
						WipLabJnl WJL
						inner join #WipMaster W on WJL.Job=W.Job
						and W.DatabaseName=@DBCode
					Group By
					WJL.Job;
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
			Insert  [#LotsHeader]
        ( [JobPurchOrder]
        , [Lot]
		, DatabaseName
        )
        Select Distinct
            [l].[JobPurchOrder]
          , [l].[Lot]
		  , @DBCode
        From
            [LotTransactions] As [l]
        Left Join [dbo].[InvMaster] As [im]
            On [im].[StockCode] = [l].[StockCode]
		inner join #WipMaster w on w.Job=l.JobPurchOrder
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
			Insert  [#SalesSummary]
        ( [DatabaseName]
        , [Job]
        , [SellingValue]
		, RemovedValue
        )
        Select
            @DBCode
          , Job = [l].[JobPurchOrder]
          , [SellingValue] = SUM([wm].[SellingPrice])
		  , RemovedValue = SUM(lt.[TrnQuantity])
        From
            LotTransactions As [lt]
        Inner Join [#LotsHeader] As [l]
            On [l].[Lot] = [lt].[Lot] Collate Latin1_General_BIN
               And [l].[DatabaseName] = @DBCode
        Left Join WipMaster As [wm]
            On [wm].[Job] = [lt].[Job] Collate Latin1_General_BIN
		Inner Join #WipMaster As [w] on [l].[JobPurchOrder]=w.Job
					and w.DatabaseName=@DBCode
        Where
            [wm].[SellingPrice] <> 0
            
        Group By
            [l].[JobPurchOrder];
			End
	End';
        Declare @SQL7 Varchar(Max) = '
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
			Insert [#SorContractPrice]
		        ( [DatabaseName]
		        , [StockCode]
		        , [StartDate]
		        , [ExpiryDate]
		        , [MaxFixedPrice]
		        , [MinFixedPrice]
		        )
			Select @DBCode
			  , [StockCode]
			  , [StartDate]
			  , [ExpiryDate]
			  , max([FixedPrice])
			  , Min([FixedPrice])
			From SorContractPrice
			group by [StockCode]
			  , [StartDate]
			  , [ExpiryDate]
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL7

--execute script against each db, populating the base tables
        --Print 1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        --Print 2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        --Print 3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        --Print 4;		
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
        --Print 5;		
        Exec [Process].[ExecForEachDB] @cmd = @SQL5;
        --Print 6; 		
        Exec [Process].[ExecForEachDB] @cmd = @SQL6;
        --Print 7;		
        Exec [Process].[ExecForEachDB] @cmd = @SQL7;
        --Print 8;
--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [Job] Varchar(50)
            , [JobDescription] Varchar(150)
            , [JobClassification] Varchar(50)
            , [ProducedStockCode] Varchar(50)
            , [ProducedStockDescription] Varchar(150)
            , [ProducedQty] Numeric(20 , 7)
            , [Uom] Varchar(10)
            , [JobTenderDate] DateTime2
            , [JobDeliveryDate] DateTime2
            , [JobStartDate] DateTime2
            , [ActCompleteDate] DateTime2
            , [Complete] Char(1)
            , [QtyManufactured] Numeric(20 , 7)
            , [SalesOrder] Varchar(50)
            , [IssMultLotsFlag] Char(1)
            , [SellingPrice] Numeric(20 , 7)
            , [MaterialValue] Numeric(20 , 7)
            , [LabourValue] Numeric(20 , 7)
            , [InputValue] Numeric(20 , 7)
            , [SellingValue] Numeric(20 , 7)
            , [Profit] Numeric(20 , 7)
            , [RemovedValue] Numeric(20 , 7)
            , [TimeTotal] Numeric(20 , 7)
            , [MaxSellingPrice] Numeric(20 , 7)
            , [MinSellingPrice] Numeric(20 , 7)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)
        --Print 9;
--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [Job]
                , [JobDescription]
                , [JobClassification]
                , [ProducedStockCode]
                , [ProducedStockDescription]
                , [ProducedQty]
                , [Uom]
                , [JobTenderDate]
                , [JobDeliveryDate]
                , [JobStartDate]
                , [ActCompleteDate]
                , [Complete]
                , [QtyManufactured]
                , [SalesOrder]
                , [IssMultLotsFlag]
                , [SellingPrice]
                , [MaterialValue]
                , [LabourValue]
                , [InputValue]
                , [SellingValue]
                , [Profit]
                , [RemovedValue]
                , [TimeTotal]
                , [MaxSellingPrice]
                , [MinSellingPrice]
                )
                Select  [WM].[DatabaseName]
                      , [WM].[Job]
                      , [WM].[JobDescription]
                      , [WM].[JobClassification]
                      , [ProducedStockCode] = [WM].[ProducedStockCode]
                      , [ProducedStockDescription] = [WM].[ProducedStockDescription]
                      , [ProducedQty] = [WM].[QtyManufactured]
                      , [Uom] = Case When [WM].[UomFlag] = 'S'
                                     Then [IM].[StockUom]
                                     When [WM].[UomFlag] = 'C'
                                     Then [IM].[CostUom]
                                     When [WM].[UomFlag] = 'O'
                                     Then [IM].[OtherUom]
                                     When [WM].[UomFlag] = 'A'
                                     Then [IM].[AlternateUom]
                                End
                      , [JobTenderDate] = [WM].[JobTenderDate]
                      , [JobDeliveryDate] = [WM].[JobDeliveryDate]
                      , [JobStartDate] = [WM].[JobStartDate]
                      , [ActCompleteDate] = [WM].[ActCompleteDate]
                      , [WM].[Complete]
                      , [WM].[QtyManufactured]
                      , [SalesOrder] = Case When [WM].[SalesOrder] = ''
                                            Then Null
                                            Else [WM].[SalesOrder]
                                       End
                      , [IM].[IssMultLotsFlag]
                      , [WM].[SellingPrice]
                      , [ims].[MaterialValue]
                      , [wljs].[LabourValue]
                      , [InputValue] = Coalesce([ims].[MaterialValue] , 0)
                        - Coalesce([wljs].[LabourValue] , 0)
                      , [ss].[SellingValue]
                      , [Profit] = [ss].[SellingValue] + [ims].[MaterialValue]
                        - [wljs].[LabourValue]
                      , [ss].[RemovedValue]
                      , [wljs].[TimeTotal]
                      , [scp].[MaxFixedPrice]
                      , [scp].[MinFixedPrice]
                From    [#WipMaster] [WM]
                        Left Join [#InvMaster] [IM] On [IM].[StockCode] = [WM].[ProducedStockCode]
                                                       And [IM].[DatabaseName] = [WM].[DatabaseName]
                        Left Join [#InvMovementsSummary] As [ims] On [ims].[DatabaseName] = [WM].[DatabaseName]
                                                              And [ims].[Job] = [WM].[Job]
                        Left Join [#WipLabJnlSummary] As [wljs] On [wljs].[DatabaseName] = [WM].[DatabaseName]
                                                              And [wljs].[Job] = [WM].[Job]
                        Left Join [#SalesSummary] As [ss] On [ss].[Job] = [WM].[Job]
                                                             And [ss].[Job] = [WM].[Job]
                        Left Join [#SorContractPrice] As [scp] On [scp].[StockCode] = [IM].[StockCode]
                                                              And [scp].[DatabaseName] = [WM].[DatabaseName];
        --Print 10;
--return results
        Select  [CN].[CompanyName]
              , [r].[Job]
              , [r].[JobDescription]
              , [r].[JobClassification]
              , [r].[ProducedStockCode]
              , [r].[ProducedStockDescription]
              , [r].[ProducedQty]
              , [r].[Uom]
              , [JobTenderDate] = Cast([r].[JobTenderDate] As Date)
              , [JobDeliveryDate] = Cast([r].[JobDeliveryDate] As Date)
              , [JobStartDate] = Cast([r].[JobStartDate] As Date)
              , [ActCompleteDate] = Cast([r].[ActCompleteDate] As Date)
              , [Complete] = Case When [r].[Complete] = 'Y' Then 'Yes'
                                  Else 'No'
                             End
              , [r].[QtyManufactured]
              , [r].[SalesOrder]
              , [r].[IssMultLotsFlag]
              , [r].[SellingPrice]
              , [MaterialValue] = Coalesce([r].[MaterialValue] , 0) * -1
              , [LabourValue] = Coalesce([r].[LabourValue] , 0)
              , [InputValue] = Coalesce([r].[InputValue] , 0)
              , [SellingValue] = Coalesce([r].[SellingValue] , 0)
              , [Profit] = Coalesce([r].[Profit] , 0)
              , [RemovedValue] = Coalesce([r].[RemovedValue] , 0)
              , [r].[TimeTotal]
              , [r].[MaxSellingPrice]
              , [r].[MinSellingPrice]
        From    [#Results] As [r]
                Left Join [Lookups].[CompanyNames] [CN] On [CN].[Company] = [r].[DatabaseName]  Collate Latin1_General_BIN;

        Drop Table [#Results];
    End;

GO
