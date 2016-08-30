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
