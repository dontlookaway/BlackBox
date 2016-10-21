CREATE TABLE [Lookups].[ArInvoicePayTrnType]
(
[TrnType] [char] (1) COLLATE Latin1_General_BIN NULL,
[TrnTypeDesc] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'ArInvoicePay TrnType Descriptions for use in reports', 'SCHEMA', N'Lookups', 'TABLE', N'ArInvoicePayTrnType', NULL, NULL
GO
