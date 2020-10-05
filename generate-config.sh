#!/bin/bash
echo "What is the ListenPort (e.g. 51820)?"
read -r listenport
echo "What is the external DNS Name (e.g. abc.dyndns.org)?"
read -r external
echo "What is the WireGuard Server IP (e.g. 10.0.0.1)?"
read -r serverip
echo "What is the local Network DNS Server IP (e.g. 192.168.0.1)?"
read -r dnsserver
echo "What is the WireGuard Client IP (e.g. 10.0.0.2)?"
read -r clientip
echo "generate keys if not exists ..."
if [[ ! -f "keys/server-privatekey" ]] || [[ ! -f "keys/server-publickey" ]] || [[ ! -f "keys/client-privatekey" ]] || [[ ! -f "keys/client-publickey" ]]; then
    echo "creating keys"
    mkdir keys
    wg genkey | tee keys/server-privatekey | wg pubkey > keys/server-publickey
    wg genkey | tee keys/client-privatekey | wg pubkey > keys/client-publickey
    chmod og-rwx keys/*key
fi
echo "create configs ..."
cat > src/wireguard << EOF
#!/bin/sh

ADDONS_DIR=/usr/local/addons/wireguard

start() {
  sysctl -w net.ipv4.ip_forward=1
  ip link add dev wg0 type wireguard
  ip address add dev wg0 $serverip/24
  wg setconf wg0 \$ADDONS_DIR/wg0.conf
  ip link set up dev wg0
  iptables -A INPUT -p udp -m udp --dport $listenport -j ACCEPT; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

stop() {
  ip link del dev wg0 type wireguard
  sysctl -w net.ipv4.ip_forward=0
  iptables -D INPUT -p udp -m udp --dport $listenport -j ACCEPT; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
}

case "\$1" in
""|start)
  start
  ;;
info)
  VER="config build at "$(date)""
  echo "Info: <b>RM WireGuard Config Addon</b><br>"
  echo "Info: <a href='https://github.com/spnmlr/rm-wireguard'>https://github.com/spnmlr/rm-wireguard</a>"
  echo "Version: config build at "$(date)""
  echo "Name: rm-wireguard"
  echo "Operations: uninstall restart"
  ;;
restart)
  stop
  sleep 2
  start
  ;;
stop)
  stop
  ;;
uninstall)
  stop
  rm -rf \$ADDONS_DIR
  ;;
*)
  echo "Usage: $0 {start|stop|restart|info|uninstall}" >&2
  exit 1
  ;;
esac

exit 0
EOF
cat > src/wg0.conf << EOF
[Interface]
PrivateKey = $(cat keys/server-privatekey)
ListenPort = $listenport

[Peer]
PublicKey  = $(cat keys/client-publickey)
AllowedIPs = $clientip/32
EOF
mkdir build
cat > build/client.conf << EOF
[Interface]
Address = $clientip/32
PrivateKey = $(cat keys/client-privatekey)
DNS = $dnsserver

[Peer]
PublicKey = $(cat keys/server-publickey)
Endpoint = $external:$listenport
AllowedIPs = 0.0.0.0/0
EOF
echo "create plugin ..."
tar cfvz build/rm-wireguard.tar.gz -C src .