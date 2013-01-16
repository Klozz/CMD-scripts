:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: getVolRoot.cmd
:: From the desk of Frank P. Westlake, 2012-08-07
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
REM DEFAULTS
Set "$ME=%~n0"
Set "$space= "
If "%*" EQU "/?" Goto :help
Call :parseArgs %* || Goto :EOF
For /F "delims=" %%A in ('%SystemRoot%\System32\mountvol.exe') Do (
  For /F %%a in ("%%A") Do (
    Set "$item=%%a"
    If "!$item:~0,11!"=="\\?\Volume{" (
      Set "$volumeName=%%a"
    ) Else If DEFINED $volumeName (
      Set "$volumePath=%%~A"
      Call :trimSpaces $volumePath
      If NOT "!$volumePath:~0,1!" EQU "*" (
        If "!$volumePath:~-1!" EQU "\" Set "$volumePath=!$volumePath:~0,-1!"
        Call :getLabel !$volumePath!
        If NOT DEFINED $FindLabel (
          Set "$volumeLabel=!$volumeLabel!           "
          Echo(!$volumeLabel:~0,11! !$volumePath!
        ) Else If /I "%$FindLabel%" EQU "!$volumeLabel!" (
          Echo(!$volumePath!
          If NOT DEFINED $ALL Goto :EOF
        )
      )
    )
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:help
For %%a in (
  "%~n0 [/ALL] [VOLUME NAME]"
  ""
  "  /A /ALL       List all mount points for the volume."
  "  VOLUME NAME   The volume to find. Quote if necessary."
  "                If not given then all volumes will be listed."
) Do Echo(%%~a
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:trimSpaces
If "!%~1:~0,1!" EQU "%$space%" (Set "%~1=!%~1:~1!"    & Call %0 %1)
If "!%~1:~-1!"  EQU "%$space%" (Set "%~1=!%~1:~0,-1!" & Call %0 %1)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getLabel
::Volume in drive E: is LABEL
::offset----------------^ Count from zero.
Set "$offset=22"
For /F "delims=" %%Y in (
    '%SystemRoot%\System32\label.exe /MP %~1^<NUL: 2^>NUL:'
    ) Do (
  Set "$volumeLabel=%%Y"
  Set "$volumeLabel=!$volumeLabel:~%$offset%!"
  Goto :EOF
)
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
    "0     $FindLabel"
    "1     $all       /A /ALL"
    "2     $FindLabel /V /VOL /VOLUME"
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
  (Echo %~n0: Unexpected argument '!$!'.)>&2
  EXIT /B 87
)
SHIFT
Goto :parseArgs
Goto :EOF
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
