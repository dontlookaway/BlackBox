SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobHeader] 
( @Company VARCHAR(Max) 
,@Job varchar(150))
As
--exec Report.UspResults_JobHeader  10, 'FA1408'
    Begin
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
///			24/9/2015	Chris Johnson			Initial version created																///
///			06/10/2015	Chris Johnson			Added details from sales, labour and materials, added parameter to select job		///
///			07/10/2015	Chris Johnson			used upper on job as was not matching												///
///			12/11/2015	Chris Johnson			Added QtyToMake												///
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
        Set NoCount on;

		Select @Job = Case When ISNUMERIC(@Job)=1 Then RIGHT('000000000000000'+@Job,15) Else @Job End

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'WipMaster,InvMaster'; 

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
			, QtyToMake NUMERIC(20,8)
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
		Create TABLE #WipLabJnlSummary
(DatabaseName VARCHAR(500) Collate Latin1_General_BIN
  , Job VARCHAR(50) Collate Latin1_General_BIN
  , LabourValue   NUMERIC(20,7)
  , TimeTotal   NUMERIC(20,7)

)
		CREATE TABLE #LotsHeader
		(DatabaseName VARCHAR(150) Collate Latin1_General_BIN
		 , [JobPurchOrder] VARCHAR(50) Collate Latin1_General_BIN
		 ,[Lot]   VARCHAR(50) Collate Latin1_General_BIN
		)
        Create Table #SalesSummary
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , Job VARCHAR(50) Collate Latin1_General_BIN
            , SellingValue NUMERIC(20, 7)
			, RemovedValue NUMERIC(20, 7)
            );

			set @Job = upper(@Job)


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
				Where upper(Job) ='''+@Job+'''
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
			Where
				[IM].[TrnType] <> ''R''
				And [IM].[Job] = '''+@Job+'''
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
						[Job] = '''+@Job+'''
					Group By
					Job;
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
        Where
            [JobPurchOrder] = '''+@Job+''';
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
        Where
            [wm].[SellingPrice] <> 0
            And [l].[JobPurchOrder] = '''+@Job+'''
        Group By
            [l].[JobPurchOrder];
			End
	End';
--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec sp_MSforeachdb             @SQL1;
		Exec sp_MSforeachdb             @SQL2;
		Exec sp_MSforeachdb             @SQL3;
		Exec sp_MSforeachdb             @SQL4;
		Exec sp_MSforeachdb             @SQL5;
		Exec sp_MSforeachdb             @SQL6;

--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150)
            , [Job] VARCHAR(50)
			,  [JobDescription] VARCHAR(150)
			,  [JobClassification] VARCHAR(50)
			,  [ProducedStockCode] VARCHAR(50)
			,  [ProducedStockDescription] VARCHAR(150)
			,  [ProducedQty] NUMERIC(20,7)
			,  [Uom] VARCHAR(10)
			,  [JobTenderDate] DATETIME2
			,  [JobDeliveryDate] DATETIME2
			,  [JobStartDate] DATETIME2
			,  [ActCompleteDate] DATETIME2 
			,  [Complete] CHAR(1)
			,  [QtyManufactured] NUMERIC(20,7)
			,  [SalesOrder] VARCHAR(50)
			,  [IssMultLotsFlag] CHAR(1)
			,  [SellingPrice] NUMERIC(20,7)
			,  [MaterialValue] NUMERIC(20,7)
			,  [LabourValue]   NUMERIC(20,7)
			,  [InputValue]	   NUMERIC(20,7)
			,  [SellingValue]  NUMERIC(20,7)
			,  [Profit]		   NUMERIC(20,7)
			,  RemovedValue   NUMERIC(20,7)
			,  TimeTotal	NUMERIC(20,7)
			,  QtyToMake NUMERIC(20,8)
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
				, QtyToMake
                )
       Select [WM].[DatabaseName]
          , WM.Job
          , WM.JobDescription
          , WM.JobClassification
          , ProducedStockCode = WM.ProducedStockCode
          , ProducedStockDescription = WM.ProducedStockDescription
          , ProducedQty = QtyManufactured
		  , Uom = Case When WM.UomFlag ='S' Then IM.StockUom
						When WM.UomFlag='C' Then IM.CostUom
						When WM.UomFlag='O' Then IM.OtherUom
						When WM.UomFlag='A' Then IM.AlternateUom End
          , JobTenderDate	=WM.JobTenderDate	
          , JobDeliveryDate =WM.JobDeliveryDate 
          , JobStartDate	=WM.JobStartDate	
          , ActCompleteDate =WM.ActCompleteDate 
          , WM.Complete
          , WM.QtyManufactured
          , SalesOrder = Case When WM.SalesOrder='' Then Null Else WM.SalesOrder End
          , IM.IssMultLotsFlag
		  , WM.SellingPrice
		  , [ims].[MaterialValue]
		  , [wljs].[LabourValue]
		  , [InputValue] = [MaterialValue] + [LabourValue]
		  , [SellingValue]
		  , [Profit] = [SellingValue] + [MaterialValue] - [LabourValue]
		  , [ss].[RemovedValue]
		  , [wljs].[TimeTotal]
		  , [WM].[QtyToMake]
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
			And [ss].[Job] = [WM].[Job];

--return results
		SELECT CN.CompanyName
             , [r].[Job]
             , [r].[JobDescription]
             , [r].[JobClassification]
             , [r].[ProducedStockCode]
             , [r].[ProducedStockDescription]
             , [r].[ProducedQty]
             , [r].[Uom]
             , [JobTenderDate]		= cast([r].[JobTenderDate]   as date)
             , [JobDeliveryDate]	= cast([r].[JobDeliveryDate] as date)
             , [JobStartDate]		= cast([r].[JobStartDate]	 as date)
             , [ActCompleteDate]	= cast([r].[ActCompleteDate] as date)
             , [r].[Complete]
             , [r].[QtyManufactured]
             , [r].[SalesOrder]
             , [r].[IssMultLotsFlag]
             , [r].[SellingPrice]
             , [MaterialValue]		= [r].[MaterialValue]*-1
             , [r].[LabourValue]
             , [r].[InputValue]
             , [r].[SellingValue]
             , [r].[Profit]		 
			 , [r].[RemovedValue]
			 , [r].[TimeTotal]
			 , [r].[QtyToMake]
			 From [#Results] As [r]
			 left join Lookups.CompanyNames CN on Company=DatabaseName  Collate Latin1_General_BIN

	drop table #Results
    End;

GO
