::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:toTitleCase <result variable name> <string>
SetLocal EnableExtensions EnableDelayedExpansion
Set "$= %~2"
For %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) Do Set "$=!$:%%a=%%a!"
For %%a in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) Do Set "$=!$: %%a= %%a!"
EndLocal & Set "%~1=%$:~1%"
Goto :EOF
