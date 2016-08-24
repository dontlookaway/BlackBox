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
