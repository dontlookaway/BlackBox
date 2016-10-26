SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspCreate_Table]
    (
      @SchemaName Varchar(500)
    , @TableName Varchar(500)
    , @Columns Varchar(500)
    , @Constraints Varchar(500)
    )
As /*Template designed by Chris Johnson, Prometic Group January 2016
Stored procedure set out to create tables*/
    Begin
        Declare @SQLTable Varchar(Max)= 'Create TABLE ' + @SchemaName + '.'
            + @TableName + '(' + @Columns + '
	 ,' + @Constraints + ')';

        Exec (@SQLTable);
        Print 'Table ' + @SchemaName + '.' + @TableName + ' created';
    End;
GO
EXEC sp_addextendedproperty N'MS_Description', N'used to create tables and constraints (used for automatic creation of history tables)', 'SCHEMA', N'Process', 'PROCEDURE', N'UspCreate_Table', NULL, NULL
GO
