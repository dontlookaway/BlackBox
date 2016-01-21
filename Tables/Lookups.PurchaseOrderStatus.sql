CREATE TABLE [Lookups].[PurchaseOrderStatus]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[OrderStatusCode] [char] (5) COLLATE Latin1_General_BIN NULL,
[OrderStatusDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
