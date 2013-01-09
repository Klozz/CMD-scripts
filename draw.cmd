:: BEGIN SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: draw.cmd
:: Version 2012-12-11
:: From the desk of Frank P. Westlake, 2012-12-11
:: Prints color ASCII art files. A sample file follows this script. 
:: Color ASCII art for this script consists of picture elements
:: defined by three characters. The first character is the character
:: to be printed and the second and third characters are the background
:: and foreground colors in hexadecimal.
:: The following characters cannot currently be printed: *\|:"<>/
@Echo OFF
SetLocal EnableExtensions DisableDelayedExpansion
If "%~1" EQU "/?" Goto :usage
Set "file=%~f1"
If NOT DEFINED file Goto :usage
Set "ME=%~n0%"
Call :makeTempDir MY "%ME%"
Pushd "%MY%"
Call :makePen
If /I "%~1" EQU "/P" Goto :pallette
For /F "delims=" %%a in (%file%) Do (
  Set "line=%%a"
  If DEFINED line Call :drawLine
)
Goto :clean-up
::Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Clean-up
Popd
RmDir /S /Q "%MY%"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:drawLine
Set "char=%line:~0,1%_"
Set "color=%line:~1,2%"
Set "line=%line:~3%"
If "%pen%" NEQ "%char%" Rename "%pen%" "%char%"
Set "pen=%char%"
FindStr /A:%color% "." *
Set /P "=%ASCII08%"<NUL:
If DEFINED line Goto :drawLine
:: Overwrite the last backspace above with space
:: and start a new line.
Set "space= "
Echo;%space%
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:makeTempDir myTemp myName
Set "%~1=%TEMP%\%~2"
MkDir "%TEMP%\%~2"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:makePen
Set "pen=A_file_name_which_will_be_repetively_changed"
:: Use pen temporarily as the script.
Echo.WScript.Echo(Chr(^&H08))>"%pen%"
:: Write a backspace to the file to delete FINDSTR's colon.
For /F "delims=" %%a in ('CSCRIPT /NOLOGO /E:VBS "%pen%"') Do (
  Set /P "=%%a %%a"<NUL: >"%pen%"
  Set "ASCII08=%%a"
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:usage
Echo Prints color ASCII art.
Echo;
Echo   %0 /P
Echo   %0 "file"
Echo;
Echo     /P   Print the pallette.
Echo   "file" Print the ASCII art file.
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:pallette
For %%a in (
	" 07 07 00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF"
	" 07 00007107207307407507607707807907A07B07C07D07E07F07"
	"007-07 00+01+02+03+04+05+06+07+08+09+0A+0B+0C+0D+0E+0F"
	"107-07+10+11+12+13+14+15+16+17+18+19+1A+1B+1C+1D+1E+1F"
	"207-07+20+21+22+23+24+25+26+27+28+29+2A+2B+2C+2D+2E+2F"
	"307-07+30+31+32+33+34+35+36+37+38+39+3A+3B+3C+3D+3E+3F"
	"407-07+40+41+42+43+44+45+46+47+48+49+4A+4B+4C+4D+4E+4F"
	"507-07+50+51+52+53+54+55+56+57+58+59+5A+5B+5C+5D+5E+5F"
	"607-07+60+61+62+63+64+65+66+67+68+69+6A+6B+6C+6D+6E+6F"
	"707-07+70+71+72+73+74+75+76+77+78+79+7A+7B+7C+7D+7E+7F"
	"807-07+80+81+82+83+84+85+86+87+88+89+8A+8B+8C+8D+8E+8F"
	"907-07+90+91+92+93+94+95+96+97+98+99+9A+9B+9C+9D+9E+9F"
	"A07-07+A0+A1+A2+A3+A4+A5+A6+A7+A8+A9+AA+AB+AC+AD+AE+AF"
	"B07-07+B0+B1+B2+B3+B4+B5+B6+B7+B8+B9+BA+BB+BC+BD+BE+BF"
	"C07-07+C0+C1+C2+C3+C4+C5+C6+C7+C8+C9+CA+CB+CC+CD+CE+CF"
	"D07-07+D0+D1+D2+D3+D4+D5+D6+D7+D8+D9+DA+DB+DC+DD+DE+DF"
	"E07-07+E0+E1+E2+E3+E4+E5+E6+E7+E8+E9+EA+EB+EC+ED+EE+EF"
	"F07-07+F0+F1+F2+F3+F4+F5+F6+F7+F8+F9+FA+FB+FC+FD+FE+FF"
) Do (
  Set "line=%%~a"
  Call :drawLine
)
Goto :clean-up
:: END SCRIPT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Cut this portion and save it to the file "christmas.txt" then display it
; with the command 
;    DRAW "christmas.txt"

; CHRISTMAS SCENE
; Frosty smoking his corncob pipe next to a Christmas tree with gifts under it.
 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88
 88 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 88
 88 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99_90 00 00 00_90 99 99{97 99 99 88
 88 99 99 99 99 99 99 99#2F 99 99 99 99 99 99 99 99 99 99 99 99 FFoF0 FFoF0 FF 99 99}97 99 99 88
 88 99 99 99 99 99 99+2F 22 22 99 99 99 99 99 99 99 99 99 99 FF FF FF^FC FF FF FF 99{97 99 99 88
 88 99 99 99 99 99 22 22 22+2F 22 99 99 99 99 99 99 99 99 99 99 FF.F0.F0.F0_FE_9E_9EU9E 99 99 88
 88 99 99 99 99 22+2F 22 22 22 22 22 99 99 99 99 99 99 EE 99 99 99 FF FF FF 99 99 99 EE 99 99 88
 88 99 99 99 22 22 22 22 22 22 22+2F 22 99 99 99 99 99 99 EE 99 FF FF FF FF FF 99 EE 99 99 99 88
 88 99 99 22 22 22+2F 22 22+2F 22 22 22 22 99 99 99 99 99 99 FF FF FF FF FF FF FF 99 99 99 99 88
 88 99 22 22+2F 22 22 22 22 22+2F 22 22+2F 22 99 99 99 99 FF FF FF FF FF FF FF FF FF 99 99 99 88
 88 99 99 99%9D 99 99 99 66 99 99 99%9C 99 99 99 99 99 99 99 FF FF FF FF FF FF FF 99 99 99 99 88
 88 99 99 CCICC CC 99 99 66 99 DD DD DD DD DD 99 99 99 99 99 99 FF FF FF FF FF 99 99 99 99 99 88
 88 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 88
 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88
