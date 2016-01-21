SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [Report].[UspResults_WipSubJobStock] 
--Exec [Report].[UspResults_WipSubJobStock] @MasterJob =94, @Company ='F'
    (
      @MasterJob VARCHAR(50)
    , @Company VARCHAR(10)
    )
As /*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			9/11/2015	Chris Johnson			Initial version created																///
///			10/11/2015	Chris Johnson			Added Lot details & reserved amounts												///
///			10/11/2015	Chris Johnson			Added details to allow parallel processing											///
///			17/11/2015	Chris Johnson			sub job stock uom																	///
///			20/11/2015	Chris Johnson			added bleed sheet data for reserved lots											///
///			25/11/2015	Chris Johnson			Removed selection on allocated stock												///
///			25/11/2015	Chris Johnson			added delete statement to clear up crystal garbage									///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
	If IsNumeric(@Company)=0
BEGIN
    Select @Company=Upper(@Company)
END
	--Remove any null values generated by crystal
	Delete From Process.Status_WipSubJobStock
	Where Job Is Null;

    Declare
        @StartTime DATETIME2 = GETDATE()
      , @CompleteTime DATETIME2
      , @LatestStartTime DATETIME2;

    Select
        @LatestStartTime = MAX(s.[StartTime])
    From
        [Process].[Status_WipSubJobStock] [s]
    Where
        [s].[IsComplete] = 0
        Or DATEDIFF(Minute, [s].[CompleteTime], GETDATE()) < 3
		And [s].[Job]=@MasterJob
		And [s].[Company]=@Company;

    If @LatestStartTime Is Null
        Begin
            Insert  [Process].[Status_WipSubJobStock]
                    ( [StartTime]
					,[Job]
					,[Company] )
                    Select
                        @StartTime
						,@MasterJob
						,@Company;

--Convert Job to varchar for querying DB
            Declare @MasterJobVarchar VARCHAR(20);
			--= RIGHT('000000000000000' + CAST(@MasterJob As VARCHAR(20)),15);

--Cater for number jobs
Select @MasterJobVarchar = Case When ISNUMERIC(@MasterJob)=1 Then RIGHT('000000000000000'+@MasterJob,15) Else @MasterJob End

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
            Declare @ListOfTables VARCHAR(Max) = 'WipMasterSub,TblApTerms'; 

--Set maxmimum recursion to 9000
            Declare @CurrentJobLevel INT = 1, @TotalJobLevel INT= 9000, @InsertCount INT;

--Create table to capture results
            Create Table #JobLevelCheck
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , JobLevel INT
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , SubJob VARCHAR(20) Collate Latin1_General_BIN
                );
            Create Table #WipMasterSub
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , SubJob VARCHAR(20) Collate Latin1_General_BIN
                );
            Create Table #WipJobAllMat
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , SequenceNum VARCHAR(6) Collate Latin1_General_BIN
                , SubJobQty NUMERIC(20, 8)
                , StockCode VARCHAR(30) Collate Latin1_General_BIN
                , StockDescription VARCHAR(50) Collate Latin1_General_BIN
                , UnitQtyReqdEnt NUMERIC(20, 8)
                , QtyIssuedEnt NUMERIC(20, 8)
                , FixedQtyPerFlag CHAR(1)
                , Uom VARCHAR(10) Collate Latin1_General_BIN
                , AllocCompleted CHAR(1)
                , OperationOffset INT
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , ReservedLotSerFlag CHAR(1)
                , ReservedLotQty NUMERIC(20, 8)
                );
            Create Table #WipAllMatLot
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , StockCode VARCHAR(30) Collate Latin1_General_BIN
                , Lot VARCHAR(50) Collate Latin1_General_BIN
                , Bin VARCHAR(20) Collate Latin1_General_BIN
				, Warehouse Varchar(20) Collate Latin1_General_BIN
                , QtyReserved NUMERIC(20, 8)
                , QtyIssued NUMERIC(20, 8)
                );
            Create Table #WipJobAllLab
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , WorkCentre VARCHAR(20) Collate Latin1_General_BIN
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , Operation INT
                );
            Create Table #WipMaster
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , Job VARCHAR(20) Collate Latin1_General_BIN
                , QtyToMake NUMERIC(20, 8)
                , QtyManufactured NUMERIC(20, 8)
				, JobDescription VARCHAR(150)
				, StockCode VARCHAR(20) Collate Latin1_General_BIN
                );
            Create Table #InvMaster
                (
                  DatabaseName		VARCHAR(150) Collate Latin1_General_BIN
                , StockCode			VARCHAR(20) Collate Latin1_General_BIN
                , PartCategory		CHAR(1)
                , [IssMultLotsFlag] CHAR(1)
				, [StockUom]		VARCHAR(10)
                );
            Create Table #LotDetail
                (
                  DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , [StockCode] VARCHAR(20) Collate Latin1_General_BIN
                , [Lot] VARCHAR(20) Collate Latin1_General_BIN
                , [Bin] VARCHAR(20) Collate Latin1_General_BIN
                , [Warehouse] VARCHAR(30) Collate Latin1_General_BIN
                , [QtyOnHand] NUMERIC(20, 8)
                , [ExpiryDate] DATETIME2
                , [CreationDate] DATETIME2
                );
            Create Table #CusLot
                (DatabaseName VARCHAR(150) Collate Latin1_General_BIN
                , Lot Varchar(50) Collate Latin1_General_BIN
                , StockCode Varchar(30) Collate Latin1_General_BIN
                , BleedNumber Varchar(20) Collate Latin1_General_BIN
                , DonorNumber Varchar(20) Collate Latin1_General_BIN
                , VendorBatchNumber Varchar(50) Collate Latin1_General_BIN
                , OldLotNumber Varchar(20) Collate Latin1_General_BIN
                , BleedDate Varchar(15) Collate Latin1_General_BIN
                );

--create script to pull data from each db into the tables
            Declare @SQLJobLevelCheck VARCHAR(Max) = '
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
            Declare @SQLWipMasterSub VARCHAR(Max) = '
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
				Insert [#WipMasterSub]
						( [DatabaseName], [Job], [SubJob] )
				SELECT [DatabaseName]=@DBCode
					 , [wms].[Job]
					 , [wms].[SubJob] 
				From [WipMasterSub] As [wms]
			End
	End';
            Declare @SQLWipJobAllMat VARCHAR(Max) = '
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
            Declare @SQLWipJobAllLab VARCHAR(Max) = '
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
            Declare @SQLWipMaster VARCHAR(Max) = '
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
            Declare @SQLInvMaster VARCHAR(Max) = '
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
            Declare @SQLWipAllMatLot VARCHAR(Max) = '
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
            Declare @SQLLotDetail VARCHAR(Max) = '
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
            Declare @SQLCusLot VARCHAR(Max) = '
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
            Exec sp_MSforeachdb @SQLJobLevelCheck;
	--Print 2
            Exec sp_MSforeachdb @SQLWipMasterSub;
	--Print 3
            Exec sp_MSforeachdb @SQLWipJobAllMat;
	--Print 4
            Exec sp_MSforeachdb @SQLWipJobAllLab;
	--Print 5
            Exec sp_MSforeachdb @SQLWipMaster;
	--Print 6
            Exec sp_MSforeachdb @SQLInvMaster;
	--Print 7
            Exec sp_MSforeachdb @SQLWipAllMatLot;
	--Print 8
            Exec sp_MSforeachdb @SQLLotDetail;
	--Print 9
			Exec sp_MSforeachdb @SQLCusLot;

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
            Values
                    ( @Company
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
                    Select
                        @StartTime
                      , jlc.Job
                      , jlc.SubJob
					  ,	SubJobDescription				= JobDescription
					  , SubJobUom						= [im2].[StockUom]
                      , wjam.SequenceNum
                      , SubJobQty						= wm.QtyToMake - wm.QtyManufactured
                      , wjam.StockCode
                      , wjam.StockDescription
                      , wjam.UnitQtyReqdEnt
                      , wjam.QtyIssuedEnt
                      , wjam.FixedQtyPerFlag
                      , wjam.Uom
                      , wjam.AllocCompleted
                      , wjam.OperationOffset
                      , wjal.WorkCentre
                      , SubJobQtyTotal					= Case When wjam.FixedQtyPerFlag = 'N'
																  Then ( ( wm.QtyToMake
																		   - wm.QtyManufactured )
																		 * wjam.UnitQtyReqdEnt )
																  Else wjam.UnitQtyReqdEnt
															 End
                      , [im].[IssMultLotsFlag]
                      , [wjam].[ReservedLotSerFlag]
                      , [wjam].[ReservedLotQty]
                      , [ReservedLot]					= [waml].[Lot]
                      , [ReservedLotBin]				= [waml].[Bin]
					  , [ReservedLotWarehouse]			= waml.Warehouse
                      , [ReservedLotQtyReserved]		= [waml].[QtyReserved]
                      , [ReservedLotQtyIssued]			= [waml].[QtyIssued]
                      , [AvailableLot]					= [ld].[Lot]
                      , [AvailableLotBin]				= [ld].[Bin]
                      , [AvailableLotWarehouse]			= [ld].[Warehouse]
                      , [AvailableLotQtyOnHand]			= [ld].[QtyOnHand]
                      , [AvailableLotExpiryDate]		= [ld].[ExpiryDate]
                      , [AvailableLotCreationDate]		= [ld].[CreationDate]
                      , [ReservedLotBleedNumber]	= CL.BleedNumber
                      , [ReservedLotDonorNumber]	= CL.DonorNumber
                      , [ReservedLotVendorBatchNumber]	= CL.VendorBatchNumber
                      , [ReservedLotOldLotNumber]	= CL.OldLotNumber
                      , [ReservedLotBleedDate]	= CL.BleedDate
                    From
                        #JobLevelCheck jlc
                    Left Join #WipJobAllMat wjam
                        On jlc.SubJob = wjam.Job
						And wjam.DatabaseName = jlc.DatabaseName
                    Left Join #WipJobAllLab wjal
                        On wjam.Job = wjal.Job
                           And wjam.OperationOffset = wjal.Operation
						   And wjal.DatabaseName = wjam.DatabaseName
                    Left Join #WipMaster wm
                        On jlc.SubJob = wm.Job
						And wm.DatabaseName = jlc.DatabaseName
					Left Join [#InvMaster] As [im2]
						On [im2].[StockCode] = [wm].[StockCode]
						And im2.DatabaseName = wm.DatabaseName
                    Left Join #InvMaster im
                        On wjam.StockCode = im.StockCode
						And im.DatabaseName = wjam.DatabaseName
                    Left Join [#LotDetail] As [ld]
                        On [ld].[StockCode] = [im].[StockCode]
                           And im.[IssMultLotsFlag] = 'Y'
                           And COALESCE([wjam].[ReservedLotSerFlag], 'N') <> 'Y'
						   And [ld].[DatabaseName] = [im].[DatabaseName]
                    Left Join [#WipAllMatLot] As [waml]
                        On [waml].[Job] = [wjam].[Job]
                           And [waml].[StockCode] = [wjam].[StockCode]
						   And [waml].[DatabaseName] = [wjam].[DatabaseName]
					Left Join #CusLot As CL 
						On CL.Lot = waml.Lot 
							And CL.StockCode = waml.StockCode
							And CL.DatabaseName = waml.DatabaseName 
                    Where
                        --wjam.AllocCompleted = 'N'
                        --And
						 im.PartCategory <> 'M';

            Update
                [Process].[Status_WipSubJobStock]
            Set
                [CompleteTime] = GETDATE()
              , [IsComplete] = 1
            Where
                [StartTime] = @StartTime
				And [Job]=@MasterJob
				And [Company]=@Company;
--tidy up
            Drop Table #JobLevelCheck;
            Drop Table #WipMasterSub;
            Drop Table #WipJobAllMat;
            Drop Table #WipAllMatLot;
            Drop Table #WipJobAllLab;
            Drop Table #WipMaster;
            Drop Table #InvMaster;
            Drop Table #LotDetail;
        End;

--Set StartTime to last start date
    If @LatestStartTime Is Not Null
        Begin
            Select
                @StartTime = @LatestStartTime;
        End;

--Hold Process until Results are ready
    Declare @Complete BIT = 0;

    While @Complete < 1
        Begin
            Select
                @Complete = [IsComplete]
            From
                [Process].[Status_WipSubJobStock] As [swsjs];
            WaitFor Delay '00:00:01';
        End;

--Return Results
	CREATE --Drop --Truncate 
	TABLE #ReservedLotKeys
	(StartTime DateTime2
	 ,StockCode  Varchar(20) Collate Latin1_General_BIN
	 , ReservedLots Bit
	)
Insert #ReservedLotKeys
        ( StartTime
        , StockCode
        , ReservedLots
        )
	Select   RWSJS.StartTime
			,RWSJS.StockCode 
			,ReservedLots = Case When Max(RWSJS.ReservedLot) Is Not Null Then 1 Else 0 End
	From	 Report.Results_WipSubJobStock As RWSJS
	Group By StockCode 
	,RWSJS.StartTime


    Select MasterJob= @MasterJob
       , [Job]				= Case When ISNUMERIC([r].[Job]) = 1
									Then CAST(CAST([Job] As INT) As VARCHAR(20))
									Else [r].[Job]
									End
      , [SubJob]			= Case When ISNUMERIC([r].[SubJob]) = 1
									Then CAST(CAST([SubJob] As INT) As VARCHAR(20))
									Else [r].[SubJob]
									End
	  , [SubJobDescription]
      , [SequenceNum]		= Case When ISNUMERIC([r].[SequenceNum]) = 1
									Then CAST(CAST([SequenceNum] As INT) As VARCHAR(20))
									Else [r].[SequenceNum]
									End
      , [r].[SubJobQty]
      , [StockCode]			= Case When ISNUMERIC([r].[StockCode]) = 1
							       Then CAST(CAST([r].[StockCode] As INT) As VARCHAR(20))
							       Else [r].[StockCode]
							  End
      , [r].[StockDescription]
      , [r].[UnitQtyReqdEnt]
      , [r].[QtyIssuedEnt]
      , [r].[FixedQtyPerFlag]
      , [Uom] = UPPER([r].[Uom])
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
	  , RLK.ReservedLots
	  , [ReservedLotBleedNumber]		
	  , [ReservedLotDonorNumber]		
	  , [ReservedLotVendorBatchNumber]
	  , [ReservedLotOldLotNumber]		
	  , [ReservedLotBleedDate]		
    From --delete from
        [Report].[Results_WipSubJobStock] As [r]
		Left Join #ReservedLotKeys As RLK 
					On RLK.StartTime = r.StartTime 
					And RLK.StockCode = r.StockCode
    Where
        [r].[StartTime] = @StartTime
    Order By
        StockCode Asc;



GO
