CREATE TABLE [Lookups].[PurchaseOrderTaxStatus]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[TaxStatusCode] [char] (5) COLLATE Latin1_General_BIN NULL,
[TaxStatusDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
