
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobHeader]
    (
      @Company Varchar(Max)
    , @Job Varchar(150)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--exec Report.UspResults_JobHeader  10, 'FA1408'
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
            @StoredProcName = 'UspResults_JobHeader' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Select  @Job = Case When IsNumeric(@Job) = 1
                            Then Right('000000000000000' + @Job , 15)
                            Else @Job
                       End;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'WipMaster,InvMaster'; 

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
            , [QtyToMake] Numeric(20 , 8)
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

        Set @Job = Upper(@Job);


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
						, QtyToMake
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
					 , QtyToMake
					  FROM WipMaster
				Where upper(Job) =''' + @Job + '''
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
			Where
				[IM].[TrnType] <> ''R''
				And [IM].[Job] = ''' + @Job + '''
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
					  , Job
					  , LabourValue = SUM(LabourValue)
					  , TimeTotal = SUM( coalesce([RunTime]		,0)
										+coalesce([SetUpTime]	,0)
										+coalesce([StartUpTime]	,0)
										+coalesce([TeardownTime],0)
									)
					From
						WipLabJnl
					Where
						[Job] = ''' + @Job + '''
					Group By
					Job;
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
        Where
            [JobPurchOrder] = ''' + @Job + ''';
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
        Where
            [wm].[SellingPrice] <> 0
            And [l].[JobPurchOrder] = ''' + @Job + '''
        Group By
            [l].[JobPurchOrder];
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;
        Exec [Process].[ExecForEachDB] @cmd = @SQL4;
        Exec [Process].[ExecForEachDB] @cmd = @SQL5;
        Exec [Process].[ExecForEachDB] @cmd = @SQL6;

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
            , [QtyToMake] Numeric(20 , 8)
            );

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

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
                , [QtyToMake]
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
                      , [InputValue] = [ims].[MaterialValue]
                        + [wljs].[LabourValue]
                      , [ss].[SellingValue]
                      , [Profit] = [ss].[SellingValue] + [ims].[MaterialValue]
                        - [wljs].[LabourValue]
                      , [ss].[RemovedValue]
                      , [wljs].[TimeTotal]
                      , [WM].[QtyToMake]
                From    [#WipMaster] [WM]
                        Left Join [#InvMaster] [IM] On [IM].[StockCode] = [WM].[ProducedStockCode]
                                                       And [IM].[DatabaseName] = [WM].[DatabaseName]
                        Left Join [#InvMovementsSummary] As [ims] On [ims].[DatabaseName] = [WM].[DatabaseName]
                                                              And [ims].[Job] = [WM].[Job]
                        Left Join [#WipLabJnlSummary] As [wljs] On [wljs].[DatabaseName] = [WM].[DatabaseName]
                                                              And [wljs].[Job] = [WM].[Job]
                        Left Join [#SalesSummary] As [ss] On [ss].[Job] = [WM].[Job]
                                                             And [ss].[Job] = [WM].[Job];

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
              , [r].[Complete]
              , [r].[QtyManufactured]
              , [r].[SalesOrder]
              , [r].[IssMultLotsFlag]
              , [r].[SellingPrice]
              , [MaterialValue] = [r].[MaterialValue] * -1
              , [r].[LabourValue]
              , [r].[InputValue]
              , [r].[SellingValue]
              , [r].[Profit]
              , [r].[RemovedValue]
              , [r].[TimeTotal]
              , [r].[QtyToMake]
        From    [#Results] As [r]
                Left Join [Lookups].[CompanyNames] [CN] On [CN].[Company] = [r].[DatabaseName]  Collate Latin1_General_BIN;

        Drop Table [#Results];
    End;

GO
