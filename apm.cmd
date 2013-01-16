:: apm.cmd
@Goto :main

This is the beginning of an arbitrary precision math subroutine 
for CMD.EXE-only requirements. This version includes addition, 
subtraction, multiplication, division, AND, and OR operations 
and a hexadecimal to decimal conversion. 

I couldn't find a fast division algorithm that used only 
integers -- it seems they all use a floating point 
library -- so I made something up that is fairly fast except 
when the difference in sizes of the dividend and divisor is 
great. 

AND, OR, division, and multiplication may be removed if not 
needed but addition and subtraction must coexist.

Frank

:main
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set commandLine=%*

If NOT DEFINED commandLine (
  Echo(%~f0
  Echo(
  Echo USAGE
  Echo Called as a command from the commandline:
  Echo   %~f0 nameOfVariable=operand1 operator operand2
  Echo(
  Echo Called as a command from a script:
  Echo   CALL %~f0 nameOfVariable=operand1 operator operand2
  Echo(
  Echo Called as a subroutine from within a script:
  Echo   Copy the entire subroutine ':apm' into your script then:
  Echo     CALL :apm nameOfVariable=operand1 operator operand2
  Echo(
  Echo Operands must be integers.
  Echo Operator may be one of:
  Echo   +    addition
  Echo   -    subtraction
  Echo   *    multiplication
  Echo   /    division
  Echo   AND  AND
  Echo   OR   OR
  Echo(
  Echo If the operator and second operand are missing then the first operand
  Echo will be saved into the variable; a haxadecimal value is converted to
  Echo decimal so this can be used for bighex-to-bigdec conversion.
  Echo(
  Echo In all cases the variable named by parameter 1 will contain the 
  Echo solution. If the operation is AND or OR then in addition to setting 
  Echo the variable specified with the decimal solution, that name with the 
  Echo suffix ".hex" will contain the hexadecimal conversion. For example, 
  Echo if %%1 is "num" then "num" is decimal and "num.hex" is hexadecimal.
  Echo(
  Echo Example:
  Echo   Call :apm num=1234567890123456789 * 1234567890123456789
  Call :apm num=1234567890123456789 * 1234567890123456789
  Echo   ECHO num=%%num%%
  Echo num=!num!
  Echo(
) Else (
  EndLocal
  Call :apm %*
)

Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Arbitrary Precision Math
Version:     2012-04-04
Author:      Frank P. Westlake
License:     None required. This script is in the public domain.
Description: Performs addition, subtraction, multiplication, and division of 
             integers of arbitrary length.
Operators:   + (addition), - (subtraction), * (multiplication), / (division).
Usage:       CALL :apm nameOfVariable=operand1 operator operand2
Example:     CALL :apm num=1234567890123456789 * 1234567890123456789
             The variable 'num' equals 1524157875323883675019051998750190521
:apm nameOfVariable operand1 operator operand2
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "#" 2^>NUL:') Do Set "%%a="
REM Get parameters.
Set "#lib=%0"
Set "#var=%~1"
Set "#A.t=%~2"
Set  "#op=%~3"
Set "#B.t=%~4"
If /I "!#op!" EQU "AND" Set "#bitOp=1"
If /I "!#op!" EQU "OR"  Set "#bitOp=1"
If /I "!#op!" EQU "LS"  Set "#bitOp=1"
If /I "!#op!" EQU "RS"  Set "#bitOp=1"

If /I "!#A.t:~0,2!" EQU "0x" (
  Set "#A.hexIn=1"
  Set "#A.t=!#A.t:~2!"
  If NOT DEFINED #bitOp (
    Set /A "#i=1, #C=0"
    Call :apm.hexToDec #A.t=!#A.t!
    If NOT DEFINED #op (
      Set "#C=!#A.t!"
      Goto :apm.exit
    )
  )
)
If /I "!#B.t:~0,2!" EQU "0x" (
  Set "#B.hexIn=1"
  Set "#B.t=!#B.t:~2!"
  If NOT DEFINED #bitOp (
    Set /A "#i=1, #C=0"
    Call :apm.hexToDec #B.t=!#B.t!
  )
)
:: Record and remove signs.
If "!#A.t:~0,1!" EQU "-" (Set "#A.neg=-" & Set "#A.t=!#A.t:~1!")
If "!#B.t:~0,1!" EQU "-" (Set "#B.neg=-" & Set "#B.t=!#B.t:~1!")
Set /A "#A.len=0, #B.len=0"
:: Separate digits with space.
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do (
  Set "#A.t=!#A.t:%%a=%%a !"
  Set "#B.t=!#B.t:%%a=%%a !"
)
:: Reverse string and count lengths.
For %%a in (!#A.t!) Do (Set "#A=%%a!#A!" & Set /A "#A.len+=1")
For %%a in (!#B.t!) Do (Set "#B=%%a!#B!" & Set /A "#B.len+=1")
Set "#A.t=!#A.t: =!"
Set "#B.t=!#B.t: =!"
Set /A "#C=0"
If !#A.len! LSS !#B.len! (Set /A "#C.len=#B.len") Else (Set /A "#C.len=#A.len")
Set /A "#A.i=#A.len-1, #B.i=#B.len-1, #C.i=#C.len-1"
REM %1 %2  %3 IF  MAKE DO
REM .a  /  .b a<b ---  return 0 
REM +a  /  +b a>b ---        divide,   make positive
REM -a  /  -b a>b ---        divide,   make positive
REM +a  /  -b a>b ---        divide,   make negative
REM -a  /  +b a>b ---        divide,   make negative
REM +a  *  +b     ---        multiply, make positive
REM -a  *  -b     a*b        multiply, make positive
REM +a  *  -b     a*b        multiply, make negative
REM -a  *  +b     a*b        multiply, make negative
REM +a  +  +b     ---        add,      make positive
REM -a  +  -b     a+b        add,      make negative
REM -a  +  +b a>b a-b        subtract, make negative
REM -a  +  +b a<b b-a  swap, subtract, make negative
REM +a  +  -b a>b a-b        subtract, make positive
REM +a  +  -b a<b b-a  swap, subtract, make negative
REM -a  -  -b a>b a-b        subtract, make negative
REM -a  -  -b a<b b-a  swap, subtract, make positive
REM +a  -  -b     a+b        add,      make positive
REM -a  -  +b     a+b        add,      make negative
REM +a  -  +b a>b a-b        subtract, make positive
REM +a  -  +b a<b b-a  swap, subtract, make negative
:: Determine operand order and change operation if necessary.
If "!#op!" EQU "/" (
  If  !#B!  EQU  0  (Set /A "1/0"  & Goto :EOF)
  If "!#A!" EQU "0" (Set    "#C=0" & Goto :apm.exit)
  Set /A "#A.o=#A.t, #B.o=#B.t, #Q=0"
  Set "#Guess="
  Call :apm.findGreater
)
If "!#op!" EQU "+" (
  REM Compare sizes if -+, +- but not ++, --
  If "!#A.neg!!#B.neg!" EQU "-" Call :apm.findGreater
)
If "!#op!" EQU "-" (
  REM Compare sizes if --, ++ but not: +-, -+
  If "!#A.neg!!#B.neg!" EQU "--" (
    Call :apm.findGreater
  ) Else If "!#A.neg!!#B.neg!" EQU "" (
    Call :apm.findGreater
  )
)
:: Finalize operator and set sign of result.
If "!#op!" EQU "*" (
  If "!#A!" EQU "0" (Set "#C=0" & Goto :apm.exit)
  If "!#B!" EQU "0" (Set "#C=0" & Goto :apm.exit)
  If "!#A.neg!" NEQ "!#B.neg!" Set "#C.neg=-"
) Else  If "!#op!" EQU "/" (
  If DEFINED #B.greater (Set "C=0" & Goto :apm.exit)
  If "!#A.neg!!#B.neg!" EQU "-" Set "#C.neg=-"
  If "!#B!" EQU "1" (Set "#C=!#A.t!" & Goto :apm.exit)
  If !#B.len! LEQ 10 (
    If !#B.len! LSS 10 (
      Set "#op=longDiv"
    ) Else If "!#B.t!" LEQ "2147483647" (
      Set "#op=longDiv"
    )
  )
) Else  If "!#op!" EQU "+" (
  If "!#A.neg!!#B.neg!" EQU "-" (
    Set "#op=-"
    Set "#swap=!#B.greater!"
  )
  If DEFINED #A.neg (
    Set "#C.neg=-"
  ) Else If DEFINED #B.greater (
    Set "#C.neg=-"
  )
) Else If "!#op!" EQU "-" (
  If "!#A.neg!!#B.neg!" EQU "-" (
    Set "#op=+"
  ) Else (
    Set "#swap=!#B.greater!"
  )
  If DEFINED #A.neg (
    If NOT DEFINED #B.greater Set "#C.neg=-"
  ) Else (
    If DEFINED #B.greater Set "#C.neg=-"
  )
)
If DEFINED #swap Call :apm.swap
:: At this point #A and #B have .len, .i, and possibly .neg, .greater.
:: #C has .len and .i for the longest of #A and #B, and possibly .neg.
Call :apm.%#op%
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.exit
For %%a in (!#C!) Do (
  Set "#ans=!#ans!%%a"
  if !#ans! EQU 0 Set "#ans="
)
If NOT DEFINED #ans (
  Set "#ans=0"
) Else (
  Set "#ans=!#C.neg!!#ans!"
)
EndLocal & Set "%#var%=%#ans%" & Set "%#var%.hex=%#C.hex%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.findGreater
Set "#B.greater="
Set "#stop="
If !#A.len! LSS !#B.len! (
  Set "#B.greater=1"
) Else If !#A.len! EQU !#B.len! (
  For /L %%i in (!#C.i!, -1, 0) Do (
    If NOT DEFINED #STOP (
      Set /a "#nA=!#A:~%%i,1!, #nB=!#B:~%%i,1!"
      If !#nB! GTR !#nA! Set "#B.greater=1"
      If !#nB! NEQ !#nA! Set "#STOP=1"
    )
  )
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.length varResult varNumber
Set "#apm.num=!%~2!"
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do (Set "#apm.num=!#apm.num:%%a=%%a !")
Set /A "%~1=0"
For %%a in (!#apm.num!) Do (Set /A "%~1+=1")
Set "#apm.num="
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.buildNum which
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do (Set "%1.t=!%1.t:%%a=%%a !")
Set "%1="
Set "%1.len=0"
For %%a in (!%1.t!) Do (Set "%1=%%a!%1!" & Set /A "%1.len+=1")
Set "%1.t=!%1.t: =!"
Set /A "%1.i=%1.len-1"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.longdiv
Set "#T=!#A.t!"
Set "#D="
Set "#C="
Set "#Z="
Set "#i=0"
For %%a in (0 1 2 3 4 5 6 7 8 9) Do Set "#T=!#T:%%a=%%a !"
Set "#len=0"
For %%a in (!#T!) Do (
  Set "#D=!#D!%%a"
  If "!#D!" EQU "0" Set "#D="
  Set "#Z=!#Z!0"
  Set /A "#i+=1"
  Call :apm.length #len #D
  If !#len! GTR 10 (Goto :apm./)
  If !#len! EQU 10 (
    If "!#D!" GTR "2147483647" (Goto :apm./)
  )
  If !#D! GEQ !#B.t! (
    Set /A "#r=#D %% #B.t, #n=#D/#B.t"
    Set "#n=!#Z!!#n!"
    For /L %%i in (!#i!, 1, !#i!) Do Set "#C=!#C!!#n:~-%%i!"
    Set "#Z="
    Set "#i=0"
    If "!#r!" EQU "0" (Set "#D=") Else (Set "#D=!#r!")
  )
)
Set "#D=!#C!!#Z!"
For %%a in (0 1 2 3 4 5 6 7 8 9) Do Set "#D=!#D:%%a=%%a !"
Set "#C="
For %%a in (!#D!) Do (
  Set "#C=!#C!%%a"
  if !#C! EQU 0 Set "#C="
)
If NOT DEFINED #C (
  Set "#C=0"
) Else (
  Set "#C=!#C!"
)
If DEFINED #Q Call :apm #C=!#Q! + !#C!
Set "#C=!#c!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm./
If NOT DEFINED #B.greater (
  If "!#B!" EQU "1" (
    Set "#C=!#A.t!"
    Goto :EOF
  )
  If "!#op!" EQU "/" (
    If !#B.len! LEQ 10 (
      If !#B.len! LSS 10           (Goto :apm.longDiv)
      If "!#B.t!" LEQ "2147483647" (Goto :apm.longDiv)
    )
  )
  If "!#B:~0,1!" EQU "0" (
    Set "#A.t=!#A.t:~0,-1!"
    Call :apm.buildNum #A
    Set "#B.t=!#B.t:~0,-1!"
    Call :apm.buildNum #B
    If !#B.len! EQU 0 (Set "#C=!#A!" & Goto :apm.exit)
    Goto :apm./
  )
  If NOT DEFINED #Guess Set "#Guess=0"
  Set /A "#G=#A.len/#B.len"
  If !#G! LSS !#A.len! (
    REM Set /A "#G=#A.len/#B.len, #T=#G"
    Set /A "#T=#G"
    For /L %%i in (2 1 !#A.len!) Do (Call :apm #G=!#G! * !#T!)
    Call :apm #Guess=!#Guess! + !#G!
    Set "#Q=!#Guess!"
    REM Call :apm #G=!#Guess! * !#B.t!
    REM Call :apm #A.t=!#A.o! - !#G!
    Call :apm #G=!#G! * !#B.t!
    Call :apm #A.t=!#A.t! - !#G!
    Call :apm.buildNum #A
    REM For %%a in (0 1 2 3 4 5 6 7 8 9) Do (Set "#A.t=!#A.t:%%a=%%a !")
    REM Set "#A="
    REM Set "#A.len=0"
    REM For %%a in (!#A.t!) Do (Set "#A=%%a!#A!" & Set /A "#A.len+=1")
    REM Set "#A.t=!#A.t: =!"
    If !#A.len! LSS !#B.len! (
      Set /A "#C.len=#B.len"
    ) Else (
      Set /A "#C.len=#A.len"
    )
    Set /A "#A.i=#A.len-1, #C.i=#C.len-1"
    Call :apm.findGreater
REM Echo [!#Q! !#A! !#G!]
    Goto :apm./
  )
REM Echo  !#Q! !#A!
  Call :apm #Q=!#Q! + 1

  REM Do #D=#C=#A-#B
    Set "#C="
    Set "#D="
    For /L %%i in (0, 1, !#C.i!) Do (
      Set "#nA=!#A:~%%i,1!"
      Set "#nB=!#B:~%%i,1!"
      Set /a "#n=#nA+9-#nB"
      Set "#C=!#C! !#n!"
    )
    Set /A "#carry=1"
    For %%a in (!#C!) Do (
      Set /A "#n=%%a+#carry, #carry=0"
      If !#n! GEQ 10 Set /A "#n-=10, #carry=1"
      Set "#D=!#n! !#D!"
    )
  REM If !#carry! EQU 1 Set "#D=1!#D!"
  REM Reverse #D into #A and get length.
    Set "#A="
    Set /A "#A.len=0"
    For %%a in (!#D!) Do (
      Set "#A=%%a!#A!"
      if "!#A!" EQU "0" (
        Set "#A="
      ) Else (
        Set /A "#A.len+=1"
      )
    )
  If !#A.len! LSS !#B.len! (
    Set /A "#C.len=#B.len"
  ) Else (
    Set /A "#C.len=#A.len"
  )
  Set /A "#A.i=#A.len-1, #C.i=#C.len-1"
