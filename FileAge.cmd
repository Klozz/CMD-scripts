:: FileAge.cmd
::
:: This entire message body is a script which includes a subroutine to list
:: files of a specified age.
:: This script may be used as is -- called either from the command line or
:: from another script -- or the subroutine may be copied into another
:: script and called as a subroutine.
:: This script should work in all languages (untested) and with any
:: date and time formats. See the subroutine for instructions.
::
:: Frank P. Westlake, 2010-03-06a.
:: The previous version sent today had the correct fix but in the wrong
:: place.
::
@Echo OFF
Call :FileAge %*
Goto :EOF

:: FileAge :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Subroutine :FileAge version 0.21 2010-03-06.
Lists files with an age matching the given criteria. If a callback subroutine
is specified the list will be passed to that subroutine, otherwise it will be
printed to the console.

USAGE
 CALL :FileAge [:CallBack] [compare-op N [unit]] [file spec [file spec ...]]

 All parameters are optional.

 CallBack   The name of the subroutine to call. The subroutine should accept
            two parameters on its command line: the first is the quoted file
            age and the second is the quoted full filename. The subroutine
            will be called once for each file meeting the criteria.
            Additionally, this subroutine has access to the :FileAge
            Environment. Some useful variables in this environment are the
            file's year ($y), month ($m), day ($d), hours ($h), and
            minutes ($m), and the callback subroutine ($CallBack). See the
            script for more. These variables are alterable so that decisions
            can be made and the job changed while it is in progress.

 compare-op A three-letter comparison operator accepted by the IF command:
              EQU NEQ LSS LEQ GTR GEQ

 N          The number of days, hours, or minutes to test for.

 unit       One of the letters D, H, M indicating that N above is in
            days (D), hours (H), or minutes (M).

 file spec  A list of files to examine; wildcards (*?) are accepted.

 EXAMPLES:
   Print the age in days of all files in the current directory:
   Call :FileAge

   Print the age of the specified files if they are greater than 12 hours:
   Call :FileAge GTR 12 H "%TEMP%\*.tmp" "%TEMP%\*.obj"

   Call the subroutine :Clean with files greater than 10 minutes:
   Call :FileAge :Clean GTR 10 M "%FTPdir%\*"

:FileAge [:CallBack] [compare-op N [D|H|M]] [file spec [file spec ...]]
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1* delims==" %%a in ('"Set "$" 2>NUL:"') Do Set "%%a="
REM TRANSLATE THESE ERROR MESSAGES TO YOUR LOCAL LANGUAGE:
  REM "$.ERRORLEVEL=MESSAGE (any length)"
  Set "$.1=Long month names are not supported."
  Set "$.2=Bad format string."
  Set "$.3=W32TM is required for this date format (%%$sShortDate%%)."
