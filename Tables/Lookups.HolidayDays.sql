CREATE TABLE [Lookups].[HolidayDays]
(
[Country] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[HolidayDesc] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[HolidayDate] [date] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookups].[HolidayDays] ADD CONSTRAINT [HD_PrimKey] PRIMARY KEY CLUSTERED  ([Country], [HolidayDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [HolidayDays_Date] ON [Lookups].[HolidayDays] ([HolidayDate], [Country]) ON [PRIMARY]
GO
