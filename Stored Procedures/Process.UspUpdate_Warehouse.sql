SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_Warehouse]
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
                                    And [TABLE_NAME] = 'Warehouse' )
           )
            Begin
                Create Table [Lookups].[Warehouse]
                    (
                      [Company] Varchar(150)				collate Latin1_General_BIN
                    , [Warehouse] Varchar(150)				collate Latin1_General_BIN
                    , [WarehouseDescription] Varchar(200)	collate Latin1_General_BIN
                    , [LastUpdated] DateTime2
                    );
            End;



--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[Warehouse];

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
                Create Table [#Table1Wh]
                    (
                      [Company] Varchar(150)	collate Latin1_General_BIN
                    , [Warehouse] Varchar(150)	collate Latin1_General_BIN
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
				Insert #Table1Wh
					( Company, Warehouse)
				Select distinct @DBCode
				,Warehouse
				From InvMovements
			End
	End';


--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

                Insert  [Lookups].[Warehouse]
                        ( [Company]
                        , [Warehouse]
                        , [LastUpdated]
                        , [WarehouseDescription]
                        )
                        Select  [Company]
                              , [Warehouse]
                              , @LastUpdated
                              , Case When [Warehouse] = 'CE'
                                     Then 'Certified Environment'
                                     When [Warehouse] = 'RL' Then 'Red Label'
                                     When [Warehouse] = 'ZV' Then 'Zero Value'
                                     When [Warehouse] = 'RM'
                                     Then 'Raw Materials'
                                     When [Warehouse] = 'QU' Then 'Quarantine'
                                     When [Warehouse] = 'CB' Then 'Cambridge'
                                     When [Warehouse] = 'FG'
                                     Then 'Finished Goods'
                                End
                        From    [#Table1Wh];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[Warehouse]
                        Where   [LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[Warehouse]
                        Where   [LastUpdated] <> @LastUpdated;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[Warehouse]
                                Where   [LastUpdated] = @LastUpdated;
                                Print 'UspUpdate_Warehouse - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[Warehouse]
                                Where   [LastUpdated] <> @LastUpdated;
                                Print 'UspUpdate_Warehouse - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[Warehouse]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_Warehouse - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates * 60 )
        Begin
            Print 'UspUpdate_Warehouse - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored proc to update specified table', 'SCHEMA', N'Process', 'PROCEDURE', N'UspUpdate_Warehouse', NULL, NULL
GO
