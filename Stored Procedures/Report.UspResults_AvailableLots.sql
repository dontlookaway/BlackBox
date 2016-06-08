SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AvailableLots]
    (
      @Company Varchar(Max)
    , @StockCode Varchar(50)
    , @Lot Varchar(1000)
    , @IssueFromYN Char(1) --choose whether to only pick from warehouses that can issue
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
--remove nocount on to speed up query
        Set NoCount On;


        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;


--If no stockcode selected, return all stock
        Select  @StockCode = Case When Lower(@StockCode) In ( '' , 'all' )
                                  Then 'ALL'
                                  Else Upper(@StockCode)
                             End;

--If no lot selected, return all lots
        Select  @Lot = Case When Lower(@Lot) In ( '' , 'all' ) Then 'ALL'
                            Else Upper(@Lot)
                       End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_AvailableLots' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvWhControl,InvMovements,InvMaster'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvWhControl]
            (
              [DatabaseName] Varchar(150)
            , [Warehouse] Varchar(10)
            , [Description] Varchar(50)
            , [Fax] Varchar(20)
            );
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)
            , [Warehouse] Varchar(10)
            , [TrnType] Char(1)
            , [Reference] Varchar(30)
            , [StockCode] Varchar(30)
            , [TrnQuantity] Numeric(20 , 6)
            , [TimeStamp] NVarchar(50)
            , [TrnDate] Date
            , [Lot] Varchar(50)
            , [EntryDateTime] As Left(Convert(NVarchar(50) , [TrnDate] , 121) ,
                                      10) + [TimeStamp]
            ); 
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [StockCode] Varchar(30)
            , [Description] Varchar(50)
            , [StockUom] Varchar(10)
            , [Decimals] Int
            );

