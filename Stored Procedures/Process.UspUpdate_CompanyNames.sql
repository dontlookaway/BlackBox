SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Process].[UspUpdate_CompanyNames]
    (
      @PrevCheck Int --if count is less than previous don't update
    , @HoursBetweenUpdates Numeric(5 , 2)
    )
As
    Begin

--check if table exists with latest field to drop if it doesn't
        If ( Not Exists ( Select    1
                          From      [sys].[tables] As [T]
                                    Left Join [sys].[schemas] As [S]
                                        On [S].[schema_id] = [T].[schema_id]
                                    Left Join [sys].[columns] As [C]
                                        On [C].[object_id] = [T].[object_id]
                          Where     [S].[name] = 'Lookups'
                                    And [T].[name] = 'CompanyNames'
                                    And [C].[name] = 'ShortName' )
           )
            Begin
                Begin Try
                    Drop Table [Lookups].[CompanyNames];
                End Try
                Begin Catch
                    Print 'unable to drop table - may not exist';
                End Catch;
            End;	
--check if table exists to create it
        If ( Not Exists ( Select    1
                          From      [sys].[tables] As [T]
                                    Left Join [sys].[schemas] As [S]
                                        On [S].[schema_id] = [T].[schema_id]
                          Where     [S].[name] = 'Lookups'
                                    And [T].[name] = 'CompanyNames' )
           )
            Begin
                Create Table [Lookups].[CompanyNames]
                    (
                      [Company] Varchar(150)
                    , [CompanyName] Varchar(250)
                    , [ShortName] Varchar(250)
                    , [Currency] Varchar(10)
                    , [LastUpdated] DateTime2
                    );
            End;

