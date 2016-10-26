SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_JournalDetails]
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
            @StoredProcName = 'UspResults_JournalDetails' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;


        Create Table [#Results]
            (
              [Company] Varchar(250)			collate latin1_general_bin
            , [CompanyName] Varchar(250)		collate latin1_general_bin
            , [GlCode] Varchar(35)				collate latin1_general_bin
            , [GlCodeStart] Varchar(10)			collate latin1_general_bin
            , [GlCodeMid] Varchar(10)			collate latin1_general_bin
            , [GlCodeEnd] Varchar(10)			collate latin1_general_bin
            , [GlCodeDesc] Varchar(250)			collate latin1_general_bin
            , [GlYear] Int						
            , [GlPeriod] Int					
            , [GlLine] Int						
            , [Source] Varchar(250)				collate latin1_general_bin
            , [Journal] Int						
            , [JnlDate] Date					
            , [Reference] Varchar(250)			collate latin1_general_bin
            , [EntryValue] Numeric(20 , 2)		
            , [Comment] Varchar(500)			collate latin1_general_bin
            , [TransactionDate] Date			
            , [SubModJournal] Int				
            , [SubModInvoiceReg] Int			
            , [SubModAssetReg] Int				
            , [SubModArInvoice] Varchar(250)	collate latin1_general_bin
            , [SubModApInvoice] Varchar(250)	collate latin1_general_bin
            , [SubModSupplier] Varchar(250)		collate latin1_general_bin
            , [SubModCustomer] Varchar(15)		collate latin1_general_bin
            , [SubModRef] Varchar(30)			collate latin1_general_bin
            , [SubModCheck] Varchar(15)			collate latin1_general_bin
            , [SubModBank] Varchar(15)			collate latin1_general_bin
            , [SubModApBranch] Varchar(10)		collate latin1_general_bin
            , [SubModArBranch] Varchar(10)		collate latin1_general_bin
            , [SubModWh] Varchar(10)			collate latin1_general_bin
            , [SubModStock] Varchar(30)			collate latin1_general_bin
            , [SubModJnlArea] Varchar(10)		collate latin1_general_bin
            , [SubModTransDesc] Varchar(50)		collate latin1_general_bin
            , [SubModAsset] Varchar(30)			collate latin1_general_bin
            , [SubModGrn] Varchar(20)			collate latin1_general_bin
            , [SubModJob] Varchar(20)			collate latin1_general_bin
            , [SubModOperation] Int				
            , [SubModWorkCenter] Varchar(20)	collate latin1_general_bin
            , [SubModEmployee] Varchar(20)		collate latin1_general_bin
            , [SubModSalesOrder] Varchar(20)	collate latin1_general_bin
            , [ExtendedComment] Varchar(500)	collate latin1_general_bin
            );

--Placeholder to create indexes as required

--script to combine base data and insert into results table
        Insert  [#Results]
                ( [Company]
                , [CompanyName]
                , [GlCode]
                , [GlCodeStart]
                , [GlCodeMid]
                , [GlCodeEnd]
                , [GlCodeDesc]
                , [GlYear]
                , [GlPeriod]
                , [GlLine]
                , [Source]
                , [Journal]
                , [JnlDate]
                , [Reference]
                , [EntryValue]
                , [Comment]
                , [TransactionDate]
                , [SubModJournal]
                , [SubModInvoiceReg]
                , [SubModAssetReg]
                , [SubModArInvoice]
                , [SubModApInvoice]
                , [SubModSupplier]
                , [SubModCustomer]
                , [SubModRef]
                , [SubModCheck]
                , [SubModBank]
                , [SubModApBranch]
                , [SubModArBranch]
                , [SubModWh]
                , [SubModStock]
                , [SubModJnlArea]
                , [SubModTransDesc]
                , [SubModAsset]
                , [SubModGrn]
                , [SubModJob]
                , [SubModOperation]
                , [SubModWorkCenter]
                , [SubModEmployee]
                , [SubModSalesOrder]
                , [ExtendedComment]
                )
                Select  [GT].[Company]
                      , [CN].[CompanyName]
                      , [GT].[GlCode]
                      , [GlCodeStart] = ParseName([GM].[GlCode] , 3)
                      , [GlCodeMid] = ParseName([GM].[GlCode] , 2)
                      , [GlCodeEnd] = ParseName([GM].[GlCode] , 1)
                      , [GlCodeDesc] = LTrim(RTrim([GT].[GlCode])) + ' - '
                        + LTrim(RTrim([GM].[Description]))
                      , [GT].[GlYear]
                      , [GT].[GlPeriod]
                      , [GT].[GlLine]
                      , [Source] = Coalesce([GTS].[SourceDesc] , [GT].[Source])
                      , [GT].[Journal]
                      , [JnlDate] = Cast([GT].[JnlDate] As Date)
                      , [Reference] = Case When [GT].[Reference] = ''
                                           Then Null
                                           Else [GT].[Reference]
                                      End
                      , [GT].[EntryValue]
                      , [Comment] = Case When [GT].[Comment] = '' Then Null
                                         Else [GT].[Comment]
                                    End
                      , [TransactionDate] = Cast([GT].[TransactionDate] As Date)
                      , [SubModJournal] = Case When [GT].[SubModJournal] = 0
                                               Then Null
                                               Else [GT].[SubModJournal]
                                          End
                      , [SubModInvoiceReg] = Case When [GT].[SubModInvoiceReg] = 0
                                                  Then Null
                                                  Else [GT].[SubModInvoiceReg]
                                             End
                      , [SubModAssetReg] = Case When [GT].[SubModAssetReg] = 0
                                                Then Null
                                                Else [GT].[SubModAssetReg]
                                           End
                      , [SubModArInvoice] = Case When [GT].[SubModArInvoice] = ''
                                                 Then Null
                                                 Else [GT].[SubModArInvoice]
                                            End
                      , [SubModApInvoice] = Case When [GT].[SubModApInvoice] = ''
                                                 Then Null
                                                 Else [GT].[SubModApInvoice]
                                            End
                      , [SubModSupplier] = Case When [GT].[SubModSupplier] = ''
                                                Then Null
                                                Else [GT].[SubModSupplier]
                                           End
                      , [SubModCustomer] = Case When [GT].[SubModCustomer] = ''
                                                Then Null
                                                Else [GT].[SubModCustomer]
                                           End
                      , [SubModRef] = Case When [GT].[SubModRef] = ''
                                           Then Null
                                           Else [GT].[SubModRef]
                                      End
                      , [SubModCheck] = Case When [GT].[SubModCheck] = ''
                                             Then Null
                                             Else [GT].[SubModCheck]
                                        End
                      , [SubModBank] = Case When [GT].[SubModBank] = ''
                                            Then Null
                                            Else [GT].[SubModBank]
                                       End
                      , [SubModApBranch] = Case When [GT].[SubModApBranch] = ''
                                                Then Null
                                                Else [GT].[SubModApBranch]
                                           End
                      , [SubModArBranch] = Case When [GT].[SubModArBranch] = ''
                                                Then Null
                                                Else [GT].[SubModArBranch]
                                           End
                      , [SubModWh] = Case When [GT].[SubModWh] = '' Then Null
                                          Else [GT].[SubModWh]
                                     End
                      , [SubModStock] = Case When [GT].[SubModStock] = ''
                                             Then Null
                                             Else [GT].[SubModStock]
                                        End
                      , [SubModJnlArea] = Case When [GT].[SubModJnlArea] = ''
                                               Then Null
                                               Else [GT].[SubModJnlArea]
                                          End
                      , [SubModTransDesc] = Case When [GT].[SubModTransDesc] = ''
                                                 Then Null
                                                 Else [GT].[SubModTransDesc]
                                            End
                      , [SubModAsset] = Case When [GT].[SubModAsset] = ''
                                             Then Null
                                             Else [GT].[SubModAsset]
                                        End
                      , [SubModGrn] = Case When [GT].[SubModGrn] = ''
                                           Then Null
                                           Else [GT].[SubModGrn]
                                      End
                      , [SubModJob] = Case When [GT].[SubModJob] = ''
                                           Then Null
                                           Else [GT].[SubModJob]
                                      End
                      , [SubModOperation] = Case When [GT].[SubModOperation] = 0
                                                 Then Null
                                                 Else [GT].[SubModOperation]
                                            End
                      , [SubModWorkCenter] = Case When [GT].[SubModWorkCenter] = ''
                                                  Then Null
                                                  Else [GT].[SubModWorkCenter]
                                             End
                      , [SubModEmployee] = Case When [GT].[SubModEmployee] = ''
                                                Then Null
                                                Else [GT].[SubModEmployee]
                                           End
                      , [SubModSalesOrder] = Case When [GT].[SubModSalesOrder] = ''
                                                  Then Null
                                                  Else [GT].[SubModSalesOrder]
                                             End
                      , [ExtendedComment] = Cast([GT].[Journal] As Varchar(10))
                        + ' - ' + Cast([GT].[JnlDate] As Varchar(11))
                        + Case When [GT].[Reference] = '' Then ''
                               Else ' - ' + [GT].[Reference]
                          End + Case When [GT].[Comment] = '' Then ''
                                     Else ' - ' + [GT].[Comment]
                                End
                From    [SysproCompany40].[dbo].[GenTransaction] As [GT] With ( NoLock )
                        Inner Join [SysproCompany40].[dbo].[GenMaster] As [GM] On [GT].[Company] = [GM].[Company]
                                                              And [GT].[GlCode] = [GM].[GlCode]
                        Left Join [BlackBox].[Lookups].[CompanyNames] As [CN] On [CN].[Company] = [GM].[Company]
                        Left Join [BlackBox].[Lookups].[GenTransactionSource]
                        As [GTS] On [GTS].[Source] = [GT].[Source];
--return results
        Select  [Company]
              , [CompanyName]
              , [GlCode]
              , [GlCodeStart]
              , [GlCodeMid]
              , [GlCodeEnd]
              , [GlCodeDesc]
              , [GlYear]
              , [GlPeriod]
              , [GlLine]
              , [Source]
              , [Journal]
              , [JnlDate]
              , [Reference]
              , [EntryValue]
              , [Comment]
              , [TransactionDate]
              , [SubModJournal]
              , [SubModInvoiceReg]
              , [SubModAssetReg]
              , [SubModArInvoice]
              , [SubModApInvoice]
              , [SubModSupplier]
              , [SubModCustomer]
              , [SubModRef]
              , [SubModCheck]
              , [SubModBank]
              , [SubModApBranch]
              , [SubModArBranch]
              , [SubModWh]
              , [SubModStock]
              , [SubModJnlArea]
              , [SubModTransDesc]
              , [SubModAsset]
              , [SubModGrn]
              , [SubModJob]
              , [SubModOperation]
              , [SubModWorkCenter]
              , [SubModEmployee]
              , [SubModSalesOrder]
              , [ExtendedComment]
        From    [#Results]
        Where   Case When @Company = 'ALL' Then 'ALL' Else [Company] End = @Company;

    End;

GO
