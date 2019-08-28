#!/bin/bash

echo -e "nameserver 208.67.222.222\nnameserver 208.67.220.220" > /etc/resolv.conf

# Connect to windscribe
/etc/init.d/windscribe-cli start 

# VPN_USERNAME=$(grep "VPN_USERNAME" /opt/JDownloader/cfg/vpn.cfg | cut -d "=" -f 2)
# VPN_PASSWORD=$(grep "VPN_PASSWORD" /opt/JDownloader/cfg/vpn.cfg | cut -d "=" -f 2)
#set timeout -1  

expect << EOF
    spawn windscribe login
    expect "Windscribe Username: "
    send "${VPN_USERNAME}\n"
    expect "Windscribe Password: "
    send "${VPN_PASSWORD}\n"
    expect eof
EOF

windscribe protocol tcp

WINDSCRIBE_LOCATION=""
if [ "$VPN_PRO" = "True" ]; then
    WINDSCRIBE_LOCATION=$(windscribe locations | awk -F " {2,}" '{print $4}' | grep -v 'Label' | sort -R | head -n 1)
else
    WINDSCRIBE_LOCATION=$(windscribe locations | grep -v "*" | awk -F " {2,}" '{print $4}' | grep -v 'Label' | sort -R | head -n 1)
fi

windscribe connect $WINDSCRIBE_LOCATION