:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: hed.cmd
:: An EDLIN style hex editor.
:: From the desk of Frank P. Westlake, 2013-02-19.
:: Provides a quick and simple means of editing binary files from the command line.
:: Get Updated script at: <https://github.com/FrankWestlake/CMD-scripts/blob/master/hed.cmd >
:: HISTORY:
:: 2013-02-17 Original.
:: 2013-02-18 Some cleanup.
:: 2013-02-19 Optimization.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "ME=%~n0"
Set "MESELF=%~f0"
Set "MY=%TEMP%\%~n0.%RANDOM%"
If "%~1" EQU ""   Call :commandLineHelp & Goto :EOF
If "%~1" EQU "/?" Call :commandLineHelp & Goto :EOF
:: CONFIGURATION
Set "commandListPrompt=true"    & REM Show [?ACD...]: 
REM Set "commandListSpaced=true"    & REM Show [? A C D ... ]: 
Set "warnUnsaved=true"          & REM If quitting, warn if changes are unsaved.
REM Set "comspecArguments=/U /V:ON" & REM Default arguments for thw C command.
Set "CLIP=%SystemRoot%\System32\clip.exe"
:: Messages for language translation.
Set "msg.append=Append: "
Set "msg.insert=Insert: "
Set "msg.enter=Enter bytes as hex pairs, i.e.: AF 01 DD"
Set "msg.clipedit=Paste the clipboard into the console, edit the line, then press ENTER."
Set "msg.edit=Edit the following line below it then press ENTER."
Set "msg.unsaved=The altered file has not been saved. Exit and lose changes?"
Set "msg.howsave=Use command W to save changes."
Set "yes=Y"
Set "no=N"
Set "msg.overwritePrompt=Overwrite [%yes%/%no%]: "
Set "msg.exitPrompt=Exit [%yes%/%no%]: "
Set "msg.newFile=New file: %file%"
:: More translation should be done to documentation in the command subroutines.
:: To simplify the task of translating the subroutine documentation all of the
:: lines which  begin with :%mode%-command? can be moved to here -- their
:: location in the file is not important to proper functioning of the script.
:: END OF CONFIGURATION

Set "TAB=	"
For /F "delims=%SP%" %%a in ("1%TAB%") Do If "%%~a" EQU "1" (
  (Echo %~nx0: The script's variable 'TAB' must be defined as a tab character.
   Set /P "=LINE "<NUL:
   FindStr /n /i /c:"TAB=" "%~f0"|FindStr /v "FindStr")>&2
  Goto :EOF
)
Set "File=%~f1"
Set "Work=%MY%\binary"
Set "dirty="
Set "quit="
Set "command="
Set "mode=HEX"
Set "caption=         0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F   0123456789ABCDEF"

:: Allow an initial set of commands on command line. Remove the file name.
Set "command=%*"
Call :strlen $=%1
For %%i in (%$%) Do Set "command=!command:~%%i!"

MkDir "%MY%"

(Copy /b "%File%" "%Work%")>NUL: && (
  For %%a in ("%File%") Do (
    Echo %%~aa %%~ta %%~za %%~fa
  )
 Call :dumpHex
) || (
  Echo;%msg.newFile%
  Call :newFile
)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getCommand
If DEFINED quit Goto :EOF
If "!command!" EQU "" Echo;
If NOT DEFINED command Call :makePrompt
:parseCommandLine
For /F "tokens=1* delims=;" %%a in ("!command!") Do (
  Set "command=%%a"
  Call :ltrim
  Call :isHelpRequest %%a || If "!command!" NEQ "" Call :%mode%-!command!
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
  Set /P "command=command: "<CON:
  Goto :EOF
)
Set /P "=command ["<NUL:
For /F "delims=: " %%a in ('TYPE %~f0^|FindStr /B ":%mode%-"^|SORT') Do (
  Set "item=%%a"
  Set "item=!item:*-=!"
  If "!item:~1,1!" NEQ "?" (
    If /I "%commandListSpaced%" EQU "true" (
      Set /P "=!item! "<NUL:
    ) Else (
      Set /P "=!item!"<NUL:
    )
  )
)
Set /P "command=]: "<CON:
Goto :EOF
REM This program may edit itself if no changes are made above this line.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:strlen <return variable>
For /F "delims=:" %%a in (
  '(Echo;%*^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"'
 ) Do Set /A "%~1=%%a-5"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:dumpHex
