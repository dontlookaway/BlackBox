SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [Lookups].[vw_DistinctBuyerList]
as
SELECT Distinct 
[B].[BuyerName] FROM [Lookups].[Buyers] As [B]

GO
EXEC sp_addextendedproperty N'MS_Description', N'limit of Buyers for use in look ups', 'SCHEMA', N'Lookups', 'VIEW', N'vw_DistinctBuyerList', NULL, NULL
GO
