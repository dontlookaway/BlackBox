SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JobStockDetails]
    (
      @Company Varchar(Max)
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

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_JobStockDetails' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'InvMovements,InvMaster'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#InvMovements]
            (
              [DatabaseName] Varchar(150)
            , [Job] Varchar(35)
            , [Warehouse] Varchar(20)
            , [Bin] Varchar(20)
            , [StockCode] Varchar(35)
            , [TrnType] Varchar(5)
            , [LotSerial] Varchar(50)
            , [TrnQty] Float
            , [TrnValue] Float
            , [UnitCost] Numeric(20 , 7)
            );
        Create Table [#InvMaster]
            (
              [DatabaseName] Varchar(150)
            , [StockCode] Varchar(35)
            , [StockDescription] Varchar(150)
            , [StockUom] Varchar(10)
            );


--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
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
				    Insert  #InvMovements
									( DatabaseName
									, Job
									, Warehouse
									, Bin
									, StockCode
									, TrnType
									, LotSerial
									, TrnQty
									, TrnValue
									,UnitCost
									)
					Select
						DatabaseName=@DBCode
						, Job
						, Warehouse
						, Bin
						, StockCode
						, TrnType
						, LotSerial
						, TrnQty
						,TrnValue
						,UnitCost
					From
						InvMovements
					where Job<>'''';
			End
	End';
        Declare @SQL2 Varchar(Max) = '
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
				Insert #InvMaster
	        ( DatabaseName
	        , StockCode
	        , StockDescription
			,StockUom
	        )
			SELECT DatabaseName=@DBCode
				 , StockCode
				 , Description
				 ,StockUom
			FROM InvMaster
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;


--Placeholder to create indexes as required

--return results
        Set NoCount Off;
        Select  [IM].[DatabaseName]
              , [IM].[Job]
              , [IM].[Warehouse]
              , [IM].[Bin]
              , [IM].[StockCode]
              , [IMA].[StockDescription]
              , [OutwardLot] = Case When [IM].[TrnType] = 'R'
                                    Then Substring([IM].[LotSerial] ,
                                                   PatIndex('%[^0]%' ,
                                                            [IM].[LotSerial]) ,
                                                   10)
                                    Else Null
                               End --receipted Lots generated from job
              , [InwardLot] = Case When [IM].[TrnType] <> 'R'
                                        And [IM].[LotSerial] <> ''
                                   Then Substring([IM].[LotSerial] ,
                                                  PatIndex('%[^0]%' ,
                                                           [IM].[LotSerial]) ,
                                                  10)
                                   Else Null
                              End --receipted Lots generated from job
              , [IM].[TrnType]
              , [Quantity] = Sum([IM].[TrnQty] * [TT].[AmountModifier])
              , [Value] = Sum([IM].[TrnValue] * [TT].[AmountModifier])
              , [IMA].[StockUom]
              , [IM].[UnitCost]
        From    [#InvMovements] [IM]
                Left Join [BlackBox].[Lookups].[TrnTypeAmountModifier] [TT]
                    On [TT].[TrnType] = [IM].[TrnType] Collate Latin1_General_BIN
                       And [TT].[Company] = [IM].[DatabaseName] Collate Latin1_General_BIN
                Left Join [#InvMaster] [IMA]
                    On [IMA].[StockCode] = [IM].[StockCode] Collate Latin1_General_BIN
                       And [IMA].[DatabaseName] = [IM].[DatabaseName] Collate Latin1_General_BIN
        Group By [IM].[DatabaseName]
              , [IM].[Job]
              , [IM].[Warehouse]
              , [IM].[Bin]
              , [IM].[StockCode]
              , [IMA].[StockDescription]
              , Case When [IM].[TrnType] = 'R'
                     Then Substring([IM].[LotSerial] ,
                                    PatIndex('%[^0]%' , [IM].[LotSerial]) , 10)
                     Else Null
                End 
              , Case When [IM].[TrnType] <> 'R'
                          And [IM].[LotSerial] <> ''
                     Then Substring([IM].[LotSerial] ,
                                    PatIndex('%[^0]%' , [IM].[LotSerial]) , 10)
                     Else Null
                End 
              , [IM].[TrnType]
              , [IMA].[StockUom]
              , [IM].[UnitCost];

    End;

GO
