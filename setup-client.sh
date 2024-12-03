#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
   echo "Please run as root"
   exit 1
fi

# Check if all arguments are provided
if [ "$#" -ne 4 ]; then
   echo "Usage: $0 <auth_secret> <url> <net_name> <name>"
   echo "Example: $0 your_secret https://api.123.321 eth0 HK-Akile"
   exit 1
fi

# Get system architecture
ARCH=$(uname -m)
CLIENT_FILE="akile_client-linux-amd64"

# Set appropriate client file based on architecture
if [ "$ARCH" = "x86_64" ]; then
   CLIENT_FILE="akile_client-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
   CLIENT_FILE="akile_client-linux-arm64"
elif [ "$ARCH" = "x86_64" ] && [ "$(uname -s)" = "Darwin" ]; then
   CLIENT_FILE="akile_client-darwin-amd64"
else
   echo "Unsupported architecture: $ARCH"
   exit 1
fi

# Assign command line arguments to variables
auth_secret="$1"
url="$2"
net_name="$3"
monitor_name="$4"

# Create directory and change to it
mkdir -p /etc/ak_monitor/
cd /etc/ak_monitor/

# Download client
wget -O client https://github.com/akile-network/akile_monitor/releases/latest/download/$CLIENT_FILE
chmod 777 client

# Create systemd service file
cat > /etc/systemd/system/ak_client.service << 'EOF'
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
ExecStart=/etc/ak_monitor/client
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create client configuration
cat > /etc/ak_monitor/client.json << EOF
{
 "auth_secret": "${auth_secret}",
 "url": "${url}",
 "net_name": "${net_name}",
 "name": "${monitor_name}"
}
EOF

# Set proper permissions
chmod 644 /etc/ak_monitor/client.json
chmod 644 /etc/systemd/system/ak_client.service

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable ak_client.service
systemctl start ak_client.service

echo "Installation complete! Service status:"
systemctl status ak_client.service
