::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: xmlParse.cmd
:: 2012-01-13 Frank P. Westlake
@Goto :main
The body of this message is a script; the statement above permits 
this message to be saved and run without concern for this 
documentation.

An XML pull and push parser. 

  xmlParse.cmd [/Q] file [command]

  /Q        Do not print the result but do set it into the environment.
  file      An XML file.
  command   A dot-joined path to the tag's content or to a tag 
            attribute being queried. This argument should be quoted 
            because in many cases the quotes will be necessary. 
            Quotes within the command must be converted to 
            apostrophes.

XML PUSH
If 'command' is not included this script will become a push-parser. 
The parser will print each tag and any attributes it may have on 
individual lines. The first word on the line is the name of the tag 
prefixed with the text "Tag.". If the entire first word is "Tag." 
then the remainder of the line is content. A tag line will appear 
similar to this: 

  Tag.body bgcolor="#000000"

A line of content will appear similar to this: 

  Tag. How now brown cow?

Those lines should be read from a master script with a statement such 
as this: 

  For /F "tokens=1* delims= " %%a in ('Call xmlParse.cmd "%file%"') Do (
    Call :%%a %%b
  )

If the tags are being used as subroutine labels as done in the FOR 
statement above, then each tag must have a corresponding subroutine. 
An example for the two lines shown above: 

  :Tag.body
  REM Begin body of text.
  CLS
  Goto :EOF

  :Tag./body
  REM Do nothing.
  Goto :EOF

  :Tag.
  REM Print the content.
  Echo(%*
  Goto :EOF

XML PULL
If 'command' is included this script becomes a pull-parser; without 
this argument it is a push-parser. If a tag should be queried only if 
it contains an attribute or attributes of a certain value, those 
attributes may be specified in a parenthesized, space-separated list 
and appended to the tag name. Each attribute name should begin with 
the character '@'. To query an a attribute of a tag, join the 
attribute name to the list with a dot and prefix the attribute name 
with the character '@'. Examples follow. 

A command line will look similar to this: 

  xmlParse demo.xml "papa.tag(@id='2' @class='A').@name"

TAG CONTENT QUERY 
'Content' is the text between an opening tag and it's closing tag and 
not including any intermediate tags. 

With this XML file 

  <papa>
    <tag>
      Content
    </tag>
  </papa>

obtain the text "Content" with this query command 

  "papa.tag"

ATTRIBUTE QUERY 
An attribute is the value identified by a key within an opening tag. 

With this XML file 

  <papa>
    <tag id="1" name="Joe"/>
  </papa>

obtain the text "Joe" with this query command 

  "papa.tag.@name"

The attribute key begins with '@' and is separated from it's tag name 
by a period. 

IDENTIFYING A TAG BY ATTRIBUTE VALUESS 
If there are multiple tags of the same name at the same level then a 
specific tag can be selected by including one or more attributes 
within parentheses: 

With this XML file 

  <papa>
    <tag id="1" name="Jim" "class='A'>James</tag>
    <tag id="1" name="Jed" "class='B'/>
    <tag id="2" name="Joe" "class='A'/>
    <tag id="2" name="Jon" "class='B'/>
  </papa>

obtain the text "Joe" with this query command 

  "papa.tag(@id='2' @class='A').@name"

The parenthesized list is appended to the tag name, attribute keys 
begin with '@', and attributes are separated by space. 

Frank Westlake 

:main
@Echo OFF
SetLocal EnableExtensions EnableDelayedExpansion
For /F "delims==" %%a in ('SET $ 2^>NUL:') Do Set "%%a="
Set "#="
Set "$ME=%~nx0"
Set "$MY=%~dp0"
Set "$TAB=	"
For /F "delims= " %%a in ("1%$TAB%") Do If "%%~a" EQU "1" (
  (Echo %$ME%: The script's variable '$TAB' must be defined as a tab character.
   Set /P "=LINE "<NUL:
   FindStr /n /i /c:"$TAB=" "%~f0"|FindStr /v "FindStr")>&2
  Goto :EOF
)
Set "$SPACE= "
Set "$find="
Set "$level=0"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:args
Set "$=%~1"
       If /I "!$!" EQU "/F" (
  Set "$xml=%~f2"
  SHIFT
) Else If /I "!$!" EQU "/Q" (
  Set "$quiet= >NUL:"
) Else If /I "!$!" EQU "/EXAMPLES" (
  Goto :examples
) Else If /I "!$!" EQU "/QUIET" (
  Set "$quiet= >NUL:"
) Else If /I "!$!" EQU "/FILE" (
  Set "$xml=%~f2"
  SHIFT
) Else If "!$:~0,1!" EQU "/" (
  (Echo %$ME%: Aborting, unknown parameter '!$!'.)>&2
  Goto :EOF
) Else If DEFINED $xml (
  If DEFINED $find (
    (Echo !$Me!: Aborting, too many filenames.)>&2
    Goto :EOF
  )
  Set "$find=%~1"
) Else (
  Set "$xml=%~f1"
)
Shift
IF "%~1" NEQ "" Goto :args

If DEFINED $find Goto :xmlPull
Goto :xmlPush
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:xmlPush
For /F "delims=" %%a in (%$xml%) Do (
  Set "#=!#!%%a"
  Call :parseXML
)
If DEFINED $Continue (
  Set "$EOF=1"
  Call :parseXML
)
EXIT /B 0
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:xmlPull
Set $find=!$find:"='!
Set "$findRemaining=!$find!"

Call :getNextSegment
For /F "delims=" %%a in (%$xml%) Do (
  Set "#=!#!%%a"
  Call :parseXML
  If DEFINED $QUIT Goto :return
)
If DEFINED $Continue (
  Set "$EOF=1"
  Call :parseXML
)
EXIT /B 1
Goto :EOF

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:return
EndLocal & Set "%$RETURN%=%$RETURN.value%"
EXIT /B 0
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:parseXML
If DEFINED $Continue (
  Set "$Continue="
  Call %$Continue%
  Goto :EOF
)
If "!#:~0,1!" EQU "<" (
  For /F "delims==" %%a in ('SET + 2^>NUL:') Do Set "%%a="
  Set "#=!#:~1!"
  Set "$tagBody="
  Call :getTag
) Else (
  Call :getContent
)
If DEFINED # Goto :parseXML
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getNextSegment
Set "$nextSegment="
Set "$attributes="
For /F "delims==" %%a in ('SET @ 2^>NUL:') Do Set "%%a="
For /F "tokens=1* delims=." %%a in ("!$findRemaining!") Do (
  Set "$nextSegment=%%~a"
  Set "$findRemaining=%%~b"
  If "!$nextSegment:~0,1!" NEQ "@" (
    For /F "tokens=1* delims=(" %%c in ("%%~a") Do (
    REM For /F "tokens=1* delims=@" %%c in ("%%~a") Do (
      Set "$nextSegment=%%~c"
      Set "$attributes=%%~d"
    )
  )
)
If DEFINED $attributes (
  For /F "tokens=1* delims=)" %%a in ("!$attributes!") Do (
    Set "$attributes=%%a"
  )
  Call :getAttributes
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getAttributes
Set "$attributes=!$attributes:~0,-1!"
Set  $attributes=!$attributes:'="!
Set "@="
For %%a in (!$attributes!) Do (
  If NOT DEFINED @ (
    Set "@=%%~a"
  ) Else (
    Set "!@!=%%~a"
    Set "@="
  )
)
If DEFINED @ (If NOT DEFINED !@! (Set "!@!=true"))
Set "@="
Set "$attributes="
:: Rebuilding $attributes but it is currently only used as a flag.
For /F "tokens=1* delims==" %%a in ('Set @ 2^>NUL:') Do Set "$attributes=!$attributes!%%a='%%~b'"
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:processTag
If "!$tag!" EQU "--" (
  Goto :EOF
)
If "!$tag:~0,1!" NEQ "/" Set /A "$level+=1"
If NOT DEFINED $findRemaining (
  If NOT DEFINED $targetLevel (
    Set /A "$targetLevel=$level"
  ) Else IF !$level! EQU !$targetLevel! (
    If DEFINED $pass (
      If "!$tag:~0,1!" EQU "/" (
        Set "$QUIT=defined"
      ) Else If DEFINED +/ (
        Set "$QUIT=defined"
      )
      If DEFINED $QUIT (
        Call :trim $Content
        Set "$RETURN.value=!$Content!"
        Echo(!$Content!%$quiet%
        EXIT /B 0
      )
    )
  )
)
If "!$tag!" EQU "!$nextSegment!" (
  Set "$pass=defined"
  If DEFINED $gut Call :parseGut
  If DEFINED $attributes (
    For /F "delims==" %%a in ('Set @ 2^>NUL:') Do (
      Set "$=%%~a"
      Call Set "$=%%!$:@=+!%%"
      If "!%%~a!" NEQ "!$!" Set "$pass="
    )
  )
  If DEFINED $pass (
    If DEFINED $findRemaining (
      Call :getNextSegment
      If DEFINED $nextSegment (
        If "!$nextSegment:~0,1!" EQU "@" (
          Set "$=+!$nextSegment:~1!"
          Call Set "$=%%!$!%%"
          Set "$QUIT=defined"
          Set "$RETURN=!$nextSegment!"
          Set "$RETURN.value=!$!"
          Echo(!$!%$quiet%
          EXIT /B 0
        )
      )
    )
    If NOT DEFINED $findRemaining (
      If NOT DEFINED $targetLevel (
        Set /A "$targetLevel=1+$level"
      ) Else If !$targetLevel! EQU !$level! (
        Set "$RETURN=!$nextSegment!"
        Set "$saveContent=defined"
      )
    )
  )
)
  If "!$tag:~0,1!" EQU "?" (
  Set /A "$level-=1"
) Else If "!$tag:~0,1!" EQU "/" (
  Set /A "$level-=1"
) Else If DEFINED /+ (
  Set /A "$level-=1"
)
::1
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getTag
Set "#=!#:>=<>!"
For /F "tokens=1* delims=<" %%a in ("!#!") Do (
  Set "$tagBody=!$tagBody!%%a "
  Set "#=%%b"
)
If DEFINED # (
  Set "#=!#:<>=>!"
  If "!#:~0,1!" EQU ">" (
    Set "#=!#:~1!"
  ) Else (
    Set "$Continue=%0"
    Goto :EOF
  )
) Else (
  Set "$Continue=%0"
  Goto :EOF
)
Set "$gut="
Call :splitGut
If DEFINED $find (
  Call :processTag
) Else (
  Echo(Tag.!$tag! !$gut!
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:splitGut
Set "$tag="
Set $tagBody=!$tagBody:"='!
For /F "tokens=1*" %%a in ("!$tagBody!") Do (
  Set "$tag=%%a"
  Set "$gut=%%b"
)
Call :trim $gut
If "!$gut:~-1!" EQU "/" Set "$gut=!$gut:~0,-1! /"
Set "$tagBody="
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:parseGut
Set "+="
Set  $gut=!$gut:'="!
If "!$gut:~-1!" EQU "?" (
  Set "+/=defined"
  Set "$gut=!$gut:~0,-1!"
) Else If "!$gut:~-1!" EQU "/" (
  Set "+/=defined"
  Set "$gut=!$gut:~0,-1!"
)
For %%a in (!$gut!) Do (
  If NOT DEFINED + (
    Set "+=%%~a"
  ) Else (
    Set "+!+!=%%~a"
    Set "+="
  )
)
Set "+="
Set "$gut="
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:getContent
Set "$thisContent="
For /F "tokens=1* delims=<" %%a in ("!#!") Do (
  Set "#=%%b"
  If NOT DEFINED $find (
    Set "$thisContent=%%a"
  ) Else If DEFINED $saveContent (
    Set "$thisContent=%%a"
  )
)
If DEFINED # (Set "#=<!#!")

REM For xmlPush:
If NOT DEFINED $find (
  Call :trim $thisContent
  If DEFINED $thisContent (
    Echo(Tag. !$thisContent!
    Set "$thisContent="
  )
  Goto :EOF
)

If DEFINED $saveContent (
  Set "$Content=!$Content!!$thisContent!"
  Call :trim $Content
)
If DEFINED $Content (
  Set "$Content=!$Content! "
)
Set "$thisContent="
Goto :EOF
:xgetContent
Set "$thisContent="
For /F "tokens=1* delims=<" %%a in ("!#!") Do (
  If DEFINED $saveContent (Set "$thisContent=%%a")
  Set "#=%%b"
)
If DEFINED # (Set "#=<!#!")
If DEFINED $saveContent (
  Set "$Content=!$Content!!$thisContent!"
  Call :trim $Content
)
If DEFINED $Content (
  Set "$Content=!$Content! "
)
Set "$thisContent="
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:trim varname
If DEFINED %1 (
  If "!%1:~0,1!" EQU "!$SPACE!" (
    Set "%1=!%1:~1!"
    Goto :trim
  ) Else If "!%1:~0,1!" EQU "!$TAB!" (
    Set "%1=!%1:~1!"
    Goto :trim
  ) Else If "!%1:~-1!" EQU "!$SPACE!" (
    Set "%1=!%1:~0,-1!"
    Goto :trim
  ) Else If "!%1:~-1!" EQU "!$TAB!" (
    Set "%1=!%1:~0,-1!"
    Goto :trim
  )
)
Goto :EOF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
