#!/bin/bash
# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
   echo "Please run as root"
   exit 1
fi

# Function to detect main network interface
get_main_interface() {
    # Get a list of network interfaces excluding loopback, docker, virtual and bridge interfaces
    local interfaces=$(ip link show | awk -F': ' '$2 !~ /^(lo|docker|veth|br-|virbr|tun|bond|vnet|wg)/{print $2}')
    
    # Try to find the interface with a default route first
    local default_route=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [[ -n "$default_route" ]] && [[ "$interfaces" == *"$default_route"* ]]; then
        echo "$default_route"
        return
    fi
    
    # If no default route found, use the first available physical interface
    echo "$interfaces" | head -n1
}

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

# Check if arguments are provided (now only need 3 as net_name will be auto-detected)
if [ "$#" -ne 3 ]; then
   detected_interface=$(get_main_interface)
   echo "Usage: $0 <auth_secret> <url> <name>"
   echo "Example: $0 your_secret https://api.123.321 HK-Akile"
   echo "Detected main network interface: $detected_interface"
   exit 1
fi

# Assign command line arguments to variables
auth_secret="$1"
url="$2"
monitor_name="$3"
net_name=$(get_main_interface)

echo "Using network interface: $net_name"

# Create directory and change to it
mkdir -p /etc/ak_monitor/
cd /etc/ak_monitor/

# Rest of your original script...
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
