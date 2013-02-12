:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: hex.cmd
:: Prints a hex dump of the given file.
:: From the desk of Frank P. Westlake, 2013-02-11
:: Written on Windows 8.
:: Requires "%SystemRoot%\System32\certutil.exe" (Windows Vista and later).
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "pagePause="
Set "pageHeight="
Set "filein="
Set "quiet=" % REM Either 0 or undefined for false, or 1 for true. %
Set "ME=%~n0"
Set "MESELF=%~f0"
:args
Set "arg=%~1"
If /I "!arg:~0,2!" EQU "/P" (
  Set "pagePause=true"
  If /I "!arg:~2,1!" EQU ":" (
    Set "pageHeight=!arg:~3!"
  )
) Else If /I "%~1" EQU "/Q" (
  Set "quiet=1"
) Else If /I "%~1" EQU "/?" (
  Echo Prints a hex dump of the file or input stream.
  Echo;
  Echo %~0 [/P[:lines]] [/Q]   "FILE"
  Echo %~0 [/P[:lines]] [/Q] ^< "FILE"
  Echo COMMAND ^| %~0 [/P[:lines]] [/Q]
  Echo;
  REM For /F "tokens=1*" %%a in ('CHOICE /? ^| FIND /I "  /?"') Do Echo(  /?  %%b
  For /F "tokens=1*" %%a in ('DIR /? ^| FINDSTR /I /B /C:"  /P"') Do Echo(  /P  %%b
  Echo;      If 'lines' not specified, lines equals buffer height.
  Echo;  /Q  Quiet: no caption.
  Goto :EOF
) Else If /I "%~1" NEQ "" (
  Set "$=%~1"
  If "!$:~0,1!" EQU "/" (
    net helpmsg 87 >&2
    Goto :EOF
  ) Else If NOT DEFINED file (
    Set filein="%~f1"
  ) Else (
    net helpmsg 87 >&2
    Goto :EOF
  )
)
If "%~2" NEQ "" (SHIFT & Goto :args)
Set "MY=%TEMP%\%ME%.%RANDOM%"
MkDir "%MY%" & PushD "%MY%"
FindStr "^" %filein% >bin
CertUtil -encodeHex bin hex >NUL:
If NOT DEFINED pageHeight (
  For /F "tokens=2 delims=: " %%a in ('MODE CON^|FIND "Lines"') Do Set /A "pageHeight=%%a"
)
If DEFINED pagePause (
  For /F %%a in ('COPY /Z "!MESELF!" NUL:') Do (
    For /F "delims=" %%b in ('PAUSE^<NUL:') Do Set "pausing=%%b%%a"
  )
)
Set "banner=         0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F   0123456789ABCDEF"
If NOT DEFINED quiet Echo;%banner%
Set /A "pageHeight-=2-quiet, n=pageHeight"
For /F "delims=" %%a in (hex) Do (
  If !n! EQU 0 (
    If NOT DEFINED quiet Echo;%banner%
    If DEFINED pagePause (
      Set /P "=!pausing!"<NUL:
      PAUSE <CON: >NUL:
    )
  )
  Echo;%%a
  Set /A "n=(n+1) %% pageHeight"
)
:cleanup
PopD & RD /S /Q "%MY%"
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
