SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspPopulate_HistoryTables1] ( @RebuildBit Bit )
As /*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
--exec [Process].[UspPopulate_HistoryTables1] @RebuildBit =0
--exec [Process].[UspPopulate_HistoryTables1] @RebuildBit =1
*/
    Begin
--remove nocount on to speed up query
        Set NoCount On;

        Declare @ErrorMessage Varchar(50)= 'SQL transaction script is too long';
        Declare @CurrentTable Int= 1
          , @TotalTables Int
          , @SchemaName Varchar(500)
          , @TableName Varchar(500)
          , @NewTableName Varchar(500);
        Declare @Columns Varchar(500)
          , @Constraints Varchar(500);
        Declare @CurrentColumn Int = 1
          , @TotalColumns Int
          , @ColumnName Varchar(500)
          , @ColumnType Varchar(500);
        Declare @TablesToUpdate Varchar(Max);

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db

--create temporary tables to be pulled from different databases, including a column to id

--Table to capture all Transactions captured

        If Not Exists ( Select  [t].[name]
                        From    [sys].[tables] [t]
                                Left Join [sys].[schemas] [s]
                                    On [s].[schema_id] = [t].[schema_id]
                        Where   [s].[name] = 'Process'
                                And [t].[name] = 'SysproTransactionsLogged' )
            Begin
                Create Table [Process].[SysproTransactionsLogged]
                    (
                      [TransactionDescription] Varchar(150)		Collate Latin1_General_BIN
                    , [DatabaseName] Varchar(150)				Collate Latin1_General_BIN
                    , [SignatureDateTime] As DateAdd(Millisecond ,
                                                     Cast(Substring(Cast([SignatureTime] As Char(8)) ,
                                                              7 , 2) As Int) ,
                                                     DateAdd(Second ,
                                                             Cast(Substring(Cast([SignatureTime] As Char(8)) ,
                                                              5 , 2) As Int) ,
                                                             DateAdd(Minute ,
                                                              Cast(Substring(Cast([SignatureTime] As Char(8)) ,
                                                              3 , 2) As Int) ,
                                                              DateAdd(Hour ,
                                                              Cast(Substring(Cast([SignatureTime] As Char(8)) ,
                                                              1 , 2) As Int) ,
                                                              Cast([SignatureDate] As DateTime)))))
                    , [SignatureDate] Date
                    , [SignatureTime] Int
                    , [Operator] Varchar(20)					Collate Latin1_General_BIN
                    , [VariableDesc] Varchar(100)				Collate Latin1_General_BIN
                    , [ItemKey] Varchar(150)					Collate Latin1_General_BIN
                    , [VariableType] Char(1)
                    , [VarAlphaValue] Varchar(255)				Collate Latin1_General_BIN
                    , [VarNumericValue] Float
                    , [VarDateValue] DateTime2
                    , [ComputerName] Varchar(150)				Collate Latin1_General_BIN
                    , [ProgramName] Varchar(100)				Collate Latin1_General_BIN
                    , [TableName] Varchar(150)					Collate Latin1_General_BIN
                    , [ConditionName] Varchar(15)				Collate Latin1_General_BIN
                    , [AlreadyEntered] Bit Default 0
                    , Constraint [TDR_AllKeys] Primary Key NonClustered
                        ( [DatabaseName] , [SignatureDate] , [SignatureTime] , [ItemKey] , [Operator] , [ProgramName] , [VariableDesc] , [TableName] )
                        With ( Ignore_Dup_Key = On )
                    );
            End;





--create script to pull data from each db into the tables
        Declare @SQLTransactions Varchar(Max) = 'USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN
