:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: From the desk of Frank P. Westlake, 2013-01-03
:: This item is being sold as a novelty only.
:: Batteries not included.
:? Obfuscates or deobfuscates standard input to standard output.
:? Version 2013-01-03-A Minor corrections.
:? Version 2013-01-03   Preserves empty lines.
:? Version 2013-01-02   Original
:?
:? USAGE
:? obsufcate [/E | /D] [<key>]
:?
:?   /E    Encode input to output (default).
:?   /D    Decode input to output.
:?   key   An optional encoding key to replace the default.
:?
:? The default behavior is to encode input to output using the internal 
:? key. The internal key may be replaced by one on the command line so 
:? that it may remain secret and the character order changable. 
:?
:? The built-in key contains only the printable ASCII characters but other 
:? single byte characters may be added to it. 
:?
:? EXAMPLES
:?   TYPE script.cmd | obfuscate > bogus.cmd
:?   TYPE bogus.cmd | obfuscate /D > good.cmd & good.cmd & DEL good.cmd
:?   TYPE sample | obfuscate | obfuscate /d

@Echo OFF
SetLocal EnableExtensions DisableDelayedExpansion
:: DEFAULTS
Set "which=encode"
Set "TAB=	"
Set "SP= "
For /F "delims=%SP%" %%a in ("1%TAB%") Do If "%%~a" EQU "1" (
  (Echo %~nx0: The script's variable 'TAB' must be defined as a tab character.
   Set /P "=LINE "<NUL:
   FindStr /n /i /c:"TAB=" "%~f0"|FindStr /v "FindStr")>&2
  Goto :EOF
)
REM In setting the key, double the percent sign and move the quote
REM to the end. Place the resulting string after the equal sign of:
REM   Set "key="
REM This will cause the line to end with two quote characters.
Set "key=%tab%%sp%0123456789QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm~`!@#$%%^&*()-_=+[{]}\|;:',<.>/?""
:args
:: ARGUMENTS
Set "$=%~1"
If DEFINED $ (
  If "%$%" EQU "/?" (
    SetLocal EnableDelayedExpansion
    For /F "delims=" %%a in ('FindStr ":\?" %~f0') Do (
      Set "$=%%a"
      Echo;!$:~3!
    )
    EndLocal
    Goto :EOF
  )
  If /I "%$%" EQU "/D" (
    Set "which=decode"
  ) Else If /I "%$%" EQU "/E" (
    Set "which=encode"
  ) Else (
    Set "key=%~1"
  )
  SHIFT
  Goto :args
)
:main
Set "hex=0123456789ABCDEF"
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "$=%key%"
For /F "delims=:" %%a in (
  '(SET $^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"'
 ) Do Set /A "keyLength=%%a-4, keyLen=keyLength-1"
Set "$="
Set "forParams=delims^=^ eol^="
For /F %forParams% %%a in ('FindStr /N "^"') Do (
  Set "line=%%a"
  Call :%which%
)
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:encode
SetLocal EnableDelayedExpansion
Set "line=!line:*:=!"
If NOT DEFINED line (Echo;&Goto :EOF)
Set "codedLine="
:encode.loop
Set "c=!line:~0,1!"
Set "line=!line:~1!"
For /L %%i in (0 1 %keyLength%) Do (
  If "!c!" EQU "!key:~%%i,1!" (
    Set /A "hi=(%%i>>4)&0xF, lo=%%i&0xF"
    For /F "tokens=1,2" %%j in ("!hi! !lo!") Do (
      Set "codedLine=!codedLine!!hex:~%%j,1!!hex:~%%k,1!"
    )
    Goto :break
  )
)
(Echo Skipped unknown character '!c!'.)>&2
:break
If DEFINED line Goto :encode.loop
Echo;!codedLine!
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:decode
SetLocal EnableDelayedExpansion
Set "line=!line:*:=!"
If NOT DEFINED line (Echo;&Goto :EOF)
Set "decodedLine="
:decode.loop
Set /A "n=0x%line:~0,2%"
Set "decodedLine=!decodedLine!!key:~%n%,1!"
Set "line=!line:~2!"
If DEFINED line Goto :decode.loop
Echo;!decodedLine!
Goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::
