:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: cpuLoadChart.cmd
:: From the desk of Frank P. Westlake, 2013-01-30
:: Written on Windows 8.
:: This script requires "%SystemRoot%\System32\wbem\WMIC.exe".
:: Some versions of WMIC do not provide useful CPU load data.
:: If you have a hex editor set mark chracter to hex DB.
@Echo OFF&SetLocal EnableExtensions EnableDelayedExpansion
:User_Configuration ****************************************************
 REM These values may be changed while the script is active.
 Set "mark=Û"           % REM Set this to your desired graphic.        %
 Set "low=20"           % REM Zero to "low" is the low range.          %
 Set "high=50"          % REM "low" to "high" is the mid range.        %
                        % REM "high" to 100 is the high range.         %
 Set "lowColor=0A"      % REM Low range color.                         %
 Set "midColor=0E"      % REM Mid range color.                         %
 Set "highColor=0C"     % REM High range color.                        %
 Set "reConfig=60"      % REM Read this configuration every x seconds. %
 Set "codePage=437"     % REM Code page.                               %
 Set "saveFile=NUL:"
 REM Set "saveFile=C:\w\cpu.txt"
REM END USER CONFIGURATION *********************************************
REM Continue if just starting, go to :EOF if CALLed.
If "%0" EQU ":User_Configuration" Goto :EOF
If NOT EXIST "%SystemRoot%\System32\wbem\WMIC.exe" (
  Echo This script requires "%SystemRoot%\System32\wbem\WMIC.exe".
  Goto :EOF
)>&2
If "%*" NEQ "/start" (
  START "CPU LOAD HISTORY" CMD /c%~f0 /start
  Goto :EOF
)
CHCP %codePage% >NUL:
MODE CON cols=116
Set "RANDOM=" & Set "TIME="
Set "ME=%~f0"
Set "MY=%TEMP%\%~n0.%RANDOM%%TIME:~-2%"
Set "myFile="
Set "bar="
For /L %%i in (1,1,100) Do Set "bar=!bar!!mark!"
Set "iteration=0"
MkDir "%MY%" & PushD "%MY%"
For /L %%i in (1,0,2) Do (
  For /F "tokens=2 delims==" %%a in ('wmic cpu get loadpercentage /format:list^|Find "="') Do (
    Set /A "load=%%a"
    TITLE !load!%%
           If !load! LSS !low! (
      Set "color=!lowColor!"
    ) Else If !load! LSS !high! (
      Set "color=!midColor!"
    ) Else (
      Set "color=!highColor!"
    )
    Set "line=!TIME:~0,8!"
    For %%b in (!load!) Do Set "line=!line::=;! !bar:~0,%%b!"
    Echo;!load!%% > "!line!"
    FindStr /A:!color! "^^" *
    ERASE "!line!"
    Echo;!line! !load!%% >>"!saveFile!"
  )
  Set /A "iteration+=1, remainder=iteration %% reConfig"
  If !remainder! EQU 0 (
    Set "iteration=0"
    Call :User_Configuration
  )
)
PopD & RD /S /Q "%MY%"
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