BEGIN
Insert [BlackBox].[Process].[SysproTransactionsLogged] ([TransactionDescription], [DatabaseName], [SignatureDate], [SignatureTime], [Operator], [VariableDesc], [ItemKey], [VariableType], [VarAlphaValue], [VarNumericValue], [VarDateValue], [ComputerName], [ProgramName], [TableName], [ConditionName])
Select  [ATI].[TransactionDescription]
, Db_Name()
, [AD].[SignatureDate]
, [AD].[SignatureTime]
, [AD].[Operator]
, [VariableDesc] = Replace(Upper([AD].[VariableDesc]),'' '','''')
, [AL].[ItemKey]
, [AD].[VariableType]
, [VarAlphaValue] = Case When [AD].[VariableType] = ''A''
Then [AD].[VarAlphaValue]
Else Cast(Null As Varchar(255))
End
, [VarNumericValue] = Case When [AD].[VariableType] = ''N''
Then [AD].[VarNumericValue]
Else Cast(Null As Float)
End
, [VarDateValue] = Case When [AD].[VariableType] = ''D''
Then [AD].[VarDateValue]
Else Cast(Null As DateTime)
End
, [AL].[ComputerName]
, [AL].[ProgramName]
, [AL].[TableName]
, [AL].[ConditionName]
From    [dbo].[AdmSignatureLog] [AL]
Left Join [dbo].[AdmSignatureLogDet] [AD] On [AD].[TransactionId] = [AL].[TransactionId]
And [AD].[SignatureDate] = [AL].[SignatureDate]
And [AD].[SignatureTime] = [AL].[SignatureTime]
And [AD].[SignatureLine] = [AL].[SignatureLine]
And [AD].[Operator] = [AL].[Operator]
Left Join [BlackBox].[Lookups].[AdmTransactionIDs] [ATI] On [ATI].[TransactionId] = [AL].[TransactionId]
Where   [AL].[TableName] <> ''''
And [AD].[VariableDesc] <> ''''

Insert  [BlackBox].[Process].[SysproTransactionsLogged]
        ( [TransactionDescription]
        , [DatabaseName]
        , [SignatureDate]
        , [SignatureTime]
        , [Operator]
        , [VariableDesc]
        , [ItemKey]
        , [VariableType]
        , [VarAlphaValue]
        , [VarNumericValue]
        , [VarDateValue]
        , [ComputerName]
        , [ProgramName]
        , [TableName]
        , [ConditionName]
        )
        Select  [t].[TransactionDescription]
              , [t].[DatabaseName]
              , [t].[SignatureDate]
              , [t].[SignatureTime]
              , [t].[Operator]
              , [VariableDesc] = Replace(Upper([VariableDesc]),'' '','''')
              , [t].[ItemKey]
              , [t].[VariableType]
              , [t].[VarAlphaValue]
              , [t].[VarNumericValue]
              , [t].[VarDateValue]
              , [t].[ComputerName]
              , [t].[ProgramName]
              , [t].[TableName]
              , [t].[ConditionName]
        From    ( Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , [DatabaseName] = Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Supplier]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''ApSupplier''
                          , [ConditionName] = ''''
                  From      [dbo].[ApAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Currency]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''TblCurrency''
                          , [ConditionName] = ''''
                  From      [dbo].[TblCurAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Asset]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''AssetMaster''
                          , [ConditionName] = ''''
                  From      [dbo].[AssetAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [Operator]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Supplier]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''EftApSupplier''
                          , [ConditionName] = ''''
                  From      [dbo].[EftCbAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorName]
                          , [VariableDesc] = ''OldComVersion''
                          , [ItemKey] = [ParentPart] + ''_''
                            + Coalesce([Version] , '''') + ''_''
                            + Coalesce([SequenceNum] , '''') + ''_''
                            + Coalesce([Component] , '''')
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [OldComVersion]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''BomStructure''
                          , [ConditionName] = ''''
                  From      [dbo].[BomAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorName]
                          , [VariableDesc] = ''OldComRelease''
                          , [ItemKey] = [ParentPart] + ''_''
                            + Coalesce([Version] , '''') + ''_''
                            + Coalesce([SequenceNum] , '''') + ''_''
                            + Coalesce([Component] , '''')
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [OldComRelease]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''BomStructure''
                          , [ConditionName] = ''''
                  From      [dbo].[BomAmendmentJnl]
                  Union All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , [DatabaseName] = Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [StockCode]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''InvMaster''
                          , [ConditionName] = ''''
                  From      [dbo].[InvMastAmendJnl]
                  Union	 All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , [DatabaseName] = Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Customer]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''ArCustomer''
                          , [ConditionName] = ''''
                  From      [dbo].[ArAmendmentJnl]
                  Union	 All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , [DatabaseName] = Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Job]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''WipMaster''
                          , [ConditionName] = ''''
                  From      [dbo].[WipJobAmendJnl]
                  Union	 All
                  Select    [TransactionDescription] = Case When [ChangeFlag] = ''A''
                                                            Then ''Addition''
                                                            When [ChangeFlag] = ''U''
                                                            Then ''Update''
                                                            When [ChangeFlag] = ''X''
                                                            Then ''Deletion''
                                                            When [ChangeFlag] = ''C''
                                                            Then ''Change''
                                                            Else ''Unknown''
                                                       End
                          , [DatabaseName] = Db_Name()
                          , [SignatureDate] = [JnlDate]
                          , [SignatureTime] = [JnlTime]
                          , [Operator] = [OperatorCode]
                          , [VariableDesc] = [ColumnName] + ''Before''
                          , [ItemKey] = [Warehouse]
                          , [VariableType] = ''A''
                          , [VarAlphaValue] = [Before]
                          , [VarNumericValue] = Null
                          , [VarDateValue] = Null
                          , [ComputerName] = ''''
                          , [ProgramName] = ''''
                          , [TableName] = ''WipMaster''
                          , [ConditionName] = ''''
                  From      [dbo].[InvWhAmendJnl]
                ) [t];
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
        Print 'Length of Transaction script:'
            + Cast(Len(@SQLTransactions) As Varchar(50));
--Print @SQLTransactions

	--Remove previous transactions if being rebuilt, but only if table 
        If @RebuildBit = 1
            Begin
                Print 'Rebuilt Option Selected - previous transactions removed';
                If Exists ( Select  [t].[name]
                            From    [sys].[tables] [t]
                                    Left Join [sys].[schemas] [s]
                                        On [s].[schema_id] = [t].[schema_id]
                            Where   [s].[name] = 'Process'
                                    And [t].[name] = 'SysproTransactionsLogged' )
                    Begin
                        Truncate Table [Process].[SysproTransactionsLogged];
                    End;
            End;

        --If Len(@SQLTransactions) <= 2000 --only run script if less than 2000
            --Begin
        Print 'Capturing Transactions';
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQLTransactions ,
            @SchemaTablesToCheck = N'AdmSignatureLog,AdmSignatureLogDet,ApAmendmentJnl,TblCurAmendmentJnl,AssetAmendmentJnl,EftCbAmendmentJnl,BomAmendmentJnl,InvMastAmendJnl,ArAmendmentJnl,WipJobAmendJnl,InvWhAmendJnl'; -- nvarchar(max)
                 
            --End;
        --If Len(@SQLTransactions) > 2000 --if the script is greater than 2000 then the script will probably fail - raise an error
            --Begin
                --Raiserror (@ErrorMessage,16,1); -- With Log;
            --End;

        If @RebuildBit = 1
            Begin

	--Get list of existing tables that use the History schema
                Create Table [#TablesToRename]
                    (
                      [TID] Int Identity(1 , 1)
                    , [SchemaName] Varchar(500) Collate Latin1_General_BIN
                    , [TableName] Varchar(500) Collate Latin1_General_BIN
                    , [NewTableName] As 'Archive' + [TableName]
                        + Upper(Replace(Replace(Convert(Varchar(24) , GetDate() , 113) ,
                                                ' ' , '') , ':' , '')) --new table name is old name plus the current timestamp
	                );

                Insert  [#TablesToRename]
                        ( [SchemaName]
                        , [TableName]
                        )
                        Select  [SchemaName] = [S].[name]
                              , [TableName] = [T].[name]
                        From    [sys].[schemas] As [S]
                                Left Join [sys].[tables] As [T]
                                    On [T].[schema_id] = [S].[schema_id]
                        Where   [S].[name] = 'History'
                                And [T].[name] Not Like 'Archive%'; --do not archive tables that have already been archived;


	--Rename all existing tables

				--Find out how many tables need to be removed
                Select  @TotalTables = Max([TTR].[TID])
                From    [#TablesToRename] As [TTR];


				--advise user
                Print 'ExistingTables to Remove '
                    + Cast(@TotalTables As Varchar(50));

		--iterate through all tables and rename them

                If @TotalTables > 0
                    Begin
                        While @CurrentTable <= @TotalTables
                            Begin
                                Select  @TableName = [TTR].[TableName]
                                      , @SchemaName = [TTR].[SchemaName]
                                      , @NewTableName = [TTR].[NewTableName]
                                From    [#TablesToRename] As [TTR]
                                Where   [TTR].[TID] = @CurrentTable;

                                Exec [Process].[UspAlter_TableName] @SchemaName , -- varchar(500)
                                    @TableName , -- varchar(500)
                                    @NewTableName; -- varchar(500)
                                Set @CurrentTable = @CurrentTable + 1;
                            End;
                    End;

                Drop Table [#TablesToRename];

	--list of all tables to be created
                Create Table [#TablesToBeCreated]
                    (
                      [TID] Int Identity(1 , 1)
                    , [TableName] Varchar(500) Collate Latin1_General_BIN
                    );

                Insert  [#TablesToBeCreated]
                        ( [TableName]
                        )
                        Select Distinct
                                [TL].[TableName]
                        From    [BlackBox].[Process].[SysproTransactionsLogged]
                                As [TL];

	--Create all required tables with keys
                Set @CurrentTable = 1;
                Set @TotalTables = 0;

	--Get number of tables to create
                Select  @TotalTables = Max([TTBC].[TID])
                From    [#TablesToBeCreated] As [TTBC];

                Print 'Number of Tables to be created: '
                    + Cast(@TotalTables As Varchar(50));



                While @CurrentTable <= @TotalTables
                    Begin
                        Select  @SchemaName = 'History'
                              , @TableName = [TTBC].[TableName]
                        From    [#TablesToBeCreated] As [TTBC]
                        Where   [TTBC].[TID] = @CurrentTable;

                        Set @Columns = 'TransactionDescription VARCHAR(150)  Collate Latin1_General_BIN, DatabaseName VARCHAR(150)  Collate Latin1_General_BIN, SignatureDateTime DATETIME2, Operator VARCHAR(20)  Collate Latin1_General_BIN, ItemKey VARCHAR(150)  Collate Latin1_General_BIN, ComputerName VARCHAR(150) Collate Latin1_General_BIN, ProgramName VARCHAR(100) Collate Latin1_General_BIN, ConditionName VARCHAR(15)  Collate Latin1_General_BIN, AlreadyEntered BIT';
                        Set @Constraints = ' Constraint ' + @TableName
                            + '_AllKeys Primary Key NonClustered ( DatabaseName, SignatureDateTime, ItemKey, Operator, ProgramName ) With ( Ignore_Dup_Key = On )';

                        Exec [Process].[UspCreate_Table] @SchemaName , -- varchar(500)
                            @TableName , -- varchar(500)
                            @Columns , -- varchar(500)
                            @Constraints;-- varchar(500)

                        Print 'Table ' + @TableName + ' '
                            + Cast(@CurrentTable As Varchar(50)) + ' created';


                        Set @CurrentTable = @CurrentTable + 1;
                    End;

                Drop Table [#TablesToBeCreated];

                Exec [Process].[UspAlter_CheckAndAddColumns];


            End;
        If @RebuildBit = 0
            Begin

                Print 'Rebuild option not selected';
            --Get list of tables that don't exist
                Create Table [#MissingTables]
                    (
                      [TID] Int Identity(1 , 1)
                    , [TableName] Varchar(500) Collate Latin1_General_BIN
                    );

                Insert  [#MissingTables]
                        ( [TableName]
                        )
                        Select Distinct
                                [TL].[TableName]
                        From    [BlackBox].[Process].[SysproTransactionsLogged]
                                As [TL]
                        Where   [TL].[TableName] Not In (
                                Select  [T].[name]
                                From    [sys].[schemas] As [S]
                                        Left Join [sys].[tables] [T]
                                            On [T].[schema_id] = [S].[schema_id]
                                Where   [S].[name] = 'History' );

	--Create all required tables with keys
                Set @CurrentTable = 1;
                Set @TotalTables = 0;

	--Get number of tables to create
                Select  @TotalTables = Max([TTBC].[TID])
                From    [#MissingTables] As [TTBC];

                Print 'Number of Tables to be created: '
                    + Cast(@TotalTables As Varchar(50));



                While @CurrentTable <= @TotalTables
                    Begin
                        Select  @SchemaName = 'History'
                              , @TableName = [TTBC].[TableName]
                        From    [#MissingTables] As [TTBC]
                        Where   [TTBC].[TID] = @CurrentTable;

                        Set @Columns = 'TransactionDescription VARCHAR(150), DatabaseName VARCHAR(150), SignatureDateTime DATETIME2, Operator VARCHAR(20), ItemKey VARCHAR(150), ComputerName VARCHAR(150), ProgramName VARCHAR(100), ConditionName VARCHAR(15), AlreadyEntered BIT';
                        Set @Constraints = ' Constraint ' + @TableName
                            + '_AllKeys Primary Key NonClustered ( DatabaseName, SignatureDateTime, ItemKey, Operator, ProgramName ) With ( Ignore_Dup_Key = On )';

                        Exec [Process].[UspCreate_Table] @SchemaName , -- varchar(500)
                            @TableName , -- varchar(500)
                            @Columns , -- varchar(500)
                            @Constraints;-- varchar(500)

                        Print 'Table ' + @TableName + ' '
                            + Cast(@CurrentTable As Varchar(50)) + ' created';


                        Set @CurrentTable = @CurrentTable + 1;
                    End;

                Drop Table [#MissingTables];
			
                Exec [Process].[UspAlter_CheckAndAddColumns];
            End;

		--run insert
        Select  @TablesToUpdate = Stuff(( Select Distinct
                                                    ', '
                                                    + Cast(''
                                                    + [STL].[TableName] + '' As Varchar(150))
                                          From      [Process].[SysproTransactionsLogged]
                                                    As [STL]
                                          Where     [STL].[AlreadyEntered] = 0
                                        For
                                          Xml Path('')
                                        ) , 1 , 1 , '');

        Print 'Tables to update ' + @TablesToUpdate;

        Exec [Process].[UspPopulate_UnpivotHistory] @Tables = @TablesToUpdate;
    End;


GO
