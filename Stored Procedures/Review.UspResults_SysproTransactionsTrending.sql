SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Review].[UspResults_SysproTransactionsTrending]
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
            @StoredProcName = 'UspResults_SysproTransactionsCheck' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Set NoCount Off;
        Select  [MonthOfSignatures] = DateFromParts(DatePart(Year ,
                                                             [STL].[SignatureDateTime]) ,
                                                    DatePart(Month ,
                                                             [STL].[SignatureDateTime]) ,
                                                    1)
              , [CountOfLogs] = Count(Distinct Convert(Varchar(155) , [STL].[SignatureDateTime])
                                      + [STL].[TableName]
                                      + Coalesce([STL].[ConditionName] , '')
                                      + [STL].[ItemKey])
              , [CountOfTables] = Count(Distinct [STL].[TableName])
              , [CountOfConditions] = Count(Distinct [STL].[ConditionName])
              , [CountOfKeys] = Count(Distinct [STL].[ItemKey])
        From    [Process].[SysproTransactionsLogged] [STL]
        Where   DateDiff(Month ,
                         DateFromParts(DatePart(Year ,
                                                [STL].[SignatureDateTime]) ,
                                       DatePart(Month ,
                                                [STL].[SignatureDateTime]) , 1) ,
                         DateFromParts(DatePart(Year , GetDate()) ,
                                       DatePart(Month , GetDate()) , 1)) <= 12
        Group By DateFromParts(DatePart(Year , [STL].[SignatureDateTime]) ,
                               DatePart(Month , [STL].[SignatureDateTime]) , 1)
        Order By DateFromParts(DatePart(Year , [STL].[SignatureDateTime]) ,
                               DatePart(Month , [STL].[SignatureDateTime]) , 1) Desc;
    End;

GO
EXEC sp_addextendedproperty N'MS_Description', N'review of syspro audit logs captured in BlackBox', 'SCHEMA', N'Review', 'PROCEDURE', N'UspResults_SysproTransactionsTrending', NULL, NULL
GO
