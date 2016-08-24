SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [Lookups].[StockCodes_Bought]
as
SELECT [SC].[Company]
     , [SC].[StockCode]
	 , [CompanyStockCode] = [SC].[Company]+' - '+[SC].[StockCode]
     , [SC].[StockDescription]
FROM [Lookups].[StockCode] [SC]
Where [SC].[PartCategory]='B'

 
GO
