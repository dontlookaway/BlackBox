CREATE TABLE [History].[ExecForEachDBLogs]
(
[LogID] [bigint] NOT NULL IDENTITY(1, 1),
[LogTime] [datetime2] NULL CONSTRAINT [DF__ExecForEa__LogTi__100234CD] DEFAULT (getdate()),
[Cmd] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