CertUtil -f -encodeHex "%work%" "%work%.hex%~1" %~1 >NUL: 2>&1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:rebuild
CertUtil -f -decodeHex "%work%.hex" "%work%" %~1 >NUL: 2>&1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:newFile
TYPE NUL:>"%Work%"
Echo;0000>"%Work%.hex"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ltrim
If "!command:~0,1!" EQU " " (
  Set "command=!command:~1!"
  Call :ltrim
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:commandError
For /F "tokens=2 delims=-" %%a in ("%~1") Do Set "command=%%a?"
:isHelpRequest
If "%~1" EQU "?" (
  If "%~2" EQU "" (
    Call :%mode%-?
    EXIT /B 0
  )
)
:: Allows "C ?", "? C", "C?", and "?C".
For /F "tokens=1,2" %%a in ("!command!") Do (
  Set "ab=%%a%%b"
  Set "c=!ab:?=!"
  If "!ab!" NEQ "!c!" (
    For /F "delims=" %%c in (
      'TYPE %~f0^|FindStr /B /I /C:":%mode%-!c!"'
    ) Do (
      Set "line=%%c"
      Set "line=!line:*-=!"
      If "!line:~1,1!" NEQ "?" Echo;!line!
    )
    For /F "tokens=1* delims=?" %%c in (
      'TYPE %~f0^|FindStr /B /I /C:":%mode%-!c!?"'
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
Echo Console command line hex editor.
Echo;
Echo   %ME% ^<file^> [command line]
Echo   %ME% ^<file^> [command line] ^<inputFile
Echo   COMMAND ^|  %ME% ^<file^> [command line]
Echo;
Echo While in the editor enter ? for the command summary.
Echo;
Echo Multiple commands on a command line should account for the 
Echo possibility that offsets may change during preceding 
Echo operations.
Echo;
Echo Input from pipe or redirection will be accepted by the APPEND
Echo (A), EDIT (E), and INSERT (I) commands. For example, LIST, INSERT
Echo "0D 0A" at offset 0, WRITE (yes), LIST again, and QUIT:
Echo;
Echo   Echo 0D 0A ^| %ME% binaryFile L; I 0; W y; L; Q
Echo;
Echo;
Echo;COMMAND SUMMARY
Set "mode=HEX"
Call :HEX-?
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:showCommands
:: Show commands:
Set /P "=commands: "<NUL:
For /F "delims=: " %%a in ('FindStr /B ":%mode%-" "%MESELF%"^|SORT') Do (
  Set "command=%%a"
  Set /P "=!command:*-=!"<NUL:
)
Echo;
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getRange
For /F "tokens=1,2 delims=-" %%a in ("%*") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
If NOT DEFINED range.high Set "range.high=%range.low%"
Set /A "range.low=%range.low%, range.high=%range.high%"
Set /A "block.start=%range.low%  - (%range.low%  %% 16)"
Set /A "block.end=  %range.high% - (%range.high% %% 16)"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: COMMANDS
:: To enhance the visual display, single-letter commands should be
:: uppercase and multi-letter commands should have only the first
:: letter uppercase (i.e. 'Clear').
:: 
:: Text on the label line is used when printing a command summary.
:: Text with labels ':%mode%-<command>?' is used when printing
:: additional help with the '<command> ?' command. 
:: 
:: 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-?: Show a summary of all commands or help for a specific command.
::?: 
Echo Separate commands with semicolon: command ; command; command
For /F "delims=" %%a in ('FindStr /B /I /C:":%mode%-" %MESELF%^|SORT') Do (
  Set "line=%%a"
  Set "line=!line:*-=!"
  If "!line:~1,1!" NEQ "?" Echo;!line!
)
Echo ^<command^> ? More help on a specific command.
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-A <offset>: Append new bytes to the file.
:HEX-A? New bytes are entered as hex pairs, i.e.: 65 0D 0A
:HEX-A? Example: A
If "%~1" NEQ "" (Call :commandError %0 & Goto :EOF)
SetLocal EnableExtensions EnableDelayedExpansion
Call :dumpHex 12
Echo;!msg.enter!
Set /P "bytes=!msg.append!"
Echo;
If DEFINED bytes Set /P "=!bytes!"<NUL: >>"%work%.hex12"
certUtil -f -decodeHex "!work!.hex12"   "!work!"  12 >NUL: 2>&1
Call :dumpHex
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-C [arguments]: Console command line interpreter.
:HEX-C? Default CMD arguments are in the variable 'comspecArguments' at 
:HEX-C? the top of this script file.
:HEX-C?
:HEX-C? If command C is followed by arguments then '%ComSpec% /C%*'
:HEX-C? is invoked, otherwise '%ComSpec% %comspecArguments%' is
:HEX-C? is invoked.
:HEX-C?   Example: C "cls & dir /r %file%"
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
:HEX-D <offset[-offset]>: Delete bytes by offset or range.
:HEX-D? All bytes following the range are moved left.
:HEX-D? Example: D 0x5-0x10
If "%~1" EQU "" (Call :commandError %0 & Goto :EOF)
SetLocal EnableExtensions EnableDelayedExpansion
Call :getRange %*
If EXIST "!Work!.raw" Erase "!Work!.raw"
Set "inBlock="
For /F "usebackq tokens=1*" %%a in ("%Work%.hex") Do (
  Set /A "line=0x%%a"
  Set "raw=%%b"
  If DEFINED raw Set "raw=!raw:~0,48!"
  If DEFINED raw Set "raw=!raw: =!"
  If DEFINED inBlock (
    If !line! EQU %block.end% (
      Set "inBlock="
      Set /A "i=(%range.high%-line+1)*2"
      For %%i in (!i!) Do Set "raw=!raw:~%%i!"
      Set /P "=!raw!"<NUL: >>"!work!.raw"
    )
  ) Else If !line! EQU %block.start% (
    Set "rawA=" && Set "rawB="
    Set /A "i=(%range.low%-line)*2"
    If DEFINED raw For %%i in (!i!) Do Set "rawA=!raw:~0,%%i!"
    If !line! EQU %block.end% (
      Set /A "i=(%range.high%-line+1)*2"
      If DEFINED raw For %%i in (!i!) Do Set "rawB=!raw:~%%i!"
    ) Else (
      Set "inBlock=true"
    )
    If "!rawA!!rawB!" NEQ "" Set /P "=!rawA!!rawB!"<NUL: >>"!work!.raw"
  ) Else (
    If DEFINED raw Set /P "=!raw!"<NUL: >>"!work!.raw"
  )
)
If EXIST "!work!.raw" (
  certUtil -f -decodeHex "!work!.raw"   "!work!"  12 >NUL: 2>&1
) Else (
  Call :newFile
)
Call :dumpHex
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-E <offset>: Edit a line.
:HEX-E? The entire line which contains offset -- a 16-byte segment -- 
:HEX-E? will be replaced by the bytes which are entered.
:HEX-E? If CLIP.EXE is available the current contents of that line
:HEX-E? will be copied to the clipboard which may then be pasted
:HEX-E? into the console for editing, otherwise you may copy the line
:HEX-E? which is printed above the prompt.
:HEX-E? New bytes are entered as hex pairs, i.e.: 65 0D 0A
:HEX-E? Example: E 0x3
If "%~1" EQU "" (Call :commandError %0 & Goto :EOF)
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "byte=%~1, range.low=byte - (byte %% 16)"
TYPE NUL:>"!Work!.raw"
For /F "usebackq tokens=1*" %%a in ("%Work%.hex") Do (
  Set /A "line=0x%%a"
  Set "raw=%%b"
  If DEFINED raw Set "raw=!raw:~0,48!"
  If !line! EQU %range.low% (
    Set /P "=!raw!"<NUL:>"!work!.oneline"
    Echo;!msg.enter!
    If EXIST "%CLIP%" (
      "%CLIP%"<"!work!.oneline"
      Echo;%msg.clipedit%
    ) Else (
      Echo;%msg.edit%
    )
    Echo;!raw!
    Set /P "raw="
    Echo;
  )
  Set /P "=!raw: =!"<NUL: >>"!work!.raw"
)
If EXIST "!work!.raw" (
  certUtil -f -decodeHex "!work!.raw"   "!work!"  12 >NUL: 2>&1
) Else (
  Call :newFile
)
Call :dumpHex
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-F: Show file information.
::F? 
Set /P "=ORIGINAL: "<NUL:
For %%a in ("%File%") Do (Echo %%~aa %%~ta %%~za-bytes %%~fa)
Set /P "=EDITOR:   "<NUL:
For %%a in ("%Work%") Do (Echo %%~aa %%~ta %%~za-bytes %%~fa)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-I <offset>: Insert new bytes to the file.
:HEX-I? Insert new bytes to the file beginning at offset.
:HEX-I? New bytes are entered as hex pairs, i.e.: 65 0D 0A
:HEX-I? Example: I 0x5
If "%~1" EQU "" (Call :commandError %0 & Goto :EOF)
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "byte=%~1"
For %%a in ("%work%") Do (
  If %byte% GEQ %%~za (
    Call :%mode%-A
    Goto :EOF
  )
)
Call :getRange %byte%
If EXIST "!Work!.raw" Erase "!Work!.raw"
For /F "usebackq tokens=1*" %%a in ("%Work%.hex") Do (
  Set /A "line=0x%%a"
  Set "raw=%%b"
  If DEFINED raw Set "raw=!raw:~0,48!"
  If DEFINED raw Set "raw=!raw: =!"
  If !line! EQU %block.start% (
    Set "rawA="
    If DEFINED raw (
      Set /A "i=(%byte%-line)*2"
      For %%i in (!i!) Do Set "rawA=!raw:~0,%%i!"
      If DEFINED rawA Set /P "=!rawA!"<NUL: >>"!work!.raw"
    )
    Echo;!msg.enter!
    Set /P "bytes=!msg.insert!"
    Echo;
    If DEFINED bytes Set /P "=!bytes!"<NUL: >>"%work%.raw"
    If DEFINED raw (
      Set /A "i=(%byte%-line)*2"
      For %%i in (!i!) Do Set "rawA=!raw:~%%i!"
      If DEFINED rawA Set /P "=!rawA!"<NUL: >>"!work!.raw"
    )
  ) Else (
    If DEFINED raw Set /P "=!raw!"<NUL: >>"!work!.raw"
  )
)
If EXIST "!work!.raw" (
  certUtil -f -decodeHex "!work!.raw"   "!work!"  12 >NUL: 2>&1
) Else (
  Call :newFile
)
Call :dumpHex
EndLocal
Set "dirty=1"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-K: Clears the screen.
:HEX-K? Example: K
CLS
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-L [offset[-offset]]: List the hex dump.
:HEX-L? Prints the entire hex dump or the specified range.
:HEX-L? Example: L 16 - 80
:HEX-L? Example: L 0x10-0x50
Echo;%Caption%
If "%~1" EQU "" (
  TYPE "%Work%.hex"
  EXIT /B 0
  Goto :EOF
)
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1,2 delims=-" %%a in ("%*") Do (
  Set "range.low=%%a"
  Set "range.high=%%b"
)
If NOT DEFINED range.high Set "range.high=%range.low%"
Set /A "range.low=%range.low% - (%range.low% %% 16), range.high=%range.high%"
For /F "usebackq tokens=1*" %%a in ("%Work%.hex") Do (
  Set /A "line=0x%%a" 2>NUL:
  If !line! GTR %range.high% Goto :break
  If !line! GEQ %range.low% Echo;%%a
)
:break
EndLocal
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-M: List the file through MORE.
::M?
MORE/E "%Work%.hex"
Goto :EOF 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-N: <new file>: Write all previous changes to the a new file.
:HEX-N? Copies the working copy to a new file. The new file will
:HEX-N? be the destination for all subsequent writes.
:HEX-N? Example: N newName.txt
Set "ok=%yes%"
REM (FindStr "^"<"%~f1">NUL:) 2>NUL: && Set /P "ok=Overwrite %~f1? [Y/N]: "<CON:
(FindStr "^"<"%~f1">NUL:) 2>NUL: && Set /P "ok=!msg.overwrite!"<CON:
If /I "%ok%" EQU "%yes%" TYPE "%Work%">"%~f1" && (
  Set "dirty="
  Set "File=%~f1"
)
Call :HEX-F
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-Q: Quit.
:HEX-Q? Parameter 1 may be the character "%yes%" to bypass the prompt.
:HEX-Q? Example: Q %yes%
If DEFINED warnUnsaved (
  If DEFINED dirty (
    If /I "%~1" NEQ "%yes%" (
      Echo;%msg.unsaved%
      Set /P "ok=%msg.exitPrompt%"<CON:
      If /I "!ok!" NEQ "%yes%" (
        Echo;%msg.howsave%
        Goto :EOF
      )
    )
  )
)
Set "quit=1"
RD /S /Q "%MY%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-R: Revert to the original.
:HEX-R? The working copy is replaced by the original file.
(Copy /b "%File%" "%Work%")>NUL: && (
  Set "dirty="
  Call :dumpHex
) || (
  If EXIST "%Work%" (
    Call :newFile
  )
)
Call :HEX-F
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-S <FindStr command line>: Search file using FINDSTR.
:HEX-S? Applies the arguments to a FINDSTR search of the hex dump.
:HEX-S? For example, 'S /C:"0D 0A"' looks for "0D 0A" in the hex dump.
FindStr %* "%Work%.hex"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HEX-W: Write all previous changes to the original file.
:HEX-W? Copies the working copy back to the original file. This is the
:HEX-W? only way that the original file can be written to.
:HEX-W? Example: W
Set "ok=%no%"
If /I "%~1" EQU "%yes%" (
  TYPE "%Work%">"%File%"
  Set "dirty="
) Else (
  Set /P "ok=%msg.overwritePrompt%"<CON:
  If /I "!ok!" EQU "%yes%" (
    TYPE "%Work%">"%File%"
    Set "dirty="
  )
)
Call :HEX-f
Goto :EOF
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
