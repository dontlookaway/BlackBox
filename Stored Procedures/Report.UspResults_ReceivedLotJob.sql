SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ReceivedLotJob]
    (
      @Company Varchar(Max)
    , @Lot Varchar(50)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

		Set @Lot = Case When IsNumeric(@Lot)=1 Then Convert(Varchar(50),Convert(Int,@Lot)) Else Upper(@Lot) End
--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ReceivedLotJob' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'LotTransactions'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#LotTransactions]
            (
              [DatabaseName] Varchar(150)
            , [Lot] Varchar(50)
            , [JobPurchOrder] Varchar(20)
            );

--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
				Insert [#LotTransactions]
		        ( [DatabaseName]
		        , [Lot]
		        , [JobPurchOrder]
		        )
		SELECT [DatabaseName]=@DBCode
             , [LT].[Lot]
             , [LT].[JobPurchOrder] 
		From [LotTransactions] [LT]
		where Case When IsNumeric(LT.Lot)=1 Then Convert(Varchar(50),Convert(Int,LT.Lot)) Else Upper(LT.Lot) End = ''' + @Lot + ''' 
		and [LT].[TrnType]=''R''
	And [LT].[JobPurchOrder]<>''''
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL , -- nvarchar(max)
            @SchemaTablesToCheck = @ListOfTables; -- nvarchar(max)
        

--define the results you want to return

--Placeholder to create indexes as required

--script to combine base data and insert into results table

        Set NoCount Off;
--return results
        Select  [LT].[DatabaseName]
              , [LT].[Lot]
              , [LT].[JobPurchOrder]
        From    [#LotTransactions] [LT];

    End;

GO
