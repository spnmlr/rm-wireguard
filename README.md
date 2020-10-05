## Raspberrymatic WireGuard Config Addon

A Raspberrymatic Addon package for create WireGuard configs.

## Installation
### Raspberrymatic
1. install 'wireguard-tools' on your local device, e.g. 'brew install wireguard-tools'
2. execute 'bash generate-config.sh'
3. upload and install 'build/rm-wireguard.tar.gz' on Raspberrymatic/Addons
4. reboot Raspberrymatic
5. wait, plugins are in the autostart, but start at the end

### Client
1. install 'build/client.conf' on your client device

or create qr code for mobile devices

1. install 'qrencode' on your local device, e.g. 'brew install qrencode'
2. qrencode -t ansiutf8 < build/client.conf
3. open WireGuard app on your mobile device and scan the qr code

Don't forget to forward the ListenPort (udp) on your router.

## Supported Raspberrymatic models
Only tested with Raspberry Pi 3 Model B Rev 1.2