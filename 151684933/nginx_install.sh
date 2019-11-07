#!/bin/bash
#
# Auto install Nginx by source
#
# Program:
#       Program test network speed.
# History
# 2019/07/07     maxseed     First release
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

install_dir="/usr/local/nginx/"
source_dir="/usr/local/src/"
cur_dir=$(pwd)

version=(
    1.12.2
    1.14.2
    1.16.0
)

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

install_main(){
    yum install -y \
    make \
    gcc \
    gcc-c++ \
    pcre \
    pcre-devel \
    perl-ExtUtils-Embed \
    zlib \
    zlib-devel \
    openssl \
    openssl-devel \
    libxml2 \
    libxml2-devel \
    libxslt \
    libxslt-devel \
    gd \
    gd-devel \
    geoip \
    geoip-devel \
    gperftools-devel \
    wget
}

select_version(){
    while true
    do
    echo  "Which Version you'd select:"
    for ((i=1;i<=${#version[@]};i++ )); do
        hint="${version[$i-1]}"
        echo -e "${green}${i}${plain}) nginx-${hint}"
    done
    read -p "Please enter a number (Default ${version[0]}):" selected
    [ -z "${selected}" ] && selected="1"
    case "${selected}" in
        1|2|3)
        echo
        echo "You choose = ${version[${selected}-1]}"
        echo
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] Please only enter a number [1-3]"
        ;;
    esac
    done
}

download_source(){
    select_version=${version[${selected}-1]}
    cd ${source_dir}
    if [[ ! -f /usr/local/src/nginx-${version[${selected}-1]}.tar.gz ]];then
        wget http://nginx.org/download/nginx-${select_version}.tar.gz
    fi
    tar -zxvf nginx-${version[${selected}-1]}.tar.gz
    cd nginx-${version[${selected}-1]}
}

configure(){
    make clean
    ./configure \
    --prefix=/usr/local/nginx \
    --user=nginx \
    --group=nginx \
    --sbin-path=/usr/local/nginx/sbin/nginx \
    --conf-path=/usr/local/nginx/conf/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/usr/local/nginx/tmp/client_body \
    --http-proxy-temp-path=/usr/local/nginx/tmp/proxy \
    --http-fastcgi-temp-path=/usr/local/nginx/tmp/fastcgi \
    --http-uwsgi-temp-path=/usr/local/nginx/tmp/uwsgi \
    --http-scgi-temp-path=/usr/local/nginx/tmp/scgi \
    --with-file-aio \
    --with-ipv6 \
    --with-http_auth_request_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-http_perl_module=dynamic \
    --with-mail=dynamic \
    --with-mail_ssl_module \
    --with-pcre \
    --with-pcre-jit \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-google_perftools_module
}

compile(){
    make
    make install
    rm -fr ${source_dir}nginx-${version[${selected}-1]}
    if [[ ! -d /usr/local/nginx/tmp/client_body ]];then
        mkdir /usr/local/nginx/tmp
        mkdir /usr/local/nginx/tmp/client_body
    fi
}

add_service(){
    cat > /lib/systemd/system/nginx.service <<-'EOF'
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    if [[ -f /usr/bin/nginx ]];then
        rm -f /usr/bin/nginx
        ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
    else
        ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
    fi
}

set_firewall(){
    systemctl status firewalld > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        firewall-cmd --list-ports|grep 80 > /dev/null 2>&1
        if [ $? -eq 1 ];then
            firewall-cmd --zone=public --add-port=80/tcp --permanent
        fi
        firewall-cmd --list-ports|grep 443 > /dev/null 2>&1
        if [ $? -eq 1 ];then
            firewall-cmd --zone=public --add-port=443/tcp --permanent
        fi
        firewall-cmd --reload
    else
        echo -e "${yellow}Warning:${plain} firewalld looks like shutdown or not installed, please enable port 80 and 443 manually set if necessary."
    fi
}

nginx_conf(){
    if [[ ! -d /usr/local/nginx/conf/conf.d ]];then
        mkdir /usr/local/nginx/conf/conf.d
    fi
    cat > /usr/local/nginx/conf/nginx.conf <<-'EOF'
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/local/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;

    #keepalive_timeout   0;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /usr/local/nginx/conf/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /usr/local/nginx/conf/conf.d/*.conf;

    server_tokens off;

    #gzip  on;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;

        #charset koi8-r;

        # Load configuration files for the default server block.
        include /usr/local/nginx/conf/default.d/*.conf;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        # redirect server error pages to the static page /50x.html
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # Settings for a TLS enabled server.

    #server {
    #    listen       443 ssl http2 default_server;
    #    listen       [::]:443 ssl http2 default_server;
    #    server_name  _;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    Load configuration files for the default server block.
    #    include /etc/nginx/default.d/*.conf;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }

    #    error_page 404 /404.html;
    #        location = /40x.html {
    #    }

    #   error_page 500 502 503 504 /50x.html;
    #        location = /50x.html {
    #    }
    #}
}
EOF
}

install_nginx(){
    select_version
    determine
    useradd -M -s /sbin/nologin nginx
    disable_selinux
    install_main
    download_source
    configure
    compile
    add_service
    nginx_conf
    set_firewall
    echo
    echo -e "${blue}Install success${plain}"
    echo -e "${blue}Enjoy to use nginx${plain}"
    echo
    install_nginx 2>&1 | tee "${cur_dir}"/install_nginx.log
}

uninstall_nginx(){
    echo
    echo -e "You choose         :  ${blue}uninstall${plain}"
    echo
    echo -e "Press any key to start...or Press ${purple}Ctrl+C${plain} to cancel"
    char=$(get_char)
    rm -fr ${install_dir}
    rm -fr /var/log/nginx
    rm -f /var/run/nginx*
    rm -f /lib/systemd/system/nginx.service
    rm -f /usr/bin/nginx
    id nginx > /dev/null 2>&1 
    if [ $? -eq 0 ];then
        userdel nginx
    fi
    echo
    echo -e "${blue}Uninstall success${plain}"
    echo
}

get_char() {
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

determine(){
    clear
    opsy=$( get_opsy )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    kern=$( uname -r )
    echo "---------- System Information ----------"
    echo -e " OS      : ${blue}$opsy${plain}"
    echo -e " Arch    : ${blue}$arch ($lbit Bit)${plain}"
    echo -e " Kernel  : ${blue}$kern${plain}"
    echo "----------------------------------------"
    echo -e " ${yellow}Auto install Nginx by source${plain}"
    echo
    echo -e " You choose         :  ${blue} ${action[${action_select}-1]} ${plain}"
    echo -e " You choose version :  ${blue} nginx-${version[${selected}-1]} ${plain}"
    echo
    echo -e " URL: ${red}https://maxseed.top${plain}"
    echo "----------------------------------------"
    echo
    echo -e "Press any key to start...or Press ${purple}Ctrl+C${plain} to cancel"
    char=$(get_char)
}

# Initialization step
action=(
    install
    uninstall
)
clear
while true
do
echo  "You'd select install or uninstall:"
for ((i=1;i<=${#action[@]};i++ ));do
    hint="${action[$i-1]}"
    echo -e "${green}${i}${plain}) ${hint}"
done
read -p "Please enter a number (Default install): " action_select
case "${action_select}" in
    1|2)
        ${action[${action_select}-1]}_nginx
        break
    ;;
    *)
        echo "Arguments error!"
        echo -e "[${red}Error${plain}] Please only enter a number [1-2]"
    ;;
esac
done
exit
