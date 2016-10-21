SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [Lookups].[vw_StockCodes_Bought_ActivePO]
As
    Select  [SC].[Company]
          , [SC].[StockCode]
          , [CompanyStockCode] = [SC].[Company] + ' - ' + [SC].[StockCode]
          , [SC].[StockDescription]
    From    [Lookups].[StockCode] [SC]
    Where   [SC].[PartCategory] = 'B'
            And [SC].[ActivePOFlag] = 1;

 

GO
EXEC sp_addextendedproperty N'MS_Description', N'limit of StockCodes for use in look ups', 'SCHEMA', N'Lookups', 'VIEW', N'vw_StockCodes_Bought_ActivePO', NULL, NULL
GO
