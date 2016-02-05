SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE Proc [Report].[UspResults_CompaniesCurrencyLatestExchangeRates]
    (
      @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As /*
Template designed by Chris Johnson, Prometic Group Feb 2015
Stored procedure set out to query all live db's and return details of general ledger journal
*/
Begin
    Set NoCount On;

--Red tag
    Declare @RedTagDB Varchar(255)= Db_Name();
    Exec [Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
        @StoredProcSchema = 'Report' ,
        @StoredProcName = 'UspResults_CompaniesCurrencyLatestExchangeRates' ,
        @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
        @UsedByDb = @RedTagDB;



CREATE TABLE #CompanyCurrency
(DatabaseName Varchar(300)
   ,Currency Varchar(10)
)
Declare @SQL Varchar(max)='Use [?];

If lower(db_name()) like ''sysprocompany%'' and lower(db_name()) not like ''%srs'' and Replace(Db_Name() , ''SysproCompany'' , '''') Not In ( ''A'' , ''B'' , ''C'' , ''D'' ,
                                                      ''E'' , ''F'' , ''G'' , ''H'' ,
                                                      ''P'' , ''Q'' , ''T'' , ''U'' ,
                                                      ''V'' )
begin
If Exists (Select 1 From sys.[tables] As [T] Where [T].[name] =''TblCurrency'')
	begin
	Insert [#CompanyCurrency]
			( [DatabaseName] , [Currency] )
	Select Db_Name()
			,[Currency] from dbo.TblCurrency
	Where [BuyEcDeclRate]=0
	End
end'

    Exec [Process].[ExecForEachDB] @cmd = @SQL;

SELECT [CC].[DatabaseName]
	, [CN].[CompanyName]
     , [CC].[Currency]
     , [CR].[StartDateTime]
     , [CR].[CADDivision]
     , [CR].[CHFDivision]
     , [CR].[EURDivision]
     , [CR].[GBPDivision]
     , [CR].[JPYDivision]
     , [CR].[USDDivision]
     , [CR].[CADMultiply]
     , [CR].[CHFMultiply]
     , [CR].[EURMultiply]
     , [CR].[GBPMultiply]
     , [CR].[JPYMultiply]
     , [CR].[USDMultiply]
     , [CR].[LastUpdated] 
	 , [CR].[StartDateTime]
	 From [#CompanyCurrency] As [CC]
Left Join [Lookups].[CurrencyRates] As [CR] On [CR].[Currency] = [CC].[Currency] 
And GetDate() Between [CR].[StartDateTime] And [CR].[EndDateTime]
Left Join [Lookups].[CompanyNames] As [CN] On Replace([CC].[DatabaseName],'SysproCompany','')=[CN].[Company]

Drop Table [#CompanyCurrency]
End
GO
