SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE Proc [Process].[UspAlter_TableName]
    (
      @SchemaName Varchar(500)
    , @TableName Varchar(500)
    , @NewTableName Varchar(500)
    )
As /*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group January 2016															///
///																																	///
///			Stored procedure to rename tables dynamically																			///
///			WARNING - THIS ALSO REMOVES Primary Keys constraints ASSOCIATED WITH TABLES RENAMED										///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			8/1/2016	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Begin
        Set NoCount On
		--before tables are moved, remove the indexes

		--get list of indexes attached to table
        Create Table [#Indexes]
            (
              [IID] Int Identity(1 , 1)
            , [ConstraintName] Varchar(500)
            );

        Insert  [#Indexes]
                ( [ConstraintName]
                )
                Select  [C].[name]
                From    [sys].[key_constraints] As [C]
                        Left Join [sys].[tables] As [T] On [T].[object_id] = [C].[parent_object_id]
                        Left Join [sys].[schemas] As [S] On [S].[schema_id] = [T].[schema_id]
                Where   [S].[name] = @SchemaName
                        And [T].[name] = @TableName
						And [C].[name] Is Not Null;
		

		--get count of all indexes to be dropped, then loop through and remove them
        Declare @CurrentConstraint Int= 1
          , @CurrentConstraintName Varchar(500)
          , @TotalConstraints Int
          , @SQLConstraints Varchar(Max);

        Select  @TotalConstraints = Coalesce(Max([I].[IID]),0)
        From    [#Indexes] As [I];

		--Show how many indexes need to be removed
        Print @SchemaName + '.' + @TableName + ' Total Constraint to remove '
            + Cast(@TotalConstraints As Varchar(50));

        If @TotalConstraints>0 --only iterate if there are indexes to remove
		Begin
		While @CurrentConstraint <= @TotalConstraints
            Begin
                Select  @CurrentConstraintName = [I].[ConstraintName]
                From    [#Indexes] As [I]
                Where   [I].[IID] = @CurrentConstraint;

                Select  @SQLConstraints = 'Alter Table '+@SchemaName+'.'+@TableName+' Drop CONSTRAINT ' + @CurrentConstraintName --+ ' on '
                        --+ @SchemaName + '.' + @TableName;

                --Print @SQLConstraints;
                Exec (@SQLConstraints);
                Print 'Constraint ' + @CurrentConstraintName + ' On table '
                    + @SchemaName + '.' + @TableName + ' dropped.';
                Set  @CurrentConstraint = @CurrentConstraint + 1;
            End
		end;
		If @TotalConstraints = 0
		BEGIN
		    Print 'No Constraints to drop On table '
                    + @SchemaName + '.' + @TableName;
		END


		Declare @ObjectName Varchar(1000)=@SchemaName+'.'+@TableName
		--Once all indexes removed rename table
        Exec [sys].[sp_rename] @objname =  @ObjectName,
            @newname = @NewTableName , @objtype = 'OBJECT';

        Print @SchemaName + '.' + @TableName + ' renamed to ' + @NewTableName;
    End;

	----Banana Test
	/*CREATE TABLE History.Banana
	( Id Int Identity (1,1) 
	,Banana Varchar(6)
	Constraint Banana_Key Primary Key NonClustered
            ( Id, Banana)
            With ( Ignore_Dup_Key = On )
	)

	--Create Index Banana On [dbo].[Banana] ([Banana],[Id])

	Insert [History].[Banana]
	        ( [Banana] )
	Values  (  'Banana'  -- Banana - varchar(6)
	          )

	SELECT * FROM [History].[Banana] As [B]*/

	--Exec [Process].[UspAlter_TableName] @SchemaName = 'History' ,    @TableName = 'Banana' , @NewTableName = 'Apple'
	--select * from History.Apple
	--drop table History.Apple
	--drop table History.Banana
GO
