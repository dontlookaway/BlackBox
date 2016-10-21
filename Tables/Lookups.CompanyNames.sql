CREATE TABLE [Lookups].[CompanyNames]
(
[Company] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[CompanyName] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[ShortName] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[Currency] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[CompanyNames] ADD CONSTRAINT [PK_CompanyLastUpdated] PRIMARY KEY CLUSTERED  ([Company], [LastUpdated]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'List of company names used in reports', 'SCHEMA', N'Lookups', 'TABLE', N'CompanyNames', NULL, NULL
GO
