CREATE TABLE [Lookups].[GLMapping]
(
[GlCode] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[GlStart] [char] (3) COLLATE Latin1_General_BIN NULL,
[GlMid] [char] (5) COLLATE Latin1_General_BIN NULL,
[GlEnd] [char] (3) COLLATE Latin1_General_BIN NULL,
[Mid1] [char] (3) COLLATE Latin1_General_BIN NULL,
[Mid2] [char] (2) COLLATE Latin1_General_BIN NULL,
[Company] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[GlDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Mapping1] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Mapping2] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Mapping3] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Mapping4] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Mapping5] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'GL Mapping as provided by finance 2015', 'SCHEMA', N'Lookups', 'TABLE', N'GLMapping', NULL, NULL
GO
