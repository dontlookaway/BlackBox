SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Proc [Review].[UspResults_SysproTransactionsCheck]
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
        Select  [LastSignatureDateTime] = Max([STL].[SignatureDateTime])
              , [SumOfErrors] = Sum(Convert(Int , [STL].[IsError]))
              , [SumOfNonEntered] = Sum(1
                                        - Convert(Int , [STL].[AlreadyEntered]))
        From    [Process].[SysproTransactionsLogged] [STL];
    End;
GO
