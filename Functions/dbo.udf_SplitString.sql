SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create --drop --alter
Function [dbo].[udf_SplitString]
    (
      @DelimittedString [VARCHAR](Max) --Text to be split
      ,@Delimiter [VARCHAR](1)  --delimiter to be used
    ) 
/*
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///			Function designed by Chris Johnson, Prometic Group September 2015														///
///																																	///
///			Function set out to create a table from a delimited text field for use in stored procedures & SSRS						///
///																																	///
///																																	///
///			Version 1.0																												///
///																																	///
///			Change Log																												///
///																																	///
///			Date		Person					Description																			///
///			7/9/2015	Chris Johnson			Initial version created																///
///			??/??/201?	Placeholder				Placeholder																			///
///			??/??/201?	Placeholder				Placeholder																			///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

--define return table
Returns @Table TABLE ( Value VARCHAR(250) )

    Begin 

		--End text to be split with a comma
        Set @DelimittedString = COALESCE(@DelimittedString, '') + @Delimiter
        
		--iterate through the text, removing each field individually and trimming the text field
		While LEN(@DelimittedString) > 0
            Begin 
                Insert @Table (Value)
                        Select Value = SUBSTRING(@DelimittedString, 1,
                                      CHARINDEX(@Delimiter, @DelimittedString) - 1)
      
                Set @DelimittedString = RIGHT(@DelimittedString,
                                   LEN(@DelimittedString) - CHARINDEX(@Delimiter, @DelimittedString))
            End; 
        Return; 
    End; 





GO
EXEC sp_addextendedproperty N'MS_Description', N'function used to parse multiple values separated by a delimiter', 'SCHEMA', N'dbo', 'FUNCTION', N'udf_SplitString', NULL, NULL
GO
