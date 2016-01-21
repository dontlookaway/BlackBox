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
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group January 2016															///
///																																	///
///			Stored procedure set out to create a column on a table																	///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			8/1/2016	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
 Begin
	Declare @SQLColumn Varchar(max) = 'Alter Table '+@Schema+'.'+@Table+' Add ['+@Column+'] '+@Type

	Exec (@SQLColumn)
	Print 'Column '+@Column+' added to table '+@Schema+'.'+@Table
 End
 
 
 --Banana Test
/*CREATE TABLE [History].Banana
(BID Int Identity (1,1),Banana varchar(6)
)

Insert [History].[Banana]( [Banana] )
Values  ( 'Banana')

SELECT * FROM [History].[Banana] As [B]

Exec [Process].[UspAlter_AddColumn] @SchemaName = '[History]' , -- varchar(500)
     @TableName = [Banana] , -- varchar(500)
     @Column = 'Banana2' , -- varchar(500)
     @ColumnType = 'varchar(500)'


SELECT * FROM [History].[Banana] As [B]

Drop Table [History].[Banana]*/
GO
