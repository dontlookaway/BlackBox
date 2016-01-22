
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_Warehouse]
    (
      @PrevCheck Int
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with warehouse details transaction types when relating to inventory changes																	///
*/

--remove nocount on to speed up query
        Set NoCount On;

--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'Warehouse' )
           )
            Begin
                Create Table [Lookups].[Warehouse]
                    (
                      [Company] Varchar(150)
                    , [Warehouse] Varchar(150)
                    , [WarehouseDescription] Varchar(200)
                    , [LastUpdated] DateTime2
                    );
            End;



--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[Warehouse];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                    Select  @LastUpdated = GetDate();

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
                Declare @ListOfTables Varchar(Max) = 'InvMovements'; 

--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#Table1Wh]
                    (
                      [Company] Varchar(150)
                    , [Warehouse] Varchar(150)
                    );

--create script to pull data from each db into the tables
                Declare @Company Varchar(30) = 'All';
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
				Insert #Table1Wh
					( Company, Warehouse)
				Select distinct @DBCode
				,Warehouse
				From InvMovements
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

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
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_Warehouse - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;


GO
