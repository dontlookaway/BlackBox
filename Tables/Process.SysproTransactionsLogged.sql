CREATE TABLE [Process].[SysproTransactionsLogged]
(
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SignatureDateTime] AS (dateadd(millisecond,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(7),(2)),(0)),dateadd(second,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(5),(2)),(0)),dateadd(minute,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(3),(2)),(0)),dateadd(hour,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(1),(2)),(0)),CONVERT([datetime],[SignatureDate],(0))))))),
[SignatureDate] [date] NOT NULL,
[SignatureTime] [int] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VariableDesc] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[VariableType] [char] (1) COLLATE Latin1_General_BIN NULL,
[VarAlphaValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VarNumericValue] [float] NULL,
[VarDateValue] [datetime2] NULL,
[ComputerName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[ProgramName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[TableName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[ConditionName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[AlreadyEntered] [bit] NULL CONSTRAINT [DF__SysproTra__Alrea__3587F3E0] DEFAULT ((0))
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_SysproTransactionsLogged_DatabaseName_SignatureDateTime_VariableDesc_ItemKey] ON [Process].[SysproTransactionsLogged] ([DatabaseName], [SignatureDateTime], [VariableDesc], [ItemKey]) INCLUDE ([VarAlphaValue], [VarDateValue], [VarNumericValue]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [SysproTransactionsLogged_Table] ON [Process].[SysproTransactionsLogged] ([TableName]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_SysproTransactionsLogged_TableName_AlreadyEntered] ON [Process].[SysproTransactionsLogged] ([TableName], [AlreadyEntered]) INCLUDE ([TransactionDescription], [DatabaseName], [SignatureDateTime], [Operator], [VariableDesc], [ItemKey], [ComputerName], [ProgramName], [ConditionName]) ON [PRIMARY]

ALTER TABLE [Process].[SysproTransactionsLogged] ADD CONSTRAINT [TDR_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDate], [SignatureTime], [ItemKey], [Operator], [ProgramName], [VariableDesc], [TableName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]

GO
