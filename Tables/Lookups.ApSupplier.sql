CREATE TABLE [Lookups].[ApSupplier]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Supplier] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[SupplierName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL,
[ActivePOFlag] [bit] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ApSupplier_ActivePOFlag] ON [Lookups].[ApSupplier] ([ActivePOFlag]) INCLUDE ([Supplier], [SupplierName]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'List of all suppliers', 'SCHEMA', N'Lookups', 'TABLE', N'ApSupplier', NULL, NULL
GO
