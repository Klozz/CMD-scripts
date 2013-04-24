:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: hiddenArguments.cmd
:: From the desk of Frank P. Westlake, 2013-04-23
:: Written on Windows 8.
@Goto :main

REMARKS
I submitted something like this a few years ago and I don't think I used
it again until this week. This technique is not often necessary but it
can greatly simplify command line parsing in some cases. Arguments are
attached to the subroutine label by separating them from it and from
each other with a colon (:subroutine_name:arg1:arg2). The second colon
terminates the label for use with CALL and GOTO but the entire string
gets stuffed into "%0" for the subroutine. Normal command line
parameters (%1-%9) don't begin until the first command line delimiter
(, ;=).

The script first demonstrates with the subroutine ":tutorial" how to get
the arguments from the label. It uses a command line which shows which
cahracters can be used and how they must be handled. The wild card
characters '*' and '?' can be passed and used but not by the technique
used in this subroutine; they require parsing with 'FOR /F' which either
causes the loss of any colons in the arguments or prohibits having
quoted arguments.

Next the script uses the subroutine ":usage_demo" to perform a very
simple task which wants the switches separate from the string contained
in '%*'. It does not do all the parsing which is done by ":tutorial"
because it is not all necessary for this simple task.

Frank

:main
@Echo OFF
SetLocal EnableExtensions DisableDelayedExpansion
REM NOT ALLOWED: & | < > !
Call :tutorial:"Quoted =,;:()":Unquoted~`@#$_-+{}[]\'/.:"Two carets=^^":"Four percents=%%%%":"Wild cards not permitted." Conventional command line arguments.
Echo Usage demo:
Call :usage_demo:/I:/N String to find.
Echo;
Echo String length demo:
Call :strlen:length Find the length of this string.
Echo Length of "Find the length of this string." is %length% characters.
Goto :EOF

:strlen:<variable name> <string>
For /F "tokens=2 delims=:" %%a in ("%0") Do (
  For /F "delims=:" %%b in (
    '(Echo;%*^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"'
  ) Do Set /A "%%~a=%%b-3"
)
Goto :EOF

:usage_demo
SetLocal EnableExtensions EnableDelayedExpansion
Set "params="
Set "$*=%0" & Set "$*=!$*:~1!" & Set "$*=!$*:*:=!"
Set "$*=!$*::= _THIS_SPACE_WAS_A_COLON_ !"
For %%a in (!$*!) Do (
  If "_THIS_SPACE_WAS_A_COLON_" NEQ "%%a" (
    Set "$=%%~a"
    Set "params=!params! !$: _THIS_SPACE_WAS_A_COLON_ =:!"
  )
)
FindStr %params% /C:"%*" "%~f0"
Goto :EOF

:tutorial
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "$#=-1"
Set "$*="
Set "$=%0"
Set "$=%$::= _THIS_SPACE_WAS_A_COLON_ %"
For %%a in (%$%) Do (
  If "_THIS_SPACE_WAS_A_COLON_" NEQ "%%a" (
    Set /A "$#+=1"
    Set "$=%%~a"
    Set "$!$#!=!$: _THIS_SPACE_WAS_A_COLON_ =:!"
    Set  $*=!$*! "!$: _THIS_SPACE_WAS_A_COLON_ =:!"
  )
)
Set "$="
Echo;$*=!$*!
Echo;$#=!$#!
For /L %%i in (0,1,!$#!) Do Echo;$%%i=!$%%i!
Echo %%*=%*
Echo;
Echo;LEGEND
Echo; $#  The number of parameters not including the subroutine name ($0).
Echo; $*  All hidden arguments separately quoted and concatenated with space.
Echo; $0  The subroutine name.
Echo; $1+ Arguments 1 through %%$#%%.
Echo; %%*  The conventional command line argument string.
Echo;
Goto :EOF
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
