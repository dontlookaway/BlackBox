SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc  [Report].[UspResults_ApSuppNarr]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
        Set NoCount On;

        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_ApSuppNarr' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ApSupplierNar'; 


        Create Table [#ApSupplierNar]
            (
              [DatabaseName] Varchar(150)
            , [Supplier] Varchar(15)
            , [Line] BigInt
            , [Text] Varchar(100)
            );



		--create script to pull data from each db into the tables
        Declare @SQL Varchar(Max) = 'USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			BEGIN
			Insert [#ApSupplierNar]
			        ( [DatabaseName]
			        , [Supplier]
			        , [Line]
			        , [Text]
			        )
			SELECT [DatabaseName]=@DBCode
                 , [ASN].[Supplier]
                 , [ASN].[Line]
                 , [ASN].[Text] FROM [ApSupplierNar] [ASN]
			End
	End';

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB_WithTableCheck] @cmd = @SQL ,
            @SchemaTablesToCheck = @ListOfTables;

        Set NoCount Off;

        Select  [ASN].[DatabaseName]
              , [ASN].[Supplier]
              , [ASN].[Line]
              , [ASN].[Text]
        From    [#ApSupplierNar] [ASN];


    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'used to return AP supp narrative in documents', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_ApSuppNarr', NULL, NULL
GO
