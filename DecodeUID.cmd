:: DecodeUID.cmd
:: Decodes RFC 4122 Universally Unique IDs
:: Frank P. Westlake, 2009-11-19
:: CHANGES:
::   2009-11-21 Fixes; added guesswork for version 2; more input validation;
::              added create options for version 1 and 4.
:: REFERENCES
:: rfc4122.txt
:: draft-mealling-uuid-urn-03.txt
:: draft-leach-uuids-guids-01.txt
:: http://www.opengroup.org/onlinepubs/9668899/chap5.htm
::
::When the node is displayed for version 1 and 2 UUIDs GETMAC will be run
::to see if the network adapter is one GETMAC has access to. If it is
::then the adapter's information will be displayed.

::Version 1     A time-based UID.
::  2b422150-d42b-11de-8a39-0800200c9a66
::  2fac1234-31f8-11b4-a222-08002b34c003
::Version 2     A DCE Security version, with embedded POSIX UIDs.
::  2b422150-d42b-21de-8039-0800200c9a66 (uncertain construct)
::Version 3     A name-based UID which uses MD5 hashing.
::  A2E3D453-6AF6-304A-94F5-017024598F63
::  e902893a-9d22-3c7e-a7b8-d6e313b71d9f
::Version 4     A randomly or pseudo-randomly generated UID.
::  f47ac10b-58cc-4372-a567-0e02b2c3d479
::  127FB026-B05D-4783-A810-B7A69DA6C96C
::  a32a3277-578c-4da1-b503-2a81ae24cad8
::Version 5     A name-based UID which uses SHA1 hashing.
::  13726f09-44a9-5eeb-8910-3525a23fb23b
::                ^
:: Note that this | is the version number column.
:Start
@Echo OFF
SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: Clear environment:
Set "DATE=" & Set "TIME=" & Set "CD=" & Set "RANDOM=" 
For /F "tokens=1* delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
For /F "tokens=1* delims==" %%a in ('Set "#" 2^>NUL:') Do Set "%%a="
:: Set constants:
Set "#MY=%temp%\%~n0.%RANDOM%%TIME:~-2%"
Set "#eval.js=%#MY%\eval.js"
Set "#GetMac=%SystemRoot%\System32\getmac.exe /V"

Set "$UID="

For /F "delims={}" %%1 in ('Echo.%*') Do Set "$UID=%%~1"
:: To create a UUID:
       If /I "%$UID%" EQU "/C" ( Call :GetUUID1
) Else If    "%$UID%" EQU "/1" ( Call :GetUUID1
) Else If    "%$UID%" EQU "/4" ( Call :GetUUID4
) Else If    "%$UID%" EQU "/?" ( Set "$UID="
)

If NOT DEFINED $UID (
  Echo.Version 1.00
  Echo.Decodes RFC 4122 UUIDs.
  Echo.
  Echo.  %~n0 {[/1] [/4] [UUID]}
  Echo.
  Echo.  /1    Create a version 1 (timestamp^) UUID.
  Echo.  /4    Create a version 4 (random^) UUID.
REM /C is still enabled but not advertised. Use /1 instead.
REM  Echo.  /C    Create a version 1 (timestamp^) UUID.
  Echo.  UUID  A UUID to decode.
  Echo.
  Echo.The UUID can be in either the string representation format
  Echo.
  Echo.  a1a2a3a4-b1b2-c1c2-d1e1-f1f2f3f4f5f6
  Echo.
  Echo.or in the internal format
  Echo.
  Echo.  a4a3a2a1b2b1c2c1d1e1f1f2f3f4f5f6
  Echo.
  Echo.Both representations will be displayed. Individual values of each component
  Echo.will be displayed below the string representation.
  Goto :EOF
)
Set "#xDigit=[0-9a-fA-F]"
Echo.%$UID%|FindStr "^%#xDigit%*\-%#xDigit%*\-%#xDigit%*\-%#xDigit%*\-%#xDigit%*$" >NUL: && (
  If "%$UID:~35%" EQU "" (Goto :Invalid) Else If "%$UID:~36%" NEQ "" (Goto :Invalid)
  For %%i in (8 13 18 23) Do If "!$UID:~%%i,1!" NEQ "-" Goto :Invalid
  Set "$UID.string=%$UID%"
  Set "$UID=!$UID:-=!"
  Set "$UID.hex=!$UID:~6,2!!$UID:~4,2!!$UID:~2,2!!$UID:~0,2!!$UID:~10,2!!$UID:~8,2!!$UID:~14,2!!$UID:~12,2!"
  Set "$UID.hex=!$UID.hex!!$UID:~16,4!!$UID:~20,12!"
  Set "$UID=!$UID.hex!"
) || (Echo.%$UID%|FindStr /x "%#xDigit%*" >NUL: && (
  If "%$UID:~31%" EQU "" (Goto :Invalid) Else If "%$UID:~32%" NEQ "" (Goto :Invalid)
  Set "$UID.hex=%$UID%"
  Set "$UID.string=!$UID:~6,2!!$UID:~4,2!!$UID:~2,2!!$UID:~0,2!-!$UID:~10,2!!$UID:~8,2!-!$UID:~14,2!!$UID:~12,2!-!$UID:~16,4!"
  Set "$UID.string=!$UID.string!-!$UID:~20,12!"
  ) || (
    Goto :Invalid
  )
)
Set "#xDigit="
MkDir "%#MY%"

