CREATE TABLE [Process].[Status_WipSubJobStock]
(
[Job] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Company] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[StartTime] [datetime2] NULL,
[CompleteTime] [datetime2] NULL,
[IsComplete] [bit] NULL CONSTRAINT [DF__Status_Wi__IsCom__1DF06171] DEFAULT ((0))
) ON [PRIMARY]
GO
