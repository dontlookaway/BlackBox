SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_MissingRI2Maps]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016
*/

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_MissingRI2Maps' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


        Select  Distinct
                [GM].[Company]
              , [CN].[CompanyName]
              , [ReportIndex2] = Case When [GM].[ReportIndex2] = '' Then Null
                                      When [GM].[Company] = '10'
                                      Then 'Co. 10 ' + [GM].[ReportIndex2]
                                      Else [GM].[ReportIndex2]
                                 End
              , [RIUM].[Map]
              , [RIUM].[IsSummary]
              , [ReportStatus] = Case When [RIUM].[Map] Is Null Then 'Missing'
                                      When [RIUM].[Map] = '' Then 'Blank'
                                      Else 'Available'
                                 End
        From    [SysproCompany40].[dbo].[GenMaster] As [GM]
                Left Join [Lookups].[ReportIndexUserMaps] As [RIUM] On [RIUM].[ReportIndex2] = Case
                                                              When [GM].[ReportIndex2] = ''
                                                              Then Null
                                                              When [GM].[Company] = '10'
                                                              Then 'Co. 10 '
                                                              + [GM].[ReportIndex2]
                                                              Else [GM].[ReportIndex2]
                                                              End
                Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [GM].[Company]
        Where   Coalesce([GM].[ReportIndex2] , '') Not In ( '' , 'FORCED' ,
                                                            'RETAINED' )
        Order By [GM].[Company]
              , [ReportStatus] Desc;
    End;
GO
