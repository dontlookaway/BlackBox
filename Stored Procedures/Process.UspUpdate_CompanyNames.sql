
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_CompanyNames]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Int
    )
As
    Begin
/*
Stored procedure created by Chris Johnson, Prometic Group September 2015 to populate table with Company Names
--exec  [Process].[UspUpdate_CompanyNames] 0,-1
*/

        Set NoCount On;

        Print 1;
--check if table exists and create if it doesn't
        If ( Not Exists ( Select    *
                          From      [INFORMATION_SCHEMA].[TABLES]
                          Where     [TABLE_SCHEMA] = 'Lookups'
                                    And [TABLE_NAME] = 'CompanyNames' )
           )
            Begin
                Print 2;
                Create --drop --alter 
				Table [Lookups].[CompanyNames]
                    (
                      [Company] Varchar(150)
                    , [CompanyName] Varchar(250)
					, Currency Varchar(10)
                    , [LastUpdated] DateTime2
                    );
            End;


--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Print 3;
        Select  @LastDate = Max([LastUpdated])
        From    [Lookups].[PurchaseOrderStatus];

        If @LastDate Is Null
            Or DateDiff(Hour , @LastDate , GetDate()) > @HoursBetweenUpdates
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();
                Print 4;
	--create master list of how codes affect stock
                Create --drop --alter 
	Table [#CompanyList]
                    (
                      [Company] Varchar(150)
                    , [CompanyName] Varchar(250)
                    );

                Print 5;
                Insert  [#CompanyList]
                        ( [Company]
                        , [CompanyName]
                        )
                        Select  [t].[Company]
                              , [t].[CompanyName]
                        From    ( Select    [Company] = '0'
                                          , [CompanyName] = 'Prometic BioSciences Ltd. TEST'
                                  Union
                                  Select    [Company] = '10'
                                          , [CompanyName] = 'Prometic BioSciences Ltd'
                                  Union
                                  Select    [Company] = '11'
                                          , [CompanyName] = 'Prometic Biotherapeutics Ltd'
								  Union
                                  Select    [Company] = '12'
                                          , [CompanyName] = 'Prometic Pharma SMT Ltd'
                                  Union
                                  Select    [Company] = '20'
                                          , [CompanyName] = 'Prometic Biotherapeutics Inc'
                                  Union
                                  Select    [Company] = '21'
                                          , [CompanyName] = 'Pathogen Removal Device Tech'
                                  Union
                                  Select    [Company] = '22'
                                          , [CompanyName] = 'Nantpro'
                                  Union
                                  Select    [Company] = '40'
                                          , [CompanyName] = 'Prometic Life Sciences Inc'
                                  Union
                                  Select    [Company] = '41'
                                          , [CompanyName] = 'Prometic Biosciences Inc'
                                  Union
                                  Select    [Company] = '42'
                                          , [CompanyName] = 'Prometic Manufacturing Inc'
                                  Union
                                  Select    [Company] = '43'
                                          , [CompanyName] = 'Prometic Bioproduction Inc'
                                  Union
                                  Select    [Company] = '44'
                                          , [CompanyName] = 'Prometic Plasma Resources Inc'
                                  Union
                                  Select    [Company] = '70'
                                          , [CompanyName] = 'Prometic Biosciences Russia'
                                  Union
                                  Select    [Company] = '91'
                                          , [CompanyName] = 'Prometic Biosciences Inc'
                                  Union
                                  Select    [Company] = '92'
                                          , [CompanyName] = 'Prometic Biotherapeutics Inc'
                                  Union
                                  Select    [Company] = 'C'
                                          , [CompanyName] = 'Prometic Biotherapeutics TEST'
                                  Union
                                  Select    [Company] = 'D'
                                          , [CompanyName] = 'Prometic Biosciences Inc TEST'
                                  Union
                                  Select    [Company] = 'F'
                                          , [CompanyName] = 'Prometic Biosciences Inc TEST'
                                  Union
                                  Select    [Company] = 'G'
                                          , [CompanyName] = 'Pathogen Removal Device Tech TEST'
                                  Union
                                  Select    [Company] = 'H'
                                          , [CompanyName] = 'Prometic Biotherapeutics TEST'
                                  Union
                                  Select    [Company] = 'P'
                                          , [CompanyName] = 'Prometic Bioproduction TEST'
                                  Union
                                  Select    [Company] = 'Q'
                                          , [CompanyName] = 'Prometic Life Sciences TEST'
                                  Union
                                  Select    [Company] = 'T'
                                          , [CompanyName] = 'Prometic Biosciences Ltd TEST'
                                  Union
                                  Select    [Company] = 'U'
                                          , [CompanyName] = 'Prometic Manufacturing TEST'
                                  Union
                                  Select    [Company] = 'V'
                                          , [CompanyName] = 'Pathogen Removal Device TEST'
                                ) [t];

	--Get list of all companies in use

	--create temporary tables to be pulled from different databases, including a column to id
                Create Table [#CompanyNameTable1] ( [Company] Varchar(150),Currency Varchar(10) );
                Print 6;
	--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = '
		USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end'
                    + --Only query DBs beginning SysProCompany
                    '
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
		Insert #CompanyNameTable1
			( Company,Currency )
		Select @DBCode,[TC].[Currency] FROM [dbo].[TblCurrency] As [TC]
		Where [TC].[BuyExchangeRate]=1
		End';
                Print 7;
	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

					
	--all companies process the same way
                Select  [T].[Company]
                      , [CompanyName] = Coalesce([cl].[CompanyName] ,
                                                 'Unknown')
					  , [T].[Currency]
                Into    [#ResultsCompanyName]
                From    [#CompanyNameTable1] [T]
                        Left Join [#CompanyList] As [cl] On [cl].[Company] = [T].[Company];


	--placeholder for anomalous results that are different to master list
	--Update #ResultsPoStatus
	--Set amountmodifier = 0--Set amount
	--Where CompanyName = ''
	--	And TrnType = '';

                Insert  [Lookups].[CompanyNames]
                        ( [Company]
                        , [CompanyName]
						, Currency
                        , [LastUpdated]
	                    )
                        Select  [rcn].[Company]
                              , [rcn].[CompanyName]
							  , [rcn].[Currency]
                              , @LastUpdated
                        From    [#ResultsCompanyName] As [rcn];

                If @PrevCheck = 1
                    Begin
                        Declare @CurrentCount Int
                          , @PreviousCount Int;
	
                        Select  @CurrentCount = Count(*)
                        From    [Lookups].[CompanyNames] As [cn]
                        Where   [cn].[LastUpdated] = @LastUpdated;

                        Select  @PreviousCount = Count(*)
                        From    [Lookups].[CompanyNames] As [cn]
                        Where   [cn].[LastUpdated] <> @LastDate;
	
                        If @PreviousCount > @CurrentCount
                            Begin
                                Delete  [Lookups].[CompanyNames]
                                Where   [LastUpdated] = @LastDate;
                                Print 'UspUpdate_CompanyNames - Count has gone down since last run, no update applied';
                                Print 'Current Count = '
                                    + Cast(@CurrentCount As Varchar(5))
                                    + ' Previous Count = '
                                    + Cast(@PreviousCount As Varchar(5));
                            End;
                        If @PreviousCount <= @CurrentCount
                            Begin
                                Delete  [Lookups].[CompanyNames]
                                Where   [LastUpdated] <> @LastUpdated
                                        Or [LastUpdated] Is Null;
                                Print 'UspUpdate_CompanyNames - Update applied successfully';
                            End;
                    End;
                If @PrevCheck = 0
                    Begin
                        Delete  [Lookups].[CompanyNames]
                        Where   [LastUpdated] <> @LastUpdated;
                        Print 'UspUpdate_CompanyNames - Update applied successfully';
                    End;
            End;
    End;
    If DateDiff(Hour , @LastDate , GetDate()) <= @HoursBetweenUpdates
        Begin
            Print 'UspUpdate_CompanyNames - Table was last updated at '
                + Cast(@LastDate As Varchar(255)) + ' no update applied';
        End;
GO
