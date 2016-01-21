CREATE TABLE [dbo].[ExecForEachDBLogs]
(
[LogID] [bigint] NOT NULL IDENTITY(1, 1),
[LogTime] [datetime2] NULL CONSTRAINT [DF__ExecForEa__LogTi__1269A02C] DEFAULT (getdate()),
[Cmd] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
