:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: CompareProcesses.cmd
:: Displays the CPU times of subroutines.
:: From the desk of Frank P. Westlake, 2013-02-05
:: Written on Windows 8.
:: Requires WMIC.exe     (Windows XP?)
:: Requires WaitFor.exe  (Windows Vista?)
:: 2013-02-05 Added Process Life Time values. These are only
:: calculated if the process begins and ends on the same day. I'm
:: not going to the trouble of calculating multiple days until I have
:: a need to do so.
@Echo OFF & Goto :beginning
GENERAL
Use this script to get the CPU times of one or more subroutines or
external programs. Initially this script is prepared as a demonstration
of two subroutines defined below as ":Task_A" and ":Task_B", which
compare the times of using

  For /F "delims=" %%A in ('DIR /S /B "%SystemRoot%\System32"') Do (
    Echo;%%~ftzaA >NUL:
  )

and

  For /R "%SystemRoot%\System32" %%A in (*) Do (
    Echo;%%~ftzaA >NUL:
  )

respectively to enumerate a directory tree.

The subroutine is run as a separate process and the CPU times are of the
instance of CMD.EXE which is used to run that subroutine.

To run the demonstration, just run this script without alterations.

PROCEDURES
1. Create one or more subroutines in this script which are either

  A. complete (they do all the work which is intended to be compared)

  B. or which call an external program.

Type "A" is demonstrated far below as subroutines ":Task_A" and
":Task_B" so the following only demonstrates how to call an external
program:

  ::::::::::::::::::::::::::::::::::::::::::::::::::
  :subroutine_1
  Call "%TEMP%\scriptA.cmd"
  Goto :finish
  ::::::::::::::::::::::::::::::::::::::::::::::::::

Each subroutine must end with the line "Goto :finish". The subroutines
are run as separate processes and the ":finish" subroutine enables this
script to obtain the CPU times from those processes after the
subroutines have completed their work but before they exit.

2. Register the subroutines to be run in the variable "taskList", which
is in the second line after the label ":main".

3. And finally, run this script.

Frank Westlake
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:beginning
SetLocal EnableExtensions EnableDelayedExpansion
Set "ME=%~n0"
Set "MESELF=%~f0"
SetLocal
SHIFT
Goto %* :main
Echo Usage: See the script.
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
REM Register subroutines to be run in "taskList".
Set taskList="Task_A" "Task_B"
REM Write any arguments in "arguments" which should be passed to the
REM subroutines.
Set "arguments="
REM Width of the columns in the table of CPU times.
Set "columnWidth=22"
Goto :work
REM Place your subroutines between this line and the label ":work".

:Task_A
For /F "delims=" %%A in ('DIR /S /B "%SystemRoot%\System32"') Do (
  Echo;%%~ftzaA >NUL:
)
Goto :finish

