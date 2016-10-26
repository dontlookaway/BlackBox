SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspCreateAmend_HistoryTables] ( @Rebuild Bit ) 
-- if rebuild = 1 then drop and recreate
-- if rebuild = 0 then 
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure iterates through all electronic signatures and use the variable description to unpivot the data
*/


    Set NoCount On;

--create temporary tables
    Create Table [#TableList]
        (
          [Tid] Int Identity(1 , 1)
        , [TableName] Varchar(150)	collate latin1_general_bin
        , Constraint [tlname] Primary Key NonClustered ( [TableName] )
            With ( Ignore_Dup_Key = On )
        );

    Create Table [#ColumnListTemp]
        (
          [Cid] Int Identity(1 , 1)
        , [ColumnName] Varchar(150)		collate latin1_general_bin
        , [ColumnType] Varchar(100)		collate latin1_general_bin
        , [TableName] Varchar(150)		collate latin1_general_bin
        , Constraint [cltdetailstemp] Primary Key NonClustered
            ( [ColumnName] , [ColumnType] , [TableName] )
            With ( Ignore_Dup_Key = On )
        );

    Create Table [#ColumnList]
        (
          [Cid] Int Identity(1 , 1)
        , [ColumnName] Varchar(150)		collate latin1_general_bin
        , [ColumnType] Varchar(100)		collate latin1_general_bin
        , [TableName] Varchar(150)		collate latin1_general_bin
        , Constraint [cldetails] Primary Key NonClustered
            ( [ColumnName] , [ColumnType] , [TableName] )
            With ( Ignore_Dup_Key = On )
        );

    Create Table [#CurrentColumns]
        (
          [ColumnName] Varchar(150)	collate latin1_general_bin
        , [TableName] Varchar(150)	collate latin1_general_bin
        );

    Insert  [#CurrentColumns]
            ( [ColumnName]
            , [TableName]
            )
            Select  [c].[name]
                  , [t].[name]
            From    [sys].[columns] [c]
                    Inner Join [sys].[tables] [t] On [t].[object_id] = [c].[object_id]
                    Inner Join [sys].[schemas] [s] On [s].[schema_id] = [t].[schema_id]
                                                And [s].[name] = 'History';

    Declare @ListOfTables Varchar(Max) = 'AdmSignatureLogDet,AdmSignatureLog'; 

--Get list of all tables that are monitored in the signature logs
    Declare @SQLTable Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
        + --Only query DBs beginning SysProCompany
        '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
				Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
        + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT

			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')

			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 

			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
						Insert  #TableList (TableName)
						Select Distinct ASL.TableName
						From dbo.AdmSignatureLog ASL
						Left Join dbo.AdmSignatureLogDet ADSL
							On ADSL.TransactionId = ASL.TransactionId
							   And ADSL.SignatureDate = ASL.SignatureDate
							   And ADSL.SignatureTime = ASL.SignatureTime
							   And ADSL.SignatureLine = ASL.SignatureLine
							   And ADSL.Operator = ASL.Operator
						Left Join BlackBox.Lookups.AdmTransactionIDs ATI
							On ATI.TransactionId = ASL.TransactionId
						Where ASL.TableName <> ''''
							And ADSL.VariableDesc <> ''''
							And ( Case When ADSL.VarDateValue Is Null
											And ADSL.VarAlphaValue = '' ''
											And ADSL.VarNumericValue = 0 Then 1
									   Else 0
								  End ) = 0
			END
			';

--Get list of all columns to be generated
    Declare @SQLColumn Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
        + --Only query DBs beginning SysProCompany
        '
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
				Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
        + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT

			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')

			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 

			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
			Insert  #ColumnListTemp
					( ColumnName
					, ColumnType
					, TableName
					)
					Select Distinct
						Upper(ADSL.VariableDesc)
						, MAX(Case When ADSL.VariableType = ''A''
								Then ''Varchar(255)''
								When ADSL.VariableType = ''N''
								Then ''Float''
								When ADSL.VariableType = ''D''
								Then ''Datetime''
								Else ''Varchar(255)''
							End)
						, ASL.TableName
					From
						dbo.AdmSignatureLog ASL
					Left Join dbo.AdmSignatureLogDet ADSL
						On ADSL.TransactionId = ASL.TransactionId
							And ADSL.SignatureDate = ASL.SignatureDate
							And ADSL.SignatureTime = ASL.SignatureTime
							And ADSL.SignatureLine = ASL.SignatureLine
							And ADSL.Operator = ASL.Operator
					Left Join BlackBox.Lookups.AdmTransactionIDs ATI
						On ATI.TransactionId = ASL.TransactionId
					Where
						ADSL.VariableDesc <> ''''
					Group By
						ADSL.VariableDesc
						, ASL.TableName
			END';

    Exec [Process].[ExecForEachDB] @cmd = @SQLTable;
    Exec [Process].[ExecForEachDB] @cmd = @SQLColumn;

    Update  [#ColumnListTemp]
    Set     [ColumnName] = Upper([ColumnName]);

    Declare @Tablecount Int
      , @CurrentTable Int = 1
      , @TableName Varchar(150)
      , @ColumnCount Int
      , @CurrentColumn Int = 1
      , @SQL Varchar(Max)
      , @ColumnName Varchar(150)
      , @ColumnType Varchar(150);

--Number of tables to iterate through
    Select  @Tablecount = Max([Tid])
    From    [#TableList];

--Run through each table
    While @CurrentTable <= @Tablecount
        Begin
            Select  @TableName = [TableName]
            From    [#TableList]
            Where   [Tid] = @CurrentTable;

--drop the existing tables and recreate them
            If @Rebuild = 1
                Begin
                    Select  @SQL = 'If Exists(Select P.name FROM sys.tables P
									Left Join sys.schemas s On s.schema_id = P.schema_id
									Where P.name=''' + @TableName
                            + ''' And s.name=''History'')
						Begin
							Drop table [History].' + @TableName + '
						end

						Create Table [History].[' + @TableName + ']
						(' + Left(@TableName , 1) + 'ID int identity(1,1)
						,TransactionDescription varchar(150)
						,SignatureDatetime datetime2
						,Operator varchar(20)
						,ProgramName varchar(20)
						,Ranking bigint
						,ItemKey varchar(150)
						,DatabaseName varchar(150)
						,CONSTRAINT [' + @TableName
                            + '_ID] PRIMARY KEY (SignatureDatetime,Operator,ProgramName,ItemKey,DatabaseName)
							WITH (IGNORE_DUP_KEY = ON))'; --ignore duplication as multiple rows to a change

                    Exec (@SQL);

					--get 
                    Insert  [#ColumnList]
                            ( [ColumnName]
                            , [ColumnType]
                            , [TableName]
                            )
                            Select Distinct
                                    [CT].[ColumnName]
                                  , [CT].[ColumnType]
                                  , @TableName
                            From    [#ColumnListTemp] [CT]
                            Where   [CT].[TableName] = @TableName;


                    Select  @ColumnCount = Max([Cid])
                    From    [#ColumnList];

                    Set @CurrentColumn = 1;
					--SELECT * FROM #ColumnList

                    While @CurrentColumn <= @ColumnCount
                        Begin
                            Select  @ColumnName = [ColumnName]
                                  , @ColumnType = [ColumnType]
                            From    [#ColumnList]
                            Where   [Cid] = @CurrentColumn;

                            Select  @SQL = 'alter table [History].['
                                    + @TableName + '] add ['
                                    + Upper(@ColumnName) + '] ' + @ColumnType
                                    + ';';
			
                            Exec (@SQL);
                            Set @CurrentColumn = @CurrentColumn + 1;
                            Set @ColumnName = '';
                        End;

                    Set @CurrentTable = @CurrentTable + 1;
                    Truncate Table [#ColumnList];
                    Set @SQL = '';
                End;
            If @Rebuild = 0
                Begin
            --only create tables that have not previously existed
                    Select  @SQL = 'If Not Exists(Select P.name FROM sys.tables P
									Left Join sys.schemas s On s.schema_id = P.schema_id
									Where P.name=''' + @TableName
                            + ''' And s.name=''History'')
					Begin
						Create Table [History].[' + @TableName + ']
						(' + Left(@TableName , 1) + 'ID int identity(1,1)
						,TransactionDescription varchar(150) collate latin1_general_bin
						,SignatureDatetime datetime2 
						,Operator varchar(20) collate latin1_general_bin
						,ProgramName varchar(20) collate latin1_general_bin
						,Ranking bigint 
						,ItemKey varchar(150) collate latin1_general_bin
						,CONSTRAINT [' + @TableName
                            + '_ID] PRIMARY KEY (SignatureDatetime,Operator,ProgramName,ItemKey)
							WITH (IGNORE_DUP_KEY = ON))
						Create NonClustered Index IX_History_' + @TableName
                            + '_1 On [History].[' + @TableName
                            + '] (SignatureDatetime,Operator,ProgramName,ItemKey)
					end'; --ignore duplication as multiple rows to a change

                    Print @SQL;
                    Exec (@SQL);

					--select only columns that do not exist
                    Insert  [#ColumnList]
                            ( [ColumnName]
                            , [ColumnType]
                            , [TableName]
                            )
                            Select Distinct
                                    [CT].[ColumnName]
                                  , [CT].[ColumnType]
                                  , @TableName
                            From    [#ColumnListTemp] [CT]
                                    Left Join [#CurrentColumns] [C] On [C].[ColumnName] = [CT].[ColumnName]
                                                              And [C].[TableName] = [CT].[TableName]
                            Where   [CT].[TableName] = @TableName
                                    And [C].[ColumnName] Is Null;

                    Select  @ColumnCount = Max([Cid])
                    From    [#ColumnList];

                    Set @CurrentColumn = 1;

                    While @CurrentColumn <= @ColumnCount
                        Begin
                            Select  @ColumnName = [ColumnName]
                                  , @ColumnType = [ColumnType]
                            From    [#ColumnList]
                            Where   [Cid] = @CurrentColumn;

                            Select  @SQL = 'alter table [History].['
                                    + @TableName + '] add [' + @ColumnName
                                    + '] ' + @ColumnType + ';';
			
                            Exec (@SQL);
                            Set @CurrentColumn = @CurrentColumn + 1;
                            Set @ColumnName = '';
                        End;

                    Set @CurrentTable = @CurrentTable + 1;

					--remove values from #ColumnList for next table
                    Truncate Table [#ColumnList];
                    Set @SQL = '';
                End;
        End;
GO
