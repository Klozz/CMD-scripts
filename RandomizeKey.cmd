:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: From the desk of Frank P. Westlake, 2013-01-03
:: Package not marked for individual sale.
:: This script will randomize the contents of the string contained in
:: the variable "key", set below, and set the new string into the
:: clipboard. The resulting string will begin with the string "$="
:: which must be removed before eating. Also, the same string will
:: be printed to the console window but the tab character will be
:: converted to 1-8 spaces.
@Echo OFF
SetLocal EnableExtensions DisableDelayedExpansion
Set "TAB=	"
Set "SP= "
For /F "delims=%SP%" %%a in ("1%TAB%") Do If "%%~a" EQU "1" (
  (Echo %~nx0: The script's variable 'TAB' must be defined as a tab character.
   Set /P "=LINE "<NUL:
   FindStr /n /i /c:"TAB=" "%~f0"|FindStr /v "FindStr")>&2
  Goto :EOF
)
Set "out="
Set "key=%tab%%sp%0123456789QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm~`!@#$%%^&*()-_=+[{]}\|;:',<.>/?""
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "$=%key%"
For /F "delims=:" %%a in (
  '(SET $^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"'
) Do Set /A "length=%%a-4, len=length-1"
SetLocal EnableDelayedExpansion
For /L %%a in (0,1,%len%) Do (
  Set /A "i=!RANDOM! %% length, j=i+1, length-=1"
  REM Echo "i=!i! , j=!j!, length=!length!"
  For /F "tokens=1-2" %%i in ("!i! !j!") Do (
    Set "out=!out!!$:~%%i,1!"
    Set "$=!$:~0,%%i!!$:~%%j!"
  )
)
Set "$=!out!"
Set $|"%SystemRoot%\system32\clip.exe"
Set $
EndLocal
EndLocal
