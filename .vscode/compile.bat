set projectName=soccer_game

taskkill /f /im %projectName%.exe


ml /Fo %projectName%.obj /c /coff /Zi %projectName%.asm
rc /v rsrc.rc
link /INCREMENTAL:no /debug /subsystem:console /entry:start /out:%projectName%.exe %projectName%.obj rsrc.res
start cmd /k "C:\Windows\System32\chcp 65001 && soccer_game.exe

exit
