#!/bin/bash
# Installing the WaziGate framework on your device
# @author: Mojiz 20 Jun 2019

#Setup WAZIUP_ROOT as first argument, with a default value
WAZIUP_ROOT=${1:-$HOME/waziup-gateway}

#--------------------------------#

echo "Installing system-wide packages..."
#Packages
sudo apt-get update
sudo apt-get install -y git network-manager python3 python3-pip dnsmasq hostapd connectd i2c-tools libopenjp2-7 libtiff5 ntp avahi-daemon libmicrohttpd-dev

sudo apt-get install python3-dev libfreetype6-dev libjpeg-dev build-essential
sudo apt-get install libsdl-dev libportmidi-dev libsdl-ttf2.0-dev libsdl-mixer1.2-dev libsdl

sleep 1

sudo usermod -a -G i2c,spi,gpio pi

sudo -H pip3 install --upgrade pip setuptools

sudo -H pip3 install luma.oled 
sudo -H pip3 install flask 
sudo -H pip3 install psutil

#--------------------------------#

#Docker
sudo curl -fsSL get.docker.com -o get-docker.sh 
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo rm get-docker.sh
sudo cp setup/docker-compose /usr/bin/ && sudo chmod +x /usr/bin/docker-compose
echo "Done"

#--------------------------------#

#Setting up the Access Point
sudo systemctl stop dnsmasq; sudo systemctl stop hostapd

sudo mv --backup=numbered /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo bash -c "echo -e 'interface=wlan0\n  dhcp-range=192.168.200.2,192.168.200.200,255.255.255.0,24h\n' > /etc/dnsmasq.conf"

sudo cp setup/hostapd.conf /etc/hostapd/hostapd.conf

#Using Rapi MAC address as device ID
#MAC=$(cat /sys/class/net/eth0/address)
#MAC=${MAC//:}
#gwId="${MAC^^}"
#sudo sed -i "s/^ssid.*/ssid=WAZIGATE_$gwId/g" /etc/hostapd/hostapd.conf

if ! grep -qFx 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
  sudo sed -i -e '$i \DAEMON_CONF="/etc/hostapd/hostapd.conf"\n' /etc/default/hostapd
fi

#setup access point by default
#sudo cp --backup=numbered setup/interfaces_ap /etc/network/interfaces

#Wlan: make a copy of the config file
sudo cp --backup=numbered /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.orig

#--------------------------------#

#Name the gateway
sudo sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\twazigate/g' /etc/hosts
sudo bash -c "echo -e '\n192.168.200.1\twazigate\n' >> /etc/hosts"
sudo echo -e 'wazigate' | sudo tee /etc/hostname

# Resolving the issue of not having internet within the containers
sudo bash -c "echo -e 'nameserver 8.8.8.8' > /etc/resolv.conf"

#--------------------------------#
#Edge default cloud settings. (Used only in the production version)
cp setup/clouds.json wazigate-edge

#--------------------------------#

#Setup autostart

sudo chmod a+x ./start.sh
sudo chmod a+x ./stop.sh

if ! grep -qF "start.sh" /etc/rc.local; then
  sudo sed -i -e '$i \cd '"$WAZIUP_ROOT"'; sudo bash ./start.sh &\n' /etc/rc.local
fi

#--------------------------------#
#Install and config WiFi Captive Portal
#cd ~
#git clone https://github.com/nodogsplash/nodogsplash.git
#cd nodogsplash
#make
#sudo make install

#sudo cp $WAZIUP_ROOT/setup/nodogsplash/nodogsplash.conf /etc/nodogsplash/nodogsplash.conf
#sudo cp $WAZIUP_ROOT/setup/nodogsplash/htdocs/splash.html /etc/nodogsplash/htdocs/splash.html

#--------------------------------#

#Setup I2C (http://www.runeaudio.com/forum/how-to-enable-i2c-t1287.html)
echo "Configuring the system..."
if ! grep -qFx "dtparam=i2c_arm=on" /boot/config.txt; then
  echo -e '\ndtparam=i2c_arm=on' | sudo tee -a /boot/config.txt
fi
if ! grep -qF "bcm2708.vc_i2c_override=1" /boot/cmdline.txt; then
  sudo bash -c "echo -n ' bcm2708.vc_i2c_override=1' >> /boot/cmdline.txt"
fi
if ! grep -qFx "i2c-bcm2708" /etc/modules-load.d/raspberrypi.conf; then
  echo -e '\ni2c-bcm2708' | sudo tee -a /etc/modules-load.d/raspberrypi.conf
fi
if ! grep -qFx "i2c-dev" /etc/modules-load.d/raspberrypi.conf; then
  echo -e '\ni2c-dev' | sudo tee -a /etc/modules-load.d/raspberrypi.conf
fi

#--------------------------------#

# ---- HDMI display web interface ----- #

##do the AUTO_LOGIN 

sudo apt install -y midori
mkdir -p ~/.config/lxsession && mkdir -p ~/.config/lxsession/LXDE-pi
#nano ~/.config/lxsession/LXDE-pi/autostart

## Auto run the browser
echo -e "@xset s off" > ~/.config/lxsession/LXDE-pi/autostart
echo -e "@xset -dpms" >> ~/.config/lxsession/LXDE-pi/autostart
echo -e "@xset s noblank" >> ~/.config/lxsession/LXDE-pi/autostart
echo -e "@midori -e Fullscreen -a file:///home/pi/waziup-gateway/wazigate-host/init-hdmi-ui.html" >> ~/.config/lxsession/LXDE-pi/autostart


# ---- Splash screen ---- #

echo -e '\ndisable_splash=1' | sudo tee -a /boot/config.txt
echo -e '\nsplash quiet plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0' | sudo tee -a /boot/cmdline.txt
sudo cp $WAZIUP_ROOT/setup/waziup-logo.png /usr/share/plymouth/themes/pix/splash.png

#--------------------------------#

echo "Done"

#echo -e "loragateway\nloragateway" | sudo passwd $USER
