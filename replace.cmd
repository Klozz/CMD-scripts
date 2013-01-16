  :: BEGIN SCRIPT ::::::::::::::::::::::::::::::::::::::::::::
  @echo OFF
  SetLocal ENABLEEXTENSIONS DISABLEDELAYEDEXPANSION
  Set "v="@#$%%"^&*(!)_-+={[}]|\:;'<,>.?/!"
  SetLocal EnableDelayedExpansion & Echo.BEGIN:    v=!v! & EndLocal
  Set "e=@#$%%" & Set "d=[1]"
  Call :ReplaceString v e d
  Set "e=^" & Set "d=[2]"
  Call :ReplaceString v e d
  Set "e=&*(^!)_-+={[}]|\:;'<,>.?/" & Set "d=[3]"
  Call :ReplaceString v e d
  Set "e=^!" & Set "d=[4]"
  Call :ReplaceString v e d
  (Set e=^")& Set "d='"
  Call :ReplaceString v e d
  SetLocal EnableDelayedExpansion & Echo.REPLACED: v=!v! & EndLocal
  Set "e=[1]" & Set "d=@#$%%"
  Call :ReplaceString v e d
  Set "e=[2]" & Set "d=^"
  Call :ReplaceString v e d
  Set "e=[3]" & Set "d=&*(^!)_-+={[}]|\:;'<,>.?/"
  Call :ReplaceString v e d
  Set "e=[4]" & Set "d=^!"
  Call :ReplaceString v e d
  Set "e='" & (Set d=^")
  Call :ReplaceString v e d
  SetLocal EnableDelayedExpansion & Echo.RESTORED: v=!v! & EndLocal

  REM Goto :EOF
  SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  :: Create a file:
	Set "OrigFile=demo1.txt"
	Set "DestFile=CON:"
	REM Set "DestFile=%OrigFile%"
	(
    Echo.To be, or not to be: that is the question:
    Echo.Whether 'tis nobler in the mind to suffer
    Echo.The slings and arrows of outrageous fortune,
    Echo.Or to take arms against a sea of troubles,
    Echo.And by opposing end them? To die: to sleep;
    Echo.No more; and by a sleep to say we end
    Echo.The heart-ache and the thousand natural shocks
    Echo.That flesh is heir to, 'tis a consummation
    Echo.Devoutly to be wish'd. To die, to sleep;
    Echo.To sleep: perchance to dream: ay, there's the rub;
    Echo.For in that sleep of death what dreams may come
    Echo.When we have shuffled off this mortal coil,
    Echo.Must give us pause: there's the respect ...
    Echo.
    Echo.William Shakespere
  )>%OrigFile%
  Type "%OrigFile%"
	REM Type NUL:>"%DestFile%"
  Set /A "i=0, StringCount=0, name=0"
  For %%a in (
    be                            DEL
    slings                        bits
    arrows                        bytes
    "outrageous fortune"          "wasted space"
    troubles                      files
    die                           DEL
    William                       Frank
    "a sleep"                     cleaning
    "sleep of"                    "cleaning of"
    sleep                         clean
    heart-ache                    corruption
    "the thousand natural shocks" fragmentation
    "flesh is"                    "disks are"
    dreams                        freeing
    dream                         free
    death                         DEL
    "mortal coil"                 "magnetic spoil"
    Shakespere                    Westlake
    pause                         PAUSE
    "DEL wi"                      "be wi"
  ) Do (
    Set "Parameter!StringCount!.!name!=%%~a"
    Set /A "StringCount+=i&1, i+=1, name=i&1"
  )
  Set /A "n=StringCount-1"
  Echo.*********************************************
  For /F "tokens=1* delims=:" %%a in ('FindStr/n "^" "%OrigFile%"') Do (
    Set "line=%%b"
    If DEFINED line (
      For /L %%i in (0,1,%n%) Do (
        Call :ReplaceString line parameter%%i.0 parameter%%i.1
      )
    )
    Echo.!line!>>"%DestFile%"
  )
  Echo.*********************************************
  If /I "%DestFile%" NEQ "CON:" (
    Type "%DestFile%"
    Erase "%OrigFile%" "%DestFile%"
  )
  Goto :EOF
  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: ReplaceString [/I] string_var find_var [replace_var]
  :: V 1.1 Frank P. Westlake, 2009-11-24. See changes at :EOF
  :: Replaces selected components of a string within a variable.
  :: PARAMETERS
  :: /I          Ignore case of characters in string_var. This
  ::             parameter is optional but can only be the first
  ::             parameter.
  :: string_var  The name of the variable containing the string.
  :: find_var    The name of the variable containing the component
  ::             to be replaced by the contents of replace_var.
  :: replace_var The name of the variable containing the string to
  ::             replace components identified by the contents of
  ::             find_var. This parameter is optional. If it is
  ::             absent then the components identified by find_var
  ::             will be deleted from the string.
  :: REMARKS
  :: - All strings require normal entry precautions. The percent sign
  ::   (%) must be doubled when entered within a script:
  ::     SET "STRING=50%%"
  :: - If find_var or replace_var contain the exclamation mark (!) it
  ::   must be escaped:
  ::     SET "FIND=^!"
  :: - Strings entered from the command line or from a file may not
  ::   need such treatment.
  ::EXAMPLE
  :: SET "string=A 50%% increase!" & SET "find=50" & SET "replace=500"
  :: Call :ReplaceString string find replace
  :ReplaceString String_Name Find_Name Replace_Name
  SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
  If /I "%~1" EQU "/I" (Set "I=/I" & SHIFT) Else (Set "I=")
  Set "old=!%~1!" & Set "new=" & Set "r2=" & Set "r3=" & Set "skip=0"
  If DEFINED %~2 For /F "tokens=1* delims==" %%a in ('Set %~2') Do (
    If NOT DEFINED r2 Set "r2=%%b")
  If DEFINED %~3 For /F "tokens=1* delims==" %%a in ('Set %~3') Do (
    If NOT DEFINED r3 Set "r3=%%b")
  Set /A "s=0,t=0"&For /F "tokens=1* delims=:" %%a in (
    '(Set old^& Echo.^)^|FindStr /O "^"') Do (Set /A "t+=1"
    If !t! EQU 2 (Set /A "s=%%a-6"))
  Set /A "o=0,t=0"&If DEFINED r2 (For /F "tokens=1* delims=:" %%a in (
    '(Set r2^& Echo.^)^|FindStr /O "^"') Do (Set /A "t+=1"
    If !t! EQU 2 (Set /A "o=%%a-5")))
  For /L %%i in (0,1,%s%) Do (
    If !skip! EQU 0 (If %I% "!old:~%%i,%o%!" EQU "!r2!" (
        Set "new=!new!!r3!" & Set /A "skip=%o%-1"
      ) Else (Set "new=!new!!old:~%%i,1!")) Else (Set /A "skip-=1"))
  For /F "tokens=1* delims==" %%a in ('Set new') Do (
    EndLocal & Set "%~1=%%b")
  Goto :EOF
  ::CHANGES:
  :: V1.1  2009-11-28  Changed string length routines to avoid
  ::                   measuring multiple variables.
  :: V1.1  2010-02-03  Minor changes for durability.
  ::                   NOT UPLOADED YET.
  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
