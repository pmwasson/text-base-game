cd ..\build
ca65 -I ..\src -t apple2 ..\src\tg.asm -l tg.dis
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tg.asm apple2.lib  -o tg.apple2 -C ..\src\start0C00.cfg

copy ..\disk\template_prodos.dsk askey_prodos.dsk
java -jar C:\jar\AppleCommander.jar -p  askey_prodos.dsk askey.system sys < C:\cc65\target\apple2\util\loader.system
java -jar C:\jar\AppleCommander.jar -as askey_prodos.dsk askey bin < tg.apple2 
copy askey_prodos.dsk ..\disk

copy ..\disk\template_dos33.do askey_dos33.do
java -jar C:\jar\AppleCommander.jar -as askey_dos33.do askey bin < tg.apple2 
copy askey_dos33.do ..\disk

C:\AppleWin\Applewin.exe -no-printscreen-dlg -d1 askey_prodos.dsk

