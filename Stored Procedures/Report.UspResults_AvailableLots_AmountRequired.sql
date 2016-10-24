SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AvailableLots_AmountRequired]
    (
      @Company Varchar(10)
    , @StockCode Varchar(150)
    , @AmountRequired Numeric(20 , 8)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--Exec [Report].[UspResults_AvailableLots] @Company ='F', @StockCode ='000000000000013', @AmountRequired = 27.606400
*/
    Set NoCount On;

--Cater for if lower case companies are entered
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_AvailableLots' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
    Declare @ListOfTables Varchar(Max) = 'WipMasterSub,TblApTerms'; 

--Set maxmimum recursion to 9000
    Declare @CurrentJobLevel Int = 1
      , @TotalJobLevel Int= 9000
      , @InsertCount Int;

--Create table to capture results
    Create Table [#InvMaster]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        , [Description] Varchar(50) Collate Latin1_General_BIN
        , [PartCategory] Char(1)
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


--create script to pull data from each db into the tables
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
					, [Description] 
					)
			SELECT [DatabaseName]=@DBCode
				 , [StockCode]
				 , [PartCategory] 
				 , [IssMultLotsFlag]
				 , [StockUom]
				 , [Description] 
			FROM [InvMaster] As [im]
			where [StockCode] =''' + @StockCode + '''
			End
	End';
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
					and [StockCode] =''' + @StockCode + '''
			End
	End';

	--Print 1 
    Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
	--Print 2
    Exec [Process].[ExecForEachDB] @cmd = @SQLLotDetail;

    Create Table [#Results]
        (
          [StockCode] Varchar(20)
        , [StockDescription] Varchar(50)
        , [IssMultLotsFlag] Char(1)
        , [AvailableLot] Varchar(20)
        , [AvailableLotBin] Varchar(20)
        , [AvailableLotWarehouse] Varchar(30)
        , [AvailableLotQtyOnHand] Numeric(20 , 8)
        , [AvailableLotExpiryDate] Date
        , [AvailableLotCreationDate] Date
        , [RunningTotal] Numeric(20 , 8)
        , [LotRank] Int
        );

    Insert  [#Results]
            ( [StockCode]
            , [StockDescription]
            , [IssMultLotsFlag]
            , [AvailableLot]
            , [AvailableLotBin]
            , [AvailableLotWarehouse]
            , [AvailableLotQtyOnHand]
            , [AvailableLotExpiryDate]
            , [AvailableLotCreationDate]
            , [LotRank]
            )
            Select  [im].[StockCode]
                  , [StockDescription] = [im].[Description]
                  , [im].[IssMultLotsFlag]
                  , [AvailableLot] = [ld].[Lot]
                  , [AvailableLotBin] = [ld].[Bin]
                  , [AvailableLotWarehouse] = [ld].[Warehouse]
                  , [AvailableLotQtyOnHand] = [ld].[QtyOnHand]
                  , [AvailableLotExpiryDate] = [ld].[ExpiryDate]
                  , [AvailableLotCreationDate] = [ld].[CreationDate]
                  , [LotRank] = Dense_Rank() Over ( Partition By [ld].[StockCode] Order By [ld].[CreationDate] Asc, [ld].[Lot] Asc )
            From    [#InvMaster] As [im]
                    Left Join [#LotDetail] As [ld] On [ld].[DatabaseName] = [im].[DatabaseName]
                                                      And [ld].[StockCode] = [im].[StockCode]
                                                      And [im].[IssMultLotsFlag] = 'Y';


    Declare @RunningTotal Numeric(20 , 8)= 0;

    Update  [#Results]
    Set     @RunningTotal = [RunningTotal] = @RunningTotal
            + [AvailableLotQtyOnHand]
    From    [#Results]; 

    Declare @Min Numeric(20 , 8)
      , @Max Numeric(20 , 8);

    Select  @Min = Min([R].[RunningTotal])
    From    [#Results] As [R]
    Where   [R].[RunningTotal] > @AmountRequired;

    Select  @Max = Max([R].[RunningTotal])
    From    [#Results] As [R]
    Where   [R].[RunningTotal] <= @AmountRequired;

    Print 1;
    Print @Min;
    Print 2;
    Print @Max;

    If @Min Is Null
        And @Max Is Null
        Begin
            Select  @AmountRequired = Min([R].[RunningTotal])
            From    [#Results] As [R];
        End;

    If Coalesce(@Max , 0) < @AmountRequired
        And @Min Is Not Null
        Begin
            Set @AmountRequired = @Min;
        End;

    Select  [R].[StockCode]
          , [R].[StockDescription]
          , [R].[IssMultLotsFlag]
          , [R].[AvailableLot]
          , [R].[AvailableLotBin]
          , [R].[AvailableLotWarehouse]
          , [R].[AvailableLotQtyOnHand]
          , [R].[AvailableLotExpiryDate]
          , [R].[AvailableLotCreationDate]
          , [R].[RunningTotal]
          , [R].[LotRank]
    From    [#Results] As [R]
            Left Join [#Results] As [R2] On [R2].[AvailableLot] = [R].[AvailableLot] + 1
    Where   [R].[RunningTotal] <= @AmountRequired;
	--Or R.LotRank=1;

--tidy up
    Drop Table [#InvMaster];
    Drop Table [#LotDetail];






GO
EXEC sp_addextendedproperty N'MS_Description', N'list of available lots up to the required amount entered, lots picked from oldest to newest', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_AvailableLots_AmountRequired', NULL, NULL
GO
