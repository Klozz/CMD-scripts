@Echo OFF
Call :unZip %*
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip [/CRC] <archive> [file list]
:: :unZip
:: Extracts files from an .ZIP archive.
:: From the desk of Frank P. Westlake, 2013-03-15
:: Compatibility identifier:           1
:: Requires :zip with same compatibility indicator.
:: Written on Windows 8.
:: Requires CERTUTIL.exe
:: Requires FSUTIL.exe write access.
:: Does not verify CRC unless switch /CRC is included.
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "tm=%TIME: =%"
Set "$ME=%~n0"
Set "$MY=%TEMP%\%~n0.%tm::=%%RANDOM%"
MkDir "!$MY!"
For %%f in (%*) Do (
  If /I "%%~f" EQU "/CRC" (
    Set "$checkCRC=true"
  ) Else If NOT DEFINED $zip ( Set "$zip=%%~ff"
  ) Else (
    Set $fileList=!$fileList! "%%~f"
  )
)
If NOT EXIST "!$zip!" (
  Echo Missing archive file.
  Goto :EOF
)>&2
Set "$self=0"
If "%~f0" EQU "%~f1" (
  For /F "delims=:" %%a  in ('FindStr /O /B /R "PK\>" "!$zip!"') Do (
    Set "$self=%%a"
    Goto :break
  )
)
:break
For %%a in ("%$zip%") Do Set /A "$zipSize2=%%~za*2"
CertUtil -f -encodeHex "%$zip%" "!$MY!\hex" 10 >NUL: 2>&1
Set "$file=0x10000"
Set "$revList=0x10000"
For /F "useBackQ tokens=1*" %%a in ("!$MY!\hex") Do (
  If 0x%%a GEQ !$file! (
    Set "$file=!$file!0"
    Set "$revList=!$file! !$revList!"
  )
  (Echo;%%a %%b)>>"!$MY!\hex.!$file!"
)
For %%a in (!$revList!) Do (
  SORT /R "!$MY!\hex.%%a" >>"!$MY!\rev"
  REM ERASE "!$MY!\hex.%%a"
)
For /F "usebackq tokens=1*" %%a in ("!$MY!\rev") Do (
  Set /A "$p=0x%%a"
  Set "$line=%%b"
  Set "$longLine=!$line: =!!$longLine!"
  If NOT DEFINED $cdOffset (
    If "!$longLine:504b0506=!" NEQ "!$longLine!" (
    For /L %%i in (0,2,30) Do (
        If /I "!$longLine:~%%i,8!" EQU "504b0506" (
          Set "$bytes=!$longLine:~%%i!"
          Call :unZip.byteToInt $cdOffset 32 8
          Set /A "$cdOffset+=$self"
          Set "$longLine=!$longLine:~0,%%i!"
        )
      )
    )
  ) Else If !$p! LSS !$cdOffset! (
    For /F %%o in ('Set /A "($cdOffset-$p)*2"') Do Set "$bytes=!$longLine:~%%o!"
    Call :unZip.504b0102
    REM ERASE "!$MY!\rev"
    CertUtil -f -encodeHex "%$zip%" "!$MY!\hex" 12 >NUL: 2>&1
    Echo;!$offsetList! | SORT>"!$MY!\offsetList"
    For /F "usebackq delims=" %%a in ("!$MY!\offsetList") Do Set "$offsetList=%%a"
    REM ERASE "!$MY!\offsetList" 1>NUL: 2>NUL:
    For %%o in (!$offsetList!) Do (
      For /F "tokens=1-5 delims=:" %%e in ("%%o") Do (
        Set /A "$fo=%%e+4, $xl=$zipSize2-$x, $dl=%%h, $nl=%%f, $crc32=%%i"
        COPY /Y "!$MY!\hex" "!$MY!\%%g.work" >NUL:
        fsUtil file setZeroData offset=0     length=%%e   "!$MY!\%%g.work" >NUL:
        fsUtil file setZeroData offset=!$fo! length=!$xl! "!$MY!\%%g.work" >NUL:
        For /F %%z in ('MORE /E /S "!$MY!\%%g.work"') Do (
          Set "$=%%z"
          Set /A "$p=$fo+$nl+0x!$:~2,2!!$:~0,2!*2, $z=$p+$dl, $zl=$zipSize2-$z"
        )
        COPY /Y "!$MY!\hex" "!$MY!\%%g.work" >NUL:
        Echo;%%g >"!$MY!\t.hex"
        CertUtil -f -decodeHex "!$MY!\t.hex" "!$MY!\t" 12 >NUL: 2>&1 && (
          For /F usebackq^ delims^=^ EOL^= %%n in ("!$MY!\t") Do (
Echo Extracting "%%n".
            fsUtil file setZeroData offset=0    length=!$p!  "!$MY!\%%g.work" >NUL:
            fsUtil file setZeroData offset=!$z! length=!$zl! "!$MY!\%%g.work" >NUL:
            MORE /E /S "!$MY!\%%g.work" >"!$MY!\%%g"
            CertUtil -f -decodeHex "!$MY!\%%g" "!$MY!\%%n" 12
            REM CertUtil -f -decodeHex "!$MY!\%%g" "!$MY!\%%n" 12 >NUL: 2>&1
            Set "$extracted="
            If DEFINED $fileList (
              For %%F in (!$fileList!) Do (
                If "%%~n" EQU "%%~F" (
                  COPY "!$MY!\%%n" "%%n">NUL:
                  Set "$extracted=true"
                )
                REM ERASE "!$MY!\%%n"
              )
            ) Else (
              MOVE "!$MY!\%%n" "%%n">NUL:
              Set "$extracted=true"
            )
            REM ERASE "!$MY!\%%g*" "!$MY!\t*"
            If DEFINED $extracted (
              If DEFINED $checkCRC (
                Echo Extracted "%%n".
                Call :unZip.getCRC32 crc "%%n"
                If !crc! NEQ !$crc32! Echo !$ME!: %%n has bad CRC: !$crc32! should be !crc!.>&2
              )
            )
          )
        )
      )
    )
    Goto :break
  )
)
:break
REM RD /S /Q "!$MY!"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip.504b0102 CentralRecord
Call :unZip.byteToInt $gpFlag        16 4
Call :unZip.byteToInt $method        20 4
Call :unZip.byteToInt $crc32         32 8
Call :unZip.byteToInt $compressed    40 8
Call :unZip.byteToInt $nameLength    56 4
Call :unZip.byteToInt $extraLength   60 4
Call :unZip.byteToInt $commentLength 64 4
Call :unZip.byteToInt $offset        84 8
Set /A "$offset+=$self"
Set /A "$v=92"
If !$nameLength! GTR 0 (
  Set /A "$L=$nameLength*2"
  For /F "tokens=1,2" %%n in ("!$v! !$L!") Do (
    Set "$name=!$bytes:~%%n,%%o!"
  )
  Set /A "$v+=$L"
)
Set /A "$v+=$extraLength*2"
Set /A "$v+=$commentLength*2"
Set /A "$p=56+$offset*2, $dl=$compressed*2"
Set /A "$nl=$nameLength*2"
Set /A "$test=0"^
,      "$test&=$gpFlag&0xFFFF" % REM No flags permitted in this configuration.       %^
,      "$test&=$method&0xFFFF" % REM No compression permitted in this configuration. %
If !$test! EQU 0 (
  Set /A "$p=56+$offset*2, $dl=$compressed*2"
  Set /A "$nl=$nameLength*2"
  Set "$offsetList=!$offsetList! !$p!:!$nl!:!$name!:!$dl!:!$crc32!"
) Else (
  REM Echo;Skipping.
)

