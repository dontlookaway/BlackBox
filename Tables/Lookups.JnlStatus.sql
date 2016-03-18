CREATE TABLE [Lookups].[JnlStatus]
(
[JnlStatus] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[JnlStatusDesc] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[JnlStatus] ADD CONSTRAINT [PK__JnlStatu__5CAFD7D463EA2AD9] PRIMARY KEY CLUSTERED  ([JnlStatus]) ON [PRIMARY]
GO
