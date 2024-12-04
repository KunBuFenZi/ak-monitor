#!/bin/bash

# Check if run as root
if [ "$EUID" -ne 0 ]; then
 echo "Please run as root"
 exit 1
fi

# Redirect all output to /dev/null and save original stdout
exec 3>&1
exec 1>/dev/null 2>&1

# Install bc if not present
if ! command -v bc > /dev/null; then
   if command -v apt-get > /dev/null; then
       apt-get update && apt-get install -y bc
   elif command -v yum > /dev/null; then
       yum update -y && yum install -y bc
   fi
fi

# Restore original stdout
exec 1>&3

# Stop existing service
systemctl stop ak_client

# Function to detect main network interface
get_main_interface() {
   local interfaces=$(ip -o link show | \
       awk -F': ' '$2 !~ /^(lo|docker|veth|br-|virbr|tun|bond|vnet|wg|vmbr|dummy|gre|sit|vlan|lxc|lxd|tap)/{print $2}' | \
       grep -v '@')
   
   local interface_count=$(echo "$interfaces" | wc -l)
   
   format_bytes() {
       local bytes=$1
       if [ $bytes -lt 1024 ]; then
           echo "${bytes} B"
       elif [ $bytes -lt 1048576 ]; then
           echo "$(echo "scale=2; $bytes/1024" | bc) KB"
       elif [ $bytes -lt 1073741824 ]; then
           echo "$(echo "scale=2; $bytes/1024/1024" | bc) MB"
       elif [ $bytes -lt 1099511627776 ]; then
           echo "$(echo "scale=2; $bytes/1024/1024/1024" | bc) GB"
       else
           echo "$(echo "scale=2; $bytes/1024/1024/1024/1024" | bc) TB"
       fi
   }
   
   show_interface_traffic() {
       local interface=$1
       local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
       local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
       echo "   ↓ Received: $(format_bytes $rx_bytes)"
       echo "   ↑ Sent: $(format_bytes $tx_bytes)"
   }
   
   if [ -z "$interfaces" ]; then
       echo "No suitable physical network interfaces found." >&2
       echo "All available interfaces:" >&2
       echo "------------------------" >&2
       while read -r interface; do
           echo "$i) $interface" >&2
           show_interface_traffic "$interface" >&2
           i=$((i+1))
       done < <(ip -o link show | grep -v "lo:" | awk -F': ' '{print $2}')
       echo "------------------------" >&2
       read -p "Please select interface number: " selection
       selected_interface=$(ip -o link show | grep -v "lo:" | sed -n "${selection}p" | awk -F': ' '{print $2}')
       echo "$selected_interface"
       return
   fi
   
   if [ "$interface_count" -eq 1 ]; then
       echo "Using single available interface:" >&2
       echo "$interfaces" >&2
       show_interface_traffic "$interfaces" >&2
       echo "$interfaces"
       return
   fi
   
   echo "Multiple suitable interfaces found:" >&2
   echo "------------------------" >&2
   local i=1
   while read -r interface; do
       echo "$i) $interface" >&2
       show_interface_traffic "$interface" >&2
       i=$((i+1))
   done <<< "$interfaces"
   echo "------------------------" >&2
   read -p "Please select interface number [1-$interface_count]: " selection >&2
   selected_interface=$(echo "$interfaces" | sed -n "${selection}p")
   echo "$selected_interface"
}

# Check arguments
if [ "$#" -ne 3 ]; then
 echo "Usage: $0 <auth_secret> <url> <name>"
 echo "Example: $0 your_secret wss://api.123.321 HK-Akile"
 exit 1
fi

# Get architecture
ARCH=$(uname -m)
CLIENT_FILE="akile_client-linux-amd64"

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

# Set variables
auth_secret="$1"
url="$2"
monitor_name="$3"

# Get network interface
net_name=$(get_main_interface)
echo "Using network interface: $net_name"

# Create directory and change to it
mkdir -p /etc/ak_monitor/
cd /etc/ak_monitor/

# Download client
wget -O client https://github.com/akile-network/akile_monitor/releases/latest/download/$CLIENT_FILE
chmod 777 client

# Create service file
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

# Create config
cat > /etc/ak_monitor/client.json << EOF
{
"auth_secret": "${auth_secret}",
"url": "${url}",
"net_name": "${net_name}",
"name": "${monitor_name}"
}
EOF

# Set permissions
chmod 644 /etc/ak_monitor/client.json
chmod 644 /etc/systemd/system/ak_client.service

# Start service
systemctl daemon-reload
systemctl enable ak_client.service
systemctl start ak_client.service

echo "Installation complete! Service status:"
systemctl status ak_client.service
