CREATE TABLE [Lookups].[CurrencyRates]
(
[StartDateTime] [datetime] NULL,
[EndDateTime] [datetime] NULL,
[Currency] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CADDivision] [numeric] (12, 7) NULL,
[CHFDivision] [numeric] (12, 7) NULL,
[EURDivision] [numeric] (12, 7) NULL,
[GBPDivision] [numeric] (12, 7) NULL,
[JPYDivision] [numeric] (12, 7) NULL,
[USDDivision] [numeric] (12, 7) NULL,
[CADMultiply] [numeric] (12, 7) NULL,
[CHFMultiply] [numeric] (12, 7) NULL,
[EURMultiply] [numeric] (12, 7) NULL,
[GBPMultiply] [numeric] (12, 7) NULL,
[JPYMultiply] [numeric] (12, 7) NULL,
[USDMultiply] [numeric] (12, 7) NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'history of currency rates', 'SCHEMA', N'Lookups', 'TABLE', N'CurrencyRates', NULL, NULL
GO
