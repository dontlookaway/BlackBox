SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_StockCode]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin
--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    1
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'StockCode' )
           )
            Begin
                Create Table [Lookups].[StockCode]
                    (
                      [Company] Varchar(150)
                    , [StockCode] Varchar(150)
                    , [LastUpdated] DateTime2
                    );
            End;

--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[StockCode];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'InvMovements'; 

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1StockCode]
                    (
                      [Company] Varchar(150)
                    , [StockCode] Varchar(150)
                    );

--create script to pull data from each db into the tables
                Declare @Company Varchar(30) = 'All';
                Declare @SQL Varchar(Max) = 'USE [?];
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
				Insert #Table1StockCode
					( Company, StockCode)
				Select distinct @DBCode
				,StockCode
				From InvMovements
			End
	End';

--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

                Insert  [Lookups].[StockCode]
                        ( [Company]
                        , [StockCode]
                        , [LastUpdated]
                        )
                        Select  [Company]
                              , [StockCode]
                              , @LastUpdated
                        From    [#Table1StockCode];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[StockCode]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[StockCode]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[StockCode]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_StockCode - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[StockCode]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_StockCode - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[StockCode]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_StockCode - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_StockCode - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;


GO
