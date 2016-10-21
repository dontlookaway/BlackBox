SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [dbo].[vw_APSuppliersWithActivePO]
as
Select Distinct [AS].[Supplier]
     , [AS].[SupplierName]
FROM [Lookups].[ApSupplier] [AS]
Where [AS].[ActivePOFlag]=1

GO
EXEC sp_addextendedproperty N'MS_Description', N'limit of Ap suppliers for use in look ups', 'SCHEMA', N'dbo', 'VIEW', N'vw_APSuppliersWithActivePO', NULL, NULL
GO
