:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: parseArgs.cmd
:: From the desk of Frank P. Westlake, 2012-08-09.
:: Demonstrates a simply configured command line parsing routine. 
::
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
REM Use '$' as a variable prefix and clear all existing:
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
REM SET DEFAULTS
Set "$normallyOn=Defined in the script. Undefine with '/normallyOn-'."
REM PARSE SIMULATED COMMAND LINES:
For %%a in (
  "/all /text stuff"
  "/all /text=stuff"
  "/normallyOn- /normallyOff"
  "/a %ComSpec% %temp%"
  "/NoSuchParameter"
) Do (
  Echo(***************
  Echo Calling :parseArgs %%~a
  SetLocal
    REM Exit if there is an error.
    Call :parseArgs %%~a || Goto :EOF
    Set $
  EndLocal
  Echo(
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:parseArgs
:: From the desk of Frank P. Westlake, 2012-08-09.
:: A command line parsing subroutine. 
::
:: 2012-09-01 Added local language error reporting.-FPW
::
REM REQUIRES DELAYED EXPANSION.

REM PARAMETER SPECIFICATION
REM Specify the parameters in the FOR statement below.
REM In all cases the first column is the parameter type and the second
REM column is the variable to be set. The third and subsequent columns will
REM identify the switchs for all but type 0 parameters. If a switch given on
REM the command line is appended with a hyphen (i.e. /A-) then the respective
REM variable wil be unset. If an argument is not recognized the ERRORLEVEL is
REM set to 87 (ERROR_INVALID_PARAMETER).

REM TYPE USAGE
REM 0    An argument not associated with a switch. The variable will be
REM      set with the argument if it has not already been defined. If it has
REM      already been defined then the next type 0 parameter will be tried.
REM      These parameters must be in the specification in the order in which
REM      they should be set. If there are no more unused type 0 parameters
REM      then the ERRORLEVEL is set to 87 (ERROR_INVALID_PARAMETER).
REM 1    A switch that sets a boolean flag. If the switch occurs and it is
REM      appended with a hyphen then the respective variable is unset; if it
REM      occurs and is not appended with a hyphen then the respective variable
REM      is set to TRUE; otherwise the variable remains as previously defined. 
REM 2    A switch that calls for the next argument to be set in the variable. 
REM      If the switch occurs and it is appended with a hyphen then the
REM      respective variable is unset; if it occurs and is not appended with a
REM      hyphen then the respective variable is set with the next argument;
REM      otherwise the variable remains as previously defined.

REM EXAMPLE
REM COMMAND LINE:   /search /string "find this" "file1" "file2"
REM PARAMETER TYPE:    1       2    (goes to 2)    0       0
REM SPECIFICATION: 
REM                 1 $doSearch /SEARCH
REM                 2 $string   /STRING
REM                 0 $file1
REM                 0 $file2
REM RESULT: '$doSearch' is assigned TRUE, '$string' is assigned "find this",
REM         '$file1' is assigned "file1", '$file2' is assigned "file2", and
REM         additional arguments will cause an error.
If "%~1" EQU "/?" (
  Set "$help=TRUE"
  SHIFT
  Goto :parseArgs
)
Set "$=%~1"
If NOT DEFINED $ Goto :EOF
REM TYPE   VARIABLE   SWITCHES
For %%a in (
    "0     $fileIn"
    "0     $fileOut"
    "1     $all         /A /ALL"
    "1     $normallyOn  /NORMALLYON"
    "1     $normallyOff /NORMALLYOFF"
    "2     $text        /T /TEXT"
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
  if EXIST "%SystemRoot%\System32\net.exe" (
    For /F "delims=" %%a in ('NET HELPMSG 87') do (
      (Set /P "=%~n0: "<NUL:)>&2
      (Echo.%%a)>&2
    )
  )
  EXIT /B 87
)
SHIFT
Goto :parseArgs
Goto :EOF
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