REM END OF TRANSLATION.
Set "$Test=EQU 0"
Set "$=%~1" & If "!$:~0,1!" EQU ":" (Set "$CallBack=!$!" & SHIFT)
For %%a in (LSS LEQ EQU GTR GEQ NEQ) Do (If /I "%~1" EQU "%%a" (Set "$op=%~1" & Set /A "$Value=%~2" & Set "$Test=!$op! !$Value!"))
If DEFINED $Value (For %%a in (D H M) Do If /I "%~3" EQU "%%a" (Set "$Unit=%%a"))
For %%a in ($op $Value $Unit) Do If DEFINED %%a SHIFT
If NOT DEFINED $Unit (Set "$Unit=D")
:FileAge.args
If "%~1" NEQ "" (Set $Files=!$Files!"%~1" & SHIFT & Goto :FileAge.args)
If NOT DEFINED $Files Set "$Files=*"
Set "$hInt=HKEY_CURRENT_USER\Control Panel\International"
Set "$hCal=%$hInt%\Calendars\TwoDigitYearMax"
Set "$sShortDate="&For /F "tokens=2*" %%a in ('Reg QUERY "%$hInt%" /V sShortDate') Do Set "$sShortDate=%%b"
If NOT DEFINED $sShortDate Goto :EOF
Set "$sTimeFormat="&For /F "tokens=2*" %%a in ('Reg QUERY "%$hInt%" /V sTimeFormat') Do Set "$sTimeFormat=%%b"
If NOT DEFINED $sTimeFormat Goto :EOF
Set "$=%$sShortDate% %$sTimeFormat%"
Set /A "#=0"&For /F "tokens=1* delims=:" %%a in ('"(Echo.%$%& Echo.)|FindStr /O ^^"') Do Set /A "#=%%a-4"
For %%a in (y m d h n t) Do Set "%%a0="&Set "%%a1=0"
Set /A "O=0, A=0, X=1, M=0"
For /L %%i in (0,1,%#%) Do (
 Set /A "X-=1, O+=A, A=0"
 If !X! LEQ 0 (
REM If DEFINED DEBUG Echo=!O!: "!$:~%%i!"
         If    "!$:~%%i,4!" EQU "MMMM"  (For %%e in (1) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e)
  ) Else If    "!$:~%%i,5!" EQU "yyyyy" (For %%e in (2) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e)
  ) Else If    "!$:~%%i,5!" EQU "ddddd" (For %%e in (2) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e)
  ) Else If /I "!$:~%%i,3!" EQU "hhh"   (For %%e in (2) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e)
  ) Else If    "!$:~%%i,3!" EQU "mmm"   (For %%e in (2) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e)
  REM        FORMAT LEN      FORMAT      ADVANCE  SKIP                            OFFSET   LEN    ALTERNATE OFSET
  ) Else If "!$:~%%i,4!" EQU "yyyy" (Set /A "A=4, X=4" & If NOT DEFINED y0 (Set /A "y0=O, y1=4")
  ) Else If "!$:~%%i,3!" EQU "yyy"  (Set /A "A=4, X=3" & If NOT DEFINED y0 (Set /A "y0=O, y1=4")
  ) Else If "!$:~%%i,2!" EQU "yy"   (Set /A "A=2, X=2" & If NOT DEFINED y0 (Set /A "y0=O, y1=2")
  ) Else If "!$:~%%i,1!" EQU "y"    (Set /A "A=1, X=1" & If NOT DEFINED y0 (Set /A "y0=O, y1=1")
  ) Else If "!$:~%%i,3!" EQU "MMM"  (Set /A "A=3, X=3" & If NOT DEFINED m0 (Set /A "m0=O, m1=3" & If !y1! EQU 1 (Set /A "m2=m0+1"))
  ) Else If "!$:~%%i,2!" EQU "MM"   (Set /A "A=2, X=2" & If NOT DEFINED m0 (Set /A "m0=O, m1=2" & If !y1! EQU 1 (Set /A "m2=m0+1"))
  ) Else If "!$:~%%i,1!" EQU "M"    (Set /A "A=2, X=1" & If NOT DEFINED m0 (Set /A m0=O,m1=2,M=4 & If !y1! EQU 1 (Set /A "m2=m0+1"))
  ) Else If "!$:~%%i,4!" EQU "dddd" (Set /A "A=3, X=4
  ) Else If "!$:~%%i,3!" EQU "ddd"  (Set /A "A=3, X=3
  ) Else If "!$:~%%i,2!" EQU "dd"   (Set /A "A=2, X=2" & If NOT DEFINED d0 (Set /A "d0=O, d1=2" & If !y1! EQU 1 (Set /A "d2=d0+1"))
  ) Else If "!$:~%%i,1!" EQU "d"    (Set /A "A=2, X=1" & If NOT DEFINED d0 (Set /A "d0=O, d1=2" & If !y1! EQU 1 (Set /A "d2=d0+1"))
  REM                                                                                     CLOCK
  ) Else If "!$:~%%i,2!" EQU "hh"   (Set /A "A=2, X=2" & If NOT DEFINED h0 (Set /A "h0=O, hp=1" & If !y1! EQU 1 (Set /A "h2=h0+1"))
  ) Else If "!$:~%%i,1!" EQU "h"    (Set /A "A=2, X=1" & If NOT DEFINED h0 (Set /A "h0=O, hp=1" & If !y1! EQU 1 (Set /A "h2=h0+1"))
  ) Else If "!$:~%%i,2!" EQU "HH"   (Set /A "A=2, X=2" & If NOT DEFINED h0 (Set /A "h0=O, hp=2" & If !y1! EQU 1 (Set /A "h2=h0+1"))
  ) Else If "!$:~%%i,1!" EQU "H"    (Set /A "A=2, X=2" & If NOT DEFINED h0 (Set /A "h0=O, hp=2" & If !y1! EQU 1 (Set /A "h2=h0+1"))
  ) Else If "!$:~%%i,2!" EQU "mm"   (Set /A "A=2, X=2" & If NOT DEFINED n0 (Set /A "n0=O"       & If !y1! EQU 1 (Set /A "n2=n0+1"))
  ) Else If "!$:~%%i,1!" EQU "m"    (Set /A "A=2, X=1" & If NOT DEFINED n0 (Set /A "n0=O"       & If !y1! EQU 1 (Set /A "n2=n0+1"))
  ) Else If "!$:~%%i,1!" EQU "ss"   (Set /A "A=0, X=2"
  ) Else If "!$:~%%i,1!" EQU "s"    (Set /A "A=0, X=1"
  ) Else If "!$:~%%i,2!" EQU "tt"   (Set /A "A=1, X=2" & If NOT DEFINED t0 (Set /A "t0=O" & If !y1! EQU 1 Set /A "t2=t0+1")
  ) Else If "!$:~%%i,2!" NEQ "!$:~%%i,1!s" (Set /A "A=1"
  )
 )
)
Set /A "#=O"
If DEFINED t0 (
  If %hp% EQU 2 Set "t0="
  For /F "tokens=2*" %%B in ('Reg QUERY "%$hInt%" /V s1159') Do Set "$s1159=%%C"
  For /F "tokens=2*" %%B in ('Reg QUERY "%$hInt%" /V s2359') Do Set "$s2359=%%C"
)
If %y1% LEQ 2 (
  For /F "tokens=2*" %%a in ('"Reg QUERY "%$hCal%" /V 1 2>NUL:"') Do Set "$TwoDigitYearMax=%%b"
  If NOT DEFINED $TwoDigitYearMax Set "$TwoDigitYearMax=2029"
  Set "$Century=!$TwoDigitYearMax:~0,-2!"
)
If %m1% EQU 3 (
 If NOT EXIST "%SystemRoot%\System32\W32TM.exe" (For %%e in (3) Do (Call Echo=!$.%%e! >&2 & Exit /B %%e) &  Goto :EOF)
 Set "i=1"
 REM         1610-01    1610-02    1610-03    1610-04    1610-05    1610-06    -01 00:00:00
 REM         1610-07    1610-08    1610-09    1610-10    1610-11    1610-12    -01 00:00:00
 For %%B in (A1732A1F38 A2F8EC4C1C A458F6852C A5DEB8B210 A757E83858 A8DDAA653C
             AA56D9EB84 ABDC9C1868 AD625E454C AEDB8DCB94 B0614FF878 B1DA7F7EC0) Do (
  For /F "tokens=1* delims=-" %%C in ('"w32tm.exe" /ntte 0x%%B000') Do (
    Set "@=%%D" & Set "@=!@:~1!"
    If DEFINED m2 (Set "@=!@:~%m2%,%m1%!") Else (Set "@=!@:~%m0%,%m1%!")
    Set /A "$Month.!@!=i, i+=1"
  )
 )
)
For %%a in (NUL: !$Files!) Do (
  If DEFINED $NOW (
    Set "ft=%%~ta" & If DEFINED $s1159 Set "ft=!ft:%$s1159%=0!" &  If DEFINED $s2359 Set "ft=!ft:%$s2359%=C!"
  ) Else (Set "ft=!DATE:~%M%!")
  If "!ft:~%#%,1!" EQU "" (Set "$y=!ft:~%y0%,%y1%!") Else (Set "$y=!ft:~%y0%,2!")
  If DEFINED $TwoDigitYearMax (
    If "!$y:~1,1!" EQU "" (Set "$y=0!$y!")
    If !$Century!!$y! LEQ !$TwoDigitYearMax! (
             Set /A "$y=(!$Century!  )*100+1!$y!-100"
    ) Else ( Set /A "$y=(!$Century!-1)*100+1!$y!-100"
    )
  )
  If "!ft:~%#%,1!" EQU "" (
    Set /A "$d=1!ft:~%d0%,%d1%!-100, $h=1!ft:~%h0%,2!-100, $n=1!ft:~%n0%,2!-100"
    If !m1! EQU 3 ( Set /A "$m=$Month.!ft:~%m0%,%m1%!"
           ) Else ( Set /A "$m=1!ft:~%m0%,%m1%!-100")
    If DEFINED t0   Set /A "$h=($h%%12)+0x!ft:~%t0%,1!"
  ) Else (
    If DEFINED m2 ( Set "$m=!ft:~%m2%,%m1%!"
           ) Else ( Set "$m=!ft:~%m0%,%m1%!")
    If !m1! EQU 3 ( Set /A "$m=$Month.!$m!"
           ) Else ( Set /A "$m=1!$m!-100")
    If DEFINED d2 ( Set /A "$d=1!ft:~%d2%,%d1%!-100"
           ) Else ( Set /A "$d=1!ft:~%d0%,%d1%!-100")
    If DEFINED h2 ( Set /A "$h=1!ft:~%h2%,2!   -100"
           ) Else ( Set /A "$h=1!ft:~%h0%,2!   -100")
    If DEFINED n2 ( Set /A "$n=1!ft:~%n2%,2!   -100"
           ) Else ( Set /A "$n=1!ft:~%n0%,2!   -100")
           If DEFINED t2 ( Set /A "$h=($h%%12)+0x!ft:~%t2%,1!"
    ) Else If DEFINED t0 ( Set /A "$h=($h%%12)+0x!ft:~%t0%,1!")
  )
  If NOT DEFINED $NOW For /F "tokens=1,2 delims=:,;. " %%b in ("%TIME: =0%") Do Set /A "$h=1%%b-100, $n=1%%c-100"
  Set /A "a=(14-$m)/12, b=$y-a, $days=(153*(12*a+$m-3)+2)/5+$d+365*b+b/4-b/100+b/400"
         If "%$Unit%" EQU "D" (Set /A "$tm=$Days"
  ) Else If "%$Unit%" EQU "H" (Set /A "$tm=$h+$Days*24"
  ) Else If "%$Unit%" EQU "M" (Set /A "$tm=($h+$Days*24)*60+$n")
  If DEFINED $NOW Set /A "$tm=$NOW-$tm"
  Set "$tm=       !$tm!" & Set "$tm=!$tm:~-8!"
         If NOT DEFINED $NOW (Set "$NOW=!$tm!"
  ) Else If DEFINED $op (If !$tm! %$Test% (If DEFINED $CallBack (
    REM SetLocal
    CALL !$CallBack! "!$tm!" "%%~fa"
    REM EndLocal
  ) Else (Echo=!$tm! %%a))
  ) Else If DEFINED $CallBack (
    REM SetLocal
    CALL !$CallBack! "!$tm!" "%%~fa"
    REM EndLocal
  ) Else (Echo=!$tm:~-8! %%a)
)
:EOS
Goto :EOF
