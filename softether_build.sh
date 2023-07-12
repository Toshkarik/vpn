#!/bin/bash
set -e
set -x

SE_VERSION="4.42-9798-rtm"
SE_VERSION_DATE="2023.06.30"
SRC_URL="https://www.softether-download.com/files/softether/v${SE_VERSION}-${SE_VERSION_DATE}-tree/Source_Code/softether-src-v${SE_VERSION}.tar.gz"
SRC_FILE_NAME="se_src"
INSTALL_DIR="/opt/softether"

J_NUM=1

WORK_DIR=softether_build

if [ ! -z $1 ]; then
    WORK_DIR=$1/${WORK_DIR}
fi

WORK_DIR=realpath ${WORK_DIR}

PREV_CFG=${WORK_DIR}/prev_vpn_server_$(date +%s).config

apt-get -y install build-essential libreadline-dev libssl-dev zlib1g-dev wget
mkdir ${WORK_DIR} -p
cd ${WORK_DIR}
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
    if [ $(systemctl is-active softether-vpnserver) == "active" ]; then
        systemctl stop softether-vpnserver
    fi

    cp bin/vpnserver/vpnserver $INSTALL_DIR
    cp bin/vpnserver/hamcore.se2 $INSTALL_DIR
else
    mkdir $INSTALL_DIR -p
    cp -R bin/vpnserver/ $INSTALL_DIR
fi

if [ -f "${PREV_CFG}" ]; then
    cp ${PREV_CFG} $INSTALL_DIR/vpnserver/vpn_server.config
fi

cp systemd/softether-vpnserver.service /etc/systemd/system/

systemctl daemon-reload
systemctl unmask softether-vpnserver
systemctl enable softether-vpnserver
systemctl start softether-vpnserver
