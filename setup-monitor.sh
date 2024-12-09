#!/bin/bash
# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Stop existing service if running
systemctl stop ak_monitor

# Get system architecture
ARCH=$(uname -m)
MONITOR_FILE="akile_monitor-linux-amd64"

# Set appropriate monitor file based on architecture
if [ "$ARCH" = "x86_64" ]; then
    MONITOR_FILE="akile_monitor-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    MONITOR_FILE="akile_monitor-linux-arm64"
elif [ "$ARCH" = "x86_64" ] && [ "$(uname -s)" = "Darwin" ]; then
    MONITOR_FILE="akile_monitor-darwin-amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Create directory and change to it
mkdir -p /etc/ak_monitor/
cd /etc/ak_monitor/

# Download monitor
wget -O ak_monitor https://github.com/akile-network/akile_monitor/releases/latest/download/$MONITOR_FILE
chmod 777 ak_monitor

# Create service file
cat > /etc/systemd/system/ak_monitor.service <<EOF
[Unit]
Description=AkileCloud Monitor Service
After=network.target nss-lookup.target
Wants=network.target

[Service]
User=root
Group=root
Type=simple
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=999999999
WorkingDirectory=/etc/ak_monitor/
ExecStart=/etc/ak_monitor/ak_monitor
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Get user input
read -p "Enter auth_secret: " auth_secret
read -p "Enter listen port (default 3000): " listen
listen=${listen:-"3000"}
read -p "Enter hook_token: " hook_token

# Get enable_tg choice and related information
while true; do
    read -p "Enable Telegram notifications? (y/n): " enable_tg_choice
    case $enable_tg_choice in
        [Yy]* ) 
            enable_tg=true
            read -p "Enter Telegram bot token: " tg_token
            read -p "Enter Telegram chat ID: " tg_chat_id
            break;;
        [Nn]* ) 
            enable_tg=false
            tg_token="your_telegram_bot_token"
            tg_chat_id=0
            break;;
        * ) echo "Please answer y or n.";;
    esac
done

# Create config file
cat > /etc/ak_monitor/config.json <<EOF
{
  "auth_secret": "${auth_secret}",
  "listen": ":${listen}",
  "enable_tg": ${enable_tg},
  "tg_token": "${tg_token}",
  "hook_uri": "/hook",
  "update_uri": "/monitor",
  "web_uri": "/ws",
  "hook_token": "${hook_token}",
  "tg_chat_id": ${tg_chat_id}
}
EOF

# Set permissions
chmod 644 /etc/ak_monitor/config.json
chmod 644 /etc/systemd/system/ak_monitor.service

# Start service
systemctl daemon-reload
systemctl enable ak_monitor.service
systemctl start ak_monitor.service

echo "Installation complete! Service status:"
systemctl status ak_monitor.service
