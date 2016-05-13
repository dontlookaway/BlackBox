SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create View [Lookups].[vw_AnalysisCategoryDistinct]
As
    Select Distinct
            [GAC].[GlAnalysisCategory]
    From    [Lookups].[GlAnalysisCategory] [GAC]
GO
