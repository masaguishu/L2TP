#!/bin/bash

# 更新系统
apt update && apt upgrade -y

# 安装必要的软件
apt install -y xl2tpd strongswan

# 生成随机用户名和密码
USERNAME="user$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"
PASSWORD="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)"
SHARED_SECRET="shared$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"

# 手动输入公网IP
read -p "请输入您的公网IP: " PUBLIC_IP

# 配置IPsec
cat <<EOF > /etc/ipsec.conf
config setup
    nat_traversal = yes

include /var/lib/strongswan/ipsec.conf.inc
EOF

# 配置xl2tpd
cat <<EOF > /etc/xl2tpd/xl2tpd.conf
[global]
ip range = 192.168.1.2-192.168.1.100
local ip = 192.168.1.1
refuse chap = yes
refuse pap = yes
require authentication = yes
name = L2TP-Server
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd

[lns default]
ip = 192.168.1.1
local ip = 192.168.1.1
refuse chap = yes
refuse pap = yes
require authentication = yes
name = L2TP-Server
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
EOF

# 配置PPP选项
cat <<EOF > /etc/ppp/options.xl2tpd
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
lock
hide-password
modem
name l2tpd
password $PASSWORD
EOF

# 设置IPsec用户和密码
cat <<EOF >> /etc/ipsec.secrets
$USERNAME : XAUTH "$PASSWORD"
$PUBLIC_IP : PSK "$SHARED_SECRET"
EOF

# 启动服务
systemctl restart strongswan
systemctl restart xl2tpd

# 输出配置信息
echo "L2TP server configured. Please use the following settings:"
echo "VPS IP: $PUBLIC_IP"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Shared Secret: $SHARED_SECRET"
echo "L2TP local IP: 192.168.1.1"
echo "L2TP IP range: 192.168.1.2-192.168.1.100"
