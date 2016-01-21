SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_ArCustomers]
(@Company VARCHAR(Max))
As --exec [Report].[UspResults_ArCustomers] 10
Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///			List of all AR customers																								///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			6/10/2015	Chris Johnson			Initial version created																///
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
Declare @ListOfTables VARCHAR(max) = 'ArCustomer' 

--create temporary tables to be pulled from different databases, including a column to id
CREATE TABLE [#ArCustomer]
	  ([DatabaseName] VARCHAR(150)
	   ,[Customer] VARCHAR(25)
	   ,[Name]    VARCHAR(255)
	   ,[InvoiceCount] INT
	   ,[DateLastSale] DATETIME2
	   ,[DateLastPay] DATETIME2
	   ,[DateCustAdded] DATETIME2
	   ,[Contact] VARCHAR(100)
	   ,[Telephone] VARCHAR(20)
	   ,[Email] VARCHAR(255)
	   ,[Nationality] Char(3)
	  )



--create script to pull data from each db into the tables
	Declare @SQL VARCHAR(max) = '
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
				Insert [#ArCustomer]
        ( [DatabaseName]
        , [Customer]
        , [Name]
        , [InvoiceCount]
        , [DateLastSale]
        , [DateLastPay]
        , [DateCustAdded]
        , [Contact]
        , [Telephone]
        , [Email]
        , [Nationality]
        )
Select @DBCode
	,[Customer]
	,[Name]
	,[InvoiceCount]
	,[DateLastSale]
	,[DateLastPay]
	,[DateCustAdded]
	,[Contact]
	,[Telephone]
	,[Email]
	,[Nationality]
 FROM [dbo].[ArCustomer] As [ac]	
			End
	End'

--Enable this function to check script changes (try to run script directly against db manually)
--Print @SQL

--execute script against each db, populating the base tables
	Exec sp_MSforeachdb @SQL

--define the results you want to return
	--Create Table #Results
	--(DatabaseName VARCHAR(150)
	--    ,Results VARCHAR(500))

--Placeholder to create indexes as required
--create NonClustered Index Index_Name On #Table1 (DatabaseName) Include (ColumnName)

--script to combine base data and insert into results table
	--Insert #Results
	--        ( DatabaseName, Results )
	--Select DatabaseName,ColumnName FROM #Table1

--return results
	SELECT [cn].[CompanyName]
         , [ac].[Customer]
         , [ac].[Name]
         , [ac].[InvoiceCount]
         , [DateLastSale] =  cast([ac].[DateLastSale]  as date)
         , [DateLastPay] =   cast([ac].[DateLastPay]   as date)
         , [DateCustAdded] = cast([ac].[DateCustAdded] as date)
         , [Contact] = Case When [ac].[Contact]='' Then Null Else [ac].[Contact] end
         , [ac].[Telephone]
         , [ac].[Email]
         , [ac].[Nationality] FROM [#ArCustomer] As [ac]
		 Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [ac].[DatabaseName]=[cn].[Company] Collate Latin1_General_BIN

End

GO
