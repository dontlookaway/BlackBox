CREATE TABLE [Process].[SysproTransactionsLogged]
(
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SignatureDate] [date] NOT NULL,
[SignatureTime] [int] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VariableDesc] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[VariableType] [char] (1) COLLATE Latin1_General_BIN NULL,
[VarAlphaValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VarNumericValue] [float] NULL,
[VarDateValue] [datetime2] NULL,
[ComputerName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[ProgramName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[TableName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[ConditionName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[AlreadyEntered] [bit] NULL CONSTRAINT [DF__SysproTra__Alrea__3587F3E0] DEFAULT ((0)),
[IsError] [bit] NULL CONSTRAINT [DF__SysproTra__IsErr__18427513] DEFAULT ((0)),
[SignatureDateTime] AS (dateadd(millisecond,CONVERT([int],substring(right('0'+CONVERT([varchar](10),[SignatureTime],(0)),(8)),(7),(2)),(0)),dateadd(second,CONVERT([int],substring(right('0'+CONVERT([varchar](10),[SignatureTime],(0)),(8)),(5),(2)),(0)),dateadd(minute,CONVERT([int],substring(right('0'+CONVERT([varchar](10),[SignatureTime],(0)),(8)),(3),(2)),(0)),dateadd(hour,CONVERT([int],substring(right('0'+CONVERT([varchar](10),[SignatureTime],(0)),(8)),(1),(2)),(0)),CONVERT([datetime],[SignatureDate],(0)))))))
) ON [PRIMARY]
GO
ALTER TABLE [Process].[SysproTransactionsLogged] ADD CONSTRAINT [TDR_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDate], [SignatureTime], [ItemKey], [Operator], [ProgramName], [VariableDesc], [TableName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SysproTransactionsLogged_DatabaseName_SignatureDateTime_VariableDesc_ItemKey] ON [Process].[SysproTransactionsLogged] ([DatabaseName], [SignatureDateTime], [VariableDesc], [ItemKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SysproTransactionsLogged_TableName] ON [Process].[SysproTransactionsLogged] ([TableName]) INCLUDE ([AlreadyEntered], [IsError]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SysproTransactionsLogged_TableName_AlreadyEntered] ON [Process].[SysproTransactionsLogged] ([TableName], [AlreadyEntered]) INCLUDE ([ComputerName], [ConditionName], [DatabaseName], [ItemKey], [Operator], [ProgramName], [SignatureDateTime], [TransactionDescription], [VariableDesc]) ON [PRIMARY]
GO
