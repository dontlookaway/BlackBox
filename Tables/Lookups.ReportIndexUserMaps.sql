CREATE TABLE [Lookups].[ReportIndexUserMaps]
(
[ReportIndex2] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[Map] [varchar] (500) COLLATE Latin1_General_BIN NOT NULL,
[IsSummary] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[ReportIndexUserMaps] ADD CONSTRAINT [dsf] PRIMARY KEY CLUSTERED  ([ReportIndex2], [Map], [IsSummary]) ON [PRIMARY]
GO
