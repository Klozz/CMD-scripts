:: BEGIN FILE ::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ProgBar.cmd
:: Frank P. Westlake, 2009-07-23
:: Demonstrates a progress bar.
:: Set variable 'size' with the number of times a loop will
:: be accomplished.
@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
Set /A size=1234, progress=0, item=0, last=0
For /F %%a in ('copy /Z "%~f0" NUL:') Do Set "CR=%%a"
Echo.Processing %size% items . . .
:: Save current code page for restoration at completion.
For /F "tokens=2 delims=:" %%a in ('CHCP') Do Set "CP=%%a"
:: Using code page 437 for the character 'Û' in the progress bar.
CHCP 437 >NUL:
:: Progress bar caption.
Set /p "=10 20 30 40 50 60 70 80 90 100%%!CR!"<NUL:
:: 7-bit ASCII progress indicator.
Set "indicator=___"
:: 8-bit progress indicator (Û=DBh, the inverted space character).
::Set "indicator=ÛÛÛ"
::Set "indicator=±±±"
:: A demonstration loop.
For /L %%i in (0 1 %size%) Do (
  Set /A item+=1,progress=item*10/%size%
  If !last! NEQ !progress! (
  	Set /P "=!indicator!"<NUL:
  	Set /A last=progress
  )
	Call :DoNothing
)
:: Terminate the progress bar.
Echo.%indicator:~0,2%
:: Say bye now.
Echo.Bye.
:: Restore the computer operator's code page.
CHCP %CP% >NUL:
:: Goto :EOF.
Goto :EOF


:DoNothing
::Not doing anything yet . . .
:: Goto :EOF again.
Goto :EOF
:: END OF FILE :::::::::::::::::::::::::::::::::::::::::::::::::::
