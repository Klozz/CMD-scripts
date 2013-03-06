:: readShortcut.cmd
:: From the desk of Frank P. Westlake, 2013-03-05
:: Displays the disassembly of a shortcut file.
:: Written on Windows 8.
:: Requires CERTUTIL, FORFILES.
:: Use MicroSoft's "[MS-SHLLINK]: Shell Link (.LNK) Binary File Format"
:: as documentation for the settings and values in this script.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "ME=%~n0"
Set "MEdp=%~dp0"
Set "MEnx=%~nx0"
Set "link=%~f1"
If ""   EQU "%~1" Goto :help
If "/?" EQU "%~1" Goto :help
If NOT EXIST "%link%" (
  For /F "delims=" %%a in ('NET helpmsg 2') Do Echo;%ME%: %%a
  Goto :EOF
)>&2
Set "MESELF=%~f0"
Set "MY=%TEMP%\%ME%.%random%"
MkDir "%MY%"
Call :readShortcut "%link%"
RD /S /Q "%MY%"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:help
Echo;%~n0 ^<shortcut file^>
Echo;Displays a disassembly of the shortcut file.
Echo;
Echo;Use MicroSoft's "[MS-SHLLINK]: Shell Link (.LNK) Binary File Format"
Echo;as documentation for the settings and values in this script.
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:readShortcut <link file>
SetLocal EnableExtensions EnableDelayedExpansion
For /F "delims=" %%a in ('ForFiles /P "%MEdp:~0,-1%" /M "%MEnx%" /C "cmd /c Echo;0x08"') Do Set "BS=%%a"
certUtil -encodeHex "%~f1" "%MY%\hex" 12 >NUL: || (
  Echo %ME%: Unable todecode this file.
  Goto :EOF
)>&2
For /F "usebackq delims=" %%a in ("%MY%\hex") Do Set "S=%%a"
Echo;SHELL_LINK_HEADER *****************************************************
Set /A "@=0" % REM #=offset, @=next offset, L=length %
Set /A "L=8,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo HeaderSize:                      !$!
Set /A "L=32, #=@,@+=L" & Call :toCSLID     $         !#! !L! & Echo;LinkCLSID:                       !$!
Set /A "L=8,  #=@,@+=L" & Call :LinkFlags   LinkFlags !#! !L!
Set /A "L=8,  #=@,@+=L" & Call :Attributes  attr      !#! !L!
Set /A "L=16, #=@,@+=L" & Call :readTime    $         !#! !L! & Echo;CreationTime:                    !$!
Set /A "L=16, #=@,@+=L" & Call :readTime    $         !#! !L! & Echo;AccessTime:                      !$!
Set /A "L=16, #=@,@+=L" & Call :readTime    $         !#! !L! & Echo;WriteTime:                       !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo FileSize:                        !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo IconIndex:                       !$!
Set /A "L=8,  #=@,@+=L" & Call :ShowCommand           !#! !L!
Set /A "L=4,  #=@,@+=L" & Call :HotKey                !#!
Set /A "L=4,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo Reserved1:                       !$! (Must be zero)
Set /A "L=8,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo Reserved2:                       !$! (Must be zero)
Set /A "L=8,  #=@,@+=L" & Call :toInt       $         !#! !L! & Echo Reserved3:                       !$! (Must be zero)
Set /A "#=@"
Set /A "$=LinkFlags&LinkFlags_HasLinkTargetIDList"
If !$! NEQ 0 Call :LinkTargetIDList # !#!
Set /A "$=LinkFlags&LinkFlags_HasLinkInfo"
If !$! NEQ 0 Call :LinkInfo # !#!
Set /A "$=LinkFlags&(LinkFlags_HasName|LinkFlags_HasRelativePath|LinkFlags_HasWorkingDir|LinkFlags_HasArguments|LinkFlags_HasIconLocation)"
If !$! NEQ 0 ECHO STRINGDATA ************************************************************
Set /A "$=LinkFlags&LinkFlags_HasName"         & If !$! NEQ 0 Call :StringData # !#! "NAME_STRING"
Set /A "$=LinkFlags&LinkFlags_HasRelativePath" & If !$! NEQ 0 Call :StringData # !#! "RELATIVE_PATH"
Set /A "$=LinkFlags&LinkFlags_HasWorkingDir"   & If !$! NEQ 0 Call :StringData # !#! "WORKING_DIR"
Set /A "$=LinkFlags&LinkFlags_HasArguments"    & If !$! NEQ 0 Call :StringData # !#! "COMMAND_LINE_ARGUMENTS"
Set /A "$=LinkFlags&LinkFlags_HasIconLocation" & If !$! NEQ 0 Call :StringData # !#! "ICON_LOCATION"
For %%a in (!#!) Do Set "S=!S:~%%a!"
If DEFINED S Call :ExtraData @ 0
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:StringData <result variable> <offset> <which type>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Echo;%~3:
Set /A "L=4,  #=@,@+=L" & Call :toInt size !#! !L! & Echo   Size:                          !size!
Set /A "#=@, size*=4"
For /F "tokens=1,2" %%i in ("!#! !size!") Do (
  Set /P "=!S:~%%~i,%%~j!"<NUL:>"%MY%\data.hex"
)
Set /A "#+=size"
CertUtil -f -decodeHex "%MY%\data.hex" "%MY%\data" >NUL: 2>&1 && (
  Set "$="
  For /F "delims=" %%a in ('MORE /E "%MY%\data"') Do Set "$=!$!%%a"
  Echo;  Data:                          "!$!"
  REM TYPE "%MY%\data"
)
REM Echo;
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:LinkInfo <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
ECHO LINKINFO **************************************************************
Set /A "@=%~2"
Set /A "L=8,  #=@,@+=L" & Call :toInt LinkInfo                        !#! !L! & Echo;LinkInfoSize:                    !LinkInfo!
Set /A "L=8,  #=@,@+=L" & Call :toInt LinkInfoHeader                  !#! !L! & Echo;LinkInfoHeaderSize:              !LinkInfoHeader!
Set /A "L=8,  #=@,@+=L"
Call :byteToHex $ !#! !L! & Call :toInt LinkInfoFlags                   !#! !L!
Echo;LinkInfoFlags:                   0x!$!
Set /A "VolumeIDAndLocalBasePath=LinkInfoFlags&0x1, CommonNetworkRelativeLinkAndPathSuffix=LinkInfoFlags&0x2"
If !VolumeIDAndLocalBasePath!               NEQ 0 Echo;                                 VolumeIDAndLocalBasePath
If !CommonNetworkRelativeLinkAndPathSuffix! NEQ 0 Echo;                                 CommonNetworkRelativeLinkAndPathSuffix
Set /A "L=8,  #=@,@+=L" & Call :toInt VolumeIDOffset                  !#! !L! & Echo;VolumeIDOffset:                  !VolumeIDOffset!
Set /A "L=8,  #=@,@+=L" & Call :toInt LocalBasePathOffset             !#! !L! & Echo;LocalBasePathOffset:             !LocalBasePathOffset!
Set /A "L=8,  #=@,@+=L" & Call :toInt CommonNetworkRelativeLinkOffset !#! !L! & Echo;CommonNetworkRelativeLinkOffset: !CommonNetworkRelativeLinkOffset!
Set /A "L=8,  #=@,@+=L" & Call :toInt CommonPathSuffixOffset          !#! !L! & Echo;CommonPathSuffixOffset:          !CommonPathSuffixOffset!
If !LinkInfoHeader! GEQ 0x24 (
  Set /A "L=8,  #=@,@+=L" & Call :toInt LocalBasePathOffsetUnicode    !#! !L! & Echo;LocalBasePathOffsetUnicode:      !LocalBasePathOffsetUnicode!
  Set /A "L=8,  #=@,@+=L" & Call :toInt CommonPathSuffixOffsetUnicode !#! !L! & Echo;CommonPathSuffixOffsetUnicode:   !CommonPathSuffixOffsetUnicode!
)
If !VolumeIDAndLocalBasePath! NEQ 0 (
  REM VolumeID
  Set /A "@=%~2+VolumeIDOffset*2, VolumeIDStructure=@"
  Set /A "L=8,  #=@,@+=L" & Call :toInt VolumeIDSize                  !#! !L! & Echo;VolumeIDSize:                    !VolumeIDSize!
  Set /A "L=8,  #=@,@+=L" & Call :toInt DriveType !#! !L!
  Set /P "=DriveType:                       "<NUL:
  If !DriveType! EQU 0 (
    Echo;Cannot be determined
  ) Else If !DriveType! EQU 1 (
    Echo;Root path is invalid
  ) Else If !DriveType! EQU 2 (
    Echo;Removable media
  ) Else If !DriveType! EQU 3 (
    Echo;Fixed media
  ) Else If !DriveType! EQU 4 (
    Echo;Remote media
  ) Else If !DriveType! EQU 5 (
    Echo;CD-ROM drive
  ) Else If !DriveType! EQU 6 (
    Echo;RAM disk
  ) Else (
    Echo;Unknown drive type value: !DriveType!
  )
  Set /A "L=8,  #=@,@+=L" & Call :ByteToHex DriveSerialNumber         !#! !L! & Echo;Serial:                          !DriveSerialNumber:~0,4!-!DriveSerialNumber:~4!
  Set /A "L=8,  #=@,@+=L" & Call :toInt VolumeLabelOffset             !#! !L! & Echo;VolumeLabelOffset:               !VolumeLabelOffset!
  If !VolumeLabelOffset! EQU 0x14 (
    Set /A "L=8,  #=@,@+=L" & Call :toInt VolumeLabelOffsetUnicode    !#! !L! & Echo;VolumeLabelOffsetUnicode:        !VolumeLabelOffsetUnicode!
    Set /P "=VolumeLabel:                     "<NUL
    Call :Decode @ "VolumeIDStructure+VolumeLabelOffsetUnicode*2" unicode
  ) Else (
    Set /P "=VolumeLabel:                     "<NUL
    Call :Decode @ "VolumeIDStructure+VolumeLabelOffset*2"
  )
  If !LocalBasePathOffset! NEQ 0 (
    Set /P "=LocalBasePath:                   "<NUL
    Call :Decode @ "%~2+LocalBasePathOffset*2"
  )
  If !LinkInfoHeader! GEQ 0x24 (
    If !LocalBasePathOffsetUnicode! NEQ 0 (
      Set /P "=LocalBasePathUnicode:            "<NUL
      Call :Decode @ "%~2+LocalBasePathOffsetUnicode*2"
    )
  )
)

If !CommonNetworkRelativeLinkAndPathSuffix! NEQ 0 (
  If !CommonNetworkRelativeLinkOffset! NEQ 0 (
    Call :CommonNetworkRelativeLink @ "%~2+CommonNetworkRelativeLinkOffset*2"
  )
)
REM CommonPathSuffix
If !CommonPathSuffixOffset! NEQ 0 (
  Set /P "=CommonPathSuffix:                "<NUL
  Call :Decode @ "%~2+CommonPathSuffixOffset*2"
)
If !LinkInfoHeader! GEQ 0x24 (
  REM LocalBasePathUnicode
  If !LocalBasePathOffsetUnicode! NEQ 0 (
    Set /P "=LocalBasePathUnicode:            "<NUL
    Call :Decode @ "%~2+LocalBasePathOffsetUnicode*2"
  )
  REM CommonPathSuffixUnicode
  If !CommonPathSuffixOffsetUnicode! NEQ 0 (
    Set /P "=CommonPathSuffixUnicode:         "<NUL
    Call :Decode @ "%~2+CommonPathSuffixOffsetUnicode*2"
  )
)

Set /A "#=%~2+LinkInfo*2"
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CommonNetworkRelativeLink <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "L=8,  #=@,@+=L" & Call :toInt size !#! !L! & Echo;CommonNetworkRelativeLinkSize:   !size!
If !size! LSS 0x14 (EndLocal & Set "%~1=!#!" & Goto :EOF)
Set /A "L=8,  #=@" & Call :toInt flags !#! !L! & Call :byteToHex $ !#! !L!
Set /A "@+=L"
Echo;CommonNetworkRelativeLinkFlags:  0x!$!
Set /A "ValidDevice=flags&1, ValidNetType=flags&2"
If !ValidDevice!  NEQ 0 Echo;                                 ValidDevice
If !ValidNetType! NEQ 0 Echo;                                 ValidNetType
Set /A "L=8,  #=@,@+=L" & Call :toInt NetNameOffset !#! !L!       & Echo;NetNameOffset:                   !NetNameOffset!
Set /A "L=8,  #=@,@+=L" & Call :toInt DeviceNameOffset !#! !L!    & Echo;DeviceNameOffset:                !DeviceNameOffset!
Set /A "L=8,  #=@,@+=L" & Call :byteToHex $ !#! !L! 
If !ValidNetType! NEQ 0 (
  Call :toInt NetworkProviderType !#! !L! & Echo;NetworkProviderType:             0x!$!
  Call :netType $ !NetworkProviderType!   & Echo;                                 !$!
) Else (
  Call :toInt NetworkProviderType !#! !L! & Echo;NetworkProviderType:             0x!$! (ignored)
)
If !NetNameOffset! GTR 0x14 (
  Set /A "L=8,  #=@,@+=L" & Call :toInt NetNameOffsetUnicode !#! !L!       & Echo;NetNameOffsetUnicode:            !NetNameOffsetUnicode!
  Set /A "L=8,  #=@,@+=L" & Call :toInt DeviceNameOffsetUnicode !#! !L!       & Echo;DeviceNameOffsetUnicode:         !DeviceNameOffsetUnicode!
  Set /P "=NetNameUnicode:                  "<NUL
  Call :Decode @ "%~2+NetNameOffsetUnicode*2" unicode
  Set /A 
  Set /P "=DeviceNameUnicode:               "<NUL
  Call :Decode @ "%~2+DeviceNameOffsetUnicode*2" unicode
) Else (
  Set /P "=NetName:                         "<NUL
  Call :Decode @ "%~2+NetNameOffset*2" 
  Set /P "=DeviceName:                      "<NUL
  Call :Decode @ "%~2+DeviceNameOffset*2" 
)
Set /A "#=%~2+CommonNetworkRelativeLinkSize*2"
EndLocal & Set "%~1=!#!"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:netType <result variable> <type>
If %~2 EQU 0x00010000 (Set "%~1=WNNC_NET_MSNET" & Goto :EOF)
If %~2 EQU 0x00020000 (Set "%~1=WNNC_NET_LANMAN" & Goto :EOF)
If %~2 EQU 0x00030000 (Set "%~1=WNNC_NET_NETWARE" & Goto :EOF)
If %~2 EQU 0x00040000 (Set "%~1=WNNC_NET_VINES" & Goto :EOF)
If %~2 EQU 0x00050000 (Set "%~1=WNNC_NET_10NET" & Goto :EOF)
If %~2 EQU 0x00060000 (Set "%~1=WNNC_NET_LOCUS" & Goto :EOF)
If %~2 EQU 0x00070000 (Set "%~1=WNNC_NET_SUN_PC_NFS" & Goto :EOF)
If %~2 EQU 0x00080000 (Set "%~1=WNNC_NET_LANSTEP" & Goto :EOF)
If %~2 EQU 0x00090000 (Set "%~1=WNNC_NET_9TILES" & Goto :EOF)
If %~2 EQU 0x000A0000 (Set "%~1=WNNC_NET_LANTASTIC" & Goto :EOF)
If %~2 EQU 0x000B0000 (Set "%~1=WNNC_NET_AS400" & Goto :EOF)
If %~2 EQU 0x000C0000 (Set "%~1=WNNC_NET_FTP_NFS" & Goto :EOF)
If %~2 EQU 0x000D0000 (Set "%~1=WNNC_NET_PATHWORKS" & Goto :EOF)
If %~2 EQU 0x000E0000 (Set "%~1=WNNC_NET_LIFENET" & Goto :EOF)
If %~2 EQU 0x000F0000 (Set "%~1=WNNC_NET_POWERLAN" & Goto :EOF)
If %~2 EQU 0x00100000 (Set "%~1=WNNC_NET_BWNFS" & Goto :EOF)
If %~2 EQU 0x00110000 (Set "%~1=WNNC_NET_COGENT" & Goto :EOF)
If %~2 EQU 0x00120000 (Set "%~1=WNNC_NET_FARALLON" & Goto :EOF)
If %~2 EQU 0x00130000 (Set "%~1=WNNC_NET_APPLETALK" & Goto :EOF)
If %~2 EQU 0x00140000 (Set "%~1=WNNC_NET_INTERGRAPH" & Goto :EOF)
If %~2 EQU 0x00150000 (Set "%~1=WNNC_NET_SYMFONET" & Goto :EOF)
If %~2 EQU 0x00160000 (Set "%~1=WNNC_NET_CLEARCASE" & Goto :EOF)
If %~2 EQU 0x00170000 (Set "%~1=WNNC_NET_FRONTIER" & Goto :EOF)
If %~2 EQU 0x00180000 (Set "%~1=WNNC_NET_BMC" & Goto :EOF)
If %~2 EQU 0x00190000 (Set "%~1=WNNC_NET_DCE" & Goto :EOF)
If %~2 EQU 0x001A0000 (Set "%~1=WNNC_NET_AVID" & Goto :EOF)
If %~2 EQU 0x001B0000 (Set "%~1=WNNC_NET_DOCUSPACE" & Goto :EOF)
If %~2 EQU 0x001C0000 (Set "%~1=WNNC_NET_MANGOSOFT" & Goto :EOF)
If %~2 EQU 0x001D0000 (Set "%~1=WNNC_NET_SERNET" & Goto :EOF)
If %~2 EQU 0x001E0000 (Set "%~1=WNNC_NET_RIVERFRONT1" & Goto :EOF)
If %~2 EQU 0x001F0000 (Set "%~1=WNNC_NET_RIVERFRONT2" & Goto :EOF)
If %~2 EQU 0x00200000 (Set "%~1=WNNC_NET_DECORB" & Goto :EOF)
If %~2 EQU 0x00210000 (Set "%~1=WNNC_NET_PROTSTOR" & Goto :EOF)
If %~2 EQU 0x00220000 (Set "%~1=WNNC_NET_FJ_REDIR" & Goto :EOF)
If %~2 EQU 0x00230000 (Set "%~1=WNNC_NET_DISTINCT" & Goto :EOF)
If %~2 EQU 0x00240000 (Set "%~1=WNNC_NET_TWINS" & Goto :EOF)
If %~2 EQU 0x00250000 (Set "%~1=WNNC_NET_RDR2SAMPLE" & Goto :EOF)
If %~2 EQU 0x00260000 (Set "%~1=WNNC_NET_CSC" & Goto :EOF)
If %~2 EQU 0x00270000 (Set "%~1=WNNC_NET_3IN1" & Goto :EOF)
If %~2 EQU 0x00280000 (Set "%~1=This is an unspecified value" & Goto :EOF)
If %~2 EQU 0x00290000 (Set "%~1=WNNC_NET_EXTENDNET" & Goto :EOF)
If %~2 EQU 0x002A0000 (Set "%~1=WNNC_NET_STAC" & Goto :EOF)
If %~2 EQU 0x002B0000 (Set "%~1=WNNC_NET_FOXBAT" & Goto :EOF)
If %~2 EQU 0x002C0000 (Set "%~1=WNNC_NET_YAHOO" & Goto :EOF)
If %~2 EQU 0x002D0000 (Set "%~1=WNNC_NET_EXIFS" & Goto :EOF)
If %~2 EQU 0x002E0000 (Set "%~1=WNNC_NET_DAV" & Goto :EOF)
If %~2 EQU 0x002F0000 (Set "%~1=WNNC_NET_KNOWARE" & Goto :EOF)
If %~2 EQU 0x00300000 (Set "%~1=WNNC_NET_OBJECT_DIRE" & Goto :EOF)
If %~2 EQU 0x00310000 (Set "%~1=WNNC_NET_MASFAX" & Goto :EOF)
If %~2 EQU 0x00320000 (Set "%~1=WNNC_NET_HOB_NFS" & Goto :EOF)
If %~2 EQU 0x00330000 (Set "%~1=WNNC_NET_SHIVA" & Goto :EOF)
If %~2 EQU 0x00340000 (Set "%~1=WNNC_NET_IBMAL" & Goto :EOF)
If %~2 EQU 0x00350000 (Set "%~1=WNNC_NET_LOCK" & Goto :EOF)
If %~2 EQU 0x00360000 (Set "%~1=WNNC_NET_TERMSRV" & Goto :EOF)
If %~2 EQU 0x00370000 (Set "%~1=WNNC_NET_SRT" & Goto :EOF)
If %~2 EQU 0x00380000 (Set "%~1=WNNC_NET_QUINCY" & Goto :EOF)
If %~2 EQU 0x00390000 (Set "%~1=WNNC_NET_OPENAFS" & Goto :EOF)
If %~2 EQU 0x003A0000 (Set "%~1=WNNC_NET_AVID1" & Goto :EOF)
If %~2 EQU 0x003B0000 (Set "%~1=WNNC_NET_DFS" & Goto :EOF)
If %~2 EQU 0x003C0000 (Set "%~1=WNNC_NET_KWNP" & Goto :EOF)
If %~2 EQU 0x003D0000 (Set "%~1=WNNC_NET_ZENWORKS" & Goto :EOF)
If %~2 EQU 0x003E0000 (Set "%~1=WNNC_NET_DRIVEONWEB" & Goto :EOF)
If %~2 EQU 0x003F0000 (Set "%~1=WNNC_NET_VMWARE" & Goto :EOF)
If %~2 EQU 0x00400000 (Set "%~1=WNNC_NET_RSFX" & Goto :EOF)
If %~2 EQU 0x00410000 (Set "%~1=WNNC_NET_MFILES" & Goto :EOF)
If %~2 EQU 0x00420000 (Set "%~1=WNNC_NET_MS_NFS" & Goto :EOF)
If %~2 EQU 0x00430000 (Set "%~1=WNNC_NET_GOOGLE" & Goto :EOF)
Set "%~1=This is an unspecified value"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:LinkTargetIDList <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Echo;LINKTARGET_IDLIST *****************************************************
Set /A "@=%~2"
Set "space=                    "
Set /A "L=4,  #=@,@+=L" & Call :toInt IDListSize !#! !L! & Echo;ID list size:!space!!IDListSize!
:LinkTargetIDList.ItemID
Set /A "L=4,  #=@,@+=L" & Call :toInt ItemIDSize !#! !L! & Echo;Item ID size:!space!!ItemIDSize! (data + size)
If !ItemIDSize! EQU 0 (EndLocal & Set "%~1=%@%" & Goto :EOF)
Set /A "L=ItemIDSize*2-4,  #=@,@+=L" & Call :byteToHex $ !#! !L! & Echo;        Data:!space!!$!
Goto :LinkTargetIDList.ItemID
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HotKey <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Call :toInt L %~1 2
Set "space=                          "
If !L! EQU 0 (Echo;HotKey:!space!Not assigned & Goto :EOF)
Set /A "O2=%~1+2"
Call :toInt H %O2% 2
If %L% LEQ 0x39 (
  Set /A "key=L-0x30"
) Else If %L% LEQ 0x5A (
  Set /A "L-=0x41"
  Set "X=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  For %%L in (!L!) Do Set "key=!X:~%%L,1!"
) Else If %L% LEQ 0x87 (
  Set /A "L-=0x6F"
  Set "key=F!L!"
) Else If %L% LEQ 0x90 (
  Set "key=NUM LOCK"
) Else If %L% LEQ 0x910 (
  Set "key=SCROLL LOCK" 
) Else (
  Set "key=Unknown value key: !L!"
)
Set /A "S=!H!&0x01"^
,      "C=!H!&0x02"^
,      "A=!H!&0x04"
Set "H="
If %S% NEQ 0 Set "H=!H!SHIFT "
If %C% NEQ 0 Set "H=!H!CONTROL "
If %A% NEQ 0 Set "H=!H!ALT "
Set "H=!H:~0,-1!"
If DEFINED H Set "key=!H! !key!
:end
Echo;HotKey:!space![!key!]
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ShowCommand <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Call :toInt $ %~1 %~2
Set /P "=ShowCommand:                     "<NUL:
       If !$! EQU 1 (
  Echo;Normal
) Else If !$! EQU 3 (
  Echo;Maximized
) Else If !$! EQU 7 (
  Echo;Minimized
) Else (
  Echo;Normal with a ShowCommand value of !$!
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:readTime <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Call :byteToHex $ %~2 %~3
For /F "tokens=1* delims=-" %%a in ('w32tm -ntte 0x!$!') Do (
  Set "$=%%b"
)
EndLocal & Set "%~1=%$:~1%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Decode <result variable> <offset> [is Unicode if arg defined]
SetLocal EnableExtensions EnableDelayedExpansion
If "%~3" NEQ "" (Set "L=4") Else (Set "L=2")
Set /A "O=%~2"
TYPE NUL:>"%MY%\data.hex"
:decoding
For /F "tokens=1,2" %%i in ("!O! !L!") Do Set "b=!S:~%%~i,%%~j!
Set /A "O+=L"
If "!b:0=!" NEQ "" (
  Set /P "=!b!"<NUL:>>"%MY%\data.hex"
  Goto :decoding
)
Set "$="
CertUtil -f -decodeHex "%MY%\data.hex" "%MY%\data" >NUL: 2>&1 && (
  For /F "delims=" %%a in ('MORE /E "%MY%\data"') Do Set "$=!$!%%a"
  Echo;"!$!"
) || (
Echo;
)
EndLocal & Set "%~1=%O%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:DecodeN <result variable> <offset> <length> [is Unicode if arg defined]
SetLocal EnableExtensions EnableDelayedExpansion
Set /P "=!S:~%~2,%~3!"<NUL:>"%MY%\data.hex"
Set "$="
CertUtil -f -decodeHex "%MY%\data.hex" "%MY%\data" >NUL: 2>&1 && (
  For /F "delims=" %%a in ('MORE /E "%MY%\data"') Do Set "$=!$!%%a"
)
EndLocal & Set "%~1=%$%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:BSTR <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "L=2,#=@,@+=L" & Call :toInt size !#! !L!
Set /A "L=size*4,#=@"
For /F "tokens=1,2" %%i in ("!#! !L!") Do Set /P "=!S:~%%~i,%%~j!"<NUL:>"%MY%\data.hex"
Set "$="
CertUtil -f -decodeHex "%MY%\data.hex" "%MY%\data" >NUL: 2>&1 && (
  For /F "delims=" %%a in ('MORE /E "%MY%\data"') Do Set "$=!$!%%a"
)
EndLocal & Set "%~1=%$%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:toCSLID <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
::a4a3a2a1b2b1c2c1d1e1f1f2f3f4f5f6
::a1a2a3a4-b1b2-c1c2-d1e1-f1f2f3f4f5f6
Set "$=!S:~%~2,%~3!"
Set "A=!$:~6,2!!$:~4,2!!$:~2,2!!$:~0,2!"
Set "B=!$:~10,2!!$:~8,2!"
Set "C=!$:~14,2!!$:~12,2!"
Set "D=!$:~16,2!!$:~18,2!"
Set "F=!$:~20!"
EndLocal & Set "%~1=%A%-%B%-%C%-%D%-%F%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:byteToHex <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Set "%~1="
Set "$=!S:~%~2,%~3!"
set "#="
Set /A "n=0"
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do Set "$=!$:%%a= %%a!"
For %%a in (%$%) Do (
  If !n! EQU 0 (
    Set "@=%%a"
  ) Else (
    Set "#=!@!%%a!#!"
  )
  Set /A "n=(n+1) %% 2"
)
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:toInt <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Call :byteToHex $ %2 %3
Set /A "$=0x!$!"
EndLocal & Set "%~1=%$%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:LinkFlags <result variable> <offset> <length>
Call :toInt $ %~2 %~3
Call :byteToHex LinkFlags %~2 %~3
Set /A LinkFlags_HasLinkTargetIDList=         "!$!&0x00000001"^
,      LinkFlags_HasLinkInfo=                 "!$!&0x00000002"^
,      LinkFlags_HasName=                     "!$!&0x00000004"^
,      LinkFlags_HasRelativePath=             "!$!&0x00000008"^
,      LinkFlags_HasWorkingDir=               "!$!&0x00000010"^
,      LinkFlags_HasArguments=                "!$!&0x00000020"^
,      LinkFlags_HasIconLocation=             "!$!&0x00000040"^
,      LinkFlags_IsUnicode=                   "!$!&0x00000080"^
,      LinkFlags_ForceNoLinkInfo=             "!$!&0x00000100"^
,      LinkFlags_HasExpString=                "!$!&0x00000200"^
,      LinkFlags_RunInSeparateProcess=        "!$!&0x00000400"^
,      LinkFlags_Unused1=                     "!$!&0x00000800"^
,      LinkFlags_HasDarwinID=                 "!$!&0x00001000"^
,      LinkFlags_RunAsUser=                   "!$!&0x00002000"^
,      LinkFlags_HasExpIcon=                  "!$!&0x00004000"^
,      LinkFlags_NoPidlAlias=                 "!$!&0x00008000"^
,      LinkFlags_Unused2=                     "!$!&0x00010000"^
,      LinkFlags_RunWithShimLayer=            "!$!&0x00020000"^
,      LinkFlags_ForceNoLinkTrack=            "!$!&0x00040000"^
,      LinkFlags_EnableTargetMetadata=        "!$!&0x00080000"^
,      LinkFlags_DisableLinkPathTracking=     "!$!&0x00100000"^
,      LinkFlags_DisableKnownFolderTracking=  "!$!&0x00200000"^
,      LinkFlags_DisableKnownFolderAlias=     "!$!&0x00400000"^
,      LinkFlags_AllowLinkToLink=             "!$!&0x00800000"^
,      LinkFlags_UnaliasOnSave=               "!$!&0x01000000"^
,      LinkFlags_PreferEnvironmentPath=       "!$!&0x02000000"^
,      LinkFlags_KeepLocalIDListForUNCTarget= "!$!&0x04000000"
Echo;LinkFlags:                       0x!LinkFlags!
Set "space=                                 "
If !LinkFlags_HasLinkTargetIDList!         NEQ 0 Echo;!space!HasLinkTargetIDList
If !LinkFlags_HasLinkInfo!                 NEQ 0 Echo;!space!HasLinkInfo
If !LinkFlags_HasName!                     NEQ 0 Echo;!space!HasName
If !LinkFlags_HasRelativePath!             NEQ 0 Echo;!space!HasRelativePath
If !LinkFlags_HasWorkingDir!               NEQ 0 Echo;!space!HasWorkingDir
If !LinkFlags_HasArguments!                NEQ 0 Echo;!space!HasArguments
If !LinkFlags_HasIconLocation!             NEQ 0 Echo;!space!HasIconLocation
If !LinkFlags_IsUnicode!                   NEQ 0 Echo;!space!IsUnicode
If !LinkFlags_ForceNoLinkInfo!             NEQ 0 Echo;!space!ForceNoLinkInfo
If !LinkFlags_HasExpString!                NEQ 0 Echo;!space!HasExpString
If !LinkFlags_RunInSeparateProcess!        NEQ 0 Echo;!space!RunInSeparateProcess
If !LinkFlags_Unused1!                     NEQ 0 Echo;!space!Unused1
If !LinkFlags_HasDarwinID!                 NEQ 0 Echo;!space!HasDarwinID
If !LinkFlags_RunAsUser!                   NEQ 0 Echo;!space!RunAsUser
If !LinkFlags_HasExpIcon!                  NEQ 0 Echo;!space!HasExpIcon
If !LinkFlags_NoPidlAlias!                 NEQ 0 Echo;!space!NoPidlAlias
If !LinkFlags_Unused2!                     NEQ 0 Echo;!space!Unused2
If !LinkFlags_RunWithShimLayer!            NEQ 0 Echo;!space!RunWithShimLayer
If !LinkFlags_ForceNoLinkTrack!            NEQ 0 Echo;!space!ForceNoLinkTrack
If !LinkFlags_EnableTargetMetadata!        NEQ 0 Echo;!space!EnableTargetMetadata
If !LinkFlags_DisableLinkPathTracking!     NEQ 0 Echo;!space!DisableLinkPathTracking
If !LinkFlags_DisableKnownFolderTracking!  NEQ 0 Echo;!space!DisableKnownFolderTracking
If !LinkFlags_DisableKnownFolderAlias!     NEQ 0 Echo;!space!DisableKnownFolderAlias
If !LinkFlags_AllowLinkToLink!             NEQ 0 Echo;!space!AllowLinkToLink
If !LinkFlags_UnaliasOnSave!               NEQ 0 Echo;!space!UnaliasOnSave
If !LinkFlags_PreferEnvironmentPath!       NEQ 0 Echo;!space!PreferEnvironmentPath
If !LinkFlags_KeepLocalIDListForUNCTarget! NEQ 0 Echo;!space!KeepLocalIDListForUNCTarget
EndLocal & Set "%~1=%$%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Attributes <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Call :toInt $ %~2 %~3
Call :byteToHex Attributes %~2 %~3
Set /A  "R=!$!&0x00000001"^
,       "H=!$!&0x00000002"^
,       "S=!$!&0x00000004"^
,       "@=!$!&0x00000008"^
,       "D=!$!&0x00000010"^
,       "A=!$!&0x00000020"^
,       "#=!$!&0x00000040"^
,       "N=!$!&0x00000080"^
,       "T=!$!&0x00000100"^
,       "P=!$!&0x00000200"^
,       "L=!$!&0x00000400"^
,       "C=!$!&0x00000800"^
,       "O=!$!&0x00001000"^
,       "I=!$!&0x00002000"^
,       "E=!$!&0x00004000"^
,      "@A=!$!&0x00008000"^
,      "@B=!$!&0x00010000"^
,      "@C=!$!&0x00020000"^
,      "@D=!$!&0x00040000"^
,      "@E=!$!&0x00080000"^
,      "@F=!$!&0x00100000"^
,      "@G=!$!&0x00200000"^
,      "@H=!$!&0x00400000"^
,      "@I=!$!&0x00800000"^
,      "@J=!$!&0x01000000"^
,      "@K=!$!&0x02000000"^
,      "@L=!$!&0x04000000"^
,      "@M=!$!&0x08000000"^
,      "@N=!$!&0x10000000"^
,      "@O=!$!&0x20000000"^
,      "@P=!$!&0x40000000"^
,      "@Q=!$!&0x80000000"
Echo;FileAttributes:                  0x!Attributes!
Set "space=                                 "
If !R! NEQ 0 Echo;!space![R] Read only
If !H! NEQ 0 Echo;!space![H] Hidden
If !S! NEQ 0 Echo;!space![S] System
If !@! NEQ 0 Echo;!space!    Reserved1
If !D! NEQ 0 Echo;!space![D] Directory
If !A! NEQ 0 Echo;!space![A] To be archived
If !#! NEQ 0 Echo;!space!    Reserved2
If !N! NEQ 0 Echo;!space!    No attributes set
If !T! NEQ 0 Echo;!space![T] Temporary
If !P! NEQ 0 Echo;!space![P] Sparse
If !L! NEQ 0 Echo;!space![L] Reparse point
If !C! NEQ 0 Echo;!space![C] Compressed
If !O! NEQ 0 Echo;!space![O] Offline
If !I! NEQ 0 Echo;!space![I] To be indexed
If !E! NEQ 0 Echo;!space![E] Encrypted
If !@A! NEQ 0 Echo;!space!  Unknown attribute !@A!
If !@B! NEQ 0 Echo;!space!  Unknown attribute !@B!
If !@C! NEQ 0 Echo;!space!  Unknown attribute !@C!
If !@D! NEQ 0 Echo;!space!  Unknown attribute !@D!
If !@E! NEQ 0 Echo;!space!  Unknown attribute !@E!
If !@F! NEQ 0 Echo;!space!  Unknown attribute !@F!
If !@G! NEQ 0 Echo;!space!  Unknown attribute !@G!
If !@H! NEQ 0 Echo;!space!  Unknown attribute !@H!
If !@I! NEQ 0 Echo;!space!  Unknown attribute !@I!
If !@J! NEQ 0 Echo;!space!  Unknown attribute !@J!
If !@K! NEQ 0 Echo;!space!  Unknown attribute !@K!
If !@L! NEQ 0 Echo;!space!  Unknown attribute !@L!
If !@M! NEQ 0 Echo;!space!  Unknown attribute !@M!
If !@N! NEQ 0 Echo;!space!  Unknown attribute !@N!
If !@O! NEQ 0 Echo;!space!  Unknown attribute !@O!
If !@P! NEQ 0 Echo;!space!  Unknown attribute !@P!
If !@Q! NEQ 0 Echo;!space!  Unknown attribute !@Q!
EndLocal & Set "%~1=%$%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ExtraData <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Echo EXTRADATA *************************************************************
:ExtraData.loop
Set /A "@=%~2"
Set "BlockSignature="
Set "subroutine="
Set /A "L=8,  #=@,@+=L" & Call :toInt     BlockSize      !#! !L!
If !BlockSize! GEQ 0x4 (
  Set /A "L=8,  #=@,@+=L" & Call :byteToHex BlockSignature !#! !L!
         If "0xA0000001" EQU "0x!BlockSignature!" ( Set "subroutine=EnvironmentVariableDataBlock"
  ) Else If "0xA0000002" EQU "0x!BlockSignature!" ( Set "subroutine=ConsoleDataBlock"
  ) Else If "0xA0000003" EQU "0x!BlockSignature!" ( Set "subroutine=TrackerDataBlock"
  ) Else If "0xA0000004" EQU "0x!BlockSignature!" ( Set "subroutine=ConsoleFEDataBlock"
  ) Else If "0xA0000005" EQU "0x!BlockSignature!" ( Set "subroutine=SpecialFolderDataBlock"
  ) Else If "0xA0000006" EQU "0x!BlockSignature!" ( Set "subroutine=DarwinDataBlock"
  ) Else If "0xA0000007" EQU "0x!BlockSignature!" ( Set "subroutine=IconEnvironmentDataBlock"
  ) Else If "0xA0000008" EQU "0x!BlockSignature!" ( Set "subroutine=ShimDataBlock"
  ) Else If "0xA0000009" EQU "0x!BlockSignature!" ( Set "subroutine=PropertyStoreDataBlock"
  ) Else If "0xA000000B" EQU "0x!BlockSignature!" ( Set "subroutine=KnownFolderDataBlock"
  ) Else If "0xA000000C" EQU "0x!BlockSignature!" ( Set "subroutine=VistaAndAboveIDListDataBlock"
  )
)
If DEFINED subroutine (
  Set "caption=!subroutine! ******************************************************"
  Echo;!caption:~0,71!
) Else (
  If DEFINED BlockSignature (
    Echo;UNKNOWN EXTRA BLOCK ***************************************************
  ) Else (
    Echo;TERMINAL BLOCK ********************************************************
  )
)
Echo BlockSize:                       !BlockSize!
If DEFINED BlockSignature (
  Echo BlockSignature:                  0x%BlockSignature%
  If DEFINED subroutine Call :%subroutine% %~1 !@!
)
Set /A "$=BlockSize*2" & For %%a in (!$!) Do Set "S=!S:~%%a!"

If !BlockSize! GEQ 0x4 Call :ExtraData.loop %~1 0
EndLocal & Set "%~1=0"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:PropertyStoreDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Echo;    There are many property types and I have only corectly deciphered
Echo;    some of them; others are simply printed as a hex dump.

:PropertyStoreDataBlock.serialized
REM Echo;================
Set /A "L=8,  #=@,@+=L" & Call :toInt StorageSize   !#! !L! & Echo;  StorageSize:                   !StorageSize!
If !StorageSize! EQU 0 Goto :end

Set /A "L=8,  #=@,@+=L" & Call :ByteToHex Version   !#! !L! & Echo;  Version:                       0x!Version! (must be 0x53505331)
Set /A "L=32, #=@,@+=L" & Call :toCSLID   FormatID  !#! !L! & Echo;  FormatID:                      !FormatID!

:PropertyStoreDataBlock.value
REM Echo;----------
If /I "D5CDD505-2E9C-101B-9397-08002B2CF9AE" EQU "!FormatID!" (
  Set /A "L=8,  #=@,@+=L" & Call :toInt     ValueSize !#! !L! & Echo;    ValueSize:                   !ValueSize!
  If !ValueSize! EQU 0 Goto :PropertyStoreDataBlock.serialized
  Set /A "L=8,  #=@,@+=L" & Call :toInt     NameSize  !#! !L! & Echo;    NameSize:                    !NameSize!
  Set /A "L=2,  #=@,@+=L" & Call :toInt     $         !#! !L! & Echo;    Reserved:                    !$!
  Set /A "L=NameSize*2,#=@,@+=L" & Call :decode Name  !#! !L! unicode
  REM & Echo Name:                            !Name!
) Else (
  Set /A "L=8,  #=@,@+=L" & Call :toInt     ValueSize !#! !L! & Echo;    ValueSize:                   !ValueSize!
  If !ValueSize! EQU 0 Goto :PropertyStoreDataBlock.serialized
  Set /A "L=8,  #=@,@+=L" & Call :toInt     Id        !#! !L! & Echo;    Id:                          !Id!
  Set /A "L=2,  #=@,@+=L" & Call :toInt     $         !#! !L! & Echo;    Reserved:                    !$!
)
Set /A "L=ValueSize*2-18,#=@,@+=L" & Call :TypedPropertyValue Value !#! !L!
Goto :PropertyStoreDataBlock.value

:end
Set /A "#=%~2+BlockSize*2"
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:TypedPropertyValue <result variable> <offset> <length>
SetLocal EnableExtensions EnableDelayedExpansion
Set "result="
Set /A "@=%~2"
Set /A "L=4,  #=@,@+=L" & Call :byteToHex Type !#! !L! & Echo;    Type:                        0x!Type!
Set /A "L=4,  #=@,@+=L" & REM Call :toInt $    !#! !L! & Echo;    Padding:                     !$!
Set /A "L=%~3-8"
Set /P "=-!BS!    Value:                       "<NUL:
REM Set /P "=Value:                           "<NUL:
Set /A "Type=0x%Type%"
For %%a in ( 0x0010 0x0011) Do ( REM INT8 UINT8
  If !Type! EQU %%a ( Call :toInt result !@! 2 & Goto :print)
)
For %%a in ( 0x0002 0x0012) Do ( REM INT16 UINT16
  If !Type! EQU %%a ( Call :toInt result !@! 4 & Goto :print)
)
For %%a in ( 0x0003 0x000A 0x000B 0x000E 0x0013
             0x1002 0x1003 0x1004 0x1005 0x1006
             0x1007 0x1008 0x100A 0x100B 0x100C
             0x1010 0x1011 0x1012 0x1013 0x1014
             0x1015 0x101E 0x101F 0x1040 0x1047
             0x1048) Do ( REM INT32 UINT32
  If !Type! EQU %%a ( Call :toInt result !@! 8 & Goto :print)
)
For %%a in ( 0x0014 0x0015 0x0016 0x0017) Do ( REM INT64 UINT64
  If !Type! EQU %%a ( Call :toInt result !@! 16 & Goto :print)
)
For %%a in ( 0x0006 0x0007 0x0041 0x0046 0x0047
             0x0042 0x0043 0x0044 0x0045 0x0049
             0x2002 0x2003 0x2004 0x2005 0x2006
             0x2007 0x2008 0x200A 0x200B 0x200C
             0x200E 0x2010 0x2011 0x2012 0x2013
             0x2016 0x2017) Do ( REM CURRENCY DATE BLOB
  If !Type! EQU %%a ( Call :ByteToHex result !@! !L! & Goto :print)
)
For %%a in ( 0x001E) Do ( REM LPSTR
  If !Type! EQU %%a ( Call :decode $ !@! !L! & Goto :print)
)
REM For %%a in ( ) Do ( REM LPWSTR
  REM If !Type! EQU %%a ( Call :decode $ !@! !L! unicode & Goto :print)
REM )
For %%a in ( 0x0008 0x001F) Do ( REM BSTR
  If !Type! EQU %%a ( Call :BSTR result !@! & Goto :print)
)
       If 0x0000 EQU !Type! ( Set "result=EMPTY" % REM EMPTY %
) Else If 0x0001 EQU !Type! ( Set "result=NULL" % REM NULL %
) Else If 0x0004 EQU !Type! ( Call :ByteToHex result !@! 8  % REM FLOAT32 %
) Else If 0x0005 EQU !Type! ( Call :ByteToHex result !@! 16 % REM FLOAT64 %
) Else If 0x0040 EQU !Type! ( Call :readTime result !@! !L! % REM FILETIME %
) Else If 0x0048 EQU !Type! ( Call :toCSLID result !#! !L!  % REM GUID %
) Else ( Call :ByteToHex result !@! !L!
)
:print
If DEFINED result Echo;"!result!"
REM EndLocal & Set "Result=%Result%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ConsoleDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
For %%Z in ("FillAttributes" "PopupFillAttributes") Do (
  Set /A "L=4,  #=@,@+=L" & Call :byteToHex %%~Z !#! !L!
  Set "$=%%~Z                                  "
  Set "$=!$:~0,33!"
  Echo !$!0x!%%~Z!
  REM Set /P "=!$!0x!%%~Z!"<NUL:
  Set /A "%%~Z=       0x!%%~Z!"^
  ,      "FOREGROUND_BLUE=      %%~Z&0x01"^
  ,      "FOREGROUND_GREEN=     %%~Z&0x02"^
  ,      "FOREGROUND_RED=       %%~Z&0x04"^
  ,      "FOREGROUND_INTENSITY= %%~Z&0x08"^
  ,      "BACKGROUND_BLUE=      %%~Z&0x10"^
  ,      "BACKGROUND_GREEN=     %%~Z&0x20"^
  ,      "BACKGROUND_RED=       %%~Z&0x40"^
  ,      "BACKGROUND_INTENSITY= %%~Z&0x80"
  Set "Foreground=" & Set "Background="
  Set /P "=-!BS!  Foreground:                    "<NUL:
  REM ForFiles /M %MEx% /C "cmd /c Set /P =-0x08  Foreground:                    <NUL:"
  REM Set /P "=Foreground:                      "          <NUL:
  If !FOREGROUND_RED!       NEQ 0 Set /P "=RED "       <NUL:
  If !FOREGROUND_GREEN!     NEQ 0 Set /P "=GREEN "     <NUL:
  If !FOREGROUND_BLUE!      NEQ 0 Set /P "=BLUE "      <NUL:
  If !FOREGROUND_INTENSITY! NEQ 0 Set /P "=INTENSITY " <NUL:
  Echo;
  Set /P "=-!BS!  Background:                    "<NUL:
  REM ForFiles /M %MEx% /C "cmd /c Set /P =-0x08  Background:                    <NUL:"
  REM Set /P "=Background:                      "          <NUL:
  If !BACKGROUND_RED!       NEQ 0 Set /P "=RED "       <NUL:
  If !BACKGROUND_GREEN!     NEQ 0 Set /P "=GREEN "     <NUL:
  If !BACKGROUND_BLUE!      NEQ 0 Set /P "=BLUE "      <NUL:
  If !BACKGROUND_INTENSITY! NEQ 0 Set /P "=INTENSITY " <NUL:
  Echo;
)
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;ScreenBufferSizeX:               !$!
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;ScreenBufferSizeY:               !$!
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;WindowSizeX:                     !$!
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;WindowSizeY:                     !$!
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;WindowOriginX:                   !$!
Set /A "L=4,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;WindowOriginY:                   !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;Unused1:                         !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;Unused2:                         !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;FontSize:                        !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;FontFamily:                      !$!
Set /A "$&=0xF0"
       If 0x00 EQU !$! ( Echo;                                 FF_DONTCARE
) Else If 0x10 EQU !$! ( Echo;                                 FF_ROMAN
) Else If 0x20 EQU !$! ( Echo;                                 FF_SWISS
) Else If 0x30 EQU !$! ( Echo;                                 FF_MODERN
) Else If 0x40 EQU !$! ( Echo;                                 FF_SCRIPT
) Else If 0x50 EQU !$! ( Echo;                                 FF_DECORATIVE
)
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;FontWeight:                      !$!
If 700 LEQ !$! ( Echo;                                 A bold font
) Else         ( Echo;                                 A regular weight font
)
Set /P "=FaceName:                        "<NUL:
Call :Decode $ !@! unicode
Set /A "@+=128"
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;CursorSize:                      !$!
       If !$! LEQ 25  ( Echo;                                 A small cursor
) Else If !$! LEQ 50  ( Echo;                                 A medium cursor
) Else If !$! LEQ 100 ( Echo;                                 A large cursor
)
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;FullScreen:                      !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;QuickEdit:                       !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;InsertMode:                      !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;AutoPosition:                    !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;HistoryBufferSize:               !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;NumberOfHistoryBuffers:          !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;HistoryNoDup:                    !$!
Set /A "L=@+128-16"
Echo;ColorTable:                      
For /L %%a in (!@!,16,!L!) Do Echo;                                 !S:~%%a,16!
Set /A "#=%~2+BlockSize*2"
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SpecialFolderDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:VistaAndAboveIDListDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set "space=                    "
REM Set /A "L=4,  #=@,@+=L" & Call :toInt IDListSize !#! !L! & Echo;ID list size:!space!!IDListSize!
:VistaAndAboveIDListDataBlock.ItemID
Set /A "L=4,  #=@,@+=L" & Call :toInt ItemIDSize !#! !L! & Echo;Item ID size:!space!!ItemIDSize! (data + size)
If !ItemIDSize! EQU 0 (EndLocal & Set "%~1=%@%" & Goto :EOF)
Set /A "L=ItemIDSize*2-4,  #=@,@+=L" & Call :byteToHex $ !#! !L! & Echo;        Data:!space!!$!
REM Goto :VistaAndAboveIDListDataBlock.ItemID
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:TrackerDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=8,  #=@,@+=L" & Call :toInt Length  !#! !L! & Echo;Length:                          !Length!
Set /A "L=8,  #=@,@+=L" & Call :toInt $       !#! !L! & Echo;Version:                         !$!
Set /P "=MachineID:                       "<NUL:
Set /A "L=2*(BlockSize-4-4-4-4-32-32)"
Set /A "#=@,@+=L" & Call :decode $ !#! !L!
Set /A "L=32, #=@,@+=L" & Call :toCSLID     $1 !#! !L!
Set /A "L=32, #=@,@+=L" & Call :toCSLID     $2 !#! !L!
Echo;Droid:                           !$1!
Echo;                                 !$2!
Set /A "L=32, #=@,@+=L" & Call :toCSLID     $1 !#! !L!
Set /A "L=32, #=@,@+=L" & Call :toCSLID     $2 !#! !L!
Echo;DroidBirth:                      !$1!
Echo;                                 !$2!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SpecialFolderDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;SpecialFolderID:                 !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;Offset:                          !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ShimDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=(BlockSize-16)*2,#=@,@+=L" & Call :decode $ !#! !L!          & Echo;LayerName:                       !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:KnownFolderDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=32, #=@,@+=L" & Call :toCSLID $ !#! !L! & Echo;KnownFolderID:                   !$!
Set /A "L=8,  #=@,@+=L" & Call :toInt   $ !#! !L! & Echo;Offset:                          !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:IconEnvironmentDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=520, #=@,@+=L" & Call :decode $ !#! !L!         & Echo;TargetAnsi:                      !$!
Set /A "L=1040,#=@,@+=L" & Call :decode $ !#! !L! unicode & Echo;TargetUnicode:                   !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:EnvironmentVariableDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /P "=TargetAnsi:                      "<NUL:
Set /A "L=520, #=@,@+=L" & Call :decode $ !#! !L!
Set /P "=TargetUnicode:                   "<NUL:
Set /A "L=1040,#=@,@+=L" & Call :decode $ !#! !L! unicode
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:DarwinDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=520, #=@,@+=L" & Call :decode $ !#! !L!         & Echo;DarwinDataAnsi:                  !$!
Set /A "L=1040,#=@,@+=L" & Call :decode $ !#! !L! unicode & Echo;DarwinDataUnicode:               !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:ConsoleFEDataBlock <result variable> <offset>
SetLocal EnableExtensions EnableDelayedExpansion
Set /A "@=%~2"
Set /A "#=%~2+BlockSize*2"
Set /A "L=8,  #=@,@+=L" & Call :toInt $ !#! !L! & Echo;CodePage:                        !$!
EndLocal & Set "%~1=%#%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
