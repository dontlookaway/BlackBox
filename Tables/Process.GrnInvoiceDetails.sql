CREATE TABLE [Process].[GrnInvoiceDetails]
(
[LoadDate] [datetime2] NULL,
[IsComplete] [bit] NULL CONSTRAINT [DF__GrnInvoic__IsCom__0BBCA29D] DEFAULT ((0)),
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
