:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ZipUnZipDemo.cmd
:: From the desk of Frank P. Westlake, 2013-03-14
:: Written on Windows 8.
:: Requires CERTUTIL.exe
:: Requires FSUTIL.exe write access.
@Goto :main
This script demonstrates the use of CERTUTIL to create a .ZIP archive with 
stored files and to extract those files from the archive. 

This script will create two files in the current directory as follows:

  Echo;How now brown cow? >cowInterrogation.txt

  DIR >dir.txt

Both those files will be added to an archive then deleted:

  CALL :zip zipArchive.zip cowInterrogation.txt dir.txt
  ERASE cowInterrogation.txt dir.txt

Then the files will be extracted from the archive by the unzip subroutine 
and displayed in the console, then the two text files will be deleted but 
the archive "zipArchive.zip" will remain so that you can examine it with
other ZIP utilities.

Both :zip and :unzip support only uncompressed files. 

:main
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "zip=zipFile.zip"

:: ERASE test files if pre-existing.
For %%a in (cowInterrogation.txt dir.txt "%zip%") Do (
  If EXIST "%%~a" ERASE  "%%~a"
)

:: Write test files.
Echo;How now brown cow? >cowInterrogation.txt
DIR >dir.txt

:: Make the archive.
Call :zip "%zip%" cowInterrogation.txt dir.txt

:: Erase the test files.
For %%a in (cowInterrogation.txt dir.txt) Do (
  If EXIST "%%~a" ERASE  "%%~a"
)

:: Extract the test files.
Call :unzip "%zip%"

:: Show the contents.
Echo;============ dir.txt ====================
TYPE dir.txt
Echo;
Echo;======= cowInterrogation.txt ============
TYPE cowInterrogation.txt
Echo;=========================================

:: Exit the script.
EXIT /B 0
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: :zip
:: Stores files into an .ZIP archive.
:: From the desk of Frank P. Westlake, 2013-03-12
:: Compatibility identifier:           1
:: Requires :unZip with same compatibility indicator.
:: Written on Windows 8.
:: Requires CERTUTIL.exe
:: Requires FSUTIL.exe write access.
:zip <zip file> [file list ....]
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "$tm=%TIME: =%"
Set "$ME=%~n0"
Set "$MY=%TEMP%\%~n0.%$tm::=%%RANDOM%"
MkDir "!$MY!"
TYPE NUL:>"!$MY!\zip"
TYPE NUL:>"!$MY!\CentralHex"
Set /A "$entries=0"
If "%~2" EQU "" ( Set "commandLine=%~1 *"
)          Else ( Set "commandLine=%*" )
For %%f in (%*) Do (
  If NOT DEFINED $zip ( Set "$zip=%%~f"
  ) Else (
    For /F "tokens=1 delims==" %%a in ('Set "@" 2^>NUL:') Do Set "%%a="
    Echo;Storing "%%~f" ...
    For %%a in ("!$MY!\zip") Do Set "@offset=%%~za"
    TYPE NUL:>"!$MY!\localHex"
    Set /P "=504b0304 " <NUL: >>"!$MY!\localHex"   % REM signature      %
    Set /P "=504b0102 " <NUL: >>"!$MY!\CentralHex" % REM signature      %

    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex  % REM Made by        %

    Set /P "=0000 "     <NUL: >>"!$MY!\localHex"   % REM needed         %
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex  % REM needed         %

    Set /P "=0000 "     <NUL: >>"!$MY!\localHex"   % REM flags          %
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex" % REM flags          %

    Set /P "=0000 "     <NUL: >>"!$MY!\localHex"   % REM method         %
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex" % REM method         %

    Call :zip.getTimeBytes @date @time %%~ff
    Set /P "=!@time! "  <NUL: >>"!$MY!\localHex"   % REM time           %
    Set /P "=!@time! "  <NUL: >>"!$MY!\CentralHex" % REM time           %

    Set /P "=!@date! "  <NUL: >>"!$MY!\localHex"   % REM date           %
    Set /P "=!@date! "  <NUL: >>"!$MY!\CentralHex" % REM date           %

    Call :zip.getCRC32 @crc "%%~ff"
    Call :zip.bytesFromInt @crc 4 !@crc!
    Set /P "=!@crc! "   <NUL: >>"!$MY!\localHex"   % REM CRC32          %
    Set /P "=!@crc! "   <NUL: >>"!$MY!\CentralHex" % REM CRC32          %

    Call :zip.bytesFromInt @bytes 4 %%~zf
    Set /P "=!@bytes! " <NUL: >>"!$MY!\localHex"   % REM compressed     %
    Set /P "=!@bytes! " <NUL: >>"!$MY!\CentralHex" % REM compressed     %

    Set /P "=!@bytes! " <NUL: >>"!$MY!\localHex"   % REM uncompressed   %
    Set /P "=!@bytes! " <NUL: >>"!$MY!\CentralHex" % REM uncompressed   %

    Call :zip.strlen @len "%%~nxf"
    Call :zip.bytesFromInt @len 2 !@len!
    Set /P "=!@len! "   <NUL: >>"!$MY!\localHex"   % REM name length    %
    Set /P "=!@len! "   <NUL: >>"!$MY!\CentralHex" % REM name length    %

    Set /P "=0000 "     <NUL: >>"!$MY!\localHex"   % REM extra length   %
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex" % REM extra length   %

    REM Central data structure only.
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex" % REM comment length %
    Set /P "=0100 "     <NUL: >>"!$MY!\CentralHex" % REM disk           %
    Set /P "=0000 "     <NUL: >>"!$MY!\CentralHex" % REM internal attr  %
    Set /A "@attr=0"
    For /F "tokens=2 delims=:" %%A in ('fsUtil usn readData "%%~ff"^|Find /I "File Attributes"') Do (
      Set /A "@attr=%%A"
    )
    Call :zip.bytesFromInt @attr 4 !@attr!
    Set /P "=!@attr! " <NUL: >>"!$MY!\CentralHex" % REM external attr  %

    Call :zip.bytesFromInt @offset 4 !@offset!
    Set /P "=!@offset! "<NUL: >>"!$MY!\CentralHex" % REM header offset  %

    REM File name
    (Echo;%%~nxf)>"!$MY!\name"
    CertUtil -f -encodeHex "!$MY!\name" "!$MY!\nameHex" 12 1>NUL: 2>NUL:
    For /F "delims=" %%n in ('TYPE "!$MY!\nameHex"') Do (
      Set "@name=%%~n"
      (Set /P "=!@name:0d0a=!"<NUL:)>"!$MY!\nameHex"
    )
    TYPE "!$MY!\nameHex" >>"!$MY!\localHex"
    TYPE "!$MY!\nameHex" >>"!$MY!\CentralHex"

    REM Extra field
    REM None.

    REM Comment field
    REM None.

    REM Write file header and file to zip.
    CertUtil -f -decodeHex "!$MY!\localHex" "!$MY!\local" 12 1>NUL: 2>NUL:
    TYPE "!$MY!\local" >>"!$MY!\zip"
    TYPE "%%~ff"        >>"!$MY!\zip"
    Set /A "$entries+=1"
  )
)
ERASE "!$MY!\local*"
For %%a in ("!$MY!\zip") Do Set "$offset=%%~za"

