:: recycle.cmd Version 1.1
:: Frank P. Westlake, 2009-03-17, 2012-07-31, 2013-01-08
:: Enumerates the recycle bin, deletes items in it, or restores items
:: to their original location.
::
:: Usage: recycle /?
::
:: One previous version was unnumbered. It is version -1.0.
:: Changes:
::   V1.1: Display altertion for additional attributes.
::   V1.0: Cosmetics, error proofing. -FPW
::   V1.0: Fixed poison problem in :SetFileName. -FPW
::
:: This program can be easily modified to work with the user's recycle
:: bin on each volume and to work with recycle bins for all users.
:: I'll leave those tasks for someone with more interest or a greater
:: need.
::
:: This program can also be made to delete items from the recycle bin
:: after restoring them to their original location, but I didn't
:: enable that feature because I would need to implement some sort of
:: verification that the undelete was complete. Someone else can do
:: that.
::
::::'::::1::::'::::2::::'::::3::::'::::4::::'::::5::::'::::6::::'::::7
@Echo OFF
SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
Set "Me=%~f0"
ChkDsk /l|Find "file system is NTFS.">NUL:||(
  Echo.%Me%: This is not an NTFS volume. >&2
  Goto :EOF
)
For /F "tokens=2" %%a in ('whoami/user') Do Set SID=%%a
:NewSid
:NewDrive
If EXIST \$Recycle.Bin\%SID% (
    ChDir \$Recycle.Bin\%SID%
) Else (
    Set "NoBin=You do not have a recycle bin on this volume. Either"
    Set "NoBin=!NoBin! it is removable or you have not yet recycled"
    Set "NoBin=!NoBin! anything to create one."
    Echo.%Me%: !NoBin!>&2
  Goto :EOF
)
:Args
       If /I "%1" EQU ""   (Shift & Goto :List
) Else If /I "%1" EQU "/B" (Shift & Goto :ListBare
) Else If /I "%1" EQU "/D" (Shift & Goto :Delete
) Else If /I "%1" EQU "/U" (Shift & Goto :UnDelete
) Else If    "%1" EQU "/?" (
  Echo.Enumerates the recycle bin, deletes items in it, or restores
  Echo.items to their original location.
  Echo.
  Echo.%Me%   [Drive]   [/B]   [/D filename]   [/U filename]
  Echo.
  Echo. /B  Bare listing of name only.
  Echo. /D  Deletes the file or directory 'filename' from the recycle
  Echo.     bin. 'filename' must include the full path. 
  Echo. /U  Undelete the file or directory 'filename' from the recycle
  Echo.     bin. This will copy the file or directory structure to the
  Echo.     orginal location but will not remove it from the recycle
  Echo.     bin. 'filename' must include the full path.
  Echo.
  Echo.If there are no commandline parameters the recycle bin of the
  Echo.current drive will be enumerated.
) Else (
  %1
	Shift
	Goto :NewDrive
)

Goto :EOF

:List
Set "Key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Set "Key=%Key%\ProfileList"
Set "Params=/t REG_EXPAND_SZ /v ProfileImagePath"
For /F "tokens=3" %%r in (
    'Reg QUERY "%key%\%SID%" %Params%^|FindStr /b /c:" "'
	) Do (
  Echo.  Recycle Bin %CD:~0,2% of %%~nr
)
Echo.
For %%F in ("%~f0") Do (
  Set "extended=%%~aF"
  If "!extended:~10!" NEQ "" (
    Set "extended=  "
  ) Else (
    Set "extended="
  )
)
Set "Color.B=ATTRIBUTES%extended% LAST WRITE       SIZE       FILENAME"
Call :ColorPrint %ConsoleTextColor.Caption%
For /F %%A in ('Dir /b /a $R*') Do (
  Call :SetFileName %%A
	Set "Z=%%~zA          "
	Echo.%%~aA  %%~tA !Z:~0,10! !FileName!
)
Goto :EOF

:ListBare
For /F %%A in ('Dir /b /a $R*') Do (
  Call :SetFileName %%A
	Echo.!FileName!
)
Goto :EOF

:Delete
Set "DelFile=%~1"
Shift
If "%DelFile%" EQU "" Goto :EOF
For /F %%A in ('Dir /b /a $R*') Do (
  Call :SetFileName %%A
	If /I "%DelFile%" EQU "!FileName!" (
	  Set "DelFile=%%A"
		Attrib /S /D /L -S -H -R %%A
	  (DIR/AD %%A 1>NUL: 2>NUL:&&RmDir/S /Q %%A||Erase %%A)
		Erase $I!DelFile:~2!
		Goto :EOF
	)
)
Echo.%Me%: Could not find %DelFile% >&2
Goto :Delete

:UnDelete
Set "UnDelFile=%~1"
Set "DelFile=%UnDelFile%"
Shift
If "%UnDelFile%" EQU "" Goto :EOF
For /F %%A in ('Dir /b /a $R*') Do (
  Call :SetFileName %%A
	If /I "%UnDelFile%" EQU "!FileName!" (
	  Set "UnDelFile=%%A"
	  XCopy /-Y /I /C /E /Q /H /R /K /X /B %%A !FileName!
		REM Echo.Use '%Me% /D %UnDelFile%' to remove these files from the bin.
		Call :Delete %DelFile%
		Goto :EOF
	)
)
Echo.%Me%: Could not find %UnDelFile% >&2
Goto :UnDelete

:SetFileName
Set "Name=%~1"
Set "Name=$I%Name:~2%"
Set "FileName="
For /F "delims=" %%c in ('more /s^<%Name%') Do (
  Set "FileName=!FileName!%%c"
)
::For /F "tokens=1,2 delims=:" %%c in ("%FileName%") Do (
For /F "tokens=1,2 delims=:" %%c in ('Set FileName') Do (
  Set "Junk=%%c"
  Set "FileName=%%d"
)
Set "FileName=%Junk:~-1%:%FileName%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::ColorPrint 
::ColorPrint ColorValue 
Prints lines in the color specified on the command line followed 
by a nasty colon. 


INPUT VARIABLES: 
  Color.A      First portion of line printed without color. 
               May be undefined. 
  Color.B      Middle portion of line printed with the color
               specified on the command line. Must be defined. 
  Color.C      Final portion of line printed without color. 
               May be undefined. 
CHARACTERS: 
Valid: 0-9 A-Z a-z `~!@#^$%&()-_+=[]{};', 
Invalid: \|*/?: 


EXAMPLE: 
  Set "Color.A=" 
  Set "Color.B=Enabled" 
  Set "Color.C= Wireless network interface." 
  Call :ColorPrint 0A 


:ColorPrint 
MD    %Temp%\%~n0 
Pushd %Temp%\%~n0 
Echo.%Color.C%>"%Color.B%" 
Set /P =%Color.A%<NUL: 
FindStr /A:%1 /R "^" "%Color.B%*" 
Popd 
RD /S /Q %Temp%\%~n0 
Goto :EOF 
