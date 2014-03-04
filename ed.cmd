:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ed.cmd
:: An EDLIN style text editor.
:: From the desk of Frank P. Westlake, 2012-04-12.
:: Provides a quick and simple means of editing files from the command line.
:: 2012-08-21 Added line count.
:: 2012-07-26 Fixed command E so that it does not expand variables. -FPW
::            Command C optionally accepts parameters and returns. -FPW
::              Example: C "cls & TYPE demo.cmd >> %work%"
:: 2012-07-15 Allow multiple commands per command line separated by ';'. -FPW
::              Example: K; L 1-10; L 15-30
::            Allow commands quoted on command line. -FPW
::              Example: ed "file"  "L 1-10; S /C:"test"; Q;"
::            Allow pipes and redirected input with A, E, and I. -FPW
::              Example: Echo Inserted at 3 | ed file "i 3; w; l; q"
::              Example: ed file "i 1; w; l; q" < FILE
:: 2012-07-14 Added command 'N'. -FPW
:: 2012-07-14 Allow editing of alternate data streams. -FPW
::            Example: ed file:stream
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "ME=%~n0"
If "%~1" EQU ""   Call :commandLineHelp & Goto :EOF
If "%~1" EQU "/?" Call :commandLineHelp & Goto :EOF
:: CONFIGURATION
REM Set "ATTR=/A:09"                & REM Color of line numbers when listed.
Set "commandListPrompt=true"    & REM i.e. command [?ACD...]: 
REM Set "commandListSpaced=true"    & REM i.e. command [? A C D ... ]: 
Set "warnUnsaved=true"          & REM If quitting, warn if changes are unsaved.
REM Set "comspecArguments=/U /V:ON" & REM Default arguments for thw C command.
Set "CLIP=%SystemRoot%\System32\clip.exe"
:: END OF CONFIGURATION
Set "File=%~f1"
Set "Work=%TEMP%\%~n0.%RANDOM%.tmp"
Set "dirty="
Set "quit="
Set "command="

:: Allow an initial set of commands on command line.
If "%~2" NEQ "" Set "command=%~2"

:: Messages for language translation.
::Set "msg.mktemp=Writing the working copy: %work%"
Set "msg.mktemp="
Set "msg.enter=Enter text; CTRL-Z on a new line to finish."
Set "msg.edit=Use console menu to paste the current line; CTRL-Z on a new line to finish."
Set "msg.unsaved=The altered file has not been saved. Exit and lose changes?"
Set "msg.howsave=Use command W to save changes."
Set "msg.exitPrompt=Exit [Y/N]: "
Set "msg.newFile=New file: %file%"
Set "msg.noClip=The application %CLIP% is not found."
:: More translation should be done to documentation in the command subroutines.
:: To simplify the task of translating the subroutine documentation all of the
:: lines which  begin with :command? can be moved to here -- their location in
:: the file is not important to proper functioning of the script.

