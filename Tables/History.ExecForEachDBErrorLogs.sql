CREATE TABLE [History].[ExecForEachDBErrorLogs]
(
[LogID] [bigint] NOT NULL IDENTITY(1, 1),
[LogTime] [datetime2] NULL CONSTRAINT [DF__ExecForEa__LogTi__11EA7D3F] DEFAULT (getdate()),
[Error] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
