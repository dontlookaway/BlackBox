SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_AvailableStock]
    (
      @Company Varchar(Max)
    , @StockCode Varchar(50)
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

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_AvailableStock' ,
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
        Create Table [#InvMovements]
            (
              [DatabaseName] Varchar(150)
            , [Warehouse] Varchar(10)
            , [MovementType] Char(1)
            , [TrnType] Char(1)
            , [Reference] Varchar(30)
            , [StockCode] Varchar(30)
            , [TrnQty] Numeric(20 , 6)
            , [EntryDate] DateTime
            , [TrnTime] Int
            , [EntryDateTime] As DateAdd(Millisecond ,
                                         Convert(Int , Right([TrnTime] , 2)) ,
                                         DateAdd(Second ,
                                                 Convert(Int , Left(Right([TrnTime] ,
                                                              4) , 2)) ,
                                                 DateAdd(Minute ,
                                                         Convert(Int , Left(Right([TrnTime] ,
                                                              6) , 2)) ,
                                                         DateAdd(Hour ,
                                                              Convert(Int , Left([TrnTime] ,
                                                              2)) ,
                                                              [EntryDate]))))
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
            + Case When @IssueFromYN = 'Y' Then 'Where case when upper([IWC].[Fax]) not in (''N'',''Y'') then ''N'' else upper([IWC].[Fax]) end=''Y'''
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
        Declare @SQLInvMovements Varchar(Max) = '
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
				Insert [#InvMovements]
						( [DatabaseName]
						, [Warehouse]
						, [MovementType]
						, [TrnType]
						, [Reference]
						, [StockCode]
						, [TrnQty]
						, [EntryDate]
						, [TrnTime]
						)
				SELECT [DatabaseName]=@DBCode
					 , [IM].[Warehouse]
					 , [IM].[MovementType]
					 , [IM].[TrnType]
					 , [IM].[Reference]
					 , [IM].[StockCode]
					 , [IM].[TrnQty]
					 , [IM].[EntryDate]
					 , [IM].[TrnTime] FROM [InvMovements] [IM]'
            + Case When @StockCode <> 'ALL'
                   Then 'Where Upper([IM].[StockCode]) In (''' + @StockCode
                        + ''')'
                   Else ''
              End + '		End
	End';
--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvWhControl;
        Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
		Exec [Process].[ExecForEachDB] @cmd = @SQLInvMovements;


--define the results you want to return
        Create Table [#AllMovements]
            (
              [Warehouse] Varchar(10)
            , [WarehouseDescription] Varchar(50)
            , [IssueFrom] Varchar(20)
            , [MovementType] Char(1)
            , [AmountModifier] Int
            , [TrnType] Char(1)
            , [Reference] Varchar(30)
            , [StockCode] Varchar(30)
            , [StockDescription] Varchar(50)
            , [StockUom] Varchar(10)
            , [TrnQty] Numeric(20 , 6)
            , [Decimals] Int
            , [EntryDateTime] DateTime2
            , [DescendingRank] BigInt
            );

--Placeholder to create indexes as required
        Create NonClustered Index [IM_Sc_Wh_Edt_Temp] On [#InvMovements] ([StockCode],[Warehouse],[EntryDateTime]);
        Create NonClustered Index [Am_All_Temp] On [#AllMovements] ([Warehouse], [IssueFrom], [StockCode], [StockUom], [DescendingRank]) Include ([WarehouseDescription], [StockDescription], [Decimals]);

--script to combine base data and insert into results table
        Insert  [#AllMovements]
                ( [Warehouse]
                , [WarehouseDescription]
                , [IssueFrom]
                , [MovementType]
                , [AmountModifier]
                , [TrnType]
                , [Reference]
                , [StockCode]
                , [StockDescription]
                , [StockUom]
                , [TrnQty]
                , [Decimals]
                , [EntryDateTime]
                , [DescendingRank]
                )
                Select  [IWC].[Warehouse]
                      , [WarehouseDescription] = [IWC].[Description]
                      , [IssueFrom] = [IWC].[Fax]
                      , [IM].[MovementType]
                      , [TTAM].[AmountModifier]
                      , [TrnType] = Case When [IM].[TrnType] = ''
                                         Then [IM].[MovementType]
                                         Else [IM].[TrnType]
                                    End
                      , [IM].[Reference]
                      , [IM].[StockCode]
                      , [StockDescription] = [IM2].[Description]
                      , [IM2].[StockUom]
                      , [IM].[TrnQty]
                      , [IM2].[Decimals]
                      , [IM].[EntryDateTime]
                      , [DescendingRank] = Rank() Over ( Partition By [IM].[StockCode] ,
                                                         [IM].[Warehouse] Order By [IM].[EntryDateTime] Desc )
                From    [#InvWhControl] [IWC]
                        Inner Join [#InvMovements] [IM]
                            On [IM].[Warehouse] = [IWC].[Warehouse]
                               And [IM].[DatabaseName] = [IWC].[DatabaseName]
                        Left Join [#InvMaster] [IM2]
                            On [IM2].[StockCode] = [IM].[StockCode]
                               And [IM2].[DatabaseName] = [IM].[DatabaseName]
                        Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier] [TTAM]
                            On [TTAM].[TrnType] = [IM].[TrnType]
                               And [TTAM].[Company] = [IM].[DatabaseName];

Set NoCount Off

--return results
        Select  [AM].[Warehouse]
              , [AM].[WarehouseDescription]
              , [AM].[IssueFrom]
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
                                             Then [AM].[TrnQty]*[AM].[AmountModifier]
                                        End)
              , [LastEntryType] = Max(Case When [AM].[DescendingRank] = 1
                                           Then [AM].[TrnType]
                                      End)
        From    [#AllMovements] [AM]
        Group By [AM].[Warehouse]
              , [AM].[WarehouseDescription]
              , [AM].[IssueFrom]
              , [AM].[StockCode]
              , [AM].[StockDescription]
              , [AM].[StockUom]
              , [AM].[Decimals];

    End;

GO
