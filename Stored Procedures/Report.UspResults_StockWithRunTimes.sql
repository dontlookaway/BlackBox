SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockWithRunTimes]
    (
      @Company Varchar(Max)
    , @EndPeriod Date
    , @LotLowerNumber BigInt
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin

        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_Template' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;



--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'WipLabJnl,LotTransactions,InvMaster'; 

--create temporary tables to be pulled from different databases, including a column to id


        Create Table [#WipLabJnl]
            (
              [DatabaseCode] Varchar(10)
            , [Job] Varchar(20)
            , [RunTime] Numeric(20 , 4)
            );
        Create Table [#LotTransactions]
            (
              [DatabaseCode] Varchar(10)
            , [StockCode] Varchar(30)
            , [Warehouse] Varchar(10)
            , [TrnQuantity] Numeric(20 , 6)
            , [JobPurchOrder] Varchar(20)
            , [TrnDate] Date
            , [TrnType] Char(1)
            , [Lot] Varchar(50)
            );
        Create Table [#InvMaster]
            (
              [DatabaseCode] Varchar(10)
            , [StockCode] Varchar(30)
            , [Description] Varchar(50)
            );
--temp tables used in calculations
        Create Table [#WarehouseLevels]
            (
              [DatabaseCode] Varchar(10)
            , [StockCode] Varchar(30)
            , [Warehouse] Varchar(10)
            , [TrnQuantityMod] Numeric(20 , 8)
            , [JobPurchOrder] Varchar(30)
            , [CreatedDate] Date
            );
        Create Table [#HoursPerJob]
            (
              [DatabaseCode] Varchar(10)
            , [Job] Varchar(20)
            , [RunTime] Numeric(20 , 4)
            );

--create script to pull data from each db into the tables
        Declare @SQLInvMaster Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert  [#InvMaster]
                ( [DatabaseCode]
                , [StockCode]
                , [Description]
                )
                Select  [DatabaseCode] = @DBCode
                      , [IM].[StockCode]
                      , [IM].[Description]
                From    [InvMaster] [IM];
			End
	End';
        Declare @SQLLotTransactions Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert  [#LotTransactions]
                ( [DatabaseCode]
                , [StockCode]
                , [Warehouse]
                , [TrnQuantity]
                , [JobPurchOrder]
                , [TrnDate]
                , [TrnType]
                , [Lot]
                )
                Select  [DatabaseCode] = @DBCode
                      , [LT].[StockCode]
                      , [LT].[Warehouse]
                      , [LT].[TrnQuantity]
                      , [LT].[JobPurchOrder]
                      , [LT].[TrnDate]
                      , [LT].[TrnType]
                      , [LT].[Lot]
                From    [LotTransactions] [LT];
			End
	End';
        Declare @SQLWipLabJnl Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert  [#WipLabJnl]
                ( [DatabaseCode]
                , [Job]
                , [RunTime]
                )
                Select  [DatabaseCode] = @DBCode
                      , [WLJ].[Job]
                      , [WLJ].[RunTime]
                From    [WipLabJnl] [WLJ];
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLInvMaster ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLLotTransactions ,
            @SchemaTablesToCheck = @ListOfTables;
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLWipLabJnl ,
            @SchemaTablesToCheck = @ListOfTables;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseCode] Varchar(10)
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(150)
            , [Warehouse] Varchar(10)
            , [QtyOnHand] Numeric(20 , 8)
            , [RunTimeTotal] Numeric(20 , 2)
            , [TimePerUnit] Float
            , [JobQuantity] Numeric(20 , 8)
            );

--Placeholder to create indexes as required
        --Get time logged per job
        Insert  [#HoursPerJob]
                ( [DatabaseCode]
                , [Job]
                , [RunTime]
                )
                Select  [WLJ].[DatabaseCode]
                      , [WLJ].[Job]
                      , Sum([WLJ].[RunTime])
                From    [#WipLabJnl] [WLJ]
                Group By [WLJ].[DatabaseCode]
                      , [WLJ].[Job];

		--get amount per job in each warehouse
        Insert  [#WarehouseLevels]
                ( [DatabaseCode]
                , [StockCode]
                , [Warehouse]
                , [TrnQuantityMod]
                , [JobPurchOrder]
                , [CreatedDate]
                )
                Select  [LT].[DatabaseCode]
                      , [LT].[StockCode]
                      , [LT].[Warehouse]
                      , [TrnQuantityMod] = Sum([LT].[TrnQuantity]
                                               * [TTAM].[AmountModifier])
                      , [LT2].[JobPurchOrder]
                      , [CreatedDate] = [LT2].[TrnDate]
                From    [#LotTransactions] [LT]
                        Inner Join [BlackBox].[Lookups].[TrnTypeAmountModifier] [TTAM]
                            On [TTAM].[TrnType] = [LT].[TrnType]
                               And [TTAM].[Company] = [LT].[DatabaseCode]
                        Left Join [#LotTransactions] [LT2]
                            On [LT].[Lot] = [LT2].[Lot]
                               And [LT2].[DatabaseCode] = [LT].[DatabaseCode]
                               And [LT2].[TrnType] = 'R'
                Where   [LT].[TrnDate] <= @EndPeriod
                        And Case When IsNumeric([LT].[Lot]) = 1
                                 Then Convert(Numeric(20) , [LT].[Lot])
                                 Else @LotLowerNumber + 1
                            End > @LotLowerNumber
                Group By [LT].[DatabaseCode]
                      , [LT].[StockCode]
                      , [LT].[Warehouse]
                      , [LT2].[JobPurchOrder]
                      , [LT2].[TrnDate];

        Select  [LT].[DatabaseCode]
              , [LT].[JobPurchOrder]
              , [TimePerUnit] = Case When [HPJ].[RunTime] Is Null
                                     Then Convert(Float , 0)
                                     When [HPJ].[RunTime] = 0
                                     Then Convert(Float , 0)
                                     Else Convert(Float , [HPJ].[RunTime]) / Convert(Float,Sum([LT].[TrnQuantity]))

                                End
              , [JobQuantity] = Sum([LT].[TrnQuantity])
        Into    [#Test]
        From    [#LotTransactions] [LT]
                Left Join [#HoursPerJob] [HPJ]
                    On [HPJ].[DatabaseCode] = [LT].[DatabaseCode]
                       And [LT].[JobPurchOrder] = [HPJ].[Job]
        Where   [LT].[TrnType] = 'R'
        Group By [LT].[DatabaseCode]
              , [LT].[JobPurchOrder]
              , [HPJ].[RunTime];

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseCode]
                , [StockCode]
                , [StockDescription]
                , [Warehouse]
                , [QtyOnHand]
                , [RunTimeTotal]
                , [TimePerUnit]
                , [JobQuantity]
                )
                Select  [WL].[DatabaseCode]
                      , [WL].[StockCode]
                      , [StockDescription] = [IM].[Description]
                      , [WL].[Warehouse]
                      , [QtyOnHand] = Sum([WL].[TrnQuantityMod])
                      , [RunTimeTotal] = Sum([HPJ].[RunTime])
                      , [T].[TimePerUnit]
                      , [JobQuantity] = Sum([T].[JobQuantity])
                From    [#WarehouseLevels] [WL]
                        Left Join [#HoursPerJob] [HPJ]
                            On [HPJ].[Job] = [WL].[JobPurchOrder]
                        Left Join [#InvMaster] [IM]
                            On [IM].[StockCode] = [WL].[StockCode]
                               And [IM].[DatabaseCode] = [WL].[DatabaseCode]
                        Left Join [#Test] [T]
                            On [T].[DatabaseCode] = [WL].[DatabaseCode]
                               And [T].[JobPurchOrder] = [WL].[JobPurchOrder]
                Group By [WL].[DatabaseCode]
                      , [WL].[StockCode]
                      , [IM].[Description]
                      , [WL].[Warehouse]
                      , [T].[TimePerUnit]
                      --, [T].[JobQuantity]
                Having  Sum([WL].[TrnQuantityMod]) <> 0;

        Drop Table [#HoursPerJob];
        Drop Table [#InvMaster];
        Drop Table [#LotTransactions];
        Drop Table [#WarehouseLevels];
        Drop Table [#WipLabJnl];

        Set NoCount Off;
--return results
        Select  [R].[DatabaseCode]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[Warehouse]
              , [R].[QtyOnHand]
              , [R].[RunTimeTotal]
              , [R].[TimePerUnit]
              , [R].[JobQuantity]
              , [CN].[CompanyName]
              , [CN].[ShortName]
        From    [#Results] [R]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [R].[DatabaseCode] = [CN].[Company];

    End;

GO
