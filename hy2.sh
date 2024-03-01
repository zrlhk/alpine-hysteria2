#!/bin/bash

apk add wget curl git openssh openssl openrc

generate_random_password() {
  dd if=/dev/random bs=18 count=1 status=none | base64
}

GENPASS="$(generate_random_password)"

echo_hysteria_config_yaml() {
  cat << EOF
listen: :40443


#有域名，使用CA证书
#acme:
#  domains:
#    - test.heybro.bid #你的域名，需要先解析到服务器ip
#  email: xxx@gmail.com

#使用自签名证书
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $GENPASS

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF
}

echo_hysteria_autoStart(){
  cat << EOF
#!/sbin/openrc-run

name="hysteria"

command="/usr/local/bin/hysteria"
command_args="server --config /etc/hysteria/config.yaml"

pidfile="/var/run/${name}.pid"

command_background="yes"

depend() {
        need networking
}

EOF
}


wget -O /usr/local/bin/hysteria https://download.hysteria.network/app/latest/hysteria-linux-amd64  --no-check-certificate
chmod +x /usr/local/bin/hysteria

mkdir -p /etc/hysteria/

openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=bing.com" -days 36500

#写配置文件
echo_hysteria_config_yaml > "/etc/hysteria/config.yaml"

#写自启动
echo_hysteria_autoStart > "/etc/init.d/hysteria"
chmod +x /etc/init.d/hysteria
#启用自启动
rc-update add hysteria

service hysteria start

#启动hy2
#/usr/local/bin/hysteria  server --config /etc/hysteria/config.yaml &

echo "------------------------------------------------------------------------"
echo "hysteria2已经安装完成"
echo "默认端口： 40443 ， 密码为： $GENPASS ，工具中配置：tls，SNI为： bing.com"
echo "配置文件：/etc/hysteria/config.yaml"
echo "已经随系统自动启动"
echo "看状态 service hysteria status"
echo "重启 service hysteria restart"
echo "请享用。"
echo "------------------------------------------------------------------------"