REM Echo !#Q! !#A!
  If DEFINED #A (
    Call :apm.findGreater
    If NOT DEFINED #B.greater (
      REM Call :apm #Q=!#Q! + 1
      Goto :apm./
    )
  )
)
Set "#C=!#Q!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.-
Set "#C="
:: 10s complement subtraction.
For /L %%i in (0, 1, !#C.i!) Do (
  Set "#nA=!#A:~%%i,1!"
  Set "#nB=!#B:~%%i,1!"
  Set /a "#n=#nA+9-#nB"
  Set "#C=!#C! !#n!"
)
Set /A "#carry=1"
For %%a in (!#C!) Do (
  Set /A "#n=%%a+#carry, #carry=0"
  If !#n! GEQ 10 Set /A "#n-=10, #carry=1"
  Set "#D=!#n! !#D!"
)
REM If !#carry! EQU 1 Set "#D=1!#D!"
set "#C=!#D!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.+
Set "#C="
For /L %%i in (0, 1, !#C.i!) Do (
  Set "#nA=!#A:~%%i,1!"
  Set "#nB=!#B:~%%i,1!"
  Set /a "#n=#nA+#nB+#carry"
  Set /A "#carry=0"
  If !#n! GEQ 10 (Set /A "#n-=10, #carry=1")
  Set "#C=!#n!!#C!"
)
If !#carry! EQU 1 Set "#C=1!#C!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.*
Set /A "#carry=0"
Set "#z="
For /L %%b in (0, 1, !#B.i!) Do (
  Set "#L=!#z!"
  For /L %%a in (0, 1, !#A.i!) Do (
    Set /A "#n=#carry + !#A:~%%a,1! * !#B:~%%b,1!"
    Set /A "#carry=#n/10, #n%%=10"
    Set "#L=!#L! !#n!"
  )
  If !#carry! NEQ 0 (
    Set "#L=!#L! !#carry!"
    Set /A "#carry=0"
  )
  Set "#T=!#C!"
  Set "#C="
  Set /a "#i=0"
  For %%n in (!#L!) Do (
    For /L %%i in (!#i!,1,!#i!) Do Set "#n=!#T:~%%i,1!"
    Set /A "#n+=#carry+%%n, #carry=#n/10, #n%%=10, #i+=1"
    Set "#C=!#C!!#n!"
  )
  If !#carry! NEQ 0 (
    Set "#C=!#C!!#carry!"
    Set /A "#carry=0"
  )
  Set "#z=!#z! 0"
)
Set "#T=!#C!"
Set "#C="
For %%a in (0 1 2 3 4 5 6 7 8 9) Do Set "#T=!#T:%%a=%%a !"
For %%a in (!#T!) Do Set "#C=%%a !#C!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.swap
REM A is less than B so swap them.
(
  Set "#A=%#B%"
  Set "#B=%#A%"
  Set "#A.len=%#B.len%"
  Set "#B.len=%#A.len%"
  Set "#A.i=%#B.i%"
  Set "#B.i=%#A.i%"
  Set "#A.neg=%#B.neg%"
  Set "#B.neg=%#A.neg%"
  Set "#A.greater=%#B.greater%"
  Set "#B.greater=%#A.greater%"
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.hexToDec
SetLocal EnableExtensions EnableDelayedExpansion
Set "#var=%1"
Set "#R=%2"
Set "#i=1"
Set "#C=0"
:apm.hexToDecLoop
  Set /A "#H=0x!#R:~-4!"
  Set "#R=!#R:~0,-4!"
  Call :apm #H=!#H! * !#i!
  Call :apm #C=!#C! + !#H!
  Call :apm #i=!#i! * 65536
If DEFINED #R Goto :apm.hexToDecLoop
EndLocal & Set "%#var%=%#C%"
Goto :EOF
REM ::::::::::::::::::::::::::::::::::::::::::::::::::
REM :apm.decToHex varName int16
REM Set "#hex=0123456789ABCDEF"
REM Set "%1="
REM Set "#t=%2"
REM For %%h in (: : : :) Do (
  REM Set /A "#n=#t %% 16, #t/=16"
  REM For /L %%i in (!#n!, 1, !#n!) Do Set "%1=!#hex:~%%i,1!!%1!"
REM )
REM set %1
REM Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.OR
:apm.AND
Set "#hex=0123456789ABCDEF"
If /I "!#op!" EQU "AND" (Set "#=&") Else (Set "#=|")
Set "#C="
For /L %%a in (0, 1, !#C.i!) Do (
  Set /A "#n=0x0!#A:~%%a,1! !#! 0x0!#B:~%%a,1!"
  For /L %%i in (!#n!, 1, !#n!) Do Set "#C=!#hex:~%%i,1!!#C!"
  REM For /L %%i in (!#n!, 1, !#n!) Do Set "#C=!#C!!#hex:~%%i,1!"
)
set "#C.hex=0x!#C!"
Call :apm.hexToDec #C !#C!
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::
:apm.LS
Set "#hex=0123456789ABCDEF"
Set "#C="
Set "#fill=" & For /L %%i in (0, 1, !#B!) Do Set "#fill=!#fill!0"
For /L %%a in (0, 1, !#A.i!) Do (
  Set /A "#n=0x0!#A:~%%a,1! !#! 0x0!#B:~%%a,1!"
  For /L %%i in (!#n!, 1, !#n!) Do Set "#C=!#hex:~%%i,1!!#C!"
  REM For /L %%i in (!#n!, 1, !#n!) Do Set "#C=!#C!!#hex:~%%i,1!"
)
set "#C.hex=0x!#C!"
Call :apm.hexToDec #C !#C!
Goto :EOF