Set /A "$variant=0x!$UID:~16,2!"
Set /A "$variant.layout=($variant>>7)&1"

Echo.  **********  %$UID.hex%  **********
Echo.**********  %$UID.string%  **********
If !$variant.layout! EQU 0 (
  Set /A "$variant.field=0x80, $variant.bits=1"
  Set "NilUUID=%$UID:0=%"
  If NOT DEFINED NilUUID (
    Echo.Variant:   A nil UUID.
    Echo.Version 0: A special form of UUID that is specified to have all 128 bits set to zero.
    Echo.           zero.
  ) Else Echo.Variant:   Reserved, NCS backward compatibility. No decode available.
  Goto :END
) Else (
  Set /A "$variant.layout=($variant>>6)&3"
  If !$variant.layout! EQU 2 (
		Set /A "$variant.field=0xC0, $variant.bits=2"
  ) Else (
    Set /A "$variant.layout=($variant>>5)&7"
		Set /A "$variant.field=0xE0, $variant.bits=3"
    If !$variant.layout! EQU 6 (
    Echo.Variant:   Old Microsoft Corporation layout. No decode available.
      Goto :END
    ) Else ( REM variant.layout EQU 7
      Echo.Variant:   Reserved for future definition. We may now be in the future but no
      Echo.           decode was available at the time of this writing.
      Goto :END
    )
  )
)
Set /A "$clock.bits=4-$variant.bits"
Set /A "$version=0x!$UID:~14,1!"
Echo.Variant:                       %$variant.layout%
Echo.Version:                  %$version%
Goto :Version.%$version%
:CommonV1V2
:: Change the byte order of the time field:
Set "$hex=%$UID:~15,1%"
For /L %%i in (12 -2 0) Do Set "$hex=!$hex!!$UID:~%%i,2!"
:: Node to display format:
Set /A "$node.admin=(%$UID:~20,1%>>1)&1"
Set /A "$node.cast=(%$UID:~20,1%)&1"
Set    "$node=%$UID:~20,2%-%$UID:~22,2%-%$UID:~24,2%-%$UID:~26,2%-"
Set    "$node=%$node%%$UID:~28,2%-%$UID:~30,2%"
If %$node.admin% EQU 0 (
  Set "$node.admin=universally"
) Else (
  Set "$node.admin=locally"
)
Goto :EOF
:ShowNode
Set /P "=Net node:  "<NUL:
CMD/A /C"%#GetMAC%|FindStr /I /C:"%$node%" || Echo.%$node%"
If %$node.cast% EQU 1 (
  Echo.           A false node address created in absence of a network card.
) Else (
  Echo.           A %$node.admin% administered IEEE 802 EUI-48/MAC-48 address.
)
Goto :EOF
:Version.1
Call :CommonV1V2
:: Clock sequence:
Set /A "$clock.field=(~$variant.field)&0xFF"
Set /A "$clock.high=(0x%$UID:~16,2%&$clock.field)"
Set /A "$clock=0x%$UID:~18,2%|($clock.high<<8)"
Set /A "$clock.high&=0xF0, $clock.high>>=4"
Set    "$clock.high=%$clock.high%%$UID:~17,1%"
Call :ToTime $hex $Time
Echo.UID Time:   %$UID.string:~0,14% %$UID.string:~15,3%
Echo.Clock Seq:                     %$clock.high%%$UID:~18,2%
Echo.Node:                               %$UID:~20,12%
Echo.Note: Variant has the high %$variant.bits% bits, clock has the lower %$clock.bits%.
Echo.
:: Spit out the answers:
Echo.Variant:   A UUID layout specified by RFC 4122.
Echo.Version 1: A time-based UUID.
Echo.UID Time:  %$Time%
Echo.           This time should be UTC but may be local time on systems which do
Echo.           not have UTC available. On Windows is probably the time the system
Echo.           was last booted. The uniqueness of time is supplemented by the
Echo.           clock sequence presented next.
Echo.Clock Seq: %$Clock%
Call :ShowNode
Goto :END
:Version.2
REM clock_seq_low:
REM typedef signed32 sec_rgy_domain_t;
 REM const signed32 sec_rgy_domain_person = 0;//"POSIX UID domain"
 REM const signed32 sec_rgy_domain_group = 1;//"POSIX GID domain"
 REM const signed32 sec_rgy_domain_org = 2; // Should not get this.

