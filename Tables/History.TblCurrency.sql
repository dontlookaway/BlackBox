CREATE TABLE [History].[TblCurrency]
(
[TransactionDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SignatureDateTime] [datetime2] NOT NULL,
[Operator] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ItemKey] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[ComputerName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[ProgramName] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[ConditionName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[AlreadyEntered] [bit] NULL,
[BUYECDECLFACTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYECDECLRATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYEXCHANGERATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BUYMULDIVBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DESCRIPTIONBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[EUROBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FIXEDRATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[INTERMEDIATECURBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SELLECDECLFACTBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SELLECDECLRATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SELLEXCHANGERATEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SELLMULDIVBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TOLERANCEBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TRIANGREQDBEFORE] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [History].[TblCurrency] ADD CONSTRAINT [TblCurrency_AllKeys] PRIMARY KEY NONCLUSTERED  ([DatabaseName], [SignatureDateTime], [ItemKey], [Operator], [ProgramName]) WITH (IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
