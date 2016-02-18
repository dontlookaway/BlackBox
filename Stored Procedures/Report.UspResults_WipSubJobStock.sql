
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_WipSubJobStock]
    (
      @MasterJob Varchar(50)
    , @Company Varchar(10)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format	
--Exec [Report].[UspResults_WipSubJobStock] @MasterJob =94, @Company ='F'
*/
    Set NoCount Off;

	--Cater for lower case company letters being entered
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

	--Red tag
    Declare @RedTagDB Varchar(255)= Db_Name();
    Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
        @StoredProcSchema = 'Report' , @StoredProcName = 'UspResults_WipSubJobStock' ,
        @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
        @UsedByDb = @RedTagDB;

	--Remove any null values generated by crystal
    Delete  From [Process].[Status_WipSubJobStock]
    Where   Coalesce([Job] , '') = '';

	--Remove any incomplete jobs that have been running 10+ minutes
    Delete  From [Process].[Status_WipSubJobStock]
    Where   [IsComplete] = 0
            And DateDiff(Minute , [StartTime] , GetDate()) > 10;

	--Remove data reported more than a day ago
    Delete  From [Report].[Results_WipSubJobStock]
    Where   DateDiff(Day , [StartTime] , GetDate()) > 1;

    Declare @StartTime DateTime2 = GetDate()
      , @CompleteTime DateTime2
      , @LatestStartTime DateTime2;

	--Work out if proc has been run in the past three minutes and has not completed yet
    Select  @LatestStartTime = Max([s].[StartTime])
    From    [Process].[Status_WipSubJobStock] [s]
    Where   ( [s].[IsComplete] = 0
              Or DateDiff(Minute , [s].[CompleteTime] , GetDate()) < 3
            )
            And [s].[Job] = @MasterJob
            And [s].[Company] = @Company;

	-- if the proc has not been run in the past three minutes start capturing data
    If @LatestStartTime Is Null
        Begin
            Insert  [Process].[Status_WipSubJobStock]
                    ( [StartTime]
                    , [Job]
                    , [Company]
                    )
                    Select  @StartTime
                          , @MasterJob
                          , @Company;

--Convert Job to varchar for querying DB
            Declare @MasterJobVarchar Varchar(20);
			--= RIGHT('000000000000000' + CAST(@MasterJob As VARCHAR(20)),15);

--Cater for number jobs
            Select  @MasterJobVarchar = Case When IsNumeric(@MasterJob) = 1
                                             Then Right('000000000000000'
                                                        + @MasterJob , 15)
                                             Else @MasterJob
                                        End;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
            Declare @ListOfTables Varchar(Max) = 'WipMasterSub,TblApTerms'; 

--Set maxmimum recursion to 9000
            Declare @CurrentJobLevel Int = 1
              , @TotalJobLevel Int= 9000
              , @InsertCount Int;

--Create tables to capture results
            Create Table [#JobLevelCheck]
                (
                  [DatabaseName] Varchar(150) Collate Latin1_General_BIN
                , [JobLevel] Int
                , [Job] Varchar(20) Collate Latin1_General_BIN
                , [SubJob] Varchar(20)
                    Collate Latin1_General_BIN
                    Constraint [JobLevelCheck_AllKeys]
                    Primary Key NonClustered ( [DatabaseName] , [Job] , [SubJob] )
                    With ( Ignore_Dup_Key = On )
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
                , [PartCategory] Char(1)
                , [IssMultLotsFlag] Char(1)
                , [StockUom] Varchar(10)
                , [Decimals] Int
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

-- all jobs that attach to a high level
            Declare @SQLJobLevelCheck Varchar(Max) = '
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

-- All sub jobs and their masters
            Declare @SQLWipMasterSub Varchar(Max) = '
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
				Insert [#WipMasterSub]
						( [DatabaseName], [Job], [SubJob] )
				SELECT [DatabaseName]=@DBCode
					 , [wms].[Job]
					 , [wms].[SubJob] 
				From [WipMasterSub] As [wms]
			End
	End';

-- list of all materials required
            Declare @SQLWipJobAllMat Varchar(Max) = '
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
			From [WipJobAllMat] As [wjam]
			End
	End';

-- list of all jobs and operations
            Declare @SQLWipJobAllLab Varchar(Max) = '
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

-- list of materials that are to be made
            Declare @SQLWipMaster Varchar(Max) = '
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

-- list of all possible stock
            Declare @SQLInvMaster Varchar(Max) = '
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
			Insert [#InvMaster]
					( [DatabaseName]
					, [StockCode]
					, [PartCategory]
					, [IssMultLotsFlag]
					, [StockUom]
					, [Decimals]
					)
			SELECT [DatabaseName]=@DBCode
				 , [StockCode]
				 , [PartCategory] 
				 , [IssMultLotsFlag]
				 , [StockUom]
				 , [Decimals]
			FROM [InvMaster] As [im]
			End
	End';

-- details of all reserved/allocated materials required
            Declare @SQLWipAllMatLot Varchar(Max) = '
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

-- details of all lots
            Declare @SQLLotDetail Varchar(Max) = '
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

-- details about reserved lots from custom lot fields
            Declare @SQLCusLot Varchar(Max) = '
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
            Exec [sys].[sp_MSforeachdb] @SQLJobLevelCheck;
	--Print 2
            Exec [sys].[sp_MSforeachdb] @SQLWipMasterSub;
	--Print 3
            Exec [sys].[sp_MSforeachdb] @SQLWipJobAllMat;
	--Print 4
            Exec [sys].[sp_MSforeachdb] @SQLWipJobAllLab;
	--Print 5
            Exec [sys].[sp_MSforeachdb] @SQLWipMaster;
	--Print 6
            Exec [sys].[sp_MSforeachdb] @SQLInvMaster;
	--Print 7
            Exec [sys].[sp_MSforeachdb] @SQLWipAllMatLot;
	--Print 8
            Exec [sys].[sp_MSforeachdb] @SQLLotDetail;
	--Print 9
            Exec [sys].[sp_MSforeachdb] @SQLCusLot;

--iterate through each sub job
            While @CurrentJobLevel < @TotalJobLevel --Total Job level defined at beginning of proc, currently 9000 iterations (CJ 2016-01-13)
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


            Insert  [Report].[Results_WipSubJobStock]
                    ( [StartTime]
                    , [Job]
                    , [SubJob]
                    , [SubJobDescription]
                    , [SubJobUom]
                    , [SequenceNum]
                    , [SubJobQty]
                    , [StockCode]
                    , [StockDescription]
                    , [UnitQtyReqdEnt]
                    , [QtyIssuedEnt]
                    , [FixedQtyPerFlag]
                    , [Uom]
                    , [AllocCompleted]
                    , [OperationOffset]
                    , [WorkCentre]
                    , [SubJobQtyTotal]
                    , [IssMultLotsFlag]
                    , [ReservedLotSerFlag]
                    , [ReservedLotQty]
                    , [ReservedLot]
                    , [ReservedLotBin]
                    , [ReservedLotWarehouse]
                    , [ReservedLotQtyReserved]
                    , [ReservedLotQtyIssued]
                    , [AvailableLot]
                    , [AvailableLotBin]
                    , [AvailableLotWarehouse]
                    , [AvailableLotQtyOnHand]
                    , [AvailableLotExpiryDate]
                    , [AvailableLotCreationDate]
                    , [ReservedLotBleedNumber]
                    , [ReservedLotDonorNumber]
                    , [ReservedLotVendorBatchNumber]
                    , [ReservedLotOldLotNumber]
                    , [ReservedLotBleedDate]		
					)
                    Select  @StartTime
                          , [jlc].[Job]
                          , [jlc].[SubJob]
                          , [SubJobDescription] = [wm].[JobDescription]
                          , [SubJobUom] = [im2].[StockUom]
                          , [wjam].[SequenceNum]
                          , [SubJobQty] = [wm].[QtyToMake]
                            - [wm].[QtyManufactured]
                          , [wjam].[StockCode]
                          , [wjam].[StockDescription]
                          , [wjam].[UnitQtyReqdEnt]
                          , [wjam].[QtyIssuedEnt]
                          , [wjam].[FixedQtyPerFlag]
                          , [wjam].[Uom]
                          , [wjam].[AllocCompleted]
                          , [wjam].[OperationOffset]
                          , [wjal].[WorkCentre]
                          , [SubJobQtyTotal] = Case When [wjam].[FixedQtyPerFlag] = 'N'
                                                    Then ( ( [wm].[QtyToMake]
                                                             - [wm].[QtyManufactured] )
                                                           * [wjam].[UnitQtyReqdEnt] )
                                                    Else [wjam].[UnitQtyReqdEnt]
                                               End
                          , [im].[IssMultLotsFlag]
                          , [wjam].[ReservedLotSerFlag]
                          , [wjam].[ReservedLotQty]
                          , [ReservedLot] = [waml].[Lot]
                          , [ReservedLotBin] = [waml].[Bin]
                          , [ReservedLotWarehouse] = [waml].[Warehouse]
                          , [ReservedLotQtyReserved] = [waml].[QtyReserved]
                          , [ReservedLotQtyIssued] = [waml].[QtyIssued]
                          , [AvailableLot] = [ld].[Lot]
                          , [AvailableLotBin] = [ld].[Bin]
                          , [AvailableLotWarehouse] = [ld].[Warehouse]
                          , [AvailableLotQtyOnHand] = [ld].[QtyOnHand]
                          , [AvailableLotExpiryDate] = [ld].[ExpiryDate]
                          , [AvailableLotCreationDate] = [ld].[CreationDate]
                          , [ReservedLotBleedNumber] = [CL].[BleedNumber]
                          , [ReservedLotDonorNumber] = [CL].[DonorNumber]
                          , [ReservedLotVendorBatchNumber] = [CL].[VendorBatchNumber]
                          , [ReservedLotOldLotNumber] = [CL].[OldLotNumber]
                          , [ReservedLotBleedDate] = [CL].[BleedDate]
                    From    [#JobLevelCheck] [jlc]
                            Left Join [#WipJobAllMat] [wjam] On [jlc].[SubJob] = [wjam].[Job]
                                                              And [wjam].[DatabaseName] = [jlc].[DatabaseName]
                            Left Join [#WipJobAllLab] [wjal] On [wjam].[Job] = [wjal].[Job]
                                                              And [wjam].[OperationOffset] = [wjal].[Operation]
                                                              And [wjal].[DatabaseName] = [wjam].[DatabaseName]
                            Left Join [#WipMaster] [wm] On [jlc].[SubJob] = [wm].[Job]
                                                           And [wm].[DatabaseName] = [jlc].[DatabaseName]
                            Left Join [#InvMaster] As [im2] On [im2].[StockCode] = [wm].[StockCode]
                                                              And [im2].[DatabaseName] = [wm].[DatabaseName]
                            Left Join [#InvMaster] [im] On [wjam].[StockCode] = [im].[StockCode]
                                                           And [im].[DatabaseName] = [wjam].[DatabaseName]
                            Left Join [#LotDetail] As [ld] On [ld].[StockCode] = [im].[StockCode]
                                                              And [im].[IssMultLotsFlag] = 'Y'
                                                              And Coalesce([wjam].[ReservedLotSerFlag] ,
                                                              'N') <> 'Y'
                                                              And [ld].[DatabaseName] = [im].[DatabaseName]
                            Left Join [#WipAllMatLot] As [waml] On [waml].[Job] = [wjam].[Job]
                                                              And [waml].[StockCode] = [wjam].[StockCode]
                                                              And [waml].[DatabaseName] = [wjam].[DatabaseName]
                            Left Join [#CusLot] As [CL] On [CL].[Lot] = [waml].[Lot]
                                                           And [CL].[StockCode] = [waml].[StockCode]
                                                           And [CL].[DatabaseName] = [waml].[DatabaseName]
                    Where   --wjam.AllocCompleted = 'N'
                        --And
                            [im].[PartCategory] <> 'M';

            Update  [Process].[Status_WipSubJobStock]
            Set     [CompleteTime] = GetDate()
                  , [IsComplete] = 1
            Where   [StartTime] = @StartTime
                    And [Job] = @MasterJob
                    And [Company] = @Company;
--tidy up
            Drop Table [#JobLevelCheck];
            Drop Table [#WipMasterSub];
            Drop Table [#WipJobAllMat];
            Drop Table [#WipAllMatLot];
            Drop Table [#WipJobAllLab];
            Drop Table [#WipMaster];
            Drop Table [#InvMaster];
            Drop Table [#LotDetail];
        End;

--Set StartTime to last start date
    If @LatestStartTime Is Not Null
        Begin
            Select  @StartTime = @LatestStartTime;
        End;

--Hold Process until Results are ready
    Declare @Complete Bit = 0;

    While @Complete < 1
        Begin
            Select  @Complete = [swsjs].[IsComplete]
            From    [Process].[Status_WipSubJobStock] As [swsjs]
            Where   [swsjs].[StartTime] = @StartTime;
            WaitFor Delay '00:00:01';
        End;

--Return Results
    Create Table [#ReservedLotKeys]
        (
          [StartTime] DateTime2
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        , [ReservedLots] Bit
        );
    Insert  [#ReservedLotKeys]
            ( [StartTime]
            , [StockCode]
            , [ReservedLots]
            )
            Select  [RWSJS].[StartTime]
                  , [RWSJS].[StockCode]
                  , [ReservedLots] = Case When Max([RWSJS].[ReservedLot]) Is Not Null
                                          Then 1
                                          Else 0
                                     End
            From    [Report].[Results_WipSubJobStock] As [RWSJS]
            Group By [RWSJS].[StockCode]
                  , [RWSJS].[StartTime];

    Select  [MasterJob] = @MasterJob
          , [Job] = Case When IsNumeric([r].[Job]) = 1
                         Then Cast(Cast([r].[Job] As Int) As Varchar(20))
                         Else [r].[Job]
                    End
          , [SubJob] = Case When IsNumeric([r].[SubJob]) = 1
                            Then Cast(Cast([r].[SubJob] As Int) As Varchar(20))
                            Else [r].[SubJob]
                       End
          , [r].[SubJobDescription]
          , [SequenceNum] = Case When IsNumeric([r].[SequenceNum]) = 1
                                 Then Cast(Cast([r].[SequenceNum] As Int) As Varchar(20))
                                 Else [r].[SequenceNum]
                            End
          , [r].[SubJobQty]
          , [StockCode] = Case When IsNumeric([r].[StockCode]) = 1
                               Then Cast(Cast([r].[StockCode] As Int) As Varchar(20))
                               Else [r].[StockCode]
                          End
          , [r].[StockDescription]
          , [r].[UnitQtyReqdEnt]
          , [r].[QtyIssuedEnt]
          , [r].[FixedQtyPerFlag]
          , [Uom] = Upper([r].[Uom])
          , [r].[AllocCompleted]
          , [r].[OperationOffset]
          , [r].[WorkCentre]
          , [r].[SubJobQtyTotal]
          , [r].[IssMultLotsFlag]
          , [r].[ReservedLotSerFlag]
          , [r].[ReservedLotQty]
          , [r].[ReservedLot]
          , [r].[ReservedLotBin]
          , [r].[ReservedLotWarehouse]
          , [r].[ReservedLotQtyReserved]
          , [r].[ReservedLotQtyIssued]
          , [r].[AvailableLot]
          , [r].[AvailableLotBin]
          , [r].[AvailableLotWarehouse]
          , [r].[AvailableLotQtyOnHand]
          , [r].[AvailableLotExpiryDate]
          , [r].[AvailableLotCreationDate]
          , [r].[SubJobUom]
          , [RLK].[ReservedLots]
          , [r].[ReservedLotBleedNumber]
          , [r].[ReservedLotDonorNumber]
          , [r].[ReservedLotVendorBatchNumber]
          , [r].[ReservedLotOldLotNumber]
          , [r].[ReservedLotBleedDate]
    From    [Report].[Results_WipSubJobStock] As [r]
            Left Join [#ReservedLotKeys] As [RLK] On [RLK].[StartTime] = [r].[StartTime]
                                                     And [RLK].[StockCode] = [r].[StockCode]
    Where   [r].[StartTime] = @StartTime
    Order By [StockCode] Asc;



GO
