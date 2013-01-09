:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ads.cmd
:: From the desk of Frank P. Westlake, 2012-08-31
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "name="
Set "last="
Set "ADS="
Set "min=1 "
Set "width=          "
Set "all="
Set "streams="
Set "verbose="
Set "dirArgs="
Call :parseArgs %*
If DEFINED all Set "min=0"
Call :getDirFilenameOffset nameOffset
REM For /F "delims=" %%a in ('DIR /R %dirArgs%') do (
  REM Set "line=%%a"
  REM If /I "!line:~-6!" EQU ":$DATA" (
    REM Set /A "count+=1"
    REM If DEFINED streams (
      REM REM For /F "tokens=2 delims=:" %%N in ("!line:~%nameOffset%!") do Set "ADS=%%N"
      REM REM Echo !width!         "!ADS!"
      REM Echo.%%a
    REM )
  REM ) Else If "!line:~0,1!" NEQ " " (
    REM If DEFINED all (
      REM Echo.%%a
    REM ) Else If DEFINED streams (
      REM If !count! GEQ %min% (
        REM Echo %%a
      REM )
      REM Echo.%%a
    REM ) Else If DEFINED name (
      REM If !count! GEQ %min% (
        REM Set "count=!count!%width%"
        REM Echo !count:~0,10! !last!
      REM )
    REM )
    REM Set "last=%%a"
    REM For /F "delims=:" %%N in ("!line:~%nameOffset%!") do Set "name=%%N"
    REM Set /A "count=0"
  REM ) Else (
    REM If DEFINED name (
      REM If !count! GEQ %min% (
        REM Set "count=!count!%width%"
        REM Echo !count:~0,10! !last!
      REM )
      REM Set "name="
    REM )
    REM Echo %%a
  REM )
REM )
Set "line="
For /F "delims=" %%a in ('DIR /R %dirArgs%') do (
  Set "lastLine=!line!"
  Set "line=%%a"
  If /I "!line:~-6!" EQU ":$DATA" (
    Set /A "count+=1"
    If DEFINED streams (
      If !count! GEQ %min% (
        Echo %%a 1
      )
    )
  ) Else If "!line:~0,1!" NEQ " " (
    If DEFINED streams (
      If !count! GEQ %min% (
        REM If DEFINED name (
          Echo !lastLine! 2
        REM )
        Echo %%a 3
      )
    ) Else If DEFINED name (
      If !count! GEQ %min% (
        Set "count=!count!%width%"
        Echo !count:~0,10! !last! 4
      )
    )
    Set "last=%%a"
    For /F "delims=:" %%N in ("!line:~%nameOffset%!") do Set "name=%%N"
    Set /A "count=0"
  ) Else (
    If DEFINED name (
      If !count! GEQ %min% (
        Set "count=!count!%width%"
        Echo !count:~0,10! !last! 5
      )
      Set "name="
    )
    Echo %%a
  )
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getDirFilenameOffset <varibleName>
SetLocal EnableExtensions EnableDelayedExpansion
For /F "delims=" %%a in ('DIR %~f0 ^| Find /I "%~nx0"') do (
  Set "line=%%a"
)
Set /A "offset=0"
:getDirFilenameOffset.loop
If /I "!line:~%offset%!" NEQ "%~nx0" (
  Set /A "offset+=1"
  Goto :getDirFilenameOffset.loop
)
EndLocal & Set "%~1=%offset%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:parseArgs
If "%~1" EQU "/?" (
  Set "$help=TRUE"
  SHIFT
  Goto :parseArgs
)
Set "$=%~1"
If NOT DEFINED $ Goto :EOF
REM TYPE   VARIABLE   SWITCHES
For %%a in (
    "1     verbose      /V"
    "1     all          /D"
    "1     streams      /W"
) Do (
  For /F "tokens=1,2*" %%1 in (%%a) Do (
    If DEFINED $ (
      If "%%1" EQU "0" (
        If "!$:~0,1!" NEQ "/" (
          If NOT DEFINED %%2 (
            Set "%%2=%~1"
            Set "$="
          )
        )
      ) Else (
        For %%b in (%%3) Do (
          If DEFINED $ (
            If /I "%%b-" EQU "%~1" (
              Set "%%2="
              Set "$="
            ) Else If /I "%%b" EQU "%~1" (
              If "%%1" EQU "1" (
                Set "%%2=TRUE"
                Set "$="
              ) Else If "%%1" EQU "2" (
                Set "%%2=%~2"
                Set "$="
                SHIFT
              )
            )
          )
        )
      )
    )
  )
)
If DEFINED $ (
  Set "dirArgs=!dirArgs!!$! "
)
SHIFT
Goto :parseArgs
Goto :EOF
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
