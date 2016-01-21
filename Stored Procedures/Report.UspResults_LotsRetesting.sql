SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_LotsRetesting] ( @Company VARCHAR(Max) )
As --Exec  [Report].[UspResults_LotsRetesting] 10
    Begin
/*
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
///			1/10/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'InvMaster,InvWhControl,LotDetail'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #Lots
            (DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            , [JobPurchOrder] VARCHAR(50) Collate Latin1_General_BIN
            , [Lot] VARCHAR(50) Collate Latin1_General_BIN
            , StockCode VARCHAR(50) Collate Latin1_General_BIN
            );
        Create Table #InvMaster
            ( DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            ,  [StockCode] VARCHAR(35) Collate Latin1_General_BIN
            , [Description] VARCHAR(150) Collate Latin1_General_BIN
            );
        Create Table #InvWhControl
            ( DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            ,  Warehouse VARCHAR(10) Collate Latin1_General_BIN
            , Description VARCHAR(150) Collate Latin1_General_BIN
            );
        Create Table #LotDetail
            ( DatabaseName VARCHAR(150) Collate Latin1_General_BIN
            ,  StockCode VARCHAR(35) Collate Latin1_General_BIN
            , Warehouse VARCHAR(10) Collate Latin1_General_BIN
            , Lot VARCHAR(35) Collate Latin1_General_BIN
            , Bin VARCHAR(10) Collate Latin1_General_BIN
            , QtyOnHand DECIMAL(20, 7)
            , ExpiryDate DATETIME2 
            );

--create script to pull data from each db into the tables
        Declare @SQL1 VARCHAR(Max) = '
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
			 Insert  [#Lots]
                ( [DatabaseName]
                , [JobPurchOrder]
                , [Lot]
                , [StockCode]
                )
              Select Distinct
                    [DatabaseName] = @DBCode
                  , JobPurchOrder
                  , Lot
                  , LT.[StockCode]
                From
                    dbo.LotTransactions LT
                Where
                    TrnType = ''R''
                    And JobPurchOrder <> ''''
					and Warehouse <>''RM''
			End
	End';
        Declare @SQL2 VARCHAR(Max) = '
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
			 Insert  [#InvMaster]
                ( [DatabaseName]
				, [StockCode]
                , [Description]
                )
             Select Distinct [DatabaseName] = @DBCode
                  , [im].[StockCode]
                  , [im].[Description]
              From [InvMaster] As [im]
			End
	End';
        Declare @SQL3 VARCHAR(Max) = '
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
				Insert [#InvWhControl]
					( [DatabaseName]
					, [Warehouse]
					, [Description] )
				SELECT [DatabaseName]=@DBCode
					, [iwc].[Warehouse]
					, [iwc].[Description] 
				FROM [InvWhControl] As [iwc]
			End
	End';
        Declare @SQL4 VARCHAR(Max) = '
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
						, [Warehouse]
						, [Lot]
						, [Bin]
						, [QtyOnHand]
						, [ExpiryDate]
						)
				SELECT [DatabaseName]=@DBCode
					 , [ld].[StockCode]
					 , [ld].[Warehouse]
					 , [ld].[Lot]
					 , [ld].[Bin]
					 , [ld].[QtyOnHand]
					 , [ld].[ExpiryDate] FROM [LotDetail] As [ld]
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec sp_MSforeachdb @SQL1;
		Exec sp_MSforeachdb @SQL2;
		Exec sp_MSforeachdb @SQL3;
		Exec sp_MSforeachdb @SQL4;

--define the results you want to return
        Create Table #Results
            (
              DatabaseName VARCHAR(150) Collate Latin1_General_BIN
          ,  [StockCode] VARCHAR(35) Collate Latin1_General_BIN
          , [Lot] VARCHAR(35) Collate Latin1_General_BIN
          , [Bin] VARCHAR(10) Collate Latin1_General_BIN
          , [QtyOnHand] NUMERIC(20,8)
          , [ExpiryDate] datetime2 
          , [Description] VARCHAR(150) Collate Latin1_General_BIN
          , [LotNumber] VARCHAR(150) Collate Latin1_General_BIN
          , [Warehouse] VARCHAR(150) Collate Latin1_General_BIN
            );

--Placeholder to create indexes as required
	 --Create NonClustered Index dfgd On [#Lots] ([StockCode]);

--script to combine base data and insert into results table
Insert [#Results]
        ( [DatabaseName]
        , [StockCode]
        , [Lot]
        , [Bin]
        , [QtyOnHand]
        , [ExpiryDate]
        , [Description]
        , [LotNumber]
        , [Warehouse]
        )
Select [LD].[DatabaseName]
  ,  LD.StockCode
  , LD.Lot
  , LD.Bin
  , LD.QtyOnHand
  , LD.ExpiryDate
  , [im].[Description]
  , LotNumber = l.[JobPurchOrder]
  , Warehouse = IWC.Description
From
    #LotDetail LD
Inner Join #InvWhControl IWC
    On LD.Warehouse = IWC.Warehouse
	And LD.[DatabaseName]=IWC.[DatabaseName]
Left Join [#InvMaster] As [im]
    On [im].[StockCode] = [LD].[StockCode]
	And [im].[DatabaseName] = [LD].[DatabaseName]
Left Outer Join [#Lots] As [l]
    On [l].[Lot] = [LD].[Lot]
	And [l].[DatabaseName] = [LD].[DatabaseName]
Where
    ( LD.QtyOnHand > 0 )
Order By
    [IWC].[Description]
  , [LD].[StockCode]


--return results
        Select
            Company = cn.[CompanyName]
          , [StockCode]
          , [Lot]
          , [Bin]
          , [QtyOnHand]
          , [ExpiryDate] = cast([ExpiryDate] as date)
          , [Description]
          , [LotNumber]
          , [Warehouse]
        From
            #Results R 
			Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] 
						On [cn].[Company]=[R].[DatabaseName];

			Drop Table [#InvMaster]
			Drop Table [#InvWhControl]
			Drop Table [#LotDetail]
			Drop Table [#Lots]
			Drop Table [#Results]

    End;


GO
