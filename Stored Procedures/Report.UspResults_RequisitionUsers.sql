SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_RequisitionUsers]
(@Company VARCHAR(Max))
As
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			List of all requisition users																							///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			16/9/2015	Chris Johnson			Initial version created																///
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    Set NoCount Off;
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;


--remove nocount on to speed up query
Set NoCount On

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
Declare @ListOfTables VARCHAR(max) = 'ReqUser,ReqGroup,ReqGroupAuthority' 

--create temporary tables to be pulled from different databases, including a column to id
Create Table #ReqUser
	(DatabaseName VARCHAR(150)
	    ,UserCode VARCHAR(20)
		,UserName VARCHAR(50)
		,AuthorityLevel CHAR(1)
		,CanAddReqn CHAR(1)
		,CanAddReqnDetails CHAR(1)
		,CanChgReqnDetails CHAR(1)
		,CanApproveReqn CHAR(1)
		,CanCreateOrder CHAR(1)
		,RequisitionGroup VARCHAR(6)
		,AdminStopFlag CHAR(1))

	Create Table #ReqGroup
	(DatabaseName VARCHAR(150)
	    ,RequisitionGroup  VARCHAR(6)
     , GroupDescription VARCHAR(50))

CREATE --drop --alter 
TABLE #ReqGroupAuthority
(DatabaseName VARCHAR(150)
    ,RequisitionGroup VARCHAR(6)
     , MaxApproveValue FLOAT
     , UserForPorder VARCHAR(20)
)

--create script to pull data from each db into the tables
	Declare @SQL1 VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
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
				 FROM [ReqUser]
			End
	End'
Declare @SQL2 VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
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
	End'
Declare @SQL3 VARCHAR(max) = '
	USE [?];
	Declare @DB varchar(150),@DBCode varchar(150)
	Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'+
	--Only query DBs beginning SysProCompany
	'
	IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
	BEGIN'+ --only companies selected in main run, or if companies selected then all
		'
		IF @DBCode in ('''+REPLACE(@Company,',',''',''') +''') or '''+UPPER(@Company)+''' = ''ALL''
			Declare @ListOfTables VARCHAR(max) = '''+@ListOfTables+'''
					, @RequiredCountOfTables INT
					, @ActualCountOfTables INT'+
			--count number of tables requested (number of commas plus one)
			'
			Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'+
			--Count of the tables requested how many exist in the db
			'
			Select @ActualCountOfTables = COUNT(1) FROM sys.tables
			Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '+
			--only if the count matches (all the tables exist in the requested db) then run the script
			'
			If @ActualCountOfTables=@RequiredCountOfTables
			BEGIN
				Insert #ReqGroupAuthority
						( DatabaseName
						, RequisitionGroup
						, MaxApproveValue
						, UserForPorder
						)
				Select @DBCode
					 , RequisitionGroup
					 , MaxApproveValue
					 , UserForPorder
				FROM  dbo.ReqGroupAuthority		
			End
	End'




		

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL1
	Exec sp_MSforeachdb @SQL2
	Exec sp_MSforeachdb @SQL3

--define the results you want to return
	CREATE --drop --alter 
	TABLE #Results
	(  DatabaseName VARCHAR(150)
		,UserCode VARCHAR(20)
		,UserName VARCHAR(50)
		,AuthorityLevel CHAR(1)
		,CanAddReqn CHAR(1)
		,CanAddReqnDetails CHAR(1)
		,CanChgReqnDetails CHAR(1)
		,CanApproveReqn CHAR(1)
		,CanCreateOrder CHAR(1)
		,AdminStopFlag CHAR(1)
		,RequisitionGroup VARCHAR(50)
		,GroupMaxApproveValue FLOAT
	 )


--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
Insert #Results
        ( DatabaseName
        , UserCode
        , UserName
        , AuthorityLevel
        , CanAddReqn
        , CanAddReqnDetails
        , CanChgReqnDetails
        , CanApproveReqn
        , CanCreateOrder
        , AdminStopFlag
        , RequisitionGroup
		, GroupMaxApproveValue
        )
Select RU.DatabaseName
		,  UserCode
		, UserName
		, AuthorityLevel
		, CanAddReqn
		, CanAddReqnDetails
		, CanChgReqnDetails
		, CanApproveReqn
		, CanCreateOrder
		, AdminStopFlag
		, RequisitionGroup = GroupDescription
		, MaxApproveValue
From
    #ReqUser RU
Left Join #ReqGroup RG
    On RG.DatabaseName = RU.DatabaseName
	And RG.RequisitionGroup = RU.RequisitionGroup
Left Join #ReqGroupAuthority RGA 
	On	RGA.DatabaseName = RG.DatabaseName
	And RGA.RequisitionGroup = RU.RequisitionGroup;

--return results
	SELECT Company = DatabaseName
         , UserCode
         , UserName
         , AuthorityLevel
         , CanAddReqn
         , CanAddReqnDetails
         , CanChgReqnDetails
         , CanApproveReqn
         , CanCreateOrder
         , RequisitionGroup = case when RequisitionGroup='' then 'No Group'
									when RequisitionGroup is null then 'No Group'
									else RequisitionGroup end
         , AdminStopFlag = Case When AdminStopFlag ='' Then Null Else AdminStopFlag  End
		 , GroupMaxApproveValue = Case When GroupMaxApproveValue='' Then 0
										When GroupMaxApproveValue Is Null Then 0
										Else GroupMaxApproveValue End
	From #Results

End

GO
