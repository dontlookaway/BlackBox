CREATE TABLE [Lookups].[StockCode]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[StockCode] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[StockDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PartCategory] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ActivePOFlag] [bit] NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_StockCode_PartCategory] ON [Lookups].[StockCode] ([PartCategory]) INCLUDE ([Company], [StockCode], [StockDescription]) ON [PRIMARY]
GO
