#!/bin/bash

if [ "$EUID" -ne 0 ]; then
   echo "Please run as root"
   exit 1
fi

function install_monitor() {
   wget -O setup-monitor.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-monitor.sh"
   chmod +x setup-monitor.sh
   ./setup-monitor.sh
}

function uninstall_monitor() {
   systemctl stop ak_monitor
   systemctl disable ak_monitor
   rm -f /etc/systemd/system/ak_monitor.service
   rm -rf /etc/ak_monitor
   systemctl daemon-reload
   echo "Monitor backend uninstalled"
}

function view_monitor_config() {
   if [ -f /etc/ak_monitor/config.json ]; then
       cat /etc/ak_monitor/config.json
   else
       echo "Monitor config not found"
   fi
}

function update_monitor() {
   systemctl stop ak_monitor
   install_monitor
   echo "Monitor updated"
}

function install_client() {
   echo "Please provide client installation parameters:"
   read -p "Enter auth_secret: " auth_secret
   read -p "Enter URL: " url
   read -p "Enter name: " name

   wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh"
   chmod +x setup-client.sh
   ./setup-client.sh "$auth_secret" "$url" "$name"
}

function uninstall_client() {
   systemctl stop ak_client
   systemctl disable ak_client
   rm -f /etc/systemd/system/ak_client.service
   rm -rf /etc/ak_monitor
   systemctl daemon-reload
   echo "Client uninstalled"
}

function view_client_config() {
   if [ -f /etc/ak_monitor/client.json ]; then
       cat /etc/ak_monitor/client.json
   else
       echo "Client config not found"
   fi
}

function update_client() {
   if [ ! -f /etc/ak_monitor/client.json ]; then
       echo "Client config not found, cannot update"
       return
   fi
   
   # Extract existing config values
   auth_secret=$(grep -o '"auth_secret": *"[^"]*"' /etc/ak_monitor/client.json | cut -d'"' -f4)
   url=$(grep -o '"url": *"[^"]*"' /etc/ak_monitor/client.json | cut -d'"' -f4)
   name=$(grep -o '"name": *"[^"]*"' /etc/ak_monitor/client.json | cut -d'"' -f4)
   
   systemctl stop ak_client
   wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh"
   chmod +x setup-client.sh
   ./setup-client.sh "$auth_secret" "$url" "$name"
   echo "Client updated"
}

while true; do
   echo "=================================================="
   echo "AkileCloud Monitor 管理脚本 Powered by KunBuFenZi"
   echo "=================================================="
   echo "1.安装主控后端"
   echo "2.卸载主控后端"
   echo "3.查看主控config"
   echo "4.更新主控后端"
   echo "5.安装被控"
   echo "6.卸载被控"
   echo "7.查看被控config"
   echo "8.更新被控"
   echo "9.退出"
   echo "============================================="
   
   read -p "Please select an option (1-9): " choice
   
   case $choice in
       1) install_monitor ;;
       2) uninstall_monitor ;;
       3) view_monitor_config ;;
       4) update_monitor ;;
       5) install_client ;;
       6) uninstall_client ;;
       7) view_client_config ;;
       8) update_client ;;
       9) exit 0 ;;
       *) echo "Invalid option" ;;
   esac
   
   echo
   read -p "Press Enter to continue..."
   clear
done
