:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: filetime.cmd
:: Calculates the 64-bit integer NTFS filetime of the file.
:: WARNING: DO NOT USE AFTER 8406-02-09 14:29:18.9999999 local.
:: From the desk of Frank P. Westlake, 2013-03-22
:: Requires WMIC.exe.
:: The purpose of this script is to distribute the subroutine and
:: to provide a demonstration of that subroutine.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "$ME=%~n0"
Set "$MESELF=%~f0"
If "%~1" EQU ""   Set "$help=true"
If "%~1" EQU "/?" Set "$help=true"
If DEFINED $help (
  Echo Gets the NTFS filetime for the file.
  Echo;
  Echo   !$ME! [/ENV[:variable]] [/C^|/A^|/W] ^<file^>
  Echo;
  Echo   /ENV      Set the result into a variable. If the name of a variable does
  Echo             not follow ':' then the result will be set into the variable 
  Echo             with the name of this script ("!$ME!"^).
  Echo   /A        The last access time of the file.
  Echo   /C        The creation time of the file.
  Echo   /W        The last write time of the file. This is the default.
  Echo   /X        Make the result hexadecimal.
  Echo   variable  The name of the variable to set the result into.
  Echo   file      The name of the file to read the time attribute of.
  Echo;
  Echo If /ENV is not specified then the result will be printed.
  Echo;
  Echo WARNING: DO NOT USE AFTER 8406-02-09 14:29:18.9999999 local.
  EXIT /B 0
)
:args
Set "$arg=%~1"
       If /I "!$arg!"      EQU "/A"   ( Set "$which=/A" 
) Else If /I "!$arg!"      EQU "/C"   ( Set "$which=/C" 
) Else If /I "!$arg!"      EQU "/W"   ( Set "$which=/W"
) Else If /I "!$arg:~0,4!" EQU "/ENV" ( Set "$env=!$arg:~5!"
  If NOT DEFINED $env Set "$env=!$ME!"
) Else If NOT DEFINED $file           ( Set "$file=!$arg!"
) Else (
  For /F "delims=" %%a in ('net helpmsg 87') Do Echo;!$ME!: "!$arg!": %%a >&2
  Exit /B 87
)
If "%~2" NEQ "" (SHIFT & Goto :args)
If NOT DEFINED $file (
  For /F "delims=" %%a in ('net helpmsg 87') Do (
    If "%%a" NEQ "" Echo;%%a |hexd
  )
  Exit /B 87
)
If NOT EXIST "!$file!" (
  For /F "delims=" %%a in ('net helpmsg 2') Do Echo;!$ME!: "!$arg!": %%a >&2
  Exit /B 2
)
If NOT DEFINED $which Set "$which=/W"
If DEFINED $env (
  EndLocal
  Call :filetime %$env% %$file% %$which%
) Else (
  Call :filetime  $env  %$file% %$which%
  Echo;!$env!
)
If %ErrorLevel% NEQ 0 (
  For /F "delims=" %%a in ('net HELPMSG %ErrorLevel%') Do (
    (Echo;!$ME!: %%a)>&2
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:filetime <variable name for result> <filename> [/c | /a | /w]
:: From the desk of Frank P. Westlake, 2013-03-22
:: Calculates the 64-bit integer NTFS filetime of the file.
:: WARNING: DO NOT USE AFTER 8406-02-09 14:29:18.9999999 local.
:: A filetime of 0 indicates an error condition; check the ERRORLEVEL.
:: PARAMETERS ('+'=required, '-'=optional):
:: + %1 The name of the variable to set the filetime into.
:: + %2 The name of the file.
:: - %3 A switch indicating which filetime to retrieve.
::      /A   The last access time of the file.
::      /C   The creation time of the file.
::      /W   The last write time of the file. This is the default.
:: Requires WMIC.exe.
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set /A "$error=0"
Set "$name=%~f2"
       If /I "%~3" EQU "/C" ( Set "$which=CreationDate"
) Else If /I "%~3" EQU "/A" ( Set "$which=LastAccessed"
) Else If /I "%~3" EQU "/W" ( Set "$which=LastModified"
) Else                      ( Set "$which=LastModified" % REM Default %
)
For /F "tokens=1,2 delims==" %%a in (
  'WMIC dataFile where name^="!$name:\=\\!" get !$which! /format:list'
) Do (
  If "%%~b" NEQ "" (
    Set    "$=%%~b"
    Set /A "$y=!$:~0,4!, $m=1!$:~4,2!-100, $d=1!$:~6,2!-100, $b=!$:~21!"
    Set /A "$a=(14-$m)/12, $y=$y-1601-$a, $m=$m+12*$a-3"
    Set /A "$ft=$d+(153*$m+2)/5+365*$y+$y/4-$y/100+$y/400+58"
    Set /A "$s=1!$:~8,2! -100, $s=1!$:~10,2!-100+$s*60+$b*-1, $s=1!$:~12,2!-100+60*$s"
    If $s LSS 0 (Set /A "$ft-=1, $s+=24*60*60")
    If !$ft! GEQ 2485514 (
      REM OVERFLOW: "2485514 * 24 * 6 * 6 = 0x800001C0"
      Set /A "$error=534, $ft=0"
    ) Else (
      Set /A "$ft=$ft*24*6*6"
      Set    "$ft=!$ft!00"
      For %%A in (0 1 2 3 4 5 6 7 8 9) Do Set "$ft=!$ft:%%A= %%A!"
      For %%A in (!$ft!) Do Set "$tf=%%A !$tf!"
      For %%A in (0 1 2 3 4 5 6 7 8 9) Do Set "$s=!$s:%%A= %%A!"
      For %%A in (!$s!) Do Set "$ts=%%A!$ts!"
      Set "$ft="
      Set /A "$carry=0, $k=0"
      For %%n in (!$tf!) Do (
        For %%k in (!$k!) Do Set "$nB=!$ts:~%%k,1!"
        Set /a "$n=%%n+$nB+$carry"
        Set /A "$carry=0, $k+=1"
        If !$n! GEQ 10 (Set /A "$n-=10, $carry=1")
        Set "$ft=!$n!!$ft!"
      )
      If !$carry! EQU 1 Set "$ft=1!$ft!"
      Set    "$ft=!$ft!!$:~15,6!0"
    )
  )
)
EndLocal & Set "%~1=%$ft%" & EXIT /B %$error%
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
