:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: From the desk of Frank P. Westlake, 2012-12-14
:: rudeGraph.cmd
:: A rudimentary graphing script. 
:: Displays a rotated bar graph from a sample data set. 
:: This script is intended to be only a simple demonstration of this advanced
:: technology. 
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "space= "
Set "ink=                                                            "
Set /A "inkLen=60"
Set "color=A0"
Set "ME=%~n0%"
Call :makeTempDir MY "x" "%ME%"
Pushd "%MY%"
Call :makePen
Call :getMax
Call :getMaxNameLength
Echo Maximum bar length is %maxNameLength%. This limit is caused by the 
Echo maximum filename length of the file system minus the
Echo length of the temporary directory name (%MY:~2%).
Set /A "excessiveBarLength=maxNameLength+1"
Set "data=5 2 4 7 9 16 25 %MaxNameLength% %excessiveBarLength% 7 3 4 2 1"
Call :printCaption
:: Print Graph
For %%n in (%data%) Do (
  Call :drawBar %%n
)
Goto :clean-up
::Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Clean-up
Popd
RmDir /S /Q "%MY%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getMax
Set "max=0"
For %%n in (%data%) Do (
  If !max! LSS %%n Set /A "max=%%n"
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:printCaption
Set "tens=" & Set "units="
For /L %%n in (1 1 %max%) Do (
  Set /A "u=%%n %% 10, n=%%n"
  Set "units=!units!!u!"
  If !u! EQU 0 (Set "tens=!tens!         !n:~-2,1!")
)
Echo;!tens!
Echo;!units!
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:drawBar
If %~1 GTR %inkLen% (
  Set /A "inkLen*=2"
  Set "ink=!ink!!ink!"
  Goto :drawBar
)
Set "bar=!ink:~0,%~1!_"
REM echo "%bar%" & Goto :EOF
If "!pen!" NEQ "!bar!" (Rename "!pen!" "!bar!" 2>NUL:)
If %ErrorLevel% EQU 0 (
  Set "pen=!bar!"
  FindStr /A:!color! "." *
  Set /P "=!ASCII08!"<NUL:
)
Echo;%space%%~1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:makePen
Set "pen=A_file_name_which_will_be_repetively_changed"
Echo.WScript.Echo(Chr(^&H08))>"%pen%"
For /F "delims=" %%a in ('CSCRIPT /NOLOGO /E:VBS "%pen%"') Do (
  Set /P "=%%a %%a"<NUL: >"%pen%"
  Set "ASCII08=%%a"
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:makeTempDir myTemp myName
Set "%~1=%TEMP%\%~2"
MkDir "%TEMP%\%~2"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getMaxNameLength
SetLocal
Set /A "maxNameLength=1"
:: Filename should always be one more then the count because the pen
:: file will have two characters in its name.
Set "maxName=x"
For /L %%i in (1 1 %maxNameLength%) Do Set "maxName=!maxName!x"
Type NUL:>!maxName!
:getMaxNameLength.loop
Set "testName=!maxName!x"
Rename "!maxName!" "!testName!" 2>NUL:
If %ErrorLevel% EQU 0 (
  Set "maxName=!testName!"
  Set /A "maxNameLength+=1"
  Goto :getMaxNameLength.loop
)
Erase !maxName!
EndLocal & Set "maxNameLength=%maxNameLength%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
