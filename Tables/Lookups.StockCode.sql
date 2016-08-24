CREATE TABLE [Lookups].[StockCode]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[StockCode] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[StockDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PartCategory] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
