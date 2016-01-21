SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspCreate_Table]
(@SchemaName Varchar(500)
,@TableName Varchar(500)
,@Columns Varchar(500)
,@Constraints Varchar(500))
As
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group January 2016															///
///																																	///
///			Stored procedure set out to create tables																				///
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
 BEGIN
     Declare @SQLTable Varchar(max)='Create TABLE '+@SchemaName+'.'+@TableName+'('+@Columns+'
	 ,'+@Constraints+')'

	 Exec (@SQLTable)
	 Print 'Table '+@SchemaName+'.'+@TableName+' created'
 End
 
 --Banana Test
/* Exec [Process].[UspCreate_Table] @SchemaName = 'History' , -- varchar(500)
     @TableName = 'Banana' , -- varchar(500)
     @Columns = 'Id Int Identity (1,1) 
	,Banana Varchar(6)' , -- varchar(500)
     @Constraints = 'Constraint Banana_Key Primary Key NonClustered
            ( Id, Banana)
            With ( Ignore_Dup_Key = On )' -- varchar(500)
 


 Drop Table History.Banana*/
GO
