#!/bin/bash
set -e
set -x
SRC_URL="https://www.softether-download.com/files/softether/v4.42-9798-rtm-2023.06.30-tree/Source_Code/softether-src-v4.42-9798-rtm.tar.gz"
SRC_FILE_NAME="se_src"

INSTALL_DIR="/opt/softether"
PREV_CFG=~/prev_vpn_server_$(date +%s).config
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

if [ -f "$INSTALL_DIR/vpnserver/vpn_server.config" ]; then
    cp $INSTALL_DIR/vpnserver/vpn_server.config ${PREV_CFG}
fi

if [ -d "$INSTALL_DIR" ]; then
    systemctl stop softether-vpnserver
    rm $INSTALL_DIR/vpnserver
    rm $INSTALL_DIR/hamcore.se2
    rm /etc/systemd/system/softether-vpnserver.service
    cp bin/vpnserver/vpnserver $INSTALL_DIR
    cp bin/vpnserver/hamcore.se2 $INSTALL_DIR
else
    mkdir $INSTALL_DIR -p
    cp -R bin/vpnserver/ $INSTALL_DIR
    systemctl enable softether-vpnserver
fi

if [ -f "${PREV_CFG}" ]; then
    cp ${PREV_CFG} $INSTALL_DIR/vpnserver/vpn_server.config
fi

cp systemd/softether-vpnserver.service /etc/systemd/system/

systemctl daemon-reload
systemctl unmask softether-vpnserver
systemctl start softether-vpnserver
