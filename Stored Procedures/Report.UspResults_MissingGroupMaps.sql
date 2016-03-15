SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Report].[UspResults_MissingGroupMaps]
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
            @StoredProcName = 'UspResults_MissingGroupMaps' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


        Select  Distinct
                [GM].[Company]
              , [CN].[CompanyName]
              , [GM].[GlGroup]
              , LGM.[Map1]
			  , LGM.[Map2]
			  , LGM.[Map3]
			  , [GroupStatus] = Case When Coalesce(LGM.[Map1], LGM.[Map2], LGM.[Map3]) Is Null Then 'Missing'
                                      When Coalesce(LGM.[Map1], LGM.[Map2], LGM.[Map3]) = '' Then 'Blank'
                                      Else 'Available'
                                 End
        From    [SysproCompany40].[dbo].[GenMaster] As [GM]
                Left Join [Lookups].[LedgerGroupMaps] As [LGM] On [LGM].[GlGroup] = [GM].[GlGroup]
                Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [GM].[Company]
        Where   Coalesce([GM].[ReportIndex2] , '') Not In ( '' , 'FORCED' ,
                                                            'RETAINED' )
        Order By [GM].[Company]
              , GroupStatus Desc;
    End;
GO
