::@START C:\P\NTL\NoteTab.exe %*
@Echo OFF
SetLocal ENABLEEXTENSIONS
Set "File=%*"
If NOT DEFINED File (
  Echo.Getting filename from STDIN...
	For /F "delims=" %%a in ('MORE') Do (
	  Start "Notepad++" "C:\Program Files\Notepad++\Notepad++.exe" "%%~a"
  )
) Else Start "Notepad++" "C:\Program Files (x86)\Notepad++\Notepad++.exe" %File%
