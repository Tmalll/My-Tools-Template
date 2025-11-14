:: 设置代理服务器
set http_proxy=socks5h://192.168.1.40:10800
set https_proxy=%http_proxy%
set HTTP_PROXY=%http_proxy%
set HTTPS_PROXY=%http_proxy%


cd /d %~dp0
git add .
git commit -m "update files"
git push --force origin master

pause
exit

:: 查看差异
git fetch origin
git log HEAD..origin/master --oneline