:Task_B
For /R "%SystemRoot%\System32" %%A in (*) Do (
  Echo;%%~ftzaA >NUL:
)
Goto :finish

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:work
Set "column="
For /L %%i in (1,1,!columnWidth!) Do Set "column=!column! "
Set "GET=KernelModeTime^,UserModeTime^,CreationDate^,ReadOperationCount^,ReadTransferCount^,WriteOperationCount^,WriteTransferCount"
For %%a in (%taskList%) Do (
  For /F "tokens=1,2 delims==;	 " %%b in (
    'WMIC PROCESS Call Create commandLine^="%MESELF% :%%~a !arguments!"^|Find "="') Do (
    Set "%%~a_%%b=%%c"
  )
  WaitFor %ME% >NUL:
  Set "pid=%%~a_processId"
  For /F "delims=" %%b in (
    'WMIC PROCESS where processid^="!%%~a_processId!" get %GET% /format:list^|Find "="') Do (
    For /F "delims=" %%c in ("%%b") Do Set "%%~a_%%c"
  )
  For /F "delims=" %%b in (
    'WMIC OS get LocalDateTime /format:list^|Find "="') Do (
    For /F "delims=" %%c in ("%%b") Do Set "%%~a_%%c"
  )
  WaitFor /SI %ME%exit >NUL:
  Call :addBigInteger %%~a_TotalcpuTime !%%~a_KernelModeTime! !%%~a_UserModeTime!
  If "!%%~a_CreationDate:~0,8!" EQU "!%%~a_LocalDateTime:~0,8!" (
    Set "tm=!%%~a_CreationDate:~8,6!" & Set "tt=1!%%~a_CreationDate:~15,4!"
    Set /A "tm=10000*(60*(60*(1!tm:~0,2!-100)+(1!tm:~2,2!-100))+(1!tm:~4,2!-100))"
    Set /A "%%~a_CreationDate=tm+(tt-10000)"

    Set "tm=!%%~a_LocalDateTime:~8,6!" & Set "tt=1!%%~a_LocalDateTime:~15,4!"
    Set /A "tm=10000*(60*(60*(1!tm:~0,2!-100)+(1!tm:~2,2!-100))+(1!tm:~4,2!-100))"
    Set /A "%%~a_LocalDateTime=tm+(tt-10000)"

    Set /A "%%~a_ProcessLifeTime=%%~a_LocalDateTime-%%~a_CreationDate"
    Set "%%~a_ProcessLifeTime=!%%~a_ProcessLifeTime!000"
  )
)
Set "caption=!column!"
For %%a in (%taskList%) Do (
  Call :FormatVar $ !columnWidth! "%%~a"
  Set "caption=!caption!!$!"
)
Echo;!caption!
For %%a in (
"Read Operation Count" "Read Transfer Count" "Write Operation Count" "Write Transfer Count"
  "Kernel Mode Time"
  "User Mode Time"
  "Total CPU Time"
  "Process Life Time
) Do (
  Set "var=%%~a"
  Call :FormatVar line !columnWidth! "%%~a"
  For %%b in ("!var: =!") Do (
    For %%c in (%taskList%) Do (
      Set "$=!%%~c_%%~b!"
      If /I "!var:~-4!" EQU "Time" (
        Call :minutesSeconds $ "!$!"
      ) Else (
        Set /A "$=$"
        Call :formatInteger $ "!$!"
      )
      Call :FormatVar $ !columnWidth! "!$!"
      Set "line=!line!!$!"
    )
    Echo;!line!
  )
)
Echo;Times are in minutes:seconds.
EndLocal
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:FormatVar <varName> <width> <value>
Set "%~1=%~3!column!"
Set "%~1=!%~1:~0,%~2!"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:addBigInteger <var> <value> <value>
SetLocal EnableExtensions EnableDelayedExpansion
Set "answer="
Set "ms1=0000000%~2" & Set "ms2=0000000%~3"
Set "s1=%~2"         & Set "s2=%~3"
Set "s1=!s1:~0,-7!"  & Set "s2=!s2:~0,-7!
Set /A "ms1=1!ms1:~-7!-10000000, ms2=1!ms2:~-7!-10000000, ms=ms1+ms2"
REM Set /A "ms=(1!ms1:~-7!-10000000)+(1!ms2:~-7!-10000000)"
Set /A "s=s1 + s2 + ms/10000000, ms %%= 10000000"
Set "ms=0000000!ms!"
Set "answer=!s!!ms:~-7!"
:addBigInteger.loop
If "!answer:~0,1!" EQU "0" (
  Set "answer=!answer:~1!"
  Goto :addBigInteger.loop
)
If NOT DEFINED answer Set "answer=0"
EndLocal & Set "%~1=%answer%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:minutesSeconds <var> <n>
SetLocal EnableExtensions EnableDelayedExpansion
Set "ms=0000000%~2"
Set "s=%~2"
Set "s=!s:~0,-7!"
Set /A "m=s/60, s%%=60"
Set "s=0!s!"
EndLocal & Set "%~1=%m%:%s:~-2%.%ms:~-7%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:finish
WaitFor /SI %ME% >NUL:
WaitFor %ME%exit >NUL:
EndLocal
EXIT
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:formatInteger <returnVariableName> <integer> [separator]
SetLocal EnableExtensions EnableDelayedExpansion
Set "answer=" & Set "raw=%~2" & Set "separator=%~3"
If NOT DEFINED separator Set "separator=,"
For /F "delims=:" %%a in ('(ECHO;%~2^& Echo.X^)^|FindStr /O "X"'
) Do Set /A "length=%%a-3"
For /L %%i in (!length!, -3, 1) Do (
  Set "answer=!raw:~-3!!separator!!answer!"
  Set "raw=!raw:~0,-3!"
)
EndLocal & Set "%~1=%answer:~0,-1%"
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
