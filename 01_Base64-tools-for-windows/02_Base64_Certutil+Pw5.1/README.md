使用 windows 自带的 Certutil 工具作为 base64 解码工具 + 使用 powershell 5.1(系统自带版) 作为编码工具

编码限制 (测试最大5G文件编码成功)

解码限制 小于 2.66GB 的 Base64 文件 ( 也就是编码前小于2GB的二进制文件 )

使用方法: 把要转码的文件拖放到.bat文件上面, 路径中不能有特殊符号.


# v1 版本 功能和 01_Base64_Certutil 内的脚本一样,  只是编码换成了 powershell 5.1 以支持大文件

# v2 版本 性能做了优化

# v3 版本 加入文件分割功能, 详情见脚本内注释, 可以设定每个分片的大小 (建议值2048M, 以兼容 Certutil 解码)

# v4.0 版本 v3版本的基础上增加批量解码功能


测试情况: (设备条件: 读写速度在500mb/s左右的垃圾sata SSD硬盘)

v1 SSD编码5G文件 57s

v2 SSD编码5G文件 29s

coreutils_base64_Conver SSD编码5G文件 18.45秒

v2 SSD编码5G文件 bufferSize=33m+fsBufSize=2m  27s

v2 SSD编码5G文件 bufferSize=12m+fsBufSize=1m 26s

v3初版 SSD编码5G文件 分割100mb 27s + Certutil单线程解码 72s + copy合并 11秒 合并成功.

v3 SSD编码5G文件 分割2048mb 28s

v4 SSD编码5G文件 分割块100mb=33s   4线程合并= 28.0s
v4 SSD编码5G文件 分割块100mb=33s   异步4线程合并= 26.0s
v4 SSD编码5G文件 分割块100mb=33s   异步8线程合并= 24.0s
v4 SSD编码5G文件 分割块100mb=33s   异步999线程合并= 17s

v4 HDD编码5G文件, 分割块100mb=112s   异步1线程合并=106
v4 HDD编码5G文件, 分割块100mb=112s   异步2线程合并=65.12s
v4 HDD编码5G文件, 分割块100mb=112s   异步3线程合并=51.73s
v4 HDD编码5G文件, 分割块100mb=112s   异步4线程合并1=100s
v4 HDD编码5G文件, 分割块100mb=112s   异步4线程合并2=55.28s
v4 HDD编码5G文件, 分割块100mb=112s   异步5线程合并=55.79s
v4 HDD编码5G文件, 分割块100mb=112s   异步5线程合并=55.79s


















