SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobHeader_AllJobs]
    (
      @Company VARCHAR(Max)
    , @StartDateText VARCHAR(50)
    , @EndDateText VARCHAR(50)
    )
As /*
Exec Report.[UspResults_JobHeader_AllJobs]   @Company=10, @StartDateText='2014-08-01', @EndDateText='2015-10-01'
*/
    Begin

        Declare
            @StartDate DATE
          , @EndDate DATE;
        Select
            @StartDate = CAST(@StartDateText As DATE);
        Select
            @EndDate = CAST(@EndDateText As DATE);
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.2																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			12/10/2015	Chris Johnson			Initial version created																///
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
        Declare @ListOfTables VARCHAR(Max) = 'WipMaster,InvMaster,InvMovements,WipLabJnl,SorContractPrice'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #WipMaster
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Job VARCHAR(35) Collate Latin1_General_BIN
            , JobDescription VARCHAR(150) Collate Latin1_General_BIN
            , JobClassification VARCHAR(10) Collate Latin1_General_BIN
            , ProducedStockCode VARCHAR(35) Collate Latin1_General_BIN
            , ProducedStockDescription VARCHAR(150) Collate Latin1_General_BIN
            , UomFlag CHAR(1)
            , JobTenderDate DATETIME2
            , JobDeliveryDate DATETIME2
            , JobStartDate DATETIME2
            , ActCompleteDate DATETIME2
            , Complete CHAR(1)
            , QtyManufactured FLOAT
            , SalesOrder VARCHAR(35) Collate Latin1_General_BIN
            , SellingPrice FLOAT
            );
        Create Table #InvMaster
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , StockCode VARCHAR(35) Collate Latin1_General_BIN
            , StockUom VARCHAR(10) Collate Latin1_General_BIN
            , CostUom VARCHAR(10) Collate Latin1_General_BIN
            , OtherUom VARCHAR(10) Collate Latin1_General_BIN
            , AlternateUom VARCHAR(10) Collate Latin1_General_BIN
            , IssMultLotsFlag CHAR(1)
            );
        Create Table #InvMovementsSummary
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Job VARCHAR(50) Collate Latin1_General_BIN
            , MaterialValue NUMERIC(20, 7)
            );
        Create Table #WipLabJnlSummary
            (
              DatabaseName VARCHAR(500) Collate Latin1_General_BIN
            , Job VARCHAR(50) Collate Latin1_General_BIN
            , LabourValue NUMERIC(20, 7)
            , TimeTotal NUMERIC(20, 7)
            );
        Create Table #LotsHeader
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [JobPurchOrder] VARCHAR(50) Collate Latin1_General_BIN
            , [Lot] VARCHAR(50) Collate Latin1_General_BIN
            );
        Create Table #SalesSummary
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Job VARCHAR(50) Collate Latin1_General_BIN
            , SellingValue NUMERIC(20, 7)
            , RemovedValue NUMERIC(20, 7)
            );
        Create Table #SorContractPrice
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [StockCode] VARCHAR(50) Collate Latin1_General_BIN
            , [StartDate] DATETIME2
            , [ExpiryDate] DATETIME2
            , [MaxFixedPrice] NUMERIC(20, 7)
            , [MinFixedPrice] NUMERIC(20, 7)
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
            + CAST(@StartDate As VARCHAR(50)) + '''
												And '''
            + CAST(@EndDate As VARCHAR(50)) + '''
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
        Declare @SQL6 VARCHAR(Max) = '
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
        Declare @SQL7 VARCHAR(Max) = '
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
        Exec sp_MSforeachdb
            @SQL1;
        --Print 2;
        Exec sp_MSforeachdb
            @SQL2;
        --Print 3;
        Exec sp_MSforeachdb
            @SQL3;
        --Print 4;		
        Exec sp_MSforeachdb
            @SQL4;
        --Print 5;		
        Exec sp_MSforeachdb
            @SQL5;
        --Print 6; 		
        Exec sp_MSforeachdb
            @SQL6;
        --Print 7;		
        Exec sp_MSforeachdb
            @SQL7;
        --Print 8;
--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150)
            , [Job] VARCHAR(50)
            , [JobDescription] VARCHAR(150)
            , [JobClassification] VARCHAR(50)
            , [ProducedStockCode] VARCHAR(50)
            , [ProducedStockDescription] VARCHAR(150)
            , [ProducedQty] NUMERIC(20, 7)
            , [Uom] VARCHAR(10)
            , [JobTenderDate] DATETIME2
            , [JobDeliveryDate] DATETIME2
            , [JobStartDate] DATETIME2
            , [ActCompleteDate] DATETIME2
            , [Complete] CHAR(1)
            , [QtyManufactured] NUMERIC(20, 7)
            , [SalesOrder] VARCHAR(50)
            , [IssMultLotsFlag] CHAR(1)
            , [SellingPrice] NUMERIC(20, 7)
            , [MaterialValue] NUMERIC(20, 7)
            , [LabourValue] NUMERIC(20, 7)
            , [InputValue] NUMERIC(20, 7)
            , [SellingValue] NUMERIC(20, 7)
            , [Profit] NUMERIC(20, 7)
            , RemovedValue NUMERIC(20, 7)
            , TimeTotal NUMERIC(20, 7)
            , [MaxSellingPrice] NUMERIC(20, 7)
            , [MinSellingPrice] NUMERIC(20, 7)
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
                Select
                    [WM].[DatabaseName]
                  , WM.Job
                  , WM.JobDescription
                  , WM.JobClassification
                  , ProducedStockCode = WM.ProducedStockCode
                  , ProducedStockDescription = WM.ProducedStockDescription
                  , ProducedQty = QtyManufactured
                  , Uom = Case When WM.UomFlag = 'S' Then IM.StockUom
                               When WM.UomFlag = 'C' Then IM.CostUom
                               When WM.UomFlag = 'O' Then IM.OtherUom
                               When WM.UomFlag = 'A' Then IM.AlternateUom
                          End
                  , JobTenderDate = WM.JobTenderDate
                  , JobDeliveryDate = WM.JobDeliveryDate
                  , JobStartDate = WM.JobStartDate
                  , ActCompleteDate = WM.ActCompleteDate
                  , WM.Complete
                  , WM.QtyManufactured
                  , SalesOrder = Case When WM.SalesOrder = '' Then Null
                                      Else WM.SalesOrder
                                 End
                  , IM.IssMultLotsFlag
                  , WM.SellingPrice
                  , [ims].[MaterialValue]
                  , [wljs].[LabourValue]
                  , [InputValue] = COALESCE([MaterialValue], 0)
                    - COALESCE([LabourValue], 0)
                  , [SellingValue]
                  , [Profit] = [SellingValue] + [MaterialValue]
                    - [LabourValue]
                  , [ss].[RemovedValue]
                  , [wljs].[TimeTotal]
                  , [scp].[MaxFixedPrice]
                  , [scp].[MinFixedPrice]
                From
                    #WipMaster WM
                Left Join #InvMaster IM
                    On IM.StockCode = WM.ProducedStockCode
                       And IM.DatabaseName = WM.DatabaseName
                Left Join [#InvMovementsSummary] As [ims]
                    On [ims].[DatabaseName] = [WM].[DatabaseName]
                       And [ims].[Job] = [WM].[Job]
                Left Join [#WipLabJnlSummary] As [wljs]
                    On [wljs].[DatabaseName] = [WM].[DatabaseName]
                       And [wljs].[Job] = [WM].[Job]
                Left Join [#SalesSummary] As [ss]
                    On [ss].[Job] = [WM].[Job]
                       And [ss].[Job] = [WM].[Job]
                Left Join [#SorContractPrice] As [scp]
                    On [scp].[StockCode] = [IM].[StockCode]
                       And [scp].[DatabaseName] = [WM].[DatabaseName];
        --Print 10;
--return results
        Select
            CN.CompanyName
          , [r].[Job]
          , [r].[JobDescription]
          , [r].[JobClassification]
          , [r].[ProducedStockCode]
          , [r].[ProducedStockDescription]
          , [r].[ProducedQty]
          , [r].[Uom]
          , [JobTenderDate] = CAST([r].[JobTenderDate] As DATE)
          , [JobDeliveryDate] = CAST([r].[JobDeliveryDate] As DATE)
          , [JobStartDate] = CAST([r].[JobStartDate] As DATE)
          , [ActCompleteDate] = CAST([r].[ActCompleteDate] As DATE)
          , [Complete] = Case When [r].[Complete] = 'Y' Then 'Yes'
                              Else 'No'
                         End
          , [r].[QtyManufactured]
          , [r].[SalesOrder]
          , [r].[IssMultLotsFlag]
          , [r].[SellingPrice]
          , [MaterialValue] = COALESCE([r].[MaterialValue], 0) * -1
          , [LabourValue] = COALESCE([r].[LabourValue], 0)
          , [InputValue] = COALESCE([r].[InputValue], 0)
          , [SellingValue] = COALESCE([r].[SellingValue], 0)
          , [Profit] = COALESCE([r].[Profit], 0)
          , [RemovedValue] = COALESCE([r].[RemovedValue], 0)
          , [r].[TimeTotal]
          , [r].[MaxSellingPrice]
          , [r].[MinSellingPrice]
        From
            [#Results] As [r]
        Left Join Lookups.CompanyNames CN
            On Company = DatabaseName  Collate Latin1_General_BIN;

        Drop Table #Results;
    End;

GO