For %%v in (!$v!) Do Set "$bytes=!$bytes:~%%v!"
If DEFINED $bytes Goto :unZip.504b0102
Erase "!$MY!\t" "!$MY!\t.hex" >NUL: 2>&1
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip.byteToInt <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Set "%~1="
Set "$=!$bytes:~%~2,%~3!"
set "#="
Set /A "n=0"
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do Set "$=!$:%%a= %%a!"
For %%a in (%$%) Do (
  If !n! EQU 0 (Set "@=%%a") Else (Set "#=!@!%%a!#!")
  Set /A "n=(n+1) %% 2"
)
Set /A "#=0x%#%"
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip.setTable
:zip.setTable
Set /A "xor=0xEDB88320"
For /L %%n in (0, 1, 255) Do (
  Set /A "c=%%n"
  For /L %%k in (8, -1, 1) Do (
    Set /A "t=c&1, c=(c>>1)&0x7FFFFFFF"
    If !t! NEQ 0 Set /A "c=xor^c"
    Set /A "TABLE%%n=c"
  )
)
Set "TABLE=%~f0"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip.getCRC32 <var name> <name of hex file>
If "!TABLE!" NEQ "%~f0" Call :unZip.setTable
:zip.getCRC32 <var name> <name of hex file>
If "!TABLE!" NEQ "%~f0" Call :zip.setTable
CertUtil -f -encodeHex "%~2" "!$MY!\crc" 4 >NUL: 2>&1
SetLocal EnableExtensions
Set /A "crc=~0"
For /F "usebackq delims=" %%L in ("!$MY!\crc") Do (
  For %%B in (%%L) Do (
    Set /A "n=(crc^0x%%B)&0xFF"
    For %%i in (!n!) Do Set "n=!TABLE%%i!"
    Set /A "crc=n^((crc>>8)&0xFFFFFF)"
  )
)
Set /A "crc=~crc"
EndLocal & Set "%~1=%crc%"
Erase "!$MY!\crc"
Goto :EOF
