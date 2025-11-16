@echo off
set SCRIPT=%~dp0SplitMerge.ps1
set SHORTCUT1=%~dp0SplitMerge_PS5.lnk
set SHORTCUT2=%~dp0SplitMerge_PS7.lnk

:: PowerShell 5.1 快捷方式
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\mklnk.vbs"
echo Set oLink = oWS.CreateShortcut("%SHORTCUT1%") >> "%TEMP%\mklnk.vbs"
echo oLink.TargetPath = "powershell.exe" >> "%TEMP%\mklnk.vbs"
echo oLink.Arguments = "-NoProfile -ExecutionPolicy Bypass -File ""%SCRIPT%""" >> "%TEMP%\mklnk.vbs"
echo oLink.WorkingDirectory = "%~dp0" >> "%TEMP%\mklnk.vbs"
echo oLink.Save >> "%TEMP%\mklnk.vbs"
cscript //nologo "%TEMP%\mklnk.vbs"
del "%TEMP%\mklnk.vbs"

:: PowerShell 7 快捷方式
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\mklnk.vbs"
echo Set oLink = oWS.CreateShortcut("%SHORTCUT2%") >> "%TEMP%\mklnk.vbs"
echo oLink.TargetPath = "pwsh.exe" >> "%TEMP%\mklnk.vbs"
echo oLink.Arguments = "-NoProfile -ExecutionPolicy Bypass -File ""%SCRIPT%""" >> "%TEMP%\mklnk.vbs"
echo oLink.WorkingDirectory = "%~dp0" >> "%TEMP%\mklnk.vbs"
echo oLink.Save >> "%TEMP%\mklnk.vbs"
cscript //nologo "%TEMP%\mklnk.vbs"
del "%TEMP%\mklnk.vbs"

echo 快捷方式已生成在脚本目录！
pause
