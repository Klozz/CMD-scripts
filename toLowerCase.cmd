::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:toLowerCase <result variable name> <string>
SetLocal EnableExtensions EnableDelayedExpansion
Set "$=%~2"
For %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) Do Set "$=!$:%%a=%%a!"
EndLocal & Set "%~1=%$%"
Goto :EOF
