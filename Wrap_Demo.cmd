:: Wrap_Demo.cmd
:: Frank P. Westlake, 2010-02-24.
:: This entire message body is a script.
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
Set "Wrap.Width=79"
Call :Wrap This is a demonstration of the even faster word^
 wrap with goodies subroutine. By default :Wrap uses the^
 buffer width as the right margin. There is no way for a^
 script to determine the window width so either the buffer^
 width must be used or the 'Wrap.Width' variable must be pre-^
defined with the window width. For this demonstration the^
 width has been set to %Wrap.Width%. One column is necessary^
 for the carriage return.
Call :Wrap
Set "Wrap=        If it is necessary to indent with leading"
Set "Wrap=!Wrap! spaces or to include the special characters"
Set "Wrap=!Wrap! ^!%%^&*|>< in your output, the paragraph"
Set "Wrap=!Wrap! must be placed in the variable 'Wrap'. The"
Set "Wrap=!Wrap! subroutine :Wrap is then called with no"
Set "Wrap=!Wrap! command line. The variable 'Wrap' will be"
Set "Wrap=!Wrap! undefined by the :Wrap subroutine."
Call :Wrap
Call :Wrap
Call :Wrap These characters %@#$%%^*()_+=-:;{[}]\'?/., need^
 no special care.
Call :Wrap
Set "Wrap.line_number=1"
Set "Wrap.prefix=:"
Call :Wrap For this and the next paragraph line numbering has^
 been activated by defining the variable 'Wrap.line_number'^
 with the beginning line number. The variable 'Wrap.prefix',^
 if defined, is printed at the beginning of each line follow^
ing the line number. The prefix, if defined, is also printed^
 if line numbering is not being used.
Call :Wrap
Call :Wrap Line numbering will continue to following paragrap^
hs until the variable 'Wrap.line_number' is undefined. Blank^
 lines can be included in the line numbering if :Wrap is call^
ed with nothing to print.
Set "Wrap.prefix=" & Set "Wrap.line_number="
Call :Wrap
PAUSE
Set "Wrap.hang=        "
Call :Wrap A paragraph can be indented with hang indentation^
 by setting the variable 'Wrap.hang' with the spaces desired^
 for the indentation. To disable the hang indentation for^
 further paragraphs undefine the variable.
Set "Wrap.hang="
Call :Wrap
Set "Wrap.prefix=        "
Set "Wrap.Width=60"
Call :Wrap For this paragraph blockquote has been employed^
 by setting 'Wrap.prefix' to the desired spaces and setting^
 'Wrap.Width' to %Wrap.Width%. The same effect can be achiev^
ed by using the 'Wrap' variable with indentation and a hangi^
ng paragraph, but it is easier to use 'Wrap.prefix'.
Call :Wrap
Set "Wrap.prefix="
Set "Wrap.Width=79"
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Wrap
If NOT DEFINED Wrap (Set "Wrap=%*")
If NOT DEFINED Wrap (Echo=%Wrap.line_number%%Wrap.prefix%&Goto :Wrap.EOR)
SetLocal EnableExtensions EnableDelayedExpansion
If NOT DEFINED Wrap.Width (For /F "tokens=2" %%i in (
  '"MODE CON:|Find "Columns:""') Do Set /A "Wrap.Width=%%i-1"
)
Set /A "Wrap.0=%Wrap.Width%, Wrap.1=%Wrap.Width%+1"
Set "Wrap=%Wrap.line_number%%Wrap.prefix%!Wrap!"
If "!Wrap:~%Wrap.0%!" NEQ "" (
  Set "Wrap.1=%Wrap.Width%"
  For /L %%i in (%Wrap.Width%,-1,1) Do If "!Wrap:~%%i,1!" EQU " " (
    Set /A "Wrap.0=%%i,Wrap.1=%%i+1"
    Goto :Wrap.break
  )
)
:Wrap.break
Echo=!Wrap:~0,%Wrap.0%! & Set "Wrap=!Wrap:~%Wrap.1%!"
If DEFINED Wrap (Set "Wrap=%Wrap.Hang%!Wrap!")
EndLocal & (
  Set "Wrap=%Wrap:!=^!%"
  Set "Wrap.Width=%Wrap.Width%"
)
:Wrap.EOR
If DEFINED Wrap.line_number Set /A "Wrap.line_number+=1"
If DEFINED Wrap Goto :Wrap
Goto :EOF
