cd ..\build
ca65 -I ..\src -t apple2 ..\src\tg.asm -l tg.dis
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tg.asm apple2.lib  -o tg.apple2 -C ..\src\start2000.cfg
copy ..\disk\template.dsk tg.dsk
java -jar C:\jar\AppleCommander.jar -p  tg.dsk tg.system sys < C:\cc65\target\apple2\util\loader.system
java -jar C:\jar\AppleCommander.jar -as tg.dsk tg bin < tg.apple2 
copy tg.dsk ..\disk
C:\AppleWin\Applewin.exe -no-printscreen-dlg -d1 tg.dsk

