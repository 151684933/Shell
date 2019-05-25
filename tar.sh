#!/bin/bash
# Program:
#       Program test network speed.
# History
# 2019/5/20     maxseed     First release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 压缩/解压
compresses=(
    压缩
    解压
)
# 压缩方式
compresses_mode=(
    gzip
    bzip2
    xz
)

# 日期
date=(
    当前日期
    手动填写
)

# 解压/压缩存放目录
directory=(
    当前目录
    手动填写
)

# 当前目录
cur_dir=$( pwd )

# 当前日期
now_date=$( date +%Y-%m-%d )

# 颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
plain='\033[0m'

clear
echo
echo "##################################################"
echo "# 这是一个 tar 打包脚本                          #"
echo "# 支持 gzip，bzip2，xz                           #"
echo "##################################################"
echo

#compresses/decompresses
    while true
    do
    echo "选择压缩/解压: "
    for ((i=1;i<=${#compresses[@]};i++ ));do
        hint="${compresses[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "请输入数字 [1-2]:" compresses_select
    case "${compresses_select}" in
        1|2)
            echo
            echo "---------------------------"
            echo -e "${blue}选择压缩/解压: ${plain}${yellow}${compresses[${compresses_select}-1]}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        *)
            echo -e "[${red}错误${plain}] 请输入数字 [1-2]"
        ;;
    esac
    done

#compresses_mode
    while true
    do
    echo "选择你的压缩/解压方式："
    for ((i=1;i<=${#compresses_mode[@]};i++ ));do
        hint="${compresses_mode[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "请输入数字 [1-3]:" compresses_mode_select
    case "${compresses_mode_select}" in
        1|2|3)
            echo
            echo "---------------------------"
            echo -e "${blue}压缩/解压方式: ${plain}${yellow}${compresses_mode[${compresses_mode_select}-1]}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        *)
            echo -e "[${red}错误${plain}] 请输入数字 [1-3]"
        ;;
    esac
    done


#date_select
    while true
    do
    echo "选择日期："
    for ((i=1;i<=${#date[@]};i++ ));do
        hint="${date[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "请输入数字 [1-2]:" select_date
    case "${select_date}" in
        1)
            echo
            echo "---------------------------"
            echo -e "${blue}选择日期: ${plain}${yellow}${now_date}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        2)
            read -p "填入日期:" date_input
            echo
            echo "---------------------------"
            echo -e "${blue}选择日期: ${plain}${yellow}${date_input}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        *)
            echo -e "[${red}错误${plain}] 请输入数字 [1-2]"
        ;;
    esac
    done

#filename
    echo "请输入你需要压缩/解压的文件"
    read -e filename
    echo
    echo "---------------------------"
    echo -e "${blue}压缩/解压的文件: ${plain}${yellow}${filename}${plain}"
    echo "---------------------------"
    echo

#directory
    while true
    do
    echo "选择压缩/解压目录: "
    for ((i=1;i<=${#directory[@]};i++ ));do
        hint="${directory[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "请输入数字 [1-2]:" select_directory
    case "${select_directory}" in
        1)
            echo
            echo "---------------------------"
            echo -e "${blue}选择压缩/解压目录: ${plain}${yellow}${cur_dir}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        2)
            read -ep "填入压缩/解压目录:" directory_input
            echo
            echo "---------------------------"
            echo -e "${blue}选择压缩/解压目录: ${plain}${yellow}${directory_input}${plain}"
            echo "---------------------------"
            echo
            break
        ;;
        *)
            echo -e "[${red}错误${plain}] 请输入数字 [1-2]"
        ;;
    esac
    done