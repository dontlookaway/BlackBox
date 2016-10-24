
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspAlter_AddColumn]
(@Schema Varchar(500)
,@Table Varchar(500)
,@Column Varchar(500)
,@Type Varchar(500))
As
/*
Template designed by Chris Johnson, Prometic Group January 2016
Stored procedure set out to create a column on a table
*/
 Begin
	Declare @SQLColumn Varchar(max) = 'Alter Table '+@Schema+'.'+@Table+' Add '+QuoteName(@Column)+' '+@Type

	Exec (@SQLColumn)
	Print 'Column '+@Column+' added to table '+@Schema+'.'+@Table
 End



GO
EXEC sp_addextendedproperty N'MS_Description', N'procedure to alter tables by adding columns, used in history table generation', 'SCHEMA', N'Process', 'PROCEDURE', N'UspAlter_AddColumn', NULL, NULL
GO
