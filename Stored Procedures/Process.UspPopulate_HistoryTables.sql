
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspPopulate_HistoryTables] ( @RebuildBit Bit )
-- if rebuild=1 then drop and recreate
-- if rebuild=0 then only update
As
    Set NoCount On;
/* 
Template designed by Chris Johnson,Prometic Group September 2015
Stored procedure to unpivot data held in audit tables and move to blackbox history tables
*/

    Declare @SqlExisting Varchar(Max);

    Create Table [#ExistingKeys]
        (
          [DatabaseName] Varchar(150)
        , [ItemKey] Varchar(150)
        , [Operator] Varchar(50)
        , [ProgramName] Varchar(50)
        , [SignatureDatetime] DateTime2
        , [TableName] Varchar(150)
        );


    Select  [TableName] = [t].[name]
          , [SchemaName] = [s].[name]
          , [Script] = 'Select distinct DatabaseName,ItemKey,Operator,ProgramName,SignatureDatetime,TableName='''
            + [t].[name] + '''  from ' + [s].[name] + '.' + [t].[name]
    Into    [#ExistingTables]
    From    [sys].[tables] [t]
            Inner Join [sys].[schemas] [s] On [s].[schema_id] = [t].[schema_id]
    Where   [s].[name] = 'History';

-- Get list of all previously entered signatures
    Select  @SqlExisting = 'Insert #ExistingKeys ( DatabaseName,ItemKey,Operator,ProgramName,SignatureDatetime,TableName)'
            + Stuff(( Select Distinct
                                ' union ' + Cast([Script] As Varchar(Max))
                      From      [#ExistingTables]
                    For
                      Xml Path('')
                    ) , 1 , 6 , '');

    Exec (@SqlExisting);

    Create Table [#TDRaw]
        (
          [TransactionDescription] Varchar(150) Collate Latin1_General_BIN
        , [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [SignatureDateTime] DateTime2
        , [Operator] Varchar(20) Collate Latin1_General_BIN
        , [VariableDesc] Varchar(50) Collate Latin1_General_BIN
        , [ItemKey] Varchar(150) Collate Latin1_General_BIN
        , [VariableType] Char(1)
        , [VarAlphaValue] Varchar(255) Collate Latin1_General_BIN
        , [VarNumericValue] Float
        , [VarDateValue] DateTime2
        , [ComputerName] Varchar(150) Collate Latin1_General_BIN
        , [ProgramName] Varchar(100) Collate Latin1_General_BIN
        , [TableName] Varchar(150) Collate Latin1_General_BIN
        , [ConditionName] Varchar(15) Collate Latin1_General_BIN
        , [AlreadyEntered] Bit
        , Constraint [TDR_AllKeys] Primary Key NonClustered
            ( [DatabaseName] , [SignatureDateTime] , [ItemKey] , [Operator] , [ProgramName] , [VariableDesc] )
            With ( Ignore_Dup_Key = On )
        );


    Create Table [#TransactionDetails]
        (
          [TransactionDescription] Varchar(150) Collate Latin1_General_BIN
        , [DatabaseName] Varchar(150) Collate Latin1_General_BIN
        , [SignatureDateTime] DateTime2
        , [Operator] Varchar(20) Collate Latin1_General_BIN
        , [VariableDesc] Varchar(50) Collate Latin1_General_BIN
        , [ItemKey] Varchar(150) Collate Latin1_General_BIN
        , [VariableType] Char(1)
        , [VarAlphaValue] Varchar(255) Collate Latin1_General_BIN
        , [VarNumericValue] Float
        , [VarDateValue] DateTime2
        , [ComputerName] Varchar(150) Collate Latin1_General_BIN
        , [ProgramName] Varchar(100) Collate Latin1_General_BIN
        , [TableName] Varchar(150) Collate Latin1_General_BIN
        , [ConditionName] Varchar(15) Collate Latin1_General_BIN
        , [AlreadyEntered] Bit
        , Constraint [TD_AllKeys] Primary Key NonClustered
            ( [DatabaseName] , [SignatureDateTime] , [ItemKey] , [Operator] , [ProgramName] , [VariableDesc] )
            With ( Ignore_Dup_Key = On )
        );

    Insert  [#TransactionDetails]
            ( [DatabaseName]
            , [ItemKey]
            , [Operator]
            , [ProgramName]
            , [SignatureDateTime]
            , [AlreadyEntered]
            , [VariableDesc]
            )
            Select  [EK].[DatabaseName]
                  , [EK].[ItemKey]
                  , [EK].[Operator]
                  , [EK].[ProgramName]
                  , [EK].[SignatureDatetime]
                  , [AlreadyEntered] = 1
                  , [VariableDesc] = Upper([c].[name]) --generate for all column names 
            From    [#ExistingKeys] [EK]
                    Left Join [sys].[tables] [t] On [t].[name] = [EK].[TableName] Collate Latin1_General_BIN
                    Left Join [sys].[columns] [c] On [c].[object_id] = [t].[object_id];


--script to return all esignatures from all companies
    Declare @ListOfTables Varchar(Max)= 'AdmSignatureLogDet,AdmSignatureLog'; 

    Declare @SQLtransactions Varchar(Max)= 'USE [?];Declare @DB varchar(150) Select @DB=DB_NAME() IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS'' Declare @Tables VARCHAR(max)='''
        + @ListOfTables
        + ''',@ReqTables INT,@ActTables INT Select @ReqTables=count(1) from BlackBox.dbo.[udf_SplitString](@Tables,'','') Select @ActTables=COUNT(1) FROM sys.tables Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@Tables,'','')) If @ActTables=@ReqTables 
		BEGIN Insert  #TDRaw (TransactionDescription,SignatureDateTime,Operator,VariableDesc,ItemKey,VariableType,VarAlphaValue,VarNumericValue,VarDateValue,ComputerName,ProgramName,TableName,ConditionName,DatabaseName,AlreadyEntered) 
		Select TransactionDescription
		,SignatureDateTime=DATEADD(Millisecond,CAST(SUBSTRING(CAST(ADSL.SignatureTime As CHAR(8)),7,2) As INT),DATEADD(Second,CAST(SUBSTRING(CAST(ADSL.SignatureTime As CHAR(8)),5,2) As INT),DATEADD(Minute,CAST(SUBSTRING(CAST(ADSL.SignatureTime As CHAR(8)),3,2) As INT),DATEADD(Hour,CAST(SUBSTRING(CAST(ADSL.SignatureTime As CHAR(8)),1,2) As INT),ADSL.SignatureDate))))
		,ADSL.Operator,VariableDesc = upper(ADSL.VariableDesc),ASL.ItemKey,ADSL.VariableType,VarAlphaValue=Case When ADSL.VariableType=''A'' Then VarAlphaValue Else CAST(Null As VARCHAR(255)) End,VarNumericValue=Case When ADSL.VariableType=''N'' Then ADSL.VarNumericValue Else CAST(Null As FLOAT) End,VarDateValue=Case When ADSL.VariableType=''D'' Then ADSL.VarDateValue Else CAST(Null As DATETIME) End,ASL.ComputerName,ASL.ProgramName,ASL.TableName,ASL.ConditionName,DB_NAME(),AlreadyEntered=0 
		From AdmSignatureLog ASL Left Join AdmSignatureLogDet ADSL On ADSL.TransactionId=ASL.TransactionId And ADSL.SignatureDate=ASL.SignatureDate And ADSL.SignatureTime=ASL.SignatureTime And ADSL.SignatureLine=ASL.SignatureLine And ADSL.Operator=ASL.Operator Left Join BlackBox.Lookups.AdmTransactionIDs ATI On ATI.TransactionId=ASL.TransactionId 
		Where ASL.TableName<>'''' And ADSL.VariableDesc<>'''' End';


-- exec can only hold 2000 characters,test for this
    If Len(@SQLtransactions) <= 2000
        Begin
            Exec [Process].[ExecForEachDB] @cmd = @SQLtransactions;
        End;
    If Len(@SQLtransactions) > 2000
        Begin
            Print 'Script too long';
            Print Len(@SQLtransactions);
            Print @SQLtransactions;
        End;


--Add index to build up quick
    Create Index [dsfgd] On [#TransactionDetails] ([SignatureDateTime],[VariableType],[Operator],[ItemKey],[DatabaseName]);
    Create Index [dsfgd] On [#TDRaw] ([SignatureDateTime],[VariableType],[Operator],[ItemKey],[DatabaseName]);

    Insert  [#TransactionDetails]
            ( [TransactionDescription]
            , [DatabaseName]
            , [SignatureDateTime]
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
            , [AlreadyEntered]
	        )
            Select  [TDR].[TransactionDescription]
                  , [TDR].[DatabaseName]
                  , [TDR].[SignatureDateTime]
                  , [TDR].[Operator]
                  , [TDR].[VariableDesc]
                  , [TDR].[ItemKey]
                  , [TDR].[VariableType]
                  , [TDR].[VarAlphaValue]
                  , [TDR].[VarNumericValue]
                  , [TDR].[VarDateValue]
                  , [TDR].[ComputerName]
                  , [TDR].[ProgramName]
                  , [TDR].[TableName]
                  , [TDR].[ConditionName]
                  , [TDR].[AlreadyEntered]
            From    [#TDRaw] [TDR]
                    Left Join [#TransactionDetails] [TD] On [TD].[DatabaseName] = [TDR].[DatabaseName] Collate Latin1_General_BIN
                                                        And [TD].[SignatureDateTime] = [TDR].[SignatureDateTime]
                                                        And [TD].[TableName] = [TDR].[TableName] Collate Latin1_General_BIN
                                                        And [TD].[ItemKey] = [TDR].[ItemKey] Collate Latin1_General_BIN
            Where   [TD].[AlreadyEntered] Is Null;


    Create Index [sdfsd] On [#TransactionDetails] ([AlreadyEntered]);


--Get distinct list of all table updates
    Create Table [#tables]
        (
          [tid] Int Identity(1 , 1)
        , [TableName] Varchar(150)
        , [ItemKey] Varchar(150)
        , [SignatureDateTime] DateTime2
        , [DatabaseName] Varchar(150)
        );
    Insert  [#tables]
            ( [TableName]
            , [SignatureDateTime]
            , [ItemKey]
            , [DatabaseName]
            )
            Select Distinct
                    [TableName]
                  , [SignatureDateTime]
                  , [ItemKey]
                  , [DatabaseName]
            From    [#TransactionDetails]
            Where   [AlreadyEntered] = 0
            Order By [TableName]
                  , [ItemKey]
                  , [SignatureDateTime];

--list of all field updates
    Create Table [#Variables]
        (
          [vid] Int Identity(1 , 1)
        , [TableName] Varchar(150)
        , [SignatureDateTime] DateTime2
        , [VariableDesc] Varchar(50)
        , [ItemKey] Varchar(150)
        , [DatabaseName] Varchar(150)
        );
    Insert  [#Variables]
            ( [TableName]
            , [SignatureDateTime]
            , [VariableDesc]
            , [ItemKey]
            , [DatabaseName]
            )
            Select Distinct
                    [TableName]
                  , [SignatureDateTime]
                  , [VariableDesc]
                  , [ItemKey]
                  , [DatabaseName]
            From    [#TransactionDetails]
            Where   [AlreadyEntered] = 0;

    Create Index [Fdgsd] On [#Variables] ([SignatureDateTime],[TableName],[ItemKey],[DatabaseName]);

    Declare @TotalTables Int
      , @CurrentTable Int= 1
      , @SQL Varchar(Max)
      , @TotalVariables Int
      , @CurrentVariable Int= 1;

    Select  @TotalTables = Max([tid])
    From    [#tables];
    Select  @TotalVariables = Max([vid])
    From    [#Variables];


    While @CurrentTable <= @TotalTables
        Begin
            Select  @SQL = 'Insert [History].[' Collate Latin1_General_BIN
                    + [t].[TableName] + ']
				(TransactionDescription
				,SignatureDatetime
				,Operator
				,ProgramName
				,ItemKey
				,DatabaseName)
				select ''' Collate Latin1_General_BIN
                    + [td].[TransactionDescription] + '''
				,''' Collate Latin1_General_BIN
                    + Cast([td].[SignatureDateTime] As Varchar(115)) + '''
				,''' Collate Latin1_General_BIN + [td].[Operator] + '''
				,''' Collate Latin1_General_BIN + [td].[ProgramName] + '''
				,''' + [td].[ItemKey] + '''
				,''' + [t].[DatabaseName] + ''''
            From    [#tables] [t]
                    Left Join [#TransactionDetails] [td] On [td].[TableName] Collate Latin1_General_BIN = [t].[TableName]
                                                        And [td].[DatabaseName] = [t].[DatabaseName] Collate Latin1_General_BIN
                                                        And [td].[SignatureDateTime] = [t].[SignatureDateTime]
            Where   [t].[tid] = @CurrentTable
                    And [td].[AlreadyEntered] = 0;
            Exec (@SQL);
            Set @CurrentTable = @CurrentTable + 1;
        End;

--Print @TotalVariables

    While @CurrentVariable <= @TotalVariables
        Begin
		--Print @CurrentVariable
      
            Select  @SQL = 'Update [History].[' + [td].[TableName] + ']
					set [' + Upper([td].[VariableDesc]) + ']='
                    + Case When [td].[VariableType] = 'A'
                           Then '''' + Replace([td].[VarAlphaValue] , '''' ,
                                               '''''') + ''''
                           When [td].[VariableType] = 'D'
                           Then 'Cast('''
                                + Cast([td].[VarDateValue] As Varchar(255))
                                + ''' as date)'
                           When [td].[VariableType] = 'N'
                           Then 'Cast('
                                + Cast([td].[VarNumericValue] As Varchar(255))
                                + ' As Float)'
                      End + '
					where SignatureDatetime='''
                    + Cast([td].[SignatureDateTime] As Varchar(255))
                    + ''' and Operator=''' + [td].[Operator] + ''' and ItemKey='''
                    + [td].[ItemKey] + ''' and DatabaseName=''' + [td].[DatabaseName]
                    + ''''
            From    [#TransactionDetails] [td]
                    Left Join [#Variables] [v] On [v].[SignatureDateTime] = [td].[SignatureDateTime]
                                              And [v].[TableName] = [td].[TableName]  Collate Latin1_General_BIN
                                              And [v].[VariableDesc] = [td].[VariableDesc] Collate Latin1_General_BIN
                                              And [v].[ItemKey] = [td].[ItemKey] Collate Latin1_General_BIN
                                              And [v].[DatabaseName] = [td].[DatabaseName]
            Where   [v].[vid] = @CurrentVariable;
            Exec (@SQL);
            Set @CurrentVariable = @CurrentVariable + 1;
        End;

--Update Ranking
    Declare @SQLRank Varchar(Max); 
    Set @CurrentTable = 1;
    While @CurrentTable <= @TotalTables
        Begin
            Select  @SQLRank = 'Update
            History.' + [T].[TableName] + '
        Set
            Ranking=b.NewRanking
        From
            History.' + [T].[TableName]
                    + ' a
        Inner Join (
                     Select
                        ItemKey
                     ,SignatureDatetime
                     ,NewRanking=RANK() Over ( Partition By ItemKey Order By SignatureDatetime Desc ) 
                     From
                        History.' + [T].[TableName] + '
                   ) b
            On a.ItemKey=b.ItemKey
			And b.SignatureDatetime=a.SignatureDatetime;'
            From    [#tables] [T]
            Where   [T].[tid] = @CurrentTable;

		--Print (@SQLRank)
            Exec (@SQLRank);
            Set @CurrentTable = @CurrentTable + 1;
        End;



--tidy up
    Drop Table [#ExistingKeys];
    Drop Table [#ExistingTables];    
    Drop Table [#tables];
    Drop Table [#TransactionDetails];
    Drop Table [#Variables];
GO
