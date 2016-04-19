CREATE TABLE [Process].[SysproTransactionsLogged]
(
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SignatureDateTime] AS (dateadd(millisecond,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(7),(2)),(0)),dateadd(second,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(5),(2)),(0)),dateadd(minute,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(3),(2)),(0)),dateadd(hour,CONVERT([int],substring(CONVERT([char](8),[SignatureTime],(0)),(1),(2)),(0)),CONVERT([datetime],[SignatureDate],(0))))))),
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
[AlreadyEntered] [bit] NULL CONSTRAINT [DF__SysproTra__Alrea__3587F3E0] DEFAULT ((0))
) ON [PRIMARY]
ALTER TABLE [Process].[SysproTransactionsLogged] ADD CONSTRAINT [TDR_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDate], [SignatureTime], [ItemKey], [Operator], [ProgramName], [VariableDesc], [TableName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]









GO
