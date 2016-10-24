SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspAlter_CheckAndAddColumns]
--exec [Process].[UspAlter_CheckAndAddColumns]
As /*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to check how many columns are missings 
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			7/9/2015	Chris Johnson			Initial version created																///
///			7/9/2015	Chris Johnson			Changed to use of udf_SplitString to define tables to return						///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			11/1/2015	Chris Johnson			Removed company & tables from script												///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Begin
--remove nocount on to speed up query
        Set NoCount On;

        Declare @TotalColumns Int
          , @CurrentColumn Int
          , @ColumnName Varchar(500)
          , @TableName Varchar(500)
          , @ColumnType Varchar(500);

        Create Table [#ColumnsToCreate]
            (
              [CID] Int Identity(1 , 1)
            , [TableName] Varchar(500)
            , [ColumnName] Varchar(500)
            , [VariableType] Char(1)
            );

			--Get list of columns that don't exist
        Insert  [#ColumnsToCreate]
                ( [TableName]
                , [ColumnName]
                , [VariableType]
                )
                Select  [TableName] = [tl].[TableName]
                      , [ColumnName] = Replace(Upper([tl].[VariableDesc]) ,
                                               ' ' , '')
                      , [tl].[VariableType]
                From    ( Select Distinct
                                    [STL].[TableName]
                                  , [STL].[VariableDesc]
                                  , [STL].[VariableType]
                          From      [Process].[SysproTransactionsLogged] As [STL]
                          Where     [STL].[AlreadyEntered] = 0
                        ) [tl]
                        Left Join [sys].[tables] As [T] On [T].[name] = [tl].[TableName]
                        Left Join [sys].[schemas] As [S] On [S].[schema_id] = [T].[schema_id]
                        Left Join [sys].[columns] As [C] On [C].[object_id] = [T].[object_id]
                                                            And [C].[name] = [tl].[VariableDesc]
                Where   [S].[name] = 'History'
                        And [T].[name] Not Like 'Archive%'
                        And [C].[name] Is Null;

				--Add new fields
        Select  @TotalColumns = Coalesce(Max([CTC].[CID]),0)
        From    [#ColumnsToCreate] As [CTC];

		If @TotalColumns>0
		Begin
        Print 'Columns to be added ' + Cast(@TotalColumns As Varchar(50));
		End
		If @TotalColumns=0
		Begin
        Print 'No columns to be added'
		End

        Set @CurrentColumn = 1;

		--iterate through each column that is required
        While @CurrentColumn <= @TotalColumns
            Begin
                Select  @ColumnName = [CTC].[ColumnName]
                      , @TableName = [CTC].[TableName]
                      , @ColumnType = Case When [CTC].[VariableType] = 'A'
                                           Then 'Varchar(255)'
                                           When [CTC].[VariableType] = 'N'
                                           Then 'Float'
                                           When [CTC].[VariableType] = 'D'
                                           Then 'Date'
                                      End
                From    [#ColumnsToCreate] As [CTC]
                Where   [CTC].[CID] = @CurrentColumn;

                Exec [Process].[UspAlter_AddColumn] @Schema = 'History' , -- varchar(500)
                    @Table = @TableName , @Column = @ColumnName , -- varchar(500)
                    @Type = @ColumnType;

                Print 'History.' + @TableName + ' added column ' + @ColumnName
                    + ' ' + @ColumnType;
                Set @CurrentColumn = @CurrentColumn + 1;
            End;

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'works out which columns need to be added to tables for history generation', 'SCHEMA', N'Process', 'PROCEDURE', N'UspAlter_CheckAndAddColumns', NULL, NULL
GO
