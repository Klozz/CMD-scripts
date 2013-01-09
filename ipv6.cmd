:: ipv6.cmd
:: From the desk of Frank P. Westlake, 2012-03-06.
:: IPv4/IPv6 translation routines.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "IP=%1"
REM Set "IPv4="
REM Set "IPv6="
If "%IP:.=%" NEQ "%IP%" (Call :IPv4to6 IPv6 %IP% & Set "IPv6")
If "%IP::=%" NEQ "%IP%" (Call :IPv6to4 IPv4 %IP% & Set "IPv4")
REM Echo IPv4 address: %IP%
REM Call :IPv4to6 IPv6 %IP%
REM Echo IPv4 translation to IPv6: %IPv6%
REM Call :IPv6to4 IPv4 %IPv6%
REM Echo IPv6 translation to IPv4: %IPv4%
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::
:IPv6to4 result string
:: From the desk of Frank P. Westlake, 2012-03-06.
:: %1  The name of the variable to write the result into.
:: %2  The colon-hex string representation of the IPv6 address.
:: Example: CALL :IPv6to4 IPv4 ::FFFF:7FFF:FFFF
::          Result can be read from "%IPv4%".
SetLocal EnableExtensions EnableDelayedExpansion
Set "IPv6=%2"
Set "IPv6=%IPv6:::=0:0:0:0:0:%"
If /I "%IPv6:~0,15%" NEQ "0:0:0:0:0:ffff:" (
  EndLocal Return nothing if not an IPv4-mapped IPv6 address.
  Set "%1="
  Goto :EOF
)
For /F "tokens=7,8 delims=:" %%a in ("%IPv6%") Do (
  Set /A "U16=0x%%a, A=(U16&0xFF00)>>8, B=U16&0xFF"
  Set /A "L16=0x%%b, C=(L16&0xFF00)>>8, D=L16&0xFF"
)
EndLocal & Set "%1=%A%.%B%.%C%.%D%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::
:IPv4to6 result string
:: From the desk of Frank P. Westlake, 2012-03-06.
:: Requires subroutine ':toHex'.
:: %1  The name of the variable to write the result into.
:: %2  The dotted-decimal string representation of the IPv4 address.
:: Example: CALL :IPv4to6 IPv6 127.0.0.1
::          Result can be read from "%IPv6%".
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1-4 delims=." %%a in ("%2") Do (
  Set /A "U16=%%a<<8|%%b"
  Set /A "L16=%%c<<8|%%d"
)
Call :toHex U16 %U16%
Call :toHex L16 %L16%
EndLocal & Set "%1=::ffff:%U16%:%L16%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::
:toHex result integer
:: From the desk of Frank P. Westlake, 2012-03-06.
:: %1  The name of the variable to write the result into.
:: %2  The integer value to convert into a hexadecimal string.
:: Example: CALL :toHex hexString 32767
SetLocal EnableExtensions EnableDelayedExpansion
Set "HEX=0123456789abcdef"
Set "toHex="
Set "int=%2"
For /L %%i in (1,1,8) Do (
  Set /A "n=int%%16, int=int/16"
  For /L %%n in (!n!,1,!n!) Do Set "toHex=!HEX:~%%n,1!!toHex!"
)
For /L %%i in (1,1,8) Do (
  If "!toHex:~0,1!" EQU "0" Set "toHex=!toHex:~1!"
)
If NOT DEFINED toHex Set "toHex=0"
EndLocal & Set "%1=%toHex%"
Goto :EOF
