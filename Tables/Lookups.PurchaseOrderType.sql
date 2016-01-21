CREATE TABLE [Lookups].[PurchaseOrderType]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[OrderTypeCode] [char] (5) COLLATE Latin1_General_BIN NULL,
[OrderTypeDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
