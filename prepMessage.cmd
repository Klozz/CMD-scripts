:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: From the desk of Frank P. Westlake, 2013-01-14
:: PrepMessage.cmd
:: Version 2013-01-14-B
:: Copies text from the clipboard, which is assumed to be an Internet
:: message, and performs a hard word wrap on all lines ending with a
:: space, then places that modified text on the clipboard.
:: Written on Windows 8.
:: Requires Clip and Paste, cScript, or PowerShell.
::
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
:: CONFIGURATION
Set "prefix=  "
Set "wrap.width=72"
:: END CONFIGURATION
Goto :main

This program copies text from the clipboard, applies a hard word wrap
where necessary, then places that modified text on the clipboard. The
text is assumed to be an Internet message which may contain dialog which
should be wrapped and script which should not be wrapped. The dialog
text should be terminated with a space, script text should not be
terminated with a space. The presence of the space identifies text to be
wrapped.

Each line of the dialog text is terminated with a space. Generally a
paragraph is written as a long line which is often wrapped in the text
viewer to the window width. But not all text viewers do word wrap
because it was customary for the sender to format each message; with
these viewers messages with long lines are difficult to read. This
script will break these long line paragraphs into lines of the length
specified by the variable "wrap.width" if the last character in the line
is a space. The space will be removed.

PROCEDURES
-The mail user agent should be set to the longest possible line length
to avoid wrapping script lines.

-Set the contents of the variable "prefix" above with the desired number
of spaces to prefix script lines with. This indentation is commonly used
to help identify lines which have been wrapped and must be rejoined, but
since that shouldn't happen with long line lengths the prefix is not
necessary for that reason alone. An indentation may still be desired to
visually separate script text from dialog text.

-Place a shortcut to this script on the desktop.

-Copy all the text of a message into the clipboard.

-Double-click the shortcut to this script.

-Paste the clipboard over the text which is still selected in the message.

:main
Set "ME=%~n0"
Set "meTemp="
Set "CLIP="
Set "PASTE="
For %%a in (clip.exe) Do (
  If "%%~$PATH:a" NEQ "" (
    Set "CLIP=clip.exe"
  )
)
For %%a in (paste.exe) Do (
  If "%%~$PATH:a" NEQ "" (
    Set "PASTE=paste.exe"
  ) Else (
    For %%b in (cScript.exe) Do (
      If "%%~$PATH:b" NEQ "" (
        Set "meTemp=%TEMP%\%ME%.vbs"
        Echo Wscript.Echo CreateObject("htmlfile"^).ParentWindow.ClipboardData.GetData("text"^)>"!meTemp!"
        Set "PASTE=cScript.exe /noLogo /E:VBS !meTemp!"
      ) Else (
        For %%c in (powershell.exe) Do (
          If "%%~$PATH:c" NEQ "" (
            Set ^"PASTE=powershell -noprofile -command "&{add-type -an system.windows.forms;[System.Windows.Forms.Clipboard]::GetText()}""
          )
        )
      )
    )
  )
)
If NOT DEFINED CLIP GOTO :abort
If NOT DEFINED PASTE GOTO :abort
If /I "%~1" NEQ "/CLIP" (
  CALL %~f0 /CLIP | %CLIP%
  Goto :EOF
)
:getClipboard
SetLocal DisableDelayedExpansion
For /F "delims=" %%a in ('%PASTE% ^|FindStr /N "^"') Do (
  Set "wrap=%%a"
  SetLocal EnableDelayedExpansion
  Set "wrap=!wrap:*:=!"
  If "!wrap:~0,1!" EQU ">" (
    Echo;!wrap!
  ) Else If "!wrap:~-1!" EQU " " (
    Set "wrap=!wrap:~0,-1!"
    Call :wrap
  ) Else If DEFINED wrap (
    Echo;!prefix!!wrap!
  ) Else (
    Echo;
  )
  EndLocal
)
If DEFINED meTemp Erase "%meTemp%"
Goto :EOF
:abort
If NOT DEFINED CLIP (
  Echo This program requires CLIP.EXE which is normally present in Windows Vista
  Echo or later.
)>&2
If NOT DEFINED PASTE (
  Echo This program requires either PASTE.EXE (http://ss64.net/westlake/nt/paste.zip^),
  Echo PowerShell.exe; or cScript.exe to retrieve text from the clipboard.
)>&2
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Wrap
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "Wrap.0=%Wrap.Width%, Wrap.1=%Wrap.Width%+1"
If "!Wrap:~%Wrap.0%!" NEQ "" (
  Set "Wrap.1=%Wrap.Width%"
  For /L %%i in (%Wrap.Width%,-1,1) Do If "!Wrap:~%%i,1!" EQU " " (
    Set /A "Wrap.0=%%i,Wrap.1=%%i+1"
    Goto :Wrap.break
  )
)
:Wrap.break
Echo=!Wrap:~0,%Wrap.0%!
Set "Wrap=!Wrap:~%Wrap.1%!"
EndLocal & (
  Set "Wrap=%Wrap:!=^!%"
  Set "Wrap.Width=%Wrap.Width%"
)
:Wrap.EOR
If DEFINED Wrap Goto :Wrap
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
