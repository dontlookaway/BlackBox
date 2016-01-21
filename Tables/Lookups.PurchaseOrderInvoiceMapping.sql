CREATE TABLE [Lookups].[PurchaseOrderInvoiceMapping]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Grn] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Invoice] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PurchaseOrder] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
