SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create View [Lookups].[vw_APSuppliersWithActivePO]
As
Select Distinct [AS].[Supplier]
     , [AS].[SupplierName]
From [Lookups].[ApSupplier] [AS]
Where [AS].[ActivePOFlag]=1

GO
EXEC sp_addextendedproperty N'MS_Description', N'limit of Ap suppliers for use in look ups', 'SCHEMA', N'Lookups', 'VIEW', N'vw_APSuppliersWithActivePO', NULL, NULL
GO