REM Write central data structure.
CertUtil -f -decodeHex "!$MY!\CentralHex" "!$MY!\Central" 12 1>NUL: 2>NUL:
For %%a in ("!$MY!\Central") Do Set "$size=%%~za"
TYPE "!$MY!\Central" >>"!$MY!\zip"
ERASE "!$MY!\Central*"

REM Begin ending data structure.
TYPE NUL:>"!$MY!\EndHex"
Set /P "=504b0506 "  <NUL: >>"!$MY!\EndHex"     % REM signature        %
Set /P "=0000 "      <NUL: >>"!$MY!\EndHex"     % REM disk #           %
Set /P "=0000 "      <NUL: >>"!$MY!\EndHex"     % REM directory disk   %
Call :zip.bytesFromInt $entries 2 !$entries!
Set /P "=!$entries! "<NUL: >>"!$MY!\EndHex"     % REM entries disk     %
Set /P "=!$entries! "<NUL: >>"!$MY!\EndHex"     % REM entries total    %
Call :zip.bytesFromInt $size 4 !$size!
Set /P "=!$size! "   <NUL: >>"!$MY!\EndHex"     % REM size             %
Call :zip.bytesFromInt $offset 4 !$offset!
Set /P "=!$offset! " <NUL: >>"!$MY!\EndHex"     % REM directory offset %
Set /P "=0000 "      <NUL: >>"!$MY!\EndHex"     % REM comment length   %
REM Comment
REM none
REM Write ending data structure.
CertUtil -f -decodeHex "!$MY!\EndHex" "!$MY!\End" 12 1>NUL: 2>NUL:
TYPE "!$MY!\End" >>"!$MY!\zip"
ERASE "!$MY!\End*"
MOVE "!$MY!\zip" "!$zip!" >NUL:
RD /S /Q "!$MY!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:zip.getTimeBytes <date return variable> <time return variable> <file>
SetLocal EnableExtensions EnableDelayedExpansion
REM time: bits 0-4 are seconds/2 (0 - 29) 
      REM bits 5-10 are minutes (0 - 59) 
      REM bits 11-15 are hours (0 - 23) 
REM date: bits 0-4 are the date (1-31)
      REM bits 5-8 are the month (1-12) 
      REM bits 9-15 are the year (add 1980 to get the correct value)
