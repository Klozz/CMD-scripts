:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: batteryGraphic.cmd
:: From the desk of Frank P. Westlake, 2013-01-28
:: For those of us who spend a lot of time on battery power.
:: Written on Windows 8.
:: This script requires "%SystemRoot%\System32\wbem\WMIC.exe".
:: The computer requires a battery.
:: Derived from Rob van der Woude's battstat.bat at
:: <http://www.robvanderwoude.com/sourcecode.php?src=battstat_xp>.
:: If you have a hex editor set mark chracter to hex DB.
@Echo OFF&SetLocal EnableExtensions EnableDelayedExpansion
:User_Configuration ****************************************************
 REM These values may be changed while the script is active.
 Set "mark=Û"            % REM Set this to your desired graphic.      %
 Set "delay=10"          % REM Delay in seconds between updates.      %
 Set "low=20"            % REM Zero to "low" is the low range.        %
 Set "mid=30"            % REM "low" to "mid" is the mid range.       %
                         % REM "mid" to 100 is the high range.        %
 Set "lowColor=0C"       % REM Battery capacity low.                  %
 Set "midColor=0E"       % REM Battery capacity moderate.             %
 Set "highColor=0A"      % REM Battery capacity high to 100%.         %
 Set "fullColor=09"      % REM Battery full and using external power. %
 Set "codePage=437"      % REM Code page.                             %
 REM Local language translations:
 Set "remaining=remaining"
 Set "toCharge=until full"
 Set "recharging=>>"
 Set "discharging=<<"
 Set "full=^"
REM END USER CONFIGURATION ********************************************
REM Continue if just starting, go to :EOF if being CALLed.
If "%0" EQU ":User_Configuration" Goto :EOF
Set "WMIC=%SystemRoot%\System32\wbem\WMIC.exe"
If NOT EXIST "%WMIC%" (
  Echo This script requires "%WMIC%".
  Goto :EOF
)>&2
If "%*" NEQ "/start" (
  START "BATTERY STATE" CMD /c%~f0 /start
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
Set WMIC0=%SystemRoot%\System32\wbem\WMIC.exe /NameSpace:"\\root\WMI" Path
Set WMIC1=%SystemRoot%\System32\wbem\WMIC.exe Path
:: Get a carriage return character.
For /F %%a in ('COPY /Z "%~dpf0" NUL:') Do Set "CR=%%a"
For /L %%i in (1,0,2) Do (
  For /F "delims=" %%A in ('%WMIC0% BatteryStatus Get Charging^,PowerOnline /Format:list ^| FIND "="') Do Set %%A
  For /F "delims=" %%A in ('%WMIC1% Win32_Battery Get EstimatedChargeRemaining^,EstimatedRunTime  /Format:list ^| FIND "="') Do Set /A %%A
  If "!PowerOnline:~0,1!" EQU "T" (
    Set "state=!recharging!"
  ) Else (
    Set "state=!discharging!"
  )
         If !EstimatedChargeRemaining! LSS !low! (
    Color !lowColor!
  ) Else If !EstimatedChargeRemaining! LSS !mid! (
    Color !midColor!
  ) Else If !EstimatedChargeRemaining! EQU 100 (
    If "!Charging:~0,1!" EQU "T" (
      Color !highColor!
    ) Else If "!PowerOnline:~0,1!" EQU "T" (
      Color !fullColor!
      Set "state=!full!"
    ) Else ( REM On battery and discharging.
      Color !highColor!
    )
  ) Else (
    Color !highColor!
  )
  Set "EstimatedTime="
  REM If "!state!" EQU "!recharging!" (
    REM Set /A "EstimatedTime=TimeToFullCharge"
    REM Set "Event=!toCharge!"
  REM ) Else (
    REM Set "Event=!remaining!"
    REM If !EstimatedRunTime! LSS 71582788 (
      REM Set /A "EstimatedTime=EstimatedRunTime"
    REM )
  REM )
  REM If DEFINED EstimatedTime (
    REM Set /A "hours="EstimatedTime/60, EstimatedTime %%= 60"
    REM Set "EstimatedTime=0!EstimatedTime!"
    REM Set "EstimatedTime=!hours!:!EstimatedTime:~-2! !event!"
  REM )
  TITLE !EstimatedChargeRemaining!%%!state! !EstimatedTime!
  For /F %%a in ("!EstimatedChargeRemaining!") Do (
    Set "load=!EstimatedChargeRemaining!%%  "
    Set /P "=!load:~0,4! !bar:~0,%%a!!sp:~%%a! !CR!"<NUL:
  )
  %SLEEP%
  Call :User_Configuration
)
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
