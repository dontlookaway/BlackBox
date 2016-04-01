CREATE TABLE [Lookups].[PorLineType]
(
[PorLineType] [int] NOT NULL,
[PorLineTypeDesc] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
ALTER TABLE [Lookups].[PorLineType] ADD 
CONSTRAINT [PK__PorLineT__411F3B22B27B447E] PRIMARY KEY CLUSTERED  ([PorLineType]) ON [PRIMARY]
GO
