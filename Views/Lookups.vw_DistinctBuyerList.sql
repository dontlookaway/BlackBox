SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [Lookups].[vw_DistinctBuyerList]
as
SELECT Distinct 
[B].[BuyerName] FROM [Lookups].[Buyers] As [B]
GO
