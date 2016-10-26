SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_DbDiffs]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin

        Set NoCount On;
	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_DbDiffs' , @UsedByType = @RedTagType ,
            @UsedByName = @RedTagUse , @UsedByDb = @RedTagDB;


        Create Table [#ObjectsAndColumns]
            (
              [SchemaName] sysname		collate latin1_general_bin 
            , [ObjectName] sysname		collate latin1_general_bin 
            , [ColumnName] sysname		collate latin1_general_bin Null
            , [DatabaseName] sysname	collate latin1_general_bin 
            , [ColumnType] sysname		collate latin1_general_bin Null
            , [max_length] Smallint
            , [precision] TinyInt
            , [ObjectType] Varchar(50)	collate latin1_general_bin
            , [parameters] sysname		collate latin1_general_bin Null
            );

        Declare @DBCount Int;
        Declare @SQLcmd NVarchar(Max) = 'Use [?];
If Lower(Db_Name()) Not Like ''%_srs'' And Lower(Db_Name()) Like ''sysprocompany%''
    Begin
        Insert [#ObjectsAndColumns]
        ( [SchemaName]
        , [ObjectName]
        , [ColumnName]
        , [DatabaseName]
        , [ColumnType]
        , [max_length]
        , [precision]
		, [ObjectType]
        )
	Select  [SchemaName] = [S].[name]
			, [TableName] = [T].[name]
			, [ColumnName] = [C].[name]
			, [DatabaseName] = Db_Name()
			, [ColumnType] = [Typ].[name]
			, [C].[max_length]
			, [C].[precision]
			, [ObjectType] = ''Table''
	From    [sys].[tables] [T]
			left Join [sys].[columns] [C]
				On [C].[object_id] = [T].[object_id]
			Inner Join [sys].[schemas] [S]
				On [S].[schema_id] = [T].[schema_id]
			Left Join [sys].[types] [Typ]
				On [Typ].[system_type_id] = [C].[system_type_id];
    End;';
        Declare @SQLcmdview NVarchar(Max) = 'Use [?];
If Lower(Db_Name()) Not Like ''%_srs'' And Lower(Db_Name()) Like ''sysprocompany%''
    Begin
        Insert [#ObjectsAndColumns]
        ( [SchemaName]
        , [ObjectName]
        , [ColumnName]
        , [DatabaseName]
        , [ColumnType]
        , [max_length]
        , [precision]
		, [ObjectType]
        )
	Select  [SchemaName] = [S].[name]
			, [TableName] = [T].[name]
			, [ColumnName] = [C].[name]
			, [DatabaseName] = Db_Name()
			, [ColumnType] = [Typ].[name]
			, [C].[max_length]
			, [C].[precision]
			, [ObjectType] = ''View''
	From    [sys].[views] [T]
			left Join [sys].[columns] [C]
				On [C].[object_id] = [T].[object_id]
			Inner Join [sys].[schemas] [S]
				On [S].[schema_id] = [T].[schema_id]
			Left Join [sys].[types] [Typ]
				On [Typ].[system_type_id] = [C].[system_type_id];
    End;';
        Declare @SQLcmdProc NVarchar(Max) = 'Use [?];
If Lower(Db_Name()) Not Like ''%_srs'' And Lower(Db_Name()) Like ''sysprocompany%''
    Begin
		Insert  [#ObjectsAndColumns]
        ( [SchemaName]
        , [ObjectName]
        , [DatabaseName]
        , [ObjectType]
		, [parameters]
        )
        Select  [S].[name]
              , [P].[name]
              , Db_Name()
              , ''StoredProc''
			  , PT.name
        From    [sys].[schemas] [S]
                Inner Join [sys].[procedures] [P]
                    On [P].[schema_id] = [S].[schema_id]
				left join sys.parameters [PT]
				on [PT].[object_id] = [P].[object_id]
    End;';




        Exec [Process].[ExecForEachDB] @cmd = @SQLcmd;
        Exec [Process].[ExecForEachDB] @cmd = @SQLcmdview;
        Exec [Process].[ExecForEachDB] @cmd = @SQLcmdProc;

        Select  @DBCount = Count(Distinct [TAC].[DatabaseName])
        From    [#ObjectsAndColumns] [TAC];

        Set NoCount Off;
        Select  [TAC].[SchemaName]
              , [TAC].[ObjectName]
              , [TAC].[ObjectType]
              , [TAC].[ColumnName]
              , [Parameters] = [TAC].[parameters]
              , [TAC].[ColumnType]
              , [Max_Length] = [TAC].[max_length]
              , [Precision] = [TAC].[precision]
              , [DbWhereExists] = Count(Distinct [TAC].[DatabaseName])
              , [TotalDbCount] = @DBCount
              , [MinDatabaseName] = Min([TAC].[DatabaseName])
              , [MaxDatabaseName] = Max([TAC].[DatabaseName])
        From    [#ObjectsAndColumns] [TAC]
        Group By [TAC].[SchemaName]
              , [TAC].[ObjectName]
              , [TAC].[ObjectType]
              , [TAC].[ColumnName]
              , [TAC].[ColumnType]
              , [TAC].[max_length]
              , [TAC].[precision]
              , [TAC].[parameters]
        Having  Count([TAC].[DatabaseName]) <> @DBCount
        Order By [TAC].[ObjectType] Desc;


        Drop Table [#ObjectsAndColumns];
    End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'provide details of differences between databases', 'SCHEMA', N'Review', 'PROCEDURE', N'UspResults_DbDiffs', NULL, NULL
GO
