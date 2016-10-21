CREATE TABLE [Lookups].[InvMaster_PartCategory]
(
[PartCategoryCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PartCategoryDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[LastUpdated] [datetime2] NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'InvMaster Part Category description', 'SCHEMA', N'Lookups', 'TABLE', N'InvMaster_PartCategory', NULL, NULL
GO
