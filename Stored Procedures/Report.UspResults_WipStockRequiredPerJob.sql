
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_WipStockRequiredPerJob]
    (
      @MasterJob Varchar(50)
    , @Company Varchar(10)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--Exec [Report].[UspResults_WipStockRequiredPerJob] @MasterJob =94, @Company ='F'
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;
	
--Convert Job to varchar for querying DB
    Declare @MasterJobVarchar Varchar(20);

--Cater for number jobs
    Select  @MasterJobVarchar = Case When IsNumeric(@MasterJob) = 1
                                     Then Right('000000000000000' + @MasterJob ,
                                                15)
                                     Else @MasterJob
                                End;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
    Declare @ListOfTables Varchar(Max) = 'WipMasterSub,TblApTerms'; 

--Set maxmimum recursion to 9000
    Declare @CurrentJobLevel Int = 1
      , @TotalJobLevel Int= 9000
      , @InsertCount Int;

--Create table to capture results
    Create Table [#JobLevelCheck]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [JobLevel] Int
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [SubJob] Varchar(20) Collate Latin1_General_BIN
        );
    Create Table [#WipMasterSub]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [SubJob] Varchar(20) Collate Latin1_General_BIN
        );
    Create Table [#WipJobAllMat]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [SequenceNum] Varchar(6) Collate Latin1_General_BIN
        , [SubJobQty] Numeric(20 , 8)
        , [StockCode] Varchar(30) Collate Latin1_General_BIN
        , [StockDescription] Varchar(50) Collate Latin1_General_BIN
        , [UnitQtyReqdEnt] Numeric(20 , 8)
        , [QtyIssuedEnt] Numeric(20 , 8)
        , [FixedQtyPerFlag] Char(1)
        , [Uom] Varchar(10) Collate Latin1_General_BIN
        , [AllocCompleted] Char(1)
        , [OperationOffset] Int
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [ReservedLotSerFlag] Char(1)
        , [ReservedLotQty] Numeric(20 , 8)
        );
    Create Table [#WipAllMatLot]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [StockCode] Varchar(30) Collate Latin1_General_BIN
        , [Lot] Varchar(50) Collate Latin1_General_BIN
        , [Bin] Varchar(20) Collate Latin1_General_BIN
        , [Warehouse] Varchar(20) Collate Latin1_General_BIN
        , [QtyReserved] Numeric(20 , 8)
        , [QtyIssued] Numeric(20 , 8)
        );
    Create Table [#WipJobAllLab]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [WorkCentre] Varchar(20) Collate Latin1_General_BIN
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [Operation] Int
        );
    Create Table [#WipMaster]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [Job] Varchar(20) Collate Latin1_General_BIN
        , [QtyToMake] Numeric(20 , 8)
        , [QtyManufactured] Numeric(20 , 8)
        , [JobDescription] Varchar(150)
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        );
    Create Table [#InvMaster]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        , [PartCategory] Char(1) Collate Latin1_General_BIN
        , [IssMultLotsFlag] Char(1)
        , [StockUom] Varchar(10)
        );
    Create Table [#LotDetail]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        , [Lot] Varchar(20) Collate Latin1_General_BIN
        , [Bin] Varchar(20) Collate Latin1_General_BIN
        , [Warehouse] Varchar(30) Collate Latin1_General_BIN
        , [QtyOnHand] Numeric(20 , 8)
        , [ExpiryDate] DateTime2
        , [CreationDate] DateTime2
        );
    Create Table [#CusLot]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [Lot] Varchar(50) Collate Latin1_General_BIN
        , [StockCode] Varchar(30) Collate Latin1_General_BIN
        , [BleedNumber] Varchar(20) Collate Latin1_General_BIN
        , [DonorNumber] Varchar(20) Collate Latin1_General_BIN
        , [VendorBatchNumber] Varchar(50) Collate Latin1_General_BIN
        , [OldLotNumber] Varchar(20) Collate Latin1_General_BIN
        , [BleedDate] Varchar(15) Collate Latin1_General_BIN
        );

--create script to pull data from each db into the tables
    Declare @SQLJobLevelCheck Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert  [#JobLevelCheck]
					( [DatabaseName]
					, [JobLevel]
					, [Job]
					, [SubJob]
					)
					SELECT DatabaseName=@DBCode
						, JobLevel = 1
						, [wms].[Job]
						, [wms].[SubJob]
					FROM
						[WipMasterSub]
						As [wms] With ( NoLock )
					Where
						[wms].[Job] = ''' + @MasterJobVarchar + '''
			End
	End';
    Declare @SQLWipMasterSub Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
				Insert [#WipMasterSub]
						( [DatabaseName], [Job], [SubJob] )
				SELECT [DatabaseName]=@DBCode
					 , [wms].[Job]
					 , [wms].[SubJob] 
				From [WipMasterSub] As [wms]
			End
	End';
    Declare @SQLWipJobAllMat Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert [#WipJobAllMat]
					( [DatabaseName]
					, [SequenceNum]
					, [StockCode]
					, [StockDescription]
					, [UnitQtyReqdEnt]
					, [QtyIssuedEnt]
					, [FixedQtyPerFlag]
					, [Uom]
					, [AllocCompleted]
					, [OperationOffset]
					, [Job]
					, ReservedLotSerFlag 
        , ReservedLotQty
					)
			SELECT [DatabaseName]=@DBCode
				 , [wjam].[SequenceNum]
				 , [wjam].[StockCode]
				 , [wjam].[StockDescription]
				 , [wjam].[UnitQtyReqdEnt]
				 , [wjam].[QtyIssuedEnt]
				 , [wjam].[FixedQtyPerFlag]
				 , [wjam].[Uom]
				 , [wjam].[AllocCompleted]
				 , [wjam].[OperationOffset]
				 , [wjam].[Job] 
				 , ReservedLotSerFlag 
        , ReservedLotQty
			From [WipJobAllMat] As [wjam]
			End
	End';
    Declare @SQLWipJobAllLab Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert [#WipJobAllLab]
					( [DatabaseName]
					, [WorkCentre]
					, [Job]
					, [Operation]
					)
			SELECT [DatabaseName]=@DBCode
				 , [wjal].[WorkCentre]
				 , [wjal].[Job]
				 , [wjal].[Operation] FROM [WipJobAllLab] As [wjal]
			End
	End';
    Declare @SQLWipMaster Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert [#WipMaster]
					( [DatabaseName]
					, [Job]
					, [QtyToMake]
					, [QtyManufactured]
					, [JobDescription]
					, StockCode
					)
			SELECT [DatabaseName]=@DBCode
				 , [Job]
				 , [QtyToMake]
				 , [QtyManufactured]
				 , [JobDescription]
				 , StockCode
			FROM [WipMaster] As [wm]
			End
	End';
    Declare @SQLInvMaster Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert [#InvMaster]
					( [DatabaseName]
					, [StockCode]
					, [PartCategory]
					, [IssMultLotsFlag]
					, [StockUom]
					)
			SELECT [DatabaseName]=@DBCode
				 , [StockCode]
				 , [PartCategory] 
				 , [IssMultLotsFlag]
				 , [StockUom]
			FROM [InvMaster] As [im]
			End
	End';
    Declare @SQLWipAllMatLot Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Insert [#WipAllMatLot]
					( [DatabaseName]
					, [Job]
					, [StockCode]
					, [Lot]
					, [Bin]
					, [QtyReserved]
					, [QtyIssued]
					, Warehouse 
					)
			SELECT @DBCode
					, [Job]
					, [StockCode]
					, [Lot]
					, [Bin]
					, [QtyReserved]
					, [QtyIssued]
					, Warehouse 
			From [WipAllMatLot] As [waml]
			End
	End';
    Declare @SQLLotDetail Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
				Insert [#LotDetail]
						( [DatabaseName]
						, [StockCode]
						, [Lot]
						, [Bin]
						, [Warehouse]
						, [QtyOnHand]
						, [ExpiryDate]
						, [CreationDate]
						)
				Select @DBCode
				  , [ld].[StockCode]
				  , [ld].[Lot]
				  , [ld].[Bin]
				  , [ld].[Warehouse]
				  , [ld].[QtyOnHand]
				  , [ld].[ExpiryDate]
				  , [ld].[CreationDate]
				From
					[LotDetail] As [ld]
				Where
					[ld].[QtyOnHand] <> 0
			End
	End';
    Declare @SQLCusLot Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
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
			Declare @SQLSub Varchar(Max) =''Insert  #CusLot
                        ( DatabaseName
                        , Lot
                        , StockCode
                        , BleedNumber
                        , DonorNumber
                        , VendorBatchNumber
                        , OldLotNumber
                        , BleedDate
				        )
                        Select  ''''''+@DBCode+''''''
							    , Lot
                              , StockCode
                              , BleedNumber
                              , DonorNumber
                              , VendorBatchNumber
                              , OldLotNumber
                              , BleedDate
                        From    [dbo].[CusLot+]''
	Exec (@SQLSub)
			End
	End';
	--Print 1 
    Exec [Process].[ExecForEachDB] @cmd = @SQLJobLevelCheck;
	--Print 2
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipMasterSub;
	--Print 3
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipJobAllMat;
	--Print 4
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipJobAllLab;
	--Print 5
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipMaster;
	--Print 6
    Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
	--Print 7
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipAllMatLot;
	--Print 8
    Exec [Process].[ExecForEachDB] @cmd = @SQLLotDetail;
	--Print 9
    Exec [Process].[ExecForEachDB] @cmd = @SQLCusLot;

--iterate through each sub job
    While @CurrentJobLevel < @TotalJobLevel
        Begin
            Insert  [#JobLevelCheck]
                    ( [DatabaseName]
                    , [JobLevel]
                    , [Job]
                    , [SubJob]
                    )
                    Select  [jlc].[DatabaseName]
                          , [JobLevel] = @CurrentJobLevel
                          , [Job] = [jlc].[SubJob]
                          , [wms].[SubJob]
                    From    [#JobLevelCheck] As [jlc]
                            Inner Join [#WipMasterSub] As [wms] On [wms].[Job] = [jlc].[SubJob]
                                                              And [jlc].[DatabaseName] = [jlc].[DatabaseName]
                    Where   [jlc].[JobLevel] = @CurrentJobLevel - 1
                            And [wms].[SubJob] <> '';
	
	--check how many rows added
            Select  @InsertCount = Count(1)
            From    [#JobLevelCheck] As [jlc]
            Where   [jlc].[JobLevel] = @CurrentJobLevel;

	--If row has been added, increase job level by 1 for next iteration
            If @InsertCount > 0
                Begin
                    Select  @CurrentJobLevel = @CurrentJobLevel + 1;
                End;

	--If no rows added, increase job level to 9000 to skip iterations
            If @InsertCount = 0
                Begin
                    Select  @CurrentJobLevel = @TotalJobLevel;
                End;    

	--reset insert count for next iteration
            Select  @InsertCount = 0;
        End;

--Add another row for top level materials without sub jobs
    Insert  [#JobLevelCheck]
            ( [DatabaseName]
            , [JobLevel]
            , [Job]
            , [SubJob]
            )
    Values  ( @Company
            , 1  -- JobLevel - int
            , @MasterJobVarchar  -- Job - varchar(20)
            , @MasterJobVarchar  -- SubJob - varchar(20)
            );


    Select  [MasterJob] = @MasterJob
          , [jlc].[Job]
          , [wjam].[SequenceNum]
          , [jlc].[SubJob]
          , [wjam].[OperationOffset]
          , [SubJobStockCode] = [wm].[StockCode]
          , [SubJobDescription] = [wm].[JobDescription]
          , [SubJobAmount] = [wm].[QtyToMake] - [wm].[QtyManufactured]
          , [SubJobUom] = [im2].[StockUom]
          , [wjam].[StockCode]
          , [wjam].[StockDescription]
          , [wjam].[UnitQtyReqdEnt]
          , [Allocated] = [wjam].[AllocCompleted]
          , [IMPC].[PartCategoryDescription]
          , [im].[PartCategory]
          , [wjam].[QtyIssuedEnt]
          , [wjam].[FixedQtyPerFlag]
          , [wjam].[Uom]
          , [wjal].[WorkCentre]
          , [im].[IssMultLotsFlag]
          , [wjam].[ReservedLotSerFlag]
          , [wjam].[ReservedLotQty]
    From    [#JobLevelCheck] [jlc]
            Left Join [#WipJobAllMat] [wjam] On [jlc].[SubJob] = [wjam].[Job]
                                              And [wjam].[DatabaseName] = [jlc].[DatabaseName]
            Left Join [#WipJobAllLab] [wjal] On [wjam].[Job] = [wjal].[Job]
                                              And [wjam].[OperationOffset] = [wjal].[Operation]
            Left Join [#WipMaster] [wm] On [jlc].[SubJob] = [wm].[Job]
                                         And [wm].[DatabaseName] = [wjal].[DatabaseName]
            Left Join [#InvMaster] [im2] On [im2].[StockCode] = [wm].[StockCode]
                                            And [im2].[DatabaseName] = [wm].[DatabaseName]
            Left Join [#InvMaster] [im] On [wjam].[StockCode] = [im].[StockCode]
                                         And [im].[DatabaseName] = [wjam].[DatabaseName]
            Left Join [Lookups].[InvMaster_PartCategory] [IMPC] On [im].[PartCategory] = [IMPC].[PartCategoryCode]
    --Where   wjam.AllocCompleted = 'N'
    --        And im.PartCategory <> 'M';
Order By    [jlc].[Job] Asc;


--SELECT * FROM #WipJobAllMat As WJAM
--tidy up
    Drop Table [#JobLevelCheck];
    Drop Table [#WipMasterSub];
    Drop Table [#WipJobAllMat];
    Drop Table [#WipAllMatLot];
    Drop Table [#WipJobAllLab];
    Drop Table [#WipMaster];
    Drop Table [#InvMaster];
    Drop Table [#LotDetail];







GO
