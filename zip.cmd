@Echo OFF
Call :zip %*
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:zip [/CRC] <zip file> [file list ....]
:: Stores files into a .ZIP archive.
:: From the desk of Frank P. Westlake, 2013-03-18
:: Compatibility identifier:           1
:: Requires :unZip with same compatibility indicator.
:: Written on Windows 8.
:: Requires CERTUTIL.exe
:: Requires FSUTIL.exe write access.
:: Does not store CRC unless switch /CRC is included.
SetLocal EnableExtensions EnableDelayedExpansion
For /F "tokens=1 delims==" %%a in ('Set "$" 2^>NUL:') Do Set "%%a="
:: DEFAULTS
Set "$checkCRC=true"
:: END DEFAULTS
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
         If /I "%%~f" EQU "/CRC" (  Set "$checkCRC=true"
  ) Else If /I "%%~f" EQU "/-CRC" ( Set "$checkCRC="
  ) Else If NOT DEFINED $zip (      Set "$zip=%%~f"
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

    Set /A "@crc=0"
    If DEFINED $checkCRC Call :zip.getCRC32 @crc "%%~ff"
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
