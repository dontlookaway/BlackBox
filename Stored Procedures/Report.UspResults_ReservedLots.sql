
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ReservedLots]
    (
      @Company Varchar(10)
    , @StockCode Varchar(20)
    , @Job Varchar(50)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format		
--Exec Report.UspResults_ReservedLots  @Company	='F',@StockCode ='000000000000005',@Job		='000000000000012'
*/
    Set NoCount On;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ReservedLots' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--Convert Job to varchar for querying DB
    Declare @JobVarchar Varchar(20);

--Cater for number jobs
    Select  @JobVarchar = Case When IsNumeric(@Job) = 1
                               Then Right('000000000000000' + @Job , 15)
                               Else @Job
                          End;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
    Declare @ListOfTables Varchar(Max) = 'WipMasterSub,TblApTerms'; 

--Create table to capture results
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
    Create Table [#InvMaster]
        (
          [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [Description] Varchar(50)
        , [StockCode] Varchar(20) Collate Latin1_General_BIN
        , [PartCategory] Char(1)
        , [IssMultLotsFlag] Char(1)
        , [StockUom] Varchar(10)
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
					, Description 
					)
			SELECT [DatabaseName]=@DBCode
				 , [StockCode]
				 , [PartCategory] 
				 , [IssMultLotsFlag]
				 , [StockUom]
				 , Description 
			FROM [InvMaster] As [im]
			where [StockCode] = ''' + @StockCode + '''
			End
	End';
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
			where Job = ''' + @Job + '''
			and StockCode = ''' + @StockCode + '''
			End
	End';
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
                        From    [dbo].[CusLot+]
						where StockCode=''''' + @StockCode + '''''''
	Exec (@SQLSub)
			End
	End';
	--Print 1 
    Exec [Process].[ExecForEachDB] @cmd = @SQLInvMaster;
	--Print 7
    Exec [Process].[ExecForEachDB] @cmd = @SQLWipAllMatLot;
	--Print 9
    Exec [Process].[ExecForEachDB] @cmd = @SQLCusLot;
    Print @SQLCusLot;

            
    Select  [waml].[Job]
          , [waml].[StockCode]
          , [IM].[Description]
          , [ReservedLot] = [waml].[Lot]
          , [ReservedLotBin] = [waml].[Bin]
          , [ReservedLotWarehouse] = [waml].[Warehouse]
          , [ReservedLotQtyReserved] = [waml].[QtyReserved]
          , [ReservedLotQtyIssued] = [waml].[QtyIssued]
          , [ReservedLotBleedNumber] = [CL].[BleedNumber]
          , [ReservedLotDonorNumber] = [CL].[DonorNumber]
          , [ReservedLotVendorBatchNumber] = [CL].[VendorBatchNumber]
          , [ReservedLotOldLotNumber] = [CL].[OldLotNumber]
          , [ReservedLotBleedDate] = [CL].[BleedDate]
    From    [#WipAllMatLot] As [waml]
            Left Join [#CusLot] As [CL] On [CL].[DatabaseName] = [waml].[DatabaseName]
                                       And [CL].[Lot] = [waml].[Lot]
                                       And [CL].[StockCode] = [waml].[StockCode]
            Left Join [#InvMaster] As [IM] On [IM].[DatabaseName] = [waml].[DatabaseName]
                                          And [IM].[StockCode] = [waml].[StockCode]
    Where   [waml].[Job] = @Job
            And [waml].[StockCode] = @StockCode;


--tidy up

    Drop Table [#WipAllMatLot];
    Drop Table [#InvMaster];
    Drop Table [#CusLot];
 
 



GO
EXEC sp_addextendedproperty N'MS_Description', N'list of reserved lots used (allocated blood)', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ReservedLots', NULL, NULL
GO