(FindStr "^"<"%File%">"%Work%") 2>NUL: && (
  For %%a in ("%File%") Do (
    Echo %%~aa %%~ta %%~za %%~fa
  )
) || (
  Echo;%msg.newFile%
  TYPE NUL:>"%Work%"
)
Call :command-#
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getCommand
If DEFINED quit Goto :EOF
If "!command!" EQU "" Echo;
If NOT DEFINED command Call :makePrompt
:parseCommandLine
For /F "tokens=1* delims=;" %%a in ("!command!") Do (
  Set "command=%%a"
  Call :ltrim
  Call :isHelpRequest %%a || If "!command!" NEQ "" Call :command-!command!
  If "%%b" NEQ "" (
    Set "command=%%b"
    Goto :parseCommandLine
  )
)
Set "command="
Goto :getCommand

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:makePrompt
REM If "!command!" NEQ "" Echo;
REM Set "command="
If /I "%commandListPrompt%" NEQ "true" (
  Set /P "command=command: "
  Goto :EOF
)
Set /P "=command ["<NUL:
For /F "delims=: " %%a in ('TYPE %~f0^|FindStr /B ":command-"^|SORT') Do (
  Set "item=%%a"
  If /I "%commandListSpaced%" EQU "true" (
    Set /P "=!item:*-=! "<NUL:
  ) Else (
    Set /P "=!item:*-=!"<NUL:
  )
)
Set /P "command=]: "
Goto :EOF
REM This program may edit itself if no changes are made above this line.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ltrim
If "!command:~0,1!" EQU " " (
  Set "command=!command:~1!"
  Call :ltrim
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:isHelpRequest
If "%~1" EQU "?" (
  If "%~2" EQU "" (
    Call :command-?
    EXIT /B 0
  )
)
:: Allows "C ?", "? C", "C?", and "?C".
For /F "tokens=1,2" %%a in ("!command!") Do (
  Set "ab=%%a%%b"
  Set "c=!ab:?=!"
  If "!ab!" NEQ "!c!" (
    For /F "delims=" %%c in (
      'TYPE %~f0^|FindStr /B /I /C:":command-!c!"'
    ) Do (
      Set "line=%%c"
      Echo;!line:*-=!
    )
    For /F "tokens=1* delims=?" %%c in (
      'TYPE %~f0^|FindStr /B /I /C:":!c!?"'
    ) Do (
      Echo;%%d
    )
    EXIT /B 0
  )
)
EXIT /B 1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:commandLineHelp
Echo Console command line text file editor.
Echo;
Echo   %ME% ^<file^> ["command line"]
Echo   %ME% ^<file^> ["command line"] ^<inputFile
Echo   COMMAND ^|  %ME% ^<file^> ["command line"]
Echo;
Echo While in the editor enter ? for a list of commands.
Echo;
Echo Multiple commands on a command line should account for the 
Echo possibility that line numbers may change during preceding 
Echo operations.
Echo;
Echo Input from pipe or redirection will be accepted by the APPEND
Echo (A), EDIT (E), and INSERT (I) commands.
Echo;
Echo The command EDIT (E) will not be available if the comand CLIP
Echo is not available and the path set in the CLIP variable.
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:showCommands
:: Show commands:
Set /P "=commands: "<NUL:
For /F "delims=: " %%a in ('TYPE %~f0^|FindStr /B ":command-"^|SORT') Do (
  Set "command=%%a"
  Set /P "=!command:*-=!"<NUL:
)
Echo;
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: COMMANDS
:: To enhance the visual display, single-letter commands should be
:: uppercase and multi-letter commands should have only the first
:: letter uppercase (i.e. 'Clear').
:: 
:: Text on the label line is used when printing a command summary.
:: Text with labels ':<command>?' is used when printing additional
:: help with the '<command> ?' command. 
:: 
 UNUSED: B G H J T U V X Y Z
:: 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-?: Show a summary of all commands or help for a specific command.
::?: 
Echo Separate commands with semicolon: command ; command; command
For /F "delims=" %%a in ('TYPE %~f0^|FindStr /B /I /C:":command-"^|SORT') Do (
  Set "line=%%a"
  Echo !line:*-=!
)
Echo ^<command^> ? More help on a specific command.
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-A: Append new lines to the file, CTRL-Z on new line to finish.
:A? More than one line may be added.
:A? Example: A
Set "dirty=1"
Echo;APPEND: %msg.enter%
REM Type CON:>>"%Work%"
FINDSTR "^">>"%Work%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-C [arguments]: Console command line interpreter.
:C? Default CMD arguments are in the variable 'comspecArguments' at 
:C? the top of this script file.
:C?
:C? If command C is followed by arguments then 'CMD /C%*' is invoked.
:C?   Example: C "cls & dir /r %file%"
If "%~1" NEQ "" (
  %ComSpec% %comspecArguments% /C%*
  Goto :EOF
)
SetLocal
Set "prompt=[%ME%]%prompt%"
%ComSpec% %comspecArguments%
EndLocal
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-D <line[-line]>: Delete lines by number or range.
:D? There may be no spaces in a range.
:D? Example: D 5-10
SetLocal EnableExtensions DisableDelayedExpansion
For /F "tokens=1,2 delims=-" %%a in ("%1") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
Set /A "cp=0"
If NOT DEFINED range.high Set "range.high=%range.low%"
Set "first=1"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  If DEFINED first (
    TYPE NUL:>"%Work%"
    Set "first="
  )
  Set "ok=1"
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  For /L %%j in (%range.low%, 1, %range.high%) Do (
    If %%j EQU !cp! (Set "ok=")
  )
  If DEFINED ok (
    (Echo;!line:*:=!)>>"%Work%"
  )
  EndLocal
)
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-E <line>: Edit a line; CTRL-Z on a new line to finish.
:E? The line is copied into the clipboard and may be pasted into
:E? the console for editing by a right-click if the console is in
:E? QuickEdit mode, or by using the console menu.
:E? Example: E 3
If NOT EXIST "%CLIP%" (
  Echo;%msg.noClip%
  Goto :EOF
)
SetLocal EnableExtensions DisableDelayedExpansion
Set /A "ip=%1, cp=0"
Set "first=1"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  If DEFINED first (
    TYPE NUL:>"%Work%"
    Set "first="
  )
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  If !cp! EQU !ip! (
    Echo;%msg.edit%
    Set "oneLine=%TEMP%\%~n0.%RANDOM%.tmp"
	Set /P "=!line:*:=!"<NUL:>"!oneLine!"
    "%CLIP%"<"!oneLine!"
	ERASE "!oneLine!"
    REM Set /P "=!line:*:=!"<NUL:|"%CLIP%"
    FINDSTR "^">>"%Work%"
  ) Else (
    (Echo;!line:*:=!)>>"%Work%"
  )
  EndLocal
)
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-F: Show file information.
::F? 
Set /P "=ORIGINAL: "<NUL:
For %%a in ("%File%") Do (Echo %%~aa %%~ta %%~za-bytes %%~fa)
Set /P "=EDITS:    "<NUL:
For %%a in ("%Work%") Do (Echo %%~aa %%~ta %%~za-bytes %%~fa)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-I <line>: Insert new lines to the file, CTRL-Z to finish.
:I? Insert new lines to the file, CTRL-Z to finish.The existing line
:I? at this position will appear below the inserted lines.
:I? Example: I 5
SetLocal EnableExtensions DisableDelayedExpansion
Set /A "ip=%1, cp=0"
Set "first=1"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  If DEFINED first (
    TYPE NUL:>"%Work%"
    Set "first="
  )
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  If !cp! EQU !ip! (
    Echo;INSERT: %msg.enter%
    REM Type CON:>>"%Work%"
    FINDSTR "^">>"%Work%"
  )
  (Echo;!line:*:=!)>>"%Work%"
  EndLocal
)
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-K: Clears the screen.
:K? Clears the screen.
:K? Example: K
CLS
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-L [line[-line]]: List the contents of the file.
:L? Lists the contents of the file, line, or range of lines with each
:L? line prefixed with it's number. The line number is not part of the
:L? file contents.
:L? Example: L 1-5
If "%~1" EQU "" (
  FindStr %ATTR% /N "^" "%Work%"
  Goto :EOF
)
SetLocal EnableExtensions DisableDelayedExpansion
For /F "tokens=1,2 delims=-" %%a in ("%1") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
Set /A "cp=0"
If NOT DEFINED range.high Set "range.high=%range.low%"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  For /L %%j in (%range.low%, 1, %range.high%) Do (
    If %%j EQU !cp! Echo;!line!
    REM If %%j EQU !cp! Echo;%%a
  )
  EndLocal
)
EndLocal
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-M: List the file through MORE.
::M?
FindStr /N "^" "%Work%"|MORE
Goto :EOF 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-N: <file>: Write all previous changes to the a new file.
:N? Copies the working copy to a new file. The new file will
:N? be the destination for all subsequent writes.
:N? Example: N newName.txt
Set "ok=Y"
(FindStr "^"<"%~f1">NUL:) 2>NUL: && Set /P "ok=Overwrite %~f1? [Y/N]: "
If /I "%ok%" EQU "Y" FindStr "^" "%Work%">"%~f1" && (
  Set "dirty="
  Set "File=%~f1"
)
Call :command-F
Call :command-#
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-O <line[-line]> <column> <string>: Insert the string into each line at <offset>.
:O? Positive numbers are an offset from the beginning of the line and
:O? negative numbers are an offset from the end of the line. 
:O? "0" is the beginning of the line and "-0" is the end of the line.
:O? Example: O 1-5 0 ":: "
If "%~2" EQU "-0" (
  Call %0 %1 0xFFFFFFFF %3
  Goto :EOF
)
SetLocal EnableExtensions DisableDelayedExpansion
Set "string=%~3"
For /F "tokens=1,2 delims=-" %%a in ("%1") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
Set /A "cp=0"
If NOT DEFINED range.high Set "range.high=%range.low%"
Set "first=1"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  If DEFINED first (
    TYPE NUL:>"%Work%"
    Set "first="
  )
  Set "ok="
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  Set "line=!line:*:=!"
  For /L %%j in (%range.low%, 1, %range.high%) Do (
    If %%j EQU !cp! (Set "ok=1")
  )
  If DEFINED ok (
    (Echo;!line:~0,%2!!string!!line:~%2!)>>"%Work%"
  ) Else (
    (Echo;!line!)>>"%Work%"
  )
  EndLocal
)
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-P [line[-line]]: Print contents of the file.
:P? Prints the contents of the file, line, or range of lines to the
:P? console, No line numbers are printed.
:P? Example: P 1-5
If "%~1" EQU "" (
  FindStr "^" "%Work%"
  Goto :EOF
)
SetLocal EnableExtensions DisableDelayedExpansion
For /F "tokens=1,2 delims=-" %%a in ("%1") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
Set /A "cp=0"
If NOT DEFINED range.high Set "range.high=%range.low%"
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A "cp+=1"
  Set "line=%%a"
  SetLocal EnableExtensions EnableDelayedExpansion
  For /L %%j in (%range.low%, 1, %range.high%) Do (
    If %%j EQU !cp! Echo;!line:*:=!
  )
  EndLocal
)
EndLocal
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-Q: Quit.
::Q?
If DEFINED warnUnsaved (
  If DEFINED dirty (
    Echo;%msg.unsaved%
    Set /P "ok=%msg.exitPrompt%"
    If /I "!ok!" NEQ "Y" (
      Echo;%msg.howsave%
      Goto :EOF
    )
  )
)
Set "quit=1"
ERASE "%Work%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-R: Revert to the original.
::R? 
::Echo;%msg.mktemp%
FindStr "^"<"%File%">"%Work%" && (
  Set "dirty="
) || (
  If EXIST "%Work%" (
    TYPE NUL>"%Work%"
  )
)
Call :command-F
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-S <FindStr command line>: Search file using FINDSTR.
:S? Applies the arguments to a FINDSTR search of the file.
:S? For example, 'S /N /I /C:"gold"' looks for "gold" in the file,
:S? not case sensitive, and prints line numbers.
FindStr %* "%Work%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-W: Write all previous changes to the original file.
:W? Copies the working copy back to the original file. This is the
:W? only way that the original file can be written to.
:W? Example: W
FindStr "^" "%Work%">"%File%" && Set "dirty="
Call :command-f
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:command-#: Display the number of lines.
Set /A lineCount=0
For /F "delims=" %%a in ('FindStr /N "^" "%Work%"') Do (
  Set /A lineCount+=1
)
Echo Lines=%lineCount%
Goto :EOF

:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