Call :CommonV1V2
:: Clock sequence:
Set /A "$clock.high=0x%$UID:~17,1%, $Clock=0x%$UID:~18,2%, $=$clock.high+1"
For /F "tokens=%$%" %%a in ("U G O") Do Set "$Posix=%%aID"
Set "$hex=%$hex:~0,7%00000000"
Call :ToTime $hex $Time
Echo.POSIX %$Posix%:  %$UID.string:~0,8%
Echo.UID Time:            %$UID.string:~9,4%  %$UID.string:~15,3%
Echo.Domain:                         %$clock.high%
Echo.Clock Seq:                       %$UID:~18,2%
Echo.Node:                               %$UID:~20,12%
Echo.Note: Variant has the high %$variant.bits% bits, clock has the lower %$clock.bits%.
Echo.
Echo.Variant:   A UUID layout specified by RFC 4122.
Echo.Version 2: DCE Security version, with	embedded POSIX UIDs. Unable to decode
Echo.           this version with any certainty. This is only a guess.
Echo.UID Time:  %$Time%
Echo.           The time for this version UUID is only the upper 4 bytes. 
Echo.Clock Seq: %$Clock%
Call :ShowNode
Goto :END
:Version.3
Echo.
Echo.Variant:   A UUID layout specified by RFC 4122.
Echo.Version 3: A name-based UID which uses MD5 hashing. The UUID is the hash.
Goto :END
:Version.4
Echo.
Echo.Variant:   A UUID layout specified by RFC 4122.
Echo.Version 4: A randomly or pseudo-randomly generated UID. The UUID is the number.
Goto :END
:Version.5
Echo.
Echo.Variant:   A UUID layout specified by RFC 4122.
Echo.Version 5: A name-based version which uses SHA-1 hashing. The UUID is the hash.
Goto :END
:Version.6
:Version.7
:Version.8
:Version.9
:Version.10
:Version.11
:Version.12
:Version.13
:Version.14
:Version.15
:Version.0
Echo.
Echo.Version %$version%: This version was not defined when this script was written.
Goto :END
:Invalid
Echo.The UUID is invalid. It must be 32 characters in one of these two forms: >&2
Echo.    a1a2a3a4-b1b2-c1c2-d1e1-f1f2f3f4f5f6 >&2
Echo.    a4a3a2a1b2b1c2c1d1e1e1f2f3f4f5f6 >&2
Exit /B 1
:END
If EXIST "%#eval.js%" DEL "%#eval.js%"
If EXIST "%#MY%" RD /S /Q "%#MY%"
REM  ....'....1....'....2....'....3....'....4....'....5....'....6....'....7....'....8
Goto :EOF
:ToTime varnameIN varnameOUT
SetLocal ENABLEEXTENSIONS
::These values are all hexadecimal. The math routines speak hex.
::Subtract #Offset from UUID time to make it an NT filetime.
Set "#Offset=0146BF33E42C000"
Set "#To1970=1B21DD213814000"
::PERIOD   100 NANOSECOND INTERVALS
::         HEXADECIMAL     DECIMAL
::yearLP   0x11F9AA3308000 (316224000000000)
::year     0x11ED178C6C000 (315360000000000)
::week     0x58028E44000   (6048000000000)
::day      0xC92A69C000    (864000000000)
::hour     0x861C46800     (36000000000)
::minute   0x23C34600      (600000000)
::second   0x989680        (10000000)
Set "$Short=[d.getUTCFullYear(),d.getUTCMonth()+1,d.getUTCDate(),d.getUTCHours(),d.getUTCMinutes(),d.getUTCSeconds()]"
Call :eval "d=new Date((0x!%~1!-0x%#To1970%)/10000);%$Short%"
Set "$Time=!eval!"
Call :eval "parseInt((0x!%~1!-0x%#Offset%) %%%% 10000000).toString()"
Set "$ns=000000!eval!" & Set "$ns=!$ns:~-7!"
Set "$=0"
For %%a in (%$Time%) Do Set "$Time.!$!=%%a" & Set /A "$+=1"
For /L %%i in (1,1,5) Do (
  Set "$Time.%%i=0!$Time.%%i!"
  Set "$Time.%%i=!$Time.%%i:~-2!"
)
Set "$Time=!$Time.0!-!$Time.1!-!$Time.2! !$Time.3!:!$Time.4!:!$Time.5!.!$ns!"
EndLocal&Set "%~2=%$Time%"
Goto :EOF
:eval expression
:: Prints the mathemagical result of the expression.
:: Permits 1024-bit numbers?? ???!
:: Parameters:
:: 1:  A math expression.
SetLocal ENABLEEXTENSIONS
If NOT DEFINED #eval.js Set "#eval.js=%TEMP%\eval.js"
Set "$return=%0"
For /F "delims=" %%a in ('Echo.%*') Do (
  EndLocal
  If NOT EXIST "%#eval.js%" (
    Echo.WScript.Echo(eval(WScript.Arguments(0^)^)^);>%#eval.js%
  )
  For /F "delims=" %%b in (
  'CSCRIPT /NOLOGO /E:JScript "%#eval.js%" "%%~a"') Do (
    Set "%$return:~1%=%%b"
  )
)
Goto :EOF
:GetUUID1
SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
Set "$UID=" & Set "$ObjectID="
FSutil ObjectID query %~f0 >NUL:
If %ErrorLevel% EQU 0 (
  REM Save IDs if they exist.
  Set "$ObjectID=TRUE" & Set "$=0"
  For /F "tokens=2 delims=:" %%2 in ('FSutil ObjectID create %~f0') Do (
    Set /A "$+=1"
    Set "$UID.!$!=%%2"
  )
  FSutil ObjectID delete %~f0
)
For /F "tokens=2 delims=:" %%2 in (
  'FSutil ObjectID create %~f0'
) Do (If NOT DEFINED $UID (For %%a in (%%2) Do Set "$UID=%%a"))
FSutil ObjectID delete %~f0
If DEFINED $ObjectID (
  REM Restore original IDs.
  FSutil ObjectID set %$UID.1% %$UID.2% %$UID.3% %$UID.4% %~f0
)
EndLocal & Set "$UID=%$UID%"
Goto :EOF
:GetUUID4
:: Todd Vargo, 2009-11-17; altered 2009-11-18,20 FPW
SetLocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
Set "RANDOM=" & Set "TIME=" & Set "$UID="
Set "$chrs=0123456789ABCDEF"
For /L %%i in (0,1,31) Do (
  If %%i EQU 14 (Set "$num=4") Else (
    Set /A "$num=(!RANDOM!+1!TIME:~-2!) %% 16"
    If %%i EQU 16 Set /A "$num=0x8 | ($num&0x3)"
  )
  Call Set $UID=!$UID!%%$chrs:~!$num!,1%%
)
EndLocal & Set "$UID=%$UID%"
Goto :EOF
