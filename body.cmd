:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: body.cmd
:: 'body' meaning not necessarily 'head' nor 'tail'.
:: From the desk of Frank P. Westlake, 2012-05-27
@Echo OFF
Goto :main to avoid documentation.
BEGIN DOCUMENTATION
Print the portion of a file which begins and ends with the specified text.
USAGE
File input:
  body [/L] [/s] [/x] [/1] start end filespec [filespec [filespec [...]]]
Redirected input:
  body [/L] [/x] [/1] start [end] < FILE OR DEVICE
Piped input:
  COMMAND | body [/L] [/x] [/1] start [end]

Options
/H     Hide the start and end matching lines.
/N     Print line numbers.
/S     Check for the file[s] in subdirectories.
/X     Match the line exactly. Otherwise the match is of any
       case insignificant occurrance of the text.
/1     Find only the first group of matching lines.
start  Text on the first line to print. Use "" to match a blank line.
end    Text on the last line to print. Use "" to match a blank line.
       Optional for pipes and redirection, in which case the remainder
       of the file is printed.

- Wildcards are accepted for multiple files.
- The filename is printed to file stream 3, which may be 
  redirected to NUL:. For example:
    PrintLines /s "hello" "goodbye" *.txt *.xml 3>NUL:
END DOCUMENTATION
:main
SetLocal EnableExtensions
:: SET DEFAULTS
REM Set "oneMatchPerFile=true"
Set "oneMatchPerFile="
REM Set "subDirs=/R"
Set "subDirs="
REM Set "matchWholeLine=true"
Set "matchWholeLine="
REM Set "lineNumbers=true"
Set "lineNumbers="
REM Set "hideMatchingLines=true"
Set "hideMatchingLines="
:args
If "%~1" EQU "/?" (
  Call %0 /H /X /1 "BEGIN DOCUMENTATION" "END DOCUMENTATION" "%~f0"
  Goto :EOF
) Else If /I "%~1"=="/H" (
  SHIFT & Set "hideMatchingLines=true" & Goto :args
) Else If /I "%~1"=="/H-" (
  SHIFT & Set "hideMatchingLines=" & Goto :args
) Else If /I "%~1"=="/N" (
  SHIFT & Set "lineNumbers=true" & Goto :args
) Else If /I "%~1"=="/N-" (
  SHIFT & Set "lineNumbers=" & Goto :args
) Else If /I "%~1"=="/S" (
  SHIFT & Set "subdirs=/R" & Goto :args
) Else If /I "%~1"=="/S-" (
  SHIFT & Set "subdirs=" & Goto :args
) Else If /I "%~1"=="/X" (
  SHIFT & Set "matchWholeLine=true" & Goto :args
) Else If /I "%~1"=="/X-" (
  SHIFT & Set "matchWholeLine=" & Goto :args
) Else If /I "%~1"=="/1" (
  SHIFT & Set "oneMatchPerFile=true" & Goto :args
) Else If /I "%~1"=="/1-" (
  SHIFT & Set "oneMatchPerFile=" & Goto :args
)
Set arg=%1
If DEFINED arg (Set "start=%~1") Else (Set "start=")
Set arg=%2
If DEFINED arg (Set "end=%~2")   Else (Set "end=")

:Work Cycle through each filespec
Set "file=%~3"
SHIFT
If DEFINED file (
  For %subdirs% %%f in (%file%) Do (
    If EXIST "%%~f" (
      Echo===== %%f ====>&3
      Call :GetLines "%start%" "%end%" "%%f"
    )
  )
) Else (REM Pipe or redirection.
  Call :GetLines "%start%" "%end%"
)
If NOT "%3"=="" Goto :Work
Goto :EOF

::::::::::::::::::::::::::
:GetLines start end file
SetLocal EnableExtensions DisableDelayedExpansion
REM Jeb's 'Echo=!print:*:=!' method might serve better
REM then calculating an offset and removing that portion
REM of the line but I have not tested it yet.
Set /A "L=0, N=10, O=2"
Set "flag="
Set "break="
For /F "delims=" %%T in ('FindStr /n "^" %3') Do (
  Set /A "L+=1, t=N, N*=1+L/N*9, O=O+N/t/10"
  Set "line=%%T"
  Call :PrintLines %1 %2
  If DEFINED break Goto :GetLines.break
)
:GetLines.break
Goto :EOF
::::::::::::::::::::::::::
:PrintLines start end
SetLocal EnableExtensions EnableDelayedExpansion
Set "match="
For /L %%i in (!O!,1,!O!) Do Set "line=!line:~%%i!"
If DEFINED flag (
  If DEFINED end (
    If DEFINED matchWholeLine (
      If "!line!" EQU "%~2" (Set "match=true")
    ) Else (
      If "!line!" EQU "" (
        If "%~2" EQU "" (Set "match=true")
      ) Else If "!line!" NEQ "!line:%~2=!" (
        Set "match=true"
      )
    )
  )
  If DEFINED match (
    Set "flag="
    If DEFINED oneMatchPerFile Set "break=true"
    If NOT DEFINED hideMatchingLines (
      If DEFINED lineNumbers (Set /P "=!L!:"<NUL:)
      Echo(!line!
    )
  ) Else (
    If DEFINED lineNumbers (Set /P "=!L!:"<NUL:)
    Echo(!line!
  )
) Else (
  If DEFINED matchWholeLine (
    If "!line!" EQU "%~1" Set "match=true"
    ) Else (
    If "!line!" EQU "" (
      If "%~1" EQU "" (Set "match=true")
    ) Else If "!line!" NEQ "!line:%~1=!" (
      Set "match=true"
    )
  )
  If DEFINED match (
    If NOT DEFINED hideMatchingLines (
      If DEFINED lineNumbers (Set /P "=!L!:"<NUL:)
      Echo(!line!
    )
    Set "flag=on"
  )
)
EndLocal & Set "flag=%flag%" & Set "break=%break%"
Goto :EOF
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
