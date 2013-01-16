:: MathToy.cmd
:: Frank P. Westlake, 2010-03-18
::
:: HISTORY
:: 2010-03-19 * Fixed upper range (was 1 less).
::            + Enabled single values in definition of variables.
:: 2010-03-20 + General improvements.
:: 2010-03-23 + Added JScript support.
:: 2010=03-24 * Fixed a math definition error.
:: 2010-03-26 - Removed JScript support.
::            + Added sequences for variable definitions.
::
:: Math definitions may be anywhere in the file.
:: Math definitions begin with label ":;".
::
:: In math definitions the columns are seperated with ":"; this is to permit spaces
:: within the definitions.
:: There is at least one column, the expression, and optionally one or more additional
:: columns for definition of the variables in the expression:
::
::   EXPRESSION : VARIABLE DEFINITION 1 [ : VARIABLE DEFINITION 2 [ : ...]]
::
:: EXPRESSION: One math expression optionally containing one or more variables.
::
::   :; 5*8
::   :; 8*x
::
:: VARIABLE DEFINITION: A variable defined as a range, as a set, or as a value.
::                                                      EXAMPLE
::   Variable with range:    variable=low,high          r=-10,10
::   Variable with set:      variable={set}             t={2,4,6,8,10}
::   Variable with value:    variable=value             x=5
::   Variable with value:    variable=expression        y=5*M
::   Variable with sequence: variable=<start,step,stop> p=<1,3,10>
::
:: SAMPLES:
::  SET /A SAMPLES
:;  I*R      :  I=1,10        :  R=1,10
:;  E/R      :  E=<30,6,96}   :  R={3,6}
:;  (r+t)*d  :  r=1,10        :  t=1,10     :  d={2,4,6,8,10}
:;  1<<i     :  i=1,0x10
::
@Echo OFF
SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
For /F "tokens=1* delims==" %%a in ('"Set "$" 2>NUL:"') Do Set "%%a="
:: Translations:
Set "$correct=GOOD"
Set "$wrong=BAD"
Set "$score=Score"
Set "$quit word=quit"
Set "$quit letter=Q"
Set "$rule=----------"
Set "$Title=                           Math Toy"
Set "$Text.1=Exercise your math skills."
Set "$Text.2=Choose the expressions you wish to use, or leave blank to use all."
Set "$Text.3=Line numbers (Example: 1 2 4):"
Set "$Text.4=Your selection:"
:: End of translations.
::::::::::::::::::::::::::::::::::
Set "$ME=%~f0"
Set "$Math_Label=:;"
Set "$line="
Set /A "$count=0, $good=0, $bad=0, $percent=0"
Echo=%$Title%
Echo=
Echo=%$Text.1%
Echo=%$Text.2%
Echo=
Set "$line="
For /F "tokens=1* delims=%$Math_Label%" %%a in ('FindStr "^%$Math_Label%" "%~f0"^|FindStr /N .') Do (
  Echo=  %%a.	%%b
  Set "$list=!$list!%%a "
)
Echo=
Set /P "$list=%$Text.3% "
Set "$list=%$list:.=%"
Echo=
Echo=%$Text.4%
Echo=
For /F "tokens=1* delims=%$Math_Label%" %%a in ('FindStr "^%$Math_Label%" "%~f0"^|FindStr /N .') Do (
  For %%A in (%$list%) Do If "%%A" EQU "%%a" (
    Echo=  %%a.	%%b
  )
)
Echo=
Echo=!$quit letter!=!$quit word!
:Loop
For /F "tokens=1,2* delims=%$Math_Label%" %%a in ('FindStr "^%$Math_Label%" "%~f0"^|FindStr /N .') Do (
  For %%A in (%$list%) Do If "%%A" EQU "%%a" (
    Echo=%$rule%
    Set "$expr=%%~b" & Set "$show=!$expr: =!" & Set "$expr=!$show!"
    Call :SetVars "%%c"
    Set /A "$answer=!$expr!"
    Echo=!$show!:
    Set "$test=" & Set /P "$test=!$expr! = "
    If /I "!$test!" EQU "!$quit letter!" Goto :Break
    If /I "!$test!" EQU "" Goto :Break
    Set /A "$count+=1"
    If !$test! EQU !$answer! (
      Set /A "$good+=1"
      Set "$report=!$correct!."
    ) Else (
      Set /A "$bad+=1"
      Set "$report=!$wrong!. !$expr!=!$answer!"
    )
    Echo=!$report!
  )
)
Goto :Loop
:Break
Echo=%$rule%
If !$count! GTR 0 Set /A "$percent=$good*100/$count"
Echo=!$correct!:	!$good!
Echo=!$wrong!:	!$bad!
Echo=!$score!:	!$percent!%%
Goto :EOF

:SetVars
For /F "tokens=1* delims=:" %%a in ("%~1") Do (
  Set "$def=%%~a"
  Set "$def=!$def: =!"
  Set "$def=!$def:{={ !" & Set "$def=!$def:}= }!"
  Set "$def=!$def:<=< !" & Set "$def=!$def:>= >!"
  For /F "tokens=1* delims==" %%B in ("!$def!") Do (
    Set "$item=%%C"
    If "!$item:~0,1!" EQU "{" (
    REM SET OF INTEGERS
      Set "$n=-2" & For %%D in (!$item!) Do (Set /A "$n+=1")
      Set /A "$index=(!RANDOM! %% $n)+2, $n=0"
      For %%D in (!$item!) Do (Set /A "$n+=1"&If !$n! EQU !$index! Set /A "$var=%%D")
    ) Else If "!$item:~0,1!" EQU "<" (
    REM SEQUENCE OF INTEGERS
      For /F "tokens=2-4 delims=, " %%D in ("!$item!") Do (
        Set /A "$start=%%D, $step=%%E, $stop=%%F"
        Set "$n=0" & For /L %%i in (!$start!, !$step!, !$stop!) Do Set /A "$n+=1"
        Set /A "$n=!RANDOM! %% $n"
        For /L %%i in (!$start!, !$step!, !$stop!) Do (
          If !$n! EQU 0 Set /A "$var=%%i"
          Set /A "$n-=1"
        )
      )
    ) Else (
    REM RANGE OF INTEGERS
      For /F "tokens=1,2 delims=," %%D in ("!$item!") Do (
        If "%%E" EQU "" ( Set /A "$var=%%D"
        ) Else (          Set /A "$D=%%D, $E=%%E, $var=!RANDOM! %% ($E-$D+1)+$D")
      )
    )
    REM Set /A "%%B=!$var!"
    For %%D in (!$var!) Do Set "$expr=!$expr:%%B=%%D!"
  )
  Set $line="%%~b"
)
REM If DEFINED $line Call %0 %$line%
If !$line! NEQ "" Call %0 %$line%
Goto :EOF