--create script to pull data from each db into the tables
        Declare @SQLInvWhControl Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert [#InvWhControl]
						( [DatabaseName]
						, [Warehouse]
						, [Description]
						, [Fax]
						)
				SELECT [DatabaseName]=@DBCode
					 , [IWC].[Warehouse]
					 , [IWC].[Description]
					 , [Fax] = case when upper([IWC].[Fax]) not in (''N'',''Y'') then ''N'' else upper([IWC].[Fax]) end FROM [InvWhControl] [IWC]'
            + Case When @IssueFromYN = 'Y'
                   Then 'Where case when upper([IWC].[Fax]) not in (''N'',''Y'') then ''N'' else upper([IWC].[Fax]) end=''Y'''
                   Else ''
              End + '			End
	End';
        Declare @SQLInvMaster Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert [#InvMaster]
					( [DatabaseName]
					, [StockCode]
					, [Description]
					, [StockUom]
					, [Decimals]
					)
			SELECT [DatabaseName]=@DBCode
				 , [IM].[StockCode]
				 , [IM].[Description]
				 , [IM].[StockUom]
				 , [IM].[Decimals] FROM [InvMaster] [IM]'
            + Case When @StockCode <> 'ALL'
                   Then 'Where Upper([IM].[StockCode]) In (''' + @StockCode
                        + ''')'
                   Else ''
              End + '		End
	End';
        Declare @SQLLotTransactions Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				 Insert  [#LotTransactions]
                    ( [DatabaseName]
                    , [Warehouse]
					, [Lot]
                    , [TrnType]
                    , [Reference]
                    , [StockCode]
                    , [TrnQuantity]
					, [TimeStamp]
                    , [TrnDate]
			        )
                    Select  [DatabaseName] = @DBCode
                          , [LT].[Warehouse]
						  , [Lot]=substring(Lot, patindex(''%[^0]%'',Lot), 10)
                          , [LT].[TrnType]
                          , [LT].[Reference]
                          , [LT].[StockCode]
                          , [LT].[TrnQuantity]
                          , [TimeStamp] = Right(Convert(NVarchar(50) , Cast([TimeStamp] As DateTime) , 121) ,13)
                          , [LT].[TrnDate]
                    From    [LotTransactions] [LT]'
            + Case When @Lot <> 'ALL'
                        Or @StockCode <> 'ALL' Then ' where '
                   Else ''
              End
            + Case When @StockCode <> 'ALL'
                   Then ' Upper([LT].[StockCode]) In (''' + @StockCode + ''')'
                   Else ''
              End + Case When @Lot <> 'ALL'
                              And @StockCode <> 'ALL' Then ' and '
                         Else ''
                    End
            + Case When @Lot <> 'ALL'
                   Then ' Upper(substring(Lot, patindex(''%[^0]%'',Lot), 10)) In ('''
                        + @Lot + ''')'
                   Else ''
              End + '		
		End
	End';
--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvWhControl;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
        Exec [Process].[ExecForEachDB] @cmd = @SQLLotTransactions;


--define the results you want to return
        Create Table [#AllMovements]
            (
              [Warehouse] Varchar(10)
            , [WarehouseDescription] Varchar(50)
            , [IssueFrom] Varchar(20)
            , [AmountModifier] Int
            , [TrnType] Char(1)
            , [Reference] Varchar(30)
            , [Lot] Varchar(50)
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [StockUom] Varchar(10)
            , [TrnQty] Numeric(20 , 6)
            , [Decimals] Int
            , [EntryDateTime] DateTime2
            , [DescendingRank] BigInt
            , [DatabaseName] Varchar(150)
            );

--Placeholder to create indexes as required
        --Create NonClustered Index [IM_Sc_Wh_Edt_Temp] On [#InvMovements] ([StockCode],[Warehouse],[EntryDateTime]);
        Create NonClustered Index [Am_All_Temp] On [#AllMovements] ([Warehouse], [IssueFrom], [StockCode], [StockUom], [DescendingRank]) Include ([WarehouseDescription], [StockDescription], [Decimals]);

--script to combine base data and insert into results table
        Insert  [#AllMovements]
                ( [Warehouse]
                , [WarehouseDescription]
                , [IssueFrom]
                , [AmountModifier]
                , [TrnType]
                , [Reference]
                , [Lot]
                , [StockCode]
                , [StockDescription]
                , [StockUom]
                , [TrnQty]
                , [Decimals]
                , [EntryDateTime]
                , [DescendingRank]
                , [DatabaseName]
                )
                Select  [IWC].[Warehouse]
                      , [WarehouseDescription] = [IWC].[Description]
                      , [IssueFrom] = [IWC].[Fax]
                      , [TTAM].[AmountModifier]
                      , [LT].[TrnType]
                      , [LT].[Reference]
                      , [LT].[Lot]
                      , [LT].[StockCode]
                      , [StockDescription] = [IM2].[Description]
                      , [IM2].[StockUom]
                      , [LT].[TrnQuantity]
                      , [IM2].[Decimals]
                      , [LT].[EntryDateTime]
                      , [DescendingRank] = Rank() Over ( Partition By [LT].[StockCode] ,
                                                         [LT].[Warehouse] ,
                                                         [LT].[Lot] Order By [LT].[EntryDateTime] Desc )
                      , [IWC].[DatabaseName]
                From    [#InvWhControl] [IWC]
                        Inner Join [#LotTransactions] [LT]
                            On [LT].[Warehouse] = [IWC].[Warehouse]
                               And [LT].[DatabaseName] = [IWC].[DatabaseName]
                        Left Join [#InvMaster] [IM2]
                            On [IM2].[StockCode] = [LT].[StockCode]
                               And [IM2].[DatabaseName] = [LT].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier] [TTAM]
                            On [TTAM].[TrnType] = [LT].[TrnType]
                               And [TTAM].[Company] = [LT].[DatabaseName];

        Set NoCount Off;

--return results
        Select  [AM].[Warehouse]
              , [AM].[WarehouseDescription]
              , [AM].[IssueFrom]
              , [AM].[Lot]
              , [AM].[StockCode]
              , [AM].[StockDescription]
              , [StockLevel] = Sum([AM].[AmountModifier] * [AM].[TrnQty])
              , [AM].[StockUom]
              , [AM].[Decimals]
              , [LastReference] = Max(Case When [AM].[DescendingRank] = 1
                                           Then [AM].[Reference]
                                      End)
              , [LastEntry] = Max(Case When [AM].[DescendingRank] = 1
                                       Then [AM].[EntryDateTime]
                                  End)
              , [LastEntryAmount] = Max(Case When [AM].[DescendingRank] = 1
                                             Then [AM].[TrnQty]
                                                  * [AM].[AmountModifier]
                                        End)
              , [LastEntryType] = Max(Case When [AM].[DescendingRank] = 1
                                           Then [AM].[TrnType]
                                      End)
              , [AM].[DatabaseName]
              , [CN].[CompanyName]
              , [CN].[ShortName]
        From    [#AllMovements] [AM]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [AM].[DatabaseName] = [CN].[Company]
        Group By [AM].[Warehouse]
              , [AM].[WarehouseDescription]
              , [AM].[IssueFrom]
              , [AM].[Lot]
              , [AM].[StockCode]
              , [AM].[StockDescription]
              , [AM].[StockUom]
              , [AM].[Decimals]
              , [AM].[DatabaseName]
              , [CN].[CompanyName]
              , [CN].[ShortName];

    End;

GO
