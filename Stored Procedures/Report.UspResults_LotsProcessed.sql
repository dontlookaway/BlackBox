SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--EXEC [Report].[UspResults_LotsProcessed]		@Company = N'10'
--GO


CREATE Proc [Report].[UspResults_LotsProcessed] ( @Company VARCHAR(Max) )
As
    Begin
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Template designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Stored procedure set out to query multiple databases with the same information and return it in a collated format		///
///																																	///
///																																	///
///			Version 1.0.1																											///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			7/9/2015	Chris Johnson			Initial version created																///
///			7/9/2015	Chris Johnson			Changed to use of udf_SplitString to define tables to return						///
///			10/9/2015	Chris Johnson			As per Hassan's notes below, creating proc for report of lots & rm					///
												QC KPI for raw material approval.
												Andrew Hafford wants 
																	>	Month 
																	>	Num RMs received 
																	>	Num Lots Processed 
																	>	Average Processing time (days) 
																	>	Urgent Release requests|
///			01/10/2015	Chris Johnson			Reviewed proc, fixed links in joins and changed the details line, updated name		///
												from time to days to be more accurate in reports, plus added stock codes and 
												quantities
///			9/12/2015	Chris Johnson			Added uppercase to company															///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
    If IsNumeric(@Company) = 0
        Begin
            Select  @Company = Upper(@Company);
        End;

--remove nocount on to speed up query
        Set NoCount On;

--list the tables that are to be pulled back from each DB - if they are not found the script will not be run against that db
        Declare @ListOfTables VARCHAR(Max) = 'InvInspect,InvInspectDet'; 

--create temporary tables to be pulled from different databases, including a column to id
        Create Table #InvInspect
            (
              Company VARCHAR(25)
            , Lot VARCHAR(50)
			, Grn VARCHAR(30)
            , StockCode VARCHAR(30)
            , GrnReceiptDate DATETIME2
			, [OrderUom] VARCHAR(5) 
            );
        Create Table #InvInspectDet
            (
              Company VARCHAR(25)
            , TrnDate DATETIME2
            , Lot VARCHAR(50)
			, Grn VARCHAR(30)
			, [TrnQty] NUMERIC (20,7)
            );

--create script to pull data from each db into the tables
Declare @SQL VARCHAR(Max) = 'USE [?];
Declare @DB varchar(150),@DBCode varchar(150)
Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
        + --Only query DBs beginning SysProCompany
        '
IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
BEGIN'
        + --only companies selected in main run, or if companies selected then all
        '
	IF @DBCode in (''' + REPLACE(@Company, ',', ''',''') + ''') or '''
        + UPPER(@Company) + ''' = ''ALL''
		Declare @ListOfTables VARCHAR(max) = ''' + @ListOfTables + '''
				, @RequiredCountOfTables INT
				, @ActualCountOfTables INT'
        + --count number of tables requested (number of commas plus one)
        '
		Select @RequiredCountOfTables= count(1) from  BlackBox.dbo.[udf_SplitString](@ListOfTables,'','')'
        + --Count of the tables requested how many exist in the db
        '
		Select @ActualCountOfTables = COUNT(1) FROM sys.tables
		Where name In (Select Value Collate Latin1_General_BIN From BlackBox.dbo.udf_SplitString(@ListOfTables,'','')) '
        + --only if the count matches (all the tables exist in the requested db) then run the script
        '
		If @ActualCountOfTables=@RequiredCountOfTables
		BEGIN
			Insert #InvInspect
					( Company,Lot,Grn, StockCode, GrnReceiptDate,[OrderUom] )
				SELECT @DBCode
					,Lot
					,Grn
					,StockCode
					,GrnReceiptDate
					,[OrderUom] = upper([OrderUom])
				FROM dbo.InvInspect
				Where Lot<>''''

			Insert #InvInspectDet
				( Company, TrnDate, Lot,Grn, [TrnQty] )
			SELECT @DBCode
				,TrnDate
				,Lot
				,Grn
				, [TrnQty]
			FROM dbo.InvInspectDet
			Where TrnType In ( ''A'', ''R'', ''T'' ) --accept reject transfer
		End
End';

--Enable this function to check script changes (try to run script directly against db manually)
        --Print @SQL;

--execute script against each db, populating the base tables
        Exec sp_MSforeachdb
            @SQL;

--define the results you want to return
        Create Table #Results
            ( [Company]			VARCHAR(25) Collate Latin1_General_BIN
			, [InspMonthStart]	DATE
            , [InspWeekofYear]	SMALLINT
            , [NumLots]			INT
            , [StockCode]		VARCHAR(250) Collate Latin1_General_BIN
            , [TotalDays]		SMALLINT
            , [MaxProcDays]		SMALLINT
			, [OrderUom]		VARCHAR(10) Collate Latin1_General_BIN
			, [Quantity]		NUMERIC(20,7)
            );

--Placeholder to create indexes as required
        Create NonClustered Index Inspect_ix On #InvInspect ([Company],[Lot]);
        Create NonClustered Index Inspectdet_ix On #InvInspectDet ([Company],[Lot]);

--script to combine base data and insert into results table
        Insert  #Results
                ( [Company]
				, [InspMonthStart]
                , [InspWeekofYear]
                , [NumLots]
                , [StockCode]
                , [TotalDays]
                , [MaxProcDays]
				, [OrderUom]
				, [Quantity]
                )
                Select
                    [II].[Company]
				  , [InspMonthStart]		= DATEADD(Day,-DAY([IID].[TrnDate])+1,[IID].[TrnDate])
                  , [InspWeekofYear]		= DATEPART(ISO_WEEK, [IID].[TrnDate])
                  , [NumLots]				= COUNT(II.Lot)
                  , [NumOfStock]			= [II].StockCode
                  , [TotalDays]				= SUM(DATEDIFF(d, [II].[GrnReceiptDate], IID.[TrnDate])
												+ 1) 
                  , [MaxProcDays]			= MAX(DATEDIFF(d, [II].[GrnReceiptDate],
                                               IID.TrnDate) + 1)
				  , [II].[OrderUom]
				  , Quantity				= SUM([IID].[TrnQty])
                From
                    #InvInspect As [II]
                Inner Join #InvInspectDet As [IID]
                    On [II].[Lot] = [IID].[Lot]
					   And [IID].[Grn] = [II].[Grn]
                       And [IID].[Company] = [II].[Company]
                Group By II.Company
				  , DATEADD(Day,-DAY([IID].[TrnDate])+1,[IID].[TrnDate])
                  , DATEPART(ISO_WEEK, [IID].[TrnDate])
				  , [II].[OrderUom]
				  , [II].StockCode;

--return results
        Select
            Company = [cn].[CompanyName]
		  , [InspMonthStart]
          , [InspWeekofYear]
          , [NumLots]
          , [StockCode]
          , [TotalDays]
          , [MaxProcDays]
		  , [OrderUom]
		  , [Quantity]
        From
            #Results R
			Left Join [BlackBox].[Lookups].[CompanyNames] As [cn] On [cn].[Company] = [R].[Company];

    End;

GO
