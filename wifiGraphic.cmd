:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: wifiGraphic.cmd
:: From the desk of Frank P. Westlake, 2013-06-01
:: A single bar graph of the connected WIFI signal strength.
:: Written on Windows 8.
:: If you have a hex editor set mark character to hex DB.
@Echo OFF
@SetLocal EnableExtensions EnableDelayedExpansion
:User_Configuration ****************************************************
 REM These values may be changed while the script is active.
 Set "mark=Û"            % REM Set this to your desired graphic.      %
 Set "delay=1"           % REM Delay in seconds between updates.      %
 Set "low=20"            % REM Zero to "low" is the low range.        %
 Set "mid=50"            % REM "low" to "mid" is the mid range.       %
                         % REM "mid" to 100 is the high range.        %
 Set "lowColor=0C"       % REM Color for low range.                   %
 Set "midColor=0E"       % REM Color for moderate range.              %
 Set "highColor=0A"      % REM Color for high range.                  %
REM END USER CONFIGURATION ********************************************
Set "codePage=437"       % REM Code page.                             %
REM Continue if just starting, go to :EOF if being CALLed.
If "%0" EQU ":User_Configuration" Goto :EOF
If "%*" NEQ "/start" (
  START "WIFI" CMD /c%~f0 /start
  Exit
  Goto :EOF
)
MODE CON lines=1 cols=107
CHCP %codePage% >NUL:
Set "bar="
Set "sp="
For /L %%i in (1,1,100) Do (
  Set "bar=!bar!!mark!"
  Set "sp=!sp! "
)
Set /A "delay*=1000"
Set "SLEEP=PING 127.255.255.255 -n 1 -w !delay! >NUL:"
:: Get a carriage return character.
For /F %%a in ('COPY /Z "%~dpf0" NUL:') Do Set "CR=%%a"
For /L %%i in (1,0,2) Do (
  For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
  Set "$Signal=0%%" & Set "color=!lowColor!"
  For /F "tokens=1,2 delims=:" %%a in ('netSh wlan show interfaces') Do (
    Set "#=%%a" & Set "#=!#: =!"
    Set "$=%%b" & Set "$=!$:~1!" & Set "$!#!=!$!"
    If DEFINED $Profile (
      If /I "!$State!" EQU "connected" (
        Set "load=!$Signal!  "
      )
      Set "$Profile="
    )
  )
  For /L %%s in (!$Signal! 1 !$Signal!) Do (
     Title WIFI %%s
           If %%s LEQ !low! ( Set "COLOR=!lowColor!"
    ) Else If %%s LEQ !mid! ( Set "COLOR=!midColor!"
    ) Else                  ( Set "COLOR=!highColor!"
    )
    Set /P "=!load:~0,4! !bar:~0,%%s!!sp:~%%s! !CR!"<NUL:
    COLOR !color!
  )
  %SLEEP%
  Call :User_Configuration
)
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
