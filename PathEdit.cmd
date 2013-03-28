:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: PathEdit.cmd
:: From the desk of Frank P. Westlake, 2013-03-25-a
:: Interactive PATH editor. Edits the path in the machine, user, or
:: volatile environment and merges the three into the console's PATH
:: variable.
:: This script should function on Todd Vargo's computer.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "ME=%~n0"
Set "MESELF=%~f0"
Set "user=HKCU\Environment"
Set "machine=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
Set "volatile=HKCU\Volatile Environment"
Set "key="
Set "Caption="
Set "testAccess=true"

       If /I "/L" EQU "%~1" ( Set "work=!PATH!"    & Set "Caption=LOCAL" & Set "testAccess="
) Else If /I "/U" EQU "%~1" ( Set "key=%user%"     & Set "Caption=USER"
) Else If /I "/M" EQU "%~1" ( Set "key=%machine%"  & Set "Caption=MACHINE"
) Else If /I "/V" EQU "%~1" ( Set "key=%volatile%" & Set "Caption=VOLATILE"
) Else If /I "/?" EQU "%~1" ( Call :Usage          & EXIT /B 0
)
       If DEFINED key                ( Call :getRegistryVariable work "%key%" PATH
) Else If /I "!Caption!" NEQ "LOCAL" ( Call :printAll & EXIT /B 0
)
:loop
Call :printList
If NOT DEFINED caption EXIT /B 0
If DEFINED testAccess Call :testWriteAccess "%key%" && Set "testAccess=" || Goto :EOF
Call :showCommands
For /F "tokens=1 delims==" %%a in ('Set "#" 2^>NUL:') Do Set "%%a="
Set    "command="
Set /P "command=ENTER: <command> [item number] "
Echo;
For /F %%a in ("%command%") Do Set "#=%%a"
       If /I "!#!" EQU "A" ( Call :Add !command!
) Else If /I "!#!" EQU "C" ( CLS
) Else If /I "!#!" EQU "E" ( Call :Edit !command!
) Else If /I "!#!" EQU "I" ( Call :Insert !command!
) Else If /I "!#!" EQU "M" ( Call :Move !command!
) Else If /I "!#!" EQU "Q" ( EXIT /B 0
) Else If /I "!#!" EQU "R" ( Call :Remove !command!
) Else If /I "!#!" EQU "S" ( Goto :Save
) Else If /I "!#!" EQU "?" ( Call :help !command!
)
Goto :loop
For %%a in ("!work:;=" "!") Do (
  Choice /M "Remove '%%~a'?"
  If !ErrorLevel! EQU 2 (
    Set "newPath=!newPath!%%~a;"
  ) Else If !ErrorLevel! NEQ 1 (
    Goto :EOF
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Edit
If DEFINED work (
  For /F "tokens=2*" %%a in ("%*") Do (
    Set "#1=%%~a"
    Set "#2=%%~b"
  )
         If !itemCount! LEQ 1 ( Set "#1=!itemCount!"
  ) Else If NOT DEFINED #1    ( Set /P "#1=Remove which entry?: "
  )
  If DEFINED #1 (
    Set "#="
    Set /A "i=0"
    For %%a in ("!work:;=" "!") Do (
      Set /A "i+=1"
      If !i! EQU !#1! (
        If DEFINED #2 (
          Set "#=!#!!#2!;"
        ) Else (
          Echo OLD=%%~a
          Set "t=%%~a"
          Set /P "t=NEW="
          If DEFINED t (
            Set "#=!#!!t!;"
          ) Else (
            Set "#=!#!%%~a;"
          )
          Echo;
        )
      ) Else (
        Set "#=!#!%%~a;"
      )
    )
    Set "work=!#!"
    If "!work:~-1!" EQU ";" (Set "work=!work:~0,-1!")
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Save
Set "save=!work!"
If /I "!caption!" NEQ "LOCAL" (
  Call :setRegistryVariable "%key%" path "%work%"
  Set "work="
  For %%a in (MACHINE USER VOLATILE) Do (
    Set "p="
    Call :getRegistryVariable p "!%%~a!" path
    If DEFINED p (
      Set "add=true"
      For %%b in ("!work:;=" "!") Do (If /I "%%~b" EQU "!p!" Set "add=")
      If DEFINED add (
        If DEFINED work (
          Set "work=!work!;!p!"
        ) Else (
          Set "work=!p!"
        )
      )
    )
    If "!work:~-1!" EQU ";" (Set "work=!work:~0,-1!")
  )
  Set "save=!work!"
)
EndLocal & Set "PATH=%work%"
PATH
EXIT /B 0

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Move
For /F "tokens=2*" %%a in ("%*") Do (
  Set "m1=%%a"
  Set "m2=%%b"
)
If NOT DEFINED m1 (Set /P "#1=Remove which entry?: ")
If DEFINED m1 (
  If NOT DEFINED m2 (Set /P "m2=Move to which line?: ")
  If DEFINED m2 (
    If !m1! GTR !m2! (
      Call :remove R !m1!
      If DEFINED removed (
        Call :insert I !m2! !removed!
      )
    ) Else If !m1! LSS !m2! (
      Set /A "m=0"
      For %%a in ("!work:;=" "!") Do (
        Set /A "m+=1"
        If !m! EQU !m1! (
          Call :insert I !m2! %%~a
          Call :remove R !m1!
        )
      )
    )
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Add
For /F "tokens=1*" %%a in ("%*") Do (
  Call :Insert I 0x7FFFFFF %%~b
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Insert
For /F "tokens=2*" %%a in ("%*") Do (
  Set "#1=%%~a"
  Set "#2=%%~b"
)
       If !itemCount! LSS 1 ( Set "#1=1"
) Else If NOT DEFINED #1    ( Set /P "#1=Insert at which line?: "
)
If DEFINED #1 (
  If NOT DEFINED #2 (Set /P "#2=New entry: ")
  If DEFINED #2 (
    If DEFINED work (
      Set "#="
      Set /A "i=1"
      For %%a in ("!work:;=" "!") Do (
        If !i! EQU !#1! (Set "#=!#!!#2!;")
        Set "#=!#!%%~a;"
        Set /A "i+=1"
      )
      If !i! LEQ !#1! (Set "#=!#!!#2!;")
      Set "work=!#!"
    ) Else (
      Set "work=!#2!"
    )
    If "!work:~-1!" EQU ";" (Set "work=!work:~0,-1!")
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Remove
Set "removed="
If DEFINED work (
  For /F "tokens=1*" %%a in ("%*") Do (
    Set "#1=%%b"
  )
         If !itemCount! LEQ 1 ( Set "#1=!itemCount!"
  ) Else If NOT DEFINED #1    ( Set /P "#1=Remove which entry?: "
  )
  If DEFINED #1 (
    Set "#="
    Set /A "i=0"
    For %%a in ("!work:;=" "!") Do (
      Set /A "i+=1"
      Set "remove="
      For %%b in (!#1!) Do (
        If !i! EQU %%b (
          Set "remove=true"
          Set "removed=%%~a"
        )
      )
      If NOT DEFINED remove (
        If "%%~a" NEQ "" (Set "#=!#!%%~a;")
      )
    )
    Set "work=!#!"
    If "!work:~-1!" EQU ";" (Set "work=!work:~0,-1!")
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:showCommands
Echo;
Echo COMMANDS: ^
A=Add, ^
C=Clear, ^
E=Edit, ^
I=Insert, ^
M=Move, ^
Q=Quit, ^
R=Remove, ^
S=Save, ^
?=Help
Echo;
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:help
Echo COMMAND INSTRUCTIONS
Echo;Enter the command character followed, if necessary, by additional
Echo;information as specified below.
Echo A:     Add a new entry to the end.
Echo        Ex: A C:\bin
Echo C:     Clear the screen and print the PATH list.
Echo E #:   Edit the entry.
Echo        Ex: E 8 C:\Bin
Echo I #:   Insert a new entry at the indicated position.
Echo        Ex: I 1 C:\bin
Echo M # #: Move the indicated entry to the indicated destination.
Echo        Ex: M 1 5
Echo Q:     Abandon all changes and quit. The PATH will be unchanged.
Echo R #:   Remove the indicated entry from the path variable.
Echo        Ex: R 4 6 8
Echo S:     Save all changes to the PATH variable and quit. The machine,
Echo        user, and volatile paths will be merged into this console's
Echo        PATH variable.
Echo     #= The line numbers and additional information may follow the command
Echo        or they will be requested at a following prompt.
Echo;
Call :PAUSE
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:PAUSE
For /F "delims=" %%p in ('PAUSE^<NUL:') Do (
  Set /P "=%%~p"<NUL:
  XCOPY /L /W "%~f0" "%~f0" >NUL: 2>&1
  For /F %%q in ('COPY /Z "%~f0" NUL:') Do (
    Set /P "=.%%q                                                  %%q"<NUL:
  )
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getRegistryVariable <var> <key> <value>
Set "%~1="
For /F "tokens=2*" %%a in ('reg QUERY "%~2" /V "%~3" 2^>NUL:') Do Set "%~1=%%b"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:setRegistryVariable <key> <value> <data>
If "%~3" NEQ "" (
  reg ADD "%~1" /V "%~2" /D "%~3"
) Else (
  reg DELETE "%~1" /V "%~2" /f 2>NUL:
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:TestWriteAccess <key>
Set "now=%DATE%T%TIME%"
reg ADD "%~1" /v "%now%" /D "%ME% testing write access." /F >NUL: && (
  reg DELETE "%~1" /v "%now%" /F >NUL: 2>&1
  EXIT /B 0
) || (
  EXIT /B 5
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:printlist
Set "cap=%Caption% PATH ****************************************"
Echo %Cap:~0,40%
Echo;
If DEFINED work (
  Set /A "itemCount=0"
  For %%a in ("!work:;=" "!") Do (
    Set /A "itemCount+=1"
    Set "n=   !itemCount!"
    Echo !n:~-3!: %%~a
  )
) Else (
  Echo   EMPTY
)
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:printAll
For %%a in (MACHINE USER VOLATILE) Do (
  Set "caption=%%~a"
  Call :getRegistryVariable work "!%%~a!" path
  Echo;
  Call :printList
)
Set "work=!PATH!"
Set "caption=LOCAL"
Echo;
Call :printList
Echo;
Echo Usage **********************************
Echo;
Call :Usage
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Usage
Echo Interactive PATH editor
Echo;
Echo %ME% [/L ^| /M ^| /U ^| /V]
Echo;
Echo  /L  Edit the local console's PATH.
Echo  /M  Edit the machine (system^) Registry PATH.
Echo  /U  Edit the user's Registry PATH.
Echo  /V  Edit the volatile Registry PATH.
Echo;
Echo The default is to display the current path in each then exit.
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