--check last time run and update if it's been longer than @HoursBetweenUpdates hours
        Declare @LastDate DateTime2;

        Select  @LastDate = Max([CN].[LastUpdated])
        From    [Lookups].[CompanyNames] As [CN];

        If @LastDate Is Null
            Or DateDiff(Minute , @LastDate , GetDate()) > ( @HoursBetweenUpdates
                                                            * 60 )
            Begin
	--Set time of run
                Declare @LastUpdated DateTime2;
                Select  @LastUpdated = GetDate();

	--create master list of Company Names
                Create 	Table [#CompanyList]
                    (
                      [Company] Varchar(150)
                    , [CompanyName] Varchar(250)
                    , [ShortName] Varchar(250)
                    );


                Insert  [#CompanyList]
                        ( [Company]
                        , [CompanyName]
                        , [ShortName]
                        )
                        Select  [t].[Company]
                              , [t].[CompanyName]
                              , [t].[ShortName]
                        From    ( Select    [Company] = '0'
                                          , [CompanyName] = 'Prometic BioSciences Ltd. TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = '10'
                                          , [CompanyName] = 'Prometic BioSciences Ltd'
                                          , [ShortName] = 'PBL'
                                  Union
                                  Select    [Company] = '11'
                                          , [CompanyName] = 'Prometic Biotherapeutics Ltd'
                                          , [ShortName] = 'PBT Ltd'
                                  Union
                                  Select    [Company] = '12'
                                          , [CompanyName] = 'Prometic Pharma SMT Ltd'
                                          , [ShortName] = 'PSMT'
                                  Union
                                  Select    [Company] = '13'
                                          , [CompanyName] = 'Prometic Pharma SMTH Ltd'
                                          , [ShortName] = 'PSMH'
                                  Union
                                  Select    [Company] = '20'
                                          , [CompanyName] = 'Prometic Biotherapeutics Inc'
                                          , [ShortName] = 'PBT'
                                  Union
                                  Select    [Company] = '21'
                                          , [CompanyName] = 'Pathogen Removal Device Tech'
                                          , [ShortName] = 'PRDT'
                                  Union
                                  Select    [Company] = '22'
                                          , [CompanyName] = 'Nantpro'
                                          , [ShortName] = 'Nantpro'
                                  Union
                                  Select    [Company] = '40'
                                          , [CompanyName] = 'Prometic Life Sciences Inc'
                                          , [ShortName] = 'PLI'
                                  Union
                                  Select    [Company] = '41'
                                          , [CompanyName] = 'Prometic Biosciences Inc'
                                          , [ShortName] = 'PBI'
                                  Union
                                  Select    [Company] = '42'
                                          , [CompanyName] = 'Prometic Manufacturing Inc'
                                          , [ShortName] = 'PMI'
                                  Union
                                  Select    [Company] = '43'
                                          , [CompanyName] = 'Prometic Bioproduction Inc'
                                          , [ShortName] = 'PBP'
                                  Union
                                  Select    [Company] = '44'
                                          , [CompanyName] = 'Prometic Plasma Resources Inc'
                                          , [ShortName] = 'PPR'
                                  Union
                                  Select    [Company] = '70'
                                          , [CompanyName] = 'Prometic Biosciences Russia'
                                          , [ShortName] = 'PBR Russia'
                                  Union
                                  Select    [Company] = '91'
                                          , [CompanyName] = 'Prometic Biosciences Inc - Dec Y/E'
                                          , [ShortName] = 'PBI - Dec Y/E'
                                  Union
                                  Select    [Company] = '92'
                                          , [CompanyName] = 'Prometic Biotherapeutics Inc'
                                          , [ShortName] = 'PBT Inc'
                                  Union
                                  Select    [Company] = 'C'
                                          , [CompanyName] = 'Prometic Biotherapeutics TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'D'
                                          , [CompanyName] = 'Prometic Biosciences Inc TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'F'
                                          , [CompanyName] = 'Prometic Biosciences Inc TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'G'
                                          , [CompanyName] = 'Pathogen Removal Device Tech TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'H'
                                          , [CompanyName] = 'Prometic Biotherapeutics TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'P'
                                          , [CompanyName] = 'Prometic Bioproduction TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'Q'
                                          , [CompanyName] = 'Prometic Life Sciences TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'T'
                                          , [CompanyName] = 'Prometic Biosciences Ltd TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'U'
                                          , [CompanyName] = 'Prometic Manufacturing TEST'
                                          , [ShortName] = 'N/A'
                                  Union
                                  Select    [Company] = 'V'
                                          , [CompanyName] = 'Pathogen Removal Device TEST'
                                          , [ShortName] = 'N/A'
                                ) [t];

	--Get list of all companies in use
                Create Table [#CompanyNameTable1]
                    (
                      [Company] Varchar(150)
                    , [Currency] Varchar(10)
                    );
 
	--create script to pull data from each db into the tables
                Declare @SQL Varchar(Max) = 'USE [?];
		Declare @DB varchar(150),@DBCode varchar(150)
		Select @DB = DB_NAME(),@DBCode = case when len(db_Name())>13 then right(db_Name(),len(db_Name())-13) else null end
		IF left(@DB,13)=''SysproCompany'' and right(@DB,3)<>''SRS''
		BEGIN				
			Insert #CompanyNameTable1 
				(Company, Currency)
			Select 
				@DBCode,[TC].[Currency] 
			FROM [dbo].[TblCurrency] As [TC]
		Where [TC].[BuyExchangeRate]=1
		End';

	--execute script against each db, populating the base tables
                Exec [Process].[ExecForEachDB] @cmd = @SQL;

                Select  [T].[Company]
                      , [CompanyName] = Coalesce([cl].[CompanyName] ,
                                                 'Unknown')
                      , [ShortName] = Coalesce([cl].[ShortName] , 'Unknown')
                      , [T].[Currency]
                Into    [#ResultsCompanyName]
                From    [#CompanyNameTable1] [T]
                        Left Join [#CompanyList] As [cl]
                            On [cl].[Company] = [T].[Company];


	--placeholder for anomalous results that are different to master list
                Insert  [Lookups].[CompanyNames]
                        ( [Company]
                        , [CompanyName]
                        , [Currency]
                        , [ShortName]
                        , [LastUpdated]
	                    )
                        Select  [rcn].[Company]
                              , [rcn].[CompanyName]
                              , [rcn].[Currency]
                              , [rcn].[ShortName]
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
                        Where   [cn].[LastUpdated] <> @LastUpdated;


	
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
        If DateDiff(Minute , @LastDate , GetDate()) <= ( @HoursBetweenUpdates
                                                         * 60 )
            Begin
                Print 'UspUpdate_CompanyNames - Table was last updated at '
                    + Cast(@LastDate As Varchar(255)) + ' no update applied';
            End;
    End;

GO
