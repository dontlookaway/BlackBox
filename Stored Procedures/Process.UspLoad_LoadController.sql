SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspLoad_LoadController]
    (
      @HoursBetweenEachRun Numeric(5,2)
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to execute all update stored procs
*/
        Set NoCount On; 
--find all procedures that need to be updated
        Create --drop --alter 
	Table [#ProcsToRun]
            (
              [PID] Int Identity(1 , 1)
            , [SchemaName] Varchar(150)
            , [ProcName] Varchar(150)
            );

        Insert  [#ProcsToRun]
                ( [SchemaName]
                , [ProcName]
                )
                Select  [s].[name]
                      , [p].[name]
                From    [sys].[procedures] [p]
                        Left Join [sys].[schemas] [s]
                            On [s].[schema_id] = [p].[schema_id]
                Where   [s].[name] = 'Process'
                        And [p].[name] Like 'UspUpdate%';

        Declare @MaxProcs Int
          , @CurrentProc Int = 1;

        Select  @MaxProcs = Max([PID])
        From    [#ProcsToRun];

        Declare @SQL Varchar(Max)
          , @SchemaName Varchar(150)
          , @ProcName Varchar(150);

	--run through each procedure, not caring if the count changes and only updating if there have been more than # hours since the last run
        While @CurrentProc <= @MaxProcs
            Begin
                Select  @SchemaName = [SchemaName]
                      , @ProcName = [ProcName]
                From    [#ProcsToRun]
                Where   [PID] = @CurrentProc;

                Select  @SQL = 'begin try
begin tran
exec ' + @SchemaName + '.' + @ProcName
                        + ' @PrevCheck = 0,@HoursBetweenUpdates = '
                        + Cast(@HoursBetweenEachRun As Varchar(5)) + '
commit
end try
begin catch
rollback
end catch';
			--Print @SQL
                Exec (@SQL);
                Set @CurrentProc = @CurrentProc + 1;
            End;
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'Stored procedure to execute all stored procs marked as update ', 'SCHEMA', N'Process', 'PROCEDURE', N'UspLoad_LoadController', NULL, NULL
GO
