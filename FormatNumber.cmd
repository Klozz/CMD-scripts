:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FormatInteger.cmd
:: From the desk of Frank P. Westlake, 2013-02-07
:: Written on Windows 8.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:formatNumber <returnVariableName> <number> [separator [group size]]
SetLocal EnableExtensions EnableDelayedExpansion
Set "answer=" & Set "raw=%~2" & Set "separator=%~3" & Set "group=%~4"
If NOT DEFINED separator Set "separator=,"
If NOT DEFINED group     Set "group=3"
For %%G in (-!group!) Do (
  For /F "tokens=1,2 delims=,." %%a in ("%~2") Do (
    Set "int=%%a"
    Set "frac=%%b"
    For /F "delims=:" %%c in ('(ECHO;%%~a^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"'
    ) Do Set /A "length=%%c-3"
    For %%c in (!length!) Do Set "radix=!raw:~%%c,1!"
    For /L %%i in (!length!, %%G, 1) Do (
      Set "answer=!int:~%%G!!separator!!answer!"
      Set "int=!int:~0,%%G!"
    )
  )
)
EndLocal & Set "%~1=%answer:~0,-1%%radix%%frac%"
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
