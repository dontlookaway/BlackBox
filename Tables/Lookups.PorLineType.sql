CREATE TABLE [Lookups].[PorLineType]
(
[PorLineType] [int] NOT NULL,
[PorLineTypeDesc] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[PorLineType] ADD CONSTRAINT [PK__PorLineT__67453B017BDF3668] PRIMARY KEY CLUSTERED  ([PorLineType], [LastUpdated] DESC) ON [PRIMARY]
GO
