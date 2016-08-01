SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspPopulate_UnpivotHistory] ( @Tables Varchar(Max) )
As
    Begin
--List of Tables insert into
        Create Table [#TablesToPopulate]
            (
              [TID] Int Identity(1 , 1)
            , [TableName] Varchar(500)
            );

        Insert  [#TablesToPopulate]
                ( [TableName]
                )
                Select Distinct
                        Replace([USS].[Value] , ' ' , '')
                From    [dbo].[udf_SplitString](@Tables , ',') As [USS];


        Create Table [#Transactions]
            (
              [TransactionDescription] Varchar(500)
            , [DatabaseName] Varchar(255)
            , [SignatureDateTime] DateTime
            , [Operator] Varchar(255)
            , [ItemKey] Varchar(500)
            , [ComputerName] Varchar(500)
            , [ProgramName] Varchar(500)
            , [ConditionName] Varchar(500)
            , [VariableDesc] Varchar(500)
            , [VariableRank] Int
            , [TransactionRank] Int
            );


        Declare @MaxTables Int
          , @CurrentTable Int = 1
          , @SQLPivot Varchar(Max)
          , @Columns Varchar(Max)
          , @TableName Varchar(500)
          , @MaxTransactions Int
          , @CurrentTransaction Int = 1
          , @MaxVariables Int
          , @CurrentVariable Int = 1
          , @VarDate Date
          , @VarString Varchar(255)
          , @VarNum Float
          , @VarName Varchar(500)
          , @VarDbName Varchar(500)
          , @VarItemKey Varchar(500)
          , @VarSignatureDateTime DateTime
          , @SQLUpdate Varchar(Max)
          , @SQLInsert Varchar(Max);

        Select  @MaxTables = Max([TTP].[TID])
        From    [#TablesToPopulate] As [TTP];
        Print Cast(@MaxTables As Varchar(50)) + ' tables to unpivot';

        While @CurrentTable <= @MaxTables
            Begin
                Select  @TableName = [TTP].[TableName]
                From    [#TablesToPopulate] As [TTP]
                Where   [TTP].[TID] = @CurrentTable;
				
                Print 'Unpivotting table ' + @TableName + ' '
                    + Cast(@CurrentTable As Varchar(50));
                
                Select  @Columns = Stuff(( Select Distinct
                                                    ', '
                                                    + Cast('['
                                                    + [STL].[VariableDesc]
                                                    + ']' As Varchar(150))
                                           From     [Process].[SysproTransactionsLogged]
                                                    As [STL]
                                           Where    [STL].[TableName] = @TableName
                                           Order By ( ', '
                                                      + Cast('['
                                                      + [STL].[VariableDesc]
                                                      + ']' As Varchar(150)) ) Asc
                                         For
                                           Xml Path('')
                                         ) , 1 , 1 , '');


--Insert All transactions
                Set @SQLInsert = 'Insert [History].' + @TableName
                    + ' ( [TransactionDescription], [DatabaseName], [SignatureDateTime], [Operator], [ItemKey], [ComputerName], [ProgramName], [ConditionName])
SELECT [TransactionDescription], [DatabaseName], [SignatureDateTime], [Operator], [ItemKey], [ComputerName], [ProgramName], [ConditionName] 
From [Process].[SysproTransactionsLogged] As [STL]
Where [STL].[TableName]=''' + @TableName + '''
and [AlreadyEntered]=0';

                Exec ( @SQLInsert );


                Insert  [#Transactions]
                        ( [TransactionDescription]
                        , [DatabaseName]
                        , [SignatureDateTime]
                        , [Operator]
                        , [ItemKey]
                        , [ComputerName]
                        , [ProgramName]
                        , [ConditionName]
                        , [VariableDesc]
                        , [VariableRank]
                        , [TransactionRank]
				        )
                        Select Top 10000 --limit to 10,000 at a time
                                [STL].[TransactionDescription]
                              , [STL].[DatabaseName]
                              , [STL].[SignatureDateTime]
                              , [STL].[Operator]
                              , [STL].[ItemKey]
                              , [STL].[ComputerName]
                              , [STL].[ProgramName]
                              , [STL].[ConditionName]
                              , [STL].[VariableDesc]
                              , [VariableRank] = Dense_Rank() Over ( Partition By [STL].[TransactionDescription] ,
                                                              [STL].[DatabaseName] ,
                                                              [STL].[SignatureDateTime] ,
                                                              [STL].[Operator] ,
                                                              [STL].[ItemKey] ,
                                                              [STL].[ComputerName] ,
                                                              [STL].[ProgramName] ,
                                                              [STL].[ConditionName] Order By [STL].[VariableDesc] )
                              , [TransactionRank] = Dense_Rank() Over ( Order By [STL].[TransactionDescription], [STL].[DatabaseName], [STL].[SignatureDateTime], [STL].[Operator], [STL].[ItemKey], [STL].[ComputerName], [STL].[ProgramName], [STL].[ConditionName] )
                        From    [Process].[SysproTransactionsLogged] As [STL]
                        Where   [STL].[TableName] = @TableName
                                And [STL].[AlreadyEntered] = 0;

                Select  @MaxTransactions = Max([T].[TransactionRank])
                From    [#Transactions] As [T];

                /*Print Cast(@MaxTransactions As Varchar(50))
                    + ' transactions to iterate';*/

                Set @CurrentTransaction = 1;

                While @CurrentTransaction <= @MaxTransactions
                    Begin
                        /*Print Cast(@CurrentTransaction As Varchar(50))
                            + ' out of '
                            + Cast(@MaxTransactions As Varchar(50));*/
                        Select  @MaxVariables = Max([T].[VariableRank])
                        From    [#Transactions] As [T]
                        Where   [T].[TransactionRank] = @CurrentTransaction;
                        Set @CurrentVariable = 1;
                        While @CurrentVariable <= @MaxVariables
                            Begin
                                Set @VarDate = Null;
                                Set @VarNum = Null;
                                Set @VarString = Null;
                                Set @VarName = Null;
								
                                Select  @VarName = [T].[VariableDesc]
                                      , @VarNum = [STL].[VarNumericValue]
                                      , @VarString = Replace([STL].[VarAlphaValue] ,
                                                             '''' , '''''')
                                      , @VarDate = [STL].[VarDateValue]
                                      , @VarDbName = [STL].[DatabaseName]
                                      , @VarItemKey = [STL].[ItemKey]
                                      , @VarSignatureDateTime = [STL].[SignatureDateTime]
                                From    [#Transactions] As [T]
                                        Left Join [Process].[SysproTransactionsLogged]
                                            As [STL]
                                            On [STL].[DatabaseName] = [T].[DatabaseName]
                                               And [STL].[ItemKey] = [T].[ItemKey]
                                               And [STL].[SignatureDateTime] = [T].[SignatureDateTime]
                                               And [STL].[VariableDesc] = [T].[VariableDesc]
                                Where   [T].[TransactionRank] = @CurrentTransaction
                                        And [T].[VariableRank] = @CurrentVariable;	    
                                If Coalesce(@VarString ,
                                            Convert(Varchar(500) , @VarNum) ,
                                            Convert(Varchar(500) , @VarDate)) Is Not Null
                                    Begin
                                        Set @SQLUpdate = 'Begin Try
								Update [History].' + QuoteName(@TableName) + '
		Set ' + QuoteName(@VarName) + ' = '
                                            + Case When @VarNum Is Not Null
                                                   Then 'Cast('''
                                                        + Cast(@VarNum As Varchar(500))
                                                        + '''as float)'
                                                   When @VarString Is Not Null
                                                   Then '''' + @VarString
                                                        + ''''
                                                   When @VarDate Is Not Null
                                                   Then 'Cast('''
                                                        + Cast(@VarDate As Varchar(500))
                                                        + '''as date)
												'
                                              End + 'Where [DatabaseName]='''
                                            + @VarDbName
                                            + ''' And [ItemKey] ='''
                                            + @VarItemKey
                                            + ''' And CONVERT(VARCHAR(23), [SignatureDateTime], 121)='''
                                            + Convert(Varchar(23) , @VarSignatureDateTime , 121)
                                            + '''
								End Try
Begin Catch
    Update  [Process].[SysproTransactionsLogged]
    Set     [IsError] = 1
    Where   [DatabaseName] = ''' + @VarDbName + '''
            And [ItemKey] = ''' + @VarItemKey + '''
            And CONVERT(VARCHAR(23), [SignatureDateTime], 121)='''
                                            + Convert(Varchar(23) , @VarSignatureDateTime , 121)
                                            + '''
			And [VariableDesc] = ''' + @VarName + ''';
End Catch';

                                        Exec ( @SQLUpdate );
                                    End;
                                Update  [Process].[SysproTransactionsLogged]
                                Set     [AlreadyEntered] = 1
                                From    [Process].[SysproTransactionsLogged] [STL]
                                        Inner Join [#Transactions] [T]
                                            On [STL].[DatabaseName] = [T].[DatabaseName]
                                               And [STL].[ItemKey] = [T].[ItemKey]
                                               And [STL].[SignatureDateTime] = [T].[SignatureDateTime]
                                               And [STL].[VariableDesc] = [T].[VariableDesc]
                                Where   [T].[TransactionRank] = @CurrentTransaction
                                        And [T].[VariableRank] = @CurrentVariable;


                                Set @CurrentVariable = @CurrentVariable + 1;
                            End;
                        Set @CurrentTransaction = @CurrentTransaction + 1;
                    End;
				
                Print @TableName + ' unpivotted';
                Truncate Table [#Transactions]; 
                Set @CurrentTable = @CurrentTable + 1;
            End;
    End;
GO
