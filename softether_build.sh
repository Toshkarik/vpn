#!/bin/bash
set -e
set -x
SRC_URL="https://www.softether-download.com/files/softether/v4.41-9787-rtm-2023.03.14-tree/Source_Code/softether-src-v4.41-9787-rtm.tar.gz"
SRC_FILE_NAME="se_src"

INSTALL_DIR="/opt/softether"
#INSTALL_DIR="$HOME/se_inst"
J_NUM=1

apt-get -y install build-essential libreadline-dev libssl-dev zlib1g-dev
mkdir ~/se -p
cd ~/se
wget -c $SRC_URL -O $SRC_FILE_NAME
mkdir src -p
tar xf $SRC_FILE_NAME -C src --strip-components=1
cd src
sed -i "s+/opt+${INSTALL_DIR}+g" systemd/softether-vpnserver.service
./configure
make -j$J_NUM
mkdir $INSTALL_DIR -p
cp -R bin/vpnserver/ $INSTALL_DIR


cp /var/lib/softether/vpn_server.config ~/prev_vpn_server.config
cp /var/lib/softether/vpn_server.config $INSTALL_DIR/vpnserver/

systemctl disable softether-vpnserver
systemctl stop softether-vpnserver

apt-get -y remove softether-vpnserver
apt-get -y autoremove

systemctl daemon-reload
cp systemd/softether-vpnserver.service /etc/systemd/system/


systemctl daemon-reload
systemctl unmask softether-vpnserver
systemctl enable softether-vpnserver
systemctl start softether-vpnserver
