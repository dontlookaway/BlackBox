SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Review].[UspResults_CompanyNamesMissing]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

	--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Review' ,
            @StoredProcName = 'UspResults_CompanyNamesMissing' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


        Create Table [#ListOfDbs]
            (
              [DatabaseName] sysname
            );

        Declare @SQLCmd Varchar(Max)= N'use [?];
If Lower(db_name()) Like ''sysprocompany%'' And Lower(db_name()) Not Like ''%_srs''
begin
Insert [#ListOfDbs]
        ( [DatabaseName] )
Select replace(lower(db_name()),''sysprocompany'','''')
end';

        Exec [Process].[ExecForEachDB] @cmd = @SQLCmd;

        Set NoCount Off;
        Select  'SysproCompany' + [LOD].[DatabaseName] As [DatabaseWithoutCompanyName]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [CN].[Currency]
        From    [#ListOfDbs] [LOD]
                Left Join [Lookups].[CompanyNames] [CN]
                    On [CN].[Company] = [LOD].[DatabaseName]
        Where   [CN].[Company] Is Null
                And IsNumeric([LOD].[DatabaseName]) = 1;

        Set NoCount On;
        Drop Table [#ListOfDbs];
    End;
GO
