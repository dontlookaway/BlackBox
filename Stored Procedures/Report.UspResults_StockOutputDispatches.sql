
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [Report].[UspResults_StockOutputDispatches]
    (
      @Company Varchar(Max)
    , @RedTagType Char(1)
    , @RedTagUse Varchar(500)
    )
As
    Begin
/*
Template designed by Chris Johnson, Prometic Group March 2016

*/
        If IsNumeric(@Company) = 0
            Begin
                Select  @Company = Upper(@Company);
            End;

		--Red tag
        Declare @RedTagDB Varchar(255)= Db_Name();
        Exec [BlackBox].[Process].[UspInsert_RedTagLogs] @StoredProcDb = 'BlackBox' ,
            @StoredProcSchema = 'Report' ,
            @StoredProcName = 'UspResults_StockOutputDispatches' ,
            @UsedByType = @RedTagType , @UsedByName = @RedTagUse ,
            @UsedByDb = @RedTagDB;

        Declare @Company2 Varchar(Max)
          , @RedTagType2 Char(1)
          , @RedTagUse2 Varchar(500);

        Set @Company2 = @Company;
        Set @RedTagType2 = @RedTagType;
        Set @RedTagUse2 = @RedTagUse;

        Create Table [#Results]
            (
              [Company] Varchar(150)
            , [CompanyName] Varchar(150)
            , [OriginalBatch] Varchar(50)
            , [Lot] Varchar(50)
            , [StockCode] Varchar(50)
            , [StockDescription] Varchar(255)
            , [Customer] Varchar(50)
            , [CustomerName] Varchar(255)
            , [JobDescription] Varchar(255)
            , [JobClassification] Varchar(150)
            , [SellingPrice] Numeric(20 , 2)
            , [SalesOrder] Varchar(50)
            , [SalesOrderLine] Varchar(15)
            , [TrnQuantity] Numeric(20 , 8)
            , [TrnValue] Numeric(20 , 2)
            , [TrnType] Varchar(10)
            , [AmountModifier] Int
            , [TrnDate] Date
            , [OldExpiryDate] Date
            , [NewExpiryDate] Date
            , [Job] Varchar(150)
            , [Bin] Varchar(150)
            , [CustomerPoNumber] Varchar(150)
            , [UnitCost] Numeric(20 , 2)
            , [Warehouse] Varchar(200)
            , [Uom] Varchar(10)
            , [Narration] Varchar(500)
            , [Reference] Varchar(500)
            , [TranRank] BigInt
            , [ContainerRank] BigInt
            );									

        Insert  [#Results]
                ( [Company]
                , [CompanyName]
                , [OriginalBatch]
                , [Lot]
                , [StockCode]
                , [StockDescription]
                , [Customer]
                , [CustomerName]
                , [JobDescription]
                , [JobClassification]
                , [SellingPrice]
                , [SalesOrder]
                , [SalesOrderLine]
                , [TrnQuantity]
                , [TrnValue]
                , [TrnType]
                , [AmountModifier]
                , [TrnDate]
                , [OldExpiryDate]
                , [NewExpiryDate]
                , [Job]
                , [Bin]
                , [CustomerPoNumber]
                , [UnitCost]
                , [Warehouse]
                , [Uom]
                , [Narration]
                , [Reference]
                , [TranRank]
                , [ContainerRank]
                )
                Exec [BlackBox].[Report].[UspResults_StockOutput] @Company = @Company2 ,
                    @RedTagType = @RedTagType2 , @RedTagUse = @RedTagUse2;
  
        Insert  [#Results]
                ( [Company]
                , [CompanyName]
                , [OriginalBatch]
                , [Lot]
                , [StockCode]
                , [StockDescription]
                , [Customer]
                , [CustomerName]
                , [JobDescription]
                , [JobClassification]
                , [SellingPrice]
                , [SalesOrder]
                , [SalesOrderLine]
                , [TrnQuantity]
                , [TrnValue]
                , [TrnType]
                , [AmountModifier]
                , [TrnDate]
                , [OldExpiryDate]
                , [NewExpiryDate]
                , [Job]
                , [Bin]
                , [CustomerPoNumber]
                , [UnitCost]
                , [Warehouse]
                , [Uom]
                , [Narration]
                , [Reference]
                , [TranRank]
                , [ContainerRank]
                )
                Exec [BlackBox].[Report].[UspResults_StockDispatches] @Company = @Company2 ,
                    @RedTagType = @RedTagType2 , @RedTagUse = @RedTagUse2;

        Select  [R].[Company]
              , [R].[CompanyName]
              , [R].[OriginalBatch]
              , [R].[Lot]
              , [R].[StockCode]
              , [R].[StockDescription]
              , [R].[Customer]
              , [R].[CustomerName]
              , [R].[JobDescription]
              , [R].[JobClassification]
              , [R].[SellingPrice]
              , [R].[SalesOrder]
              , [R].[SalesOrderLine]
              , [R].[TrnQuantity]
              , [R].[TrnValue]
              , [R].[TrnType]
              , [R].[AmountModifier]
              , [R].[TrnDate]
              , [R].[OldExpiryDate]
              , [R].[NewExpiryDate]
              , [R].[Job]
              , [R].[Bin]
              , [R].[CustomerPoNumber]
              , [R].[UnitCost]
              , [R].[Warehouse]
              , [R].[Uom]
              , [R].[Narration]
              , [R].[Reference]
              , [R].[TranRank]
              , [R].[ContainerRank]
        From    [#Results] As [R];

        Drop Table [#Results];
    End;
GO
