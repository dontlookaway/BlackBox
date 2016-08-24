CREATE TABLE [Lookups].[ApSupplier]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Supplier] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SupplierName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL,
[ActivePOFlag] [bit] NULL
) ON [PRIMARY]
GO
