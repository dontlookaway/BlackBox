CREATE TABLE [Lookups].[BankBalances]
(
[DatabaseName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[CompanyName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Bank] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BankDescription] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[CashGlCode] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[BankCurrency] [char] (3) COLLATE Latin1_General_BIN NULL,
[CurrentBalance] [numeric] (20, 7) NULL,
[StatementBalance] [numeric] (20, 7) NULL,
[OutStandingDeposits] [numeric] (20, 7) NULL,
[OutStandingWithdrawals] [numeric] (20, 7) NULL,
[PrevMonth1CurrentBalance] [numeric] (20, 7) NULL,
[PrevMonth1StatementBalance] [numeric] (20, 7) NULL,
[PrevMonth1OutStandingDeposits] [numeric] (20, 7) NULL,
[PrevMonth1OutStandingWithdrawals] [numeric] (20, 7) NULL,
[PrevMonth2CurrentBalance] [numeric] (20, 7) NULL,
[PrevMonth2StatementBalance] [numeric] (20, 7) NULL,
[PrevMonth2OutStandingDeposits] [numeric] (20, 7) NULL,
[PrevMonth2OutStandingWithdrawals] [numeric] (20, 7) NULL,
[DateOfBalance] [date] NULL,
[DateTimeOfBalance] [datetime2] NULL CONSTRAINT [DF__BankBalan__DateT__09D45A2B] DEFAULT (getdate())
) ON [PRIMARY]
GO
