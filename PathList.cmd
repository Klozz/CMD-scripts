:: Display PATH as a list
:: Frank P. Westlake, 10:30 2006-06-19
@Echo OFF
SetLocal ENABLEEXTENSIONS
FOR %%a in ("%PATH:;=" "%") Do Echo.%%~a
Goto :EOF