REM 0    4  6  8  A  C
REM 2012 12 03 06 46 58
Set "file=%~3"
For /F "tokens=2 delims==." %%a in (
  'wmic datafile where name^="%file:\=\\%" get LastModified /format:list'
) Do Set "#=%%a"
Set /A "#date=((%#:~0,4%-1980)<<9)|((1%#:~4,2%-100)<<5)|(1%#:~6,2%-100)"
Set /A "#time=((1%#:~8,2%-100)<<11)|((1%#:~10,2%-100)<<5)|(1%#:~12,2%-100)/2"
Call :zip.bytesFromInt #date 2 !#date!
Call :zip.bytesFromInt #time 2 !#time!
EndLocal & Set "%~1=%#date%" & Set "%~2=%#time%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:zip.strlen <return variable> <quoted string>
:: I.e.: 'Call :strlen length "C:\temp\junk.txt"' sets length=16
For /F delims^=:^ EOL^= %%a in (
  '(Echo;%~2^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"') Do Set /A "%~1=%%a-3"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:zip.bytesFromInt <var> < # bytes > <int>
SetLocal EnableExtensions EnableDelayedExpansion
set "hex=0123456789ABCDEF"
Set /A "int=%~3"
Set "$="
For /L %%i in (1,1,%~2) Do (
  Set /A "L=int&0x0F, int>>=4, H=int&0xF, int>>=4"
  For /F "tokens=1,2" %%j in ("!H! !L!") Do (
    Set "$=!$!!hex:~%%j,1!!hex:~%%k,1!"
  )
)
EndLocal & Set "%~1=%$%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:unZip <archive> [file list]
:: :unZip
:: Extracts files from an .ZIP archive.
:: From the desk of Frank P. Westlake, 2013-03-09
:: Compatibility identifier:           1
:: Requires :zip with same compatibility indicator.
:: Written on Windows 8.
:: Requires CERTUTIL.exe
:: Requires FSUTIL.exe write access.
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
Set "tm=%TIME: =%"
Set "$ME=%~n0"
Set "$MY=%TEMP%\%~n0.%tm::=%%RANDOM%"
MkDir "!$MY!"
For %%f in (%*) Do (
  If NOT DEFINED $zip ( Set "$zip=%%~ff"
  ) Else (
    Set $fileList=!$fileList! "%%~f"
  )
)
Set "$self=0"
If "%~f0" EQU "%~f1" (
  For /F "delims=:" %%a  in ('FindStr /O /B /R "PK\>" "!$zip!"') Do (
    Set "$self=%%a"
    Goto :break
  )
)
:break
For %%a in ("%$zip%") Do Set /A "$zipSize2=2*%%~za"
CertUtil -f -encodeHex "%$zip%" "!$MY!\hex" 10 >NUL: 2>&1
SORT /R "!$MY!\hex" /O "!$MY!\rev"
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
    ERASE "!$MY!\rev"
    CertUtil -f -encodeHex "%$zip%" "!$MY!\hex" 12 >NUL: 2>&1
    Echo;!$offsetList! | SORT>"!$MY!\offsetList"
    For /F "usebackq delims=" %%a in ("!$MY!\offsetList") Do Set "$offsetList=%%a"
    ERASE "!$MY!\offsetList" 1>NUL: 2>NUL:
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
          For /F usebackq^ delims^=^  %%n in ("!$MY!\t") Do (
            fsUtil file setZeroData offset=0    length=!$p!  "!$MY!\%%g.work" >NUL:
            fsUtil file setZeroData offset=!$z! length=!$zl! "!$MY!\%%g.work" >NUL:
            MORE /E /S "!$MY!\%%g.work" >"!$MY!\%%g"
            CertUtil -f -decodeHex "!$MY!\%%g" "!$MY!\%%n" 12 >NUL: 2>&1
Echo Extracting "%%n".
            Set "$extracted="
            If DEFINED $fileList (
              For %%F in (!$fileList!) Do (
                If "%%~n" EQU "%%~F" (
                  COPY "!$MY!\%%n" "%%n">NUL:
                  Set "$extracted=true"
                )
                ERASE "!$MY!\%%n"
              )
            ) Else (
              MOVE "!$MY!\%%n" "%%n">NUL:
              Set "$extracted=true"
            )
            ERASE "!$MY!\%%g*" "!$MY!\t*"
            If DEFINED $extracted (
              Echo Extracted "%%n".
              Call :unZip.getCRC32 crc "%%n"
              If !crc! NEQ !$crc32! Echo !$ME!: %%n has bad CRC: !$crc32! should be !crc!.>&2
            )
          )
        )
      )
    )
    Goto :break
  )
)
:break
RD /S /Q "!$MY!"
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
:: END SCRIPT ::::::::::::::::::::::::::::::::::::::::::::::::::::
