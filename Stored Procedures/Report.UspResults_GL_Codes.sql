SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GL_Codes]
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
            @StoredProcName = 'UspResults_GL_CodeLists' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


--define the results you want to return
        Create Table [#Results]
            (
              [Company] Char(4)					collate latin1_general_bin
            , [GlCode] Varchar(35)				collate latin1_general_bin
            , [Description] Varchar(50)			collate latin1_general_bin
            , [ReportIndex1] Varchar(35)		collate latin1_general_bin
            , [ReportIndex2] Varchar(35)		collate latin1_general_bin
            , [GlGroup] Varchar(10)				collate latin1_general_bin
            , [CurrentBalance] Numeric(20 , 2)	
            , [PrevPerEndBal] Numeric(20 , 2)	
            );

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Company]
                , [GlCode]
                , [Description]
                , [ReportIndex1]
                , [ReportIndex2]
                , [GlGroup]
                , [CurrentBalance]
                , [PrevPerEndBal]
                )
                Select  [GM].[Company]
                      , [GM].[GlCode]
                      , [GM].[Description]
                      , [GM].[ReportIndex1]
                      , [GM].[ReportIndex2]
                      , [GM].[GlGroup]
                      , [GM].[CurrentBalance]
                      , [GM].[PrevPerEndBal]
                From    [SysproCompany40].[dbo].[GenMaster] [GM]
                Where   Upper([GM].[GlCode]) Not In ( 'FORCED' , 'RETAINED' );

Set NoCount Off
--return results
        Select  [R].[Company]
              , [R].[GlCode]
              , [R].[Description]
              , [R].[ReportIndex1]
              , [R].[ReportIndex2]
              , [R].[GlGroup]
              , [R].[CurrentBalance]
              , [R].[PrevPerEndBal]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [CN].[Currency]
        From    [#Results] [R]
		Left Join [Lookups].[CompanyNames] [CN] On [CN].[Company] = [R].[Company];

    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'list of gl codes', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_GL_Codes', NULL, NULL
GO
