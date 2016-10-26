SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_GenMasterMapping]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
--Exec [Report].[UspResults_GenMasterMapping] @Company='10'
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015
Stored procedure set out to query multiple databases with the same information and return it in a collated format
*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--remove nocount on to speed up query
        Set NoCount On;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_GenMasterMapping' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#GenMaster]
            (
              [Company] Varchar(150)		Collate Latin1_General_BIN
            , [GlCode] Varchar(150)			Collate Latin1_General_BIN
            , [Description] Varchar(255)	Collate Latin1_General_BIN
            );
        Print 1;
        Insert  [#GenMaster]
                ( [Company]
                , [GlCode]
                , [Description]
	            )
                Select  [gm].[Company]
                      , [gm].[GlCode]
                      , [gm].[Description]
                From    [SysproCompany40]..[GenMaster] As [gm]
                Where   [gm].[Company] = @Company
                        And [gm].[GlCode] Not In ( 'FORCED' , 'RETAINED' );



--define the results you want to return
        Create Table [#Results]
            (
              [GlCode] Varchar(150)					collate Latin1_General_BIN
            , [Company] Varchar(150)				collate Latin1_General_BIN
            , [GlStart] Varchar(3)					collate Latin1_General_BIN
            , [GlMid] Varchar(5)					collate Latin1_General_BIN
            , [Mid1] Varchar(3)						collate Latin1_General_BIN
            , [Mid2] Varchar(2)						collate Latin1_General_BIN
            , [GlEnd] Varchar(3)					collate Latin1_General_BIN
            , [MappingDescription] Varchar(255)		collate Latin1_General_BIN
            , [LedgerDescription] Varchar(255)		collate Latin1_General_BIN
            , [Mapping1] Varchar(255)				collate Latin1_General_BIN
            , [Mapping2] Varchar(255)				collate Latin1_General_BIN
            , [Mapping3] Varchar(255)				collate Latin1_General_BIN
            , [Mapping4] Varchar(255)				collate Latin1_General_BIN
            , [Mapping5] Varchar(255)				collate Latin1_General_BIN
            , [Status] Varchar(255)					collate Latin1_General_BIN
            );

        Print 2;
--script to combine base data and insert into results table
        Insert  [#Results]
                ( [GlCode]
                , [Company]
                , [GlStart]
                , [GlMid]
                , [Mid1]
                , [Mid2]
                , [GlEnd]
                , [MappingDescription]
                , [LedgerDescription]
                , [Mapping1]
                , [Mapping2]
                , [Mapping3]
                , [Mapping4]
                , [Mapping5]
                , [Status]
                )
                Select  [GlCode] = Coalesce([gm].[GlCode] , [gm2].[GlCode])
                      , [Company] = Coalesce([gm].[Company] , [gm2].[Company])
                      , [GlStart] = Coalesce([gm2].[GlStart] ,
                                             ParseName([gm].[GlCode] , 3))
                      , [GlMid] = Coalesce([gm2].[GlMid] ,
                                           ParseName([gm].[GlCode] , 2))
                      , [Mid1] = Coalesce([gm2].[Mid1] ,
                                          Left(( ParseName([gm].[GlCode] , 2) ) ,
                                               3))
                      , [Mid2] = Coalesce([gm2].[Mid2] ,
                                          Right(( ParseName([gm].[GlCode] , 2) ) ,
                                                2))
                      , [GlEnd] = Coalesce([gm2].[GlEnd] ,
                                           ParseName([gm].[GlCode] , 1))
                      , [MappingDescription] = [gm2].[GlDescription]
                      , [LedgerDescription] = [gm].[Description]
                      , [Mapping1] = [gm2].[Mapping1]
                      , [Mapping2] = [gm2].[Mapping2]
                      , [Mapping3] = [gm2].[Mapping3]
                      , [Mapping4] = [gm2].[Mapping4]
                      , [Mapping5] = [gm2].[Mapping5]
                      , [Status] = Case When [gm].[GlCode] Is     Null
                                        Then 'Map does not have value in General Ledger' Collate Latin1_General_BIN
                                        When [gm2].[GlCode] Is     Null
                                        Then 'Ledger code does not have a map' Collate Latin1_General_BIN
                                        When [gm2].[GlDescription] <> [gm].[Description]
                                        Then 'Map description does not match GL description' Collate Latin1_General_BIN
                                        When [gm].[GlCode] Is Not Null
                                             And [gm2].[GlCode] Is Not Null
                                        Then 'Map Available' Collate Latin1_General_BIN
                                   End
                From    [#GenMaster] As [gm]
                        Full Outer Join [Lookups].[GLMapping] As [gm2] On [gm2].[Company] = [gm].[Company]
                                                              And [gm2].[GlCode] = [gm].[GlCode];

--return results
        Select  [GlCode]
              , [Company]
              , [GlStart]
              , [GlMid]
              , [Mid1]
              , [Mid2]
              , [GlEnd]
              , [MappingDescription]
              , [LedgerDescription]
              , [Mapping1]
              , [Mapping2]
              , [Mapping3]
              , [Mapping4]
              , [Mapping5]
              , [Status]
        From    [#Results];

    End;

GO
