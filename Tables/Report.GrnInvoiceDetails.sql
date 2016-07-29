CREATE TABLE [Report].[GrnInvoiceDetails]
(
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Supplier] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Grn] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[TransactionType] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[Journal] [int] NULL,
[EntryNumber] [int] NULL,
[Invoice] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PurchaseOrder] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PurchaseOrderLine] [int] NULL,
[Requisition] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[RequisitionLine] [int] NULL,
[GlCode] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[MatchedValue] [decimal] (15, 3) NULL,
[MatchedDate] [date] NULL,
[StockCode] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[QtyReceived] [decimal] (20, 12) NULL,
[MatchedYear] [int] NULL,
[MatchedMonth] [int] NULL,
[MatchedQty] [decimal] (20, 12) NULL,
[Operator] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Approver] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[OrigReceiptDate] [date] NULL,
[LoadDate] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_GrnInvoiceDetails_LoadDate_DatabaseName] ON [Report].[GrnInvoiceDetails] ([LoadDate], [DatabaseName]) INCLUDE ([Approver], [Description], [EntryNumber], [GlCode], [Grn], [Invoice], [Journal], [MatchedDate], [MatchedMonth], [MatchedQty], [MatchedValue], [MatchedYear], [Operator], [OrigReceiptDate], [PurchaseOrder], [PurchaseOrderLine], [QtyReceived], [Requisition], [RequisitionLine], [StockCode], [Supplier], [TransactionType]) ON [PRIMARY]
GO
