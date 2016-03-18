SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_MissingRI2Groups]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_MissingRI2Groups' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--return results
        Select  [GM].[Company]
              , [GM].[GlCode]
              , [GM].[Description]
              , [GM].[ReportIndex2]
              , [GM].[GlGroup]
        From    [SysproCompany40].[dbo].[GenMaster] As [GM]
        Where   [GM].[GlCode] Not In ( 'FORCED' , 'RETAINED' )
                And ( [GM].[ReportIndex2] = ''
                      Or [GM].[GlGroup] = ''
                    );

    End;

GO
