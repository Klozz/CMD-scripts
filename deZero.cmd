::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:deZero <result variable name> <number>
SetLocal EnableExtensions EnableDelayedExpansion
Set "fake=%~2" & Set "real="
For %%a in (0 1 2 3 4 5 6 7 8 9 A B C D E F) Do Set "fake=!fake:%%a= %%a!"
For %%a in (%fake:~0,-1%) Do If NOT "%%a!real!" EQU "0" Set "real=!real!%%a"
EndLocal & Set "%~1=%real%%fake:~-1%"
Goto :EOF
