@echo off
:: 设置代理服务器
set http_proxy=socks5h://192.168.1.40:10800
set https_proxy=%http_proxy%
set HTTP_PROXY=%http_proxy%
set HTTPS_PROXY=%http_proxy%

:: 菜单选择器
echo ==========================================
echo 请选择同步方式:
echo [1] 普通更新 (add/commit/push --force)
echo [2] 覆盖远程 (fetch/reset/push --force)
echo [3] 强制更新彻底覆盖远程 (add -A/commit/push --force)
echo [4] 强制覆盖并重置远程历史 (clean commit --force)
echo [5] 彻底重置仓库 (initialization)
echo ==========================================
set /p choice=请输入数字(1-5): 

if "%choice%"=="1" goto 1_Normal_update
if "%choice%"=="2" goto 2_Normal_update
if "%choice%"=="3" goto 3_Force_update
if "%choice%"=="4" goto 4_Force_coverage
if "%choice%"=="5" goto 5_initialization

echo 输入错误，请输入 1-5
goto :EOF

:: 普通更新
:1_Normal_update
cd /d %~dp0
git add .
git commit -m "update files"
git push --force origin master
goto :EOF

:: 覆盖远程
:2_Normal_update
cd /d %~dp0
git fetch origin
git reset --hard HEAD
git push origin master --force
goto :EOF

:: 强制更新彻底覆盖远程
:3_Force_update
cd /d %~dp0
git add -A
git commit -m "reset commit"
git push --force origin master
goto :EOF

:: 强制覆盖并重置远程历史
:4_Force_coverage
cd /d %~dp0
git checkout master
git add -A
git commit -m "initial clean commit" --allow-empty
git push origin master --force
goto :EOF

:5_initialization
cd /d %~dp0
rmdir /s /q .git

git init
git remote add origin https://github.com/Tmalll/My-Tools-Template
git branch -M master

git add -A
git commit -m "initial clean commit"
git push origin master --force



pause
exit
