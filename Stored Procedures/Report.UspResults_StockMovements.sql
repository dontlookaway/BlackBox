
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockMovements] ( @Company Varchar(Max) )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
-- exec [Report].[UspResults_StockMovements] 10 @Warehouses ='All',@Bins='All',@StockCodes='3000'
*/
        Set NoCount Off;
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;
        Declare @Warehouses Varchar(Max) = 'All'
          , @Bins Varchar(Max) = 'All'
          , @StockCodes Varchar(Max) = 'All';
--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvMaster,InvMovements'; 

	--List of Warehouses selected by User
        Create Table [#WarehouseList]
            (
              [Warehouse] Varchar(10) Collate Latin1_General_BIN
            );

        If @Warehouses = 'All'
            Begin
                Insert  [#WarehouseList]
                        ( [Warehouse]
                        )
                        Select  [Warehouse]
                        From    [Lookups].[Warehouse]
                        Where   [Company] = @Company;
            End;
        If @Warehouses <> 'All'
            Begin
                Insert  [#WarehouseList]
                        ( [Warehouse]
                        )
                        Select  [Value]
                        From    [BlackBox].[dbo].[udf_SplitString](@Warehouses , ',');
            End;

	--List of Bins selected by User
        Create Table [#BinList]
            (
              [Bin] Varchar(20) Collate Latin1_General_BIN
            );

        If @Bins = 'All'
            Begin
                Insert  [#BinList]
                        ( [Bin]
                        )
                        Select  [Bin]
                        From    [Lookups].[Bin]
                        Where   [Company] = @Company;
            End;
        If @Bins <> 'All'
            Begin
                Insert  [#BinList]
                        ( [Bin]
                        )
                        Select  [Value]
                        From    [BlackBox].[dbo].[udf_SplitString](@Bins , ',');
            End;

        Create --drop --alter 
	Table [#StockCodeList]
            (
              [StockCode] Varchar(30) Collate Latin1_General_BIN
            );

        If @StockCodes = 'All'
            Begin
                Insert  [#StockCodeList]
                        ( [StockCode]
                        )
                        Select  [StockCode]
                        From    [Lookups].[StockCode]
                        Where   [Company] = @Company;
            End;
        If @StockCodes <> 'All'
            Begin
                Insert  [#StockCodeList]
                        ( [StockCode]
                        )
                        Select  [Value]
                        From    [BlackBox].[dbo].[udf_SplitString](@StockCodes , ',');
            End;

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [AbcClass] Char(1)
            , [CostUom] Varchar(10)
            , [CycleCount] Decimal
            , [Description] Varchar(50)
            , [ProductClass] Varchar(20)
            , [StockCode] Varchar(30)
            , [StockUom] Varchar(10)
            );



        Create Table [#InvMovements]
            (
              [DatabaseName] Varchar(150)
            , [Bin] Varchar(20)
            , [EnteredCost] Float
            , [EntryDate] DateTime2
            , [MovementType] Char(1)
            , [TrnQty] Float
            , [TrnType] Char(1)
            , [TrnValue] Float
            , [Warehouse] Varchar(10)
            , [StockCode] Varchar(30)
            , [LotSerial] Varchar(50)
            , [TrnPeriod] Int
            );

			



--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
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
			    , AbcClass
			    , CostUom
			    , CycleCount
			    , Description
			    , ProductClass
			    , StockCode
			    , StockUom
			    )
			Select @DBCode
				, AbcClass
				, CostUom
				, CycleCount
				, Description
				, ProductClass
				, IM.StockCode
				, IM.StockUom
			From InvMaster IM
			inner join #StockCodeList SL
			on IM.StockCode = SL.StockCode

			Insert #InvMovements
			    ( DatabaseName
			    , Bin
			    , EnteredCost
			    , EntryDate
			    , MovementType
			    , TrnQty
			    , TrnType
			    , TrnValue
			    , Warehouse
				, StockCode
				,[LotSerial]
				, TrnPeriod
			    )
			Select @DBCode
				,	IM.Bin
				, EnteredCost
				, EntryDate
				, MovementType
				, TrnQty
				, TrnType
				, TrnValue
				, IM.Warehouse
				, IM.StockCode
				, IM.[LotSerial]
				, TrnPeriod = TrnYear*100+TrnMonth
			From dbo.InvMovements IM
			inner join #StockCodeList SL
				on IM.StockCode = SL.StockCode
			inner join #WarehouseList WL
				on IM.Warehouse = WL.Warehouse
			inner join #BinList BL
				on IM.Bin = BL.Bin
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
        Print @SQL;

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL;

--define the results you want to return
        Create Table [#Results]
            (
              [Company] Varchar(150)
            , [AbcClass] Char(1)
            , [CostUom] Varchar(10)
            , [CycleCount] Float
            , [Description] Varchar(50)
            , [ProductClass] Varchar(20)
            , [StockCode] Varchar(30)
            , [StockUom] Varchar(10)
            , [Bin] Varchar(20)
            , [EnteredCost] Decimal
            , [EntryDate] DateTime2
            , [MovementType] Char(1)
            , [TrnQty] Float
            , [TrnType] Char(1)
            , [TrnValue] Float
            , [Warehouse] Varchar(10)
            , [LotSerial] Varchar(50)
            , [TrnPeriod] Int
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Company]
                , [AbcClass]
                , [CostUom]
                , [CycleCount]
                , [Description]
                , [ProductClass]
                , [StockCode]
                , [StockUom]
                , [Bin]
                , [EnteredCost]
                , [EntryDate]
                , [MovementType]
                , [TrnQty]
                , [TrnType]
                , [TrnValue]
                , [Warehouse]
                , [LotSerial]
                , [TrnPeriod]
                )
                Select  [Company] = [IM].[DatabaseName]
                      , [IM].[AbcClass]
                      , [IM].[CostUom]
                      , [IM].[CycleCount]
                      , [IM].[Description]
                      , [IM].[ProductClass]
                      , [IM].[StockCode]
                      , [IM].[StockUom]
                      , [IM2].[Bin]
                      , [IM2].[EnteredCost]
                      , [IM2].[EntryDate]
                      , [IM2].[MovementType]
                      , [IM2].[TrnQty]
                      , [IM2].[TrnType]
                      , [IM2].[TrnValue] * [TM].[AmountModifier]
                      , [IM2].[Warehouse]
                      , [IM2].[LotSerial]
                      , [IM2].[TrnPeriod]
                From    [#InvMaster] [IM]
                        Left Join [#InvMovements] [IM2] On [IM2].[DatabaseName] = [IM].[DatabaseName]
                                                       And [IM2].[StockCode] = [IM].[StockCode]
                        Left Join [Lookups].[TrnTypeAmountModifier] [TM] On [TM].[TrnType] Collate Latin1_General_BIN = [IM2].[TrnType]
                                                              And [TM].[Company] = [IM].[DatabaseName] Collate Latin1_General_BIN;

--return results
        Select  [Company]
              , [AbcClass]
              , [CostUom]
              , [CycleCount]
              , [Description]
              , [ProductClass]
              , [StockCode]
              , [StockUom]
              , [Bin]
              , [EnteredCost]
              , [EntryDate]
              , [MovementType]
              , [TrnQty]
              , [TrnType]
              , [TrnValue] = Coalesce([TrnValue] , 0)
              , [Warehouse]
              , [Lot] = Case When [LotSerial] = '' Then Null
                           When IsNumeric([LotSerial]) = 1
                           Then Cast([LotSerial] As BigInt)
                           Else [LotSerial]
                      End
              , [TrnPeriod] = Cast(DateAdd(Month ,
                                         Cast(Right([TrnPeriod] , 2) As Int) - 1 ,
                                         DateAdd(Year ,
                                                 Cast(Left([TrnPeriod] , 4) As Int)
                                                 - 1900 ,
                                                 Cast('' As DateTime2))) As Date)
        From    [#Results];

    End;

GO
