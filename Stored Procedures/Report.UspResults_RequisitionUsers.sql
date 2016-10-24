
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_RequisitionUsers]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group September 2015												
Stored procedure set out to query multiple databases with the same information and return it in a collated format
List of all requisition users																					
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
            @StoredProcName = 'UspResults_RequisitionUsers' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables Varchar(Max) = 'ReqUser,ReqGroup,ReqGroupAuthority'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table [#ReqUser]
            (
              [DatabaseName] Varchar(150)
            , [UserCode] Varchar(20)
            , [UserName] Varchar(50)
            , [AuthorityLevel] Char(1)
            , [CanAddReqn] Char(1)
            , [CanAddReqnDetails] Char(1)
            , [CanChgReqnDetails] Char(1)
            , [CanApproveReqn] Char(1)
            , [CanCreateOrder] Char(1)
            , [RequisitionGroup] Varchar(6)
            , [AdminStopFlag] Char(1)
            , [MaxApproveValue] Float
            );

        Create Table [#ReqGroup]
            (
              [DatabaseName] Varchar(150)
            , [RequisitionGroup] Varchar(6)
            , [GroupDescription] Varchar(50)
            );

        Create Table [#ReqGroupAuthority]
            (
              [DatabaseName] Varchar(150)
            , [RequisitionGroup] Varchar(6)
            , [MaxApproveValue] Float
            , [UserForPorder] Varchar(20)
            , [ProductClass] Varchar(20)
            );

--create script to pull data from each db into the tables
        Declare @SQL1 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #ReqUser
						( DatabaseName
						, UserCode
						, UserName
						, AuthorityLevel
						, CanAddReqn
						, CanAddReqnDetails
						, CanChgReqnDetails
						, CanApproveReqn
						, CanCreateOrder
						, RequisitionGroup
						, AdminStopFlag
						, [MaxApproveValue]
						)
				Select @DBCode
					,UserCode
					,UserName
					,AuthorityLevel
					,CanAddReqn
					,CanAddReqnDetails
					,CanChgReqnDetails
					,CanApproveReqn
					,CanCreateOrder
					,RequisitionGroup
					,AdminStopFlag
					, [MaxApproveValue]
				 FROM [ReqUser]
			End
	End';
        Declare @SQL2 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #ReqGroup
					( DatabaseName
					, RequisitionGroup
					, GroupDescription
					)
				SELECT @DBCode
					,RequisitionGroup
					, GroupDescription
				FROM [ReqGroup]
			End
	End';
        Declare @SQL3 Varchar(Max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN
		IF @DBCode in (''' + Replace(@Company , ',' , ''',''') + ''') or '''
            + Upper(@Company) + ''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables
            + '''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) 
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #ReqGroupAuthority
						( DatabaseName
						, RequisitionGroup
						, MaxApproveValue
						, UserForPorder
						, [ProductClass]
						)
				Select @DBCode
					 , RequisitionGroup
					 , MaxApproveValue
					 , UserForPorder
					 , [ProductClass]
				FROM  dbo.ReqGroupAuthority		
			End
	End';

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
        Exec [Process].[ExecForEachDB] @cmd = @SQL1;
        Exec [Process].[ExecForEachDB] @cmd = @SQL2;
        Exec [Process].[ExecForEachDB] @cmd = @SQL3;

--define the results you want to return
        Create Table [#Results]
            (
              [DatabaseName] Varchar(150)
            , [UserCode] Varchar(20)
            , [UserName] Varchar(50)
            , [AuthorityLevel] Char(1)
            , [CanAddReqn] Char(1)
            , [CanAddReqnDetails] Char(1)
            , [CanChgReqnDetails] Char(1)
            , [CanApproveReqn] Char(1)
            , [CanCreateOrder] Char(1)
            , [AdminStopFlag] Char(1)
            , [RequisitionGroup] Varchar(50)
            , [GroupMaxApproveValue] Float
            , [UserMaxApproveValue] Float
            , [ProductClass] Varchar(20)
            );


--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [DatabaseName]
                , [UserCode]
                , [UserName]
                , [AuthorityLevel]
                , [CanAddReqn]
                , [CanAddReqnDetails]
                , [CanChgReqnDetails]
                , [CanApproveReqn]
                , [CanCreateOrder]
                , [AdminStopFlag]
                , [RequisitionGroup]
                , [GroupMaxApproveValue]
                , [UserMaxApproveValue]
                , [ProductClass]
                )
                Select  [RU].[DatabaseName]
                      , [RU].[UserCode]
                      , [RU].[UserName]
                      , [RU].[AuthorityLevel]
                      , [RU].[CanAddReqn]
                      , [RU].[CanAddReqnDetails]
                      , [RU].[CanChgReqnDetails]
                      , [RU].[CanApproveReqn]
                      , [RU].[CanCreateOrder]
                      , [RU].[AdminStopFlag]
                      , [RequisitionGroup] = [RG].[GroupDescription]
                      , [RGA].[MaxApproveValue]
                      , [RU].[MaxApproveValue]
                      , [RGA].[ProductClass]
                From    [#ReqUser] [RU]
                        Left Join [#ReqGroup] [RG]
                            On [RG].[DatabaseName] = [RU].[DatabaseName]
                               And [RG].[RequisitionGroup] = [RU].[RequisitionGroup]
                        Left Join [#ReqGroupAuthority] [RGA]
                            On [RGA].[DatabaseName] = [RG].[DatabaseName]
                               And [RGA].[RequisitionGroup] = [RU].[RequisitionGroup];

--return results
        Select  [CN].[Company]
              , [CN].[CompanyName]
              , [CN].[ShortName]
              , [CN].[Currency]
              , [R].[UserCode]
              , [R].[UserName]
              , [R].[AuthorityLevel]
              , [R].[CanAddReqn]
              , [R].[CanAddReqnDetails]
              , [R].[CanChgReqnDetails]
              , [R].[CanApproveReqn]
              , [R].[CanCreateOrder]
              , [ProductClass] = Case When Coalesce([R].[ProductClass] , '') = ''
                                      Then 'N/A'
                                      Else [R].[ProductClass]
                                 End
              , [RequisitionGroup] = Case When [R].[RequisitionGroup] = ''
                                          Then 'No Group'
                                          When [R].[RequisitionGroup] Is Null
                                          Then 'No Group'
                                          Else [R].[RequisitionGroup]
                                     End
              , [AdminStopFlag] = Case When [R].[AdminStopFlag] = '' Then Null
                                       Else [R].[AdminStopFlag]
                                  End
              , [GroupMaxApproveValue] = Case When [R].[GroupMaxApproveValue] = ''
                                              Then 0
                                              When [R].[GroupMaxApproveValue] Is Null
                                              Then 0
                                              Else [R].[GroupMaxApproveValue]
                                         End
              , [UserMaxApproveValue] = Case When [R].[UserMaxApproveValue] = ''
                                             Then 0
                                             When [R].[UserMaxApproveValue] Is Null
                                             Then 0
                                             Else [R].[UserMaxApproveValue]
                                        End
        From    [#Results] As [R]
                Left Join [BlackBox].[Lookups].[CompanyNames] [CN]
                    On [R].[DatabaseName] = [CN].[Company];

    End;


GO
EXEC sp_addextendedproperty N'MS_Description', N'list of requisitions users', 'SCHEMA', N'Report', 'PROCEDURE', N'UspResults_RequisitionUsers', NULL, NULL
GO
