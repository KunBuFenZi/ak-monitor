#!/bin/bash
# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Stop existing service if running
systemctl stop ak_client

# Function to detect main network interface
get_main_interface() {
   # 先过滤掉所有虚拟接口和容器接口
   local interfaces=$(ip -o link show | \
       awk -F': ' '$2 !~ /^(lo|docker|veth|br-|virbr|tun|bond|vnet|wg|vmbr|dummy|gre|sit|vlan|lxc|lxd|tap)/{print $2}' | \
       grep -v '@')
   
   # 获取接口数量
   local interface_count=$(echo "$interfaces" | wc -l)
   
   # 如果没有找到合适的接口
   if [ -z "$interfaces" ]; then
       echo "No suitable physical network interfaces found." >&2
       echo "All available interfaces:" >&2
       echo "------------------------" >&2
       ip -o link show | grep -v "lo:" | awk -F': ' '{print NR") "$2}' >&2
       echo "------------------------" >&2
       read -p "Please select interface number: " selection
       selected_interface=$(ip -o link show | grep -v "lo:" | sed -n "${selection}p" | awk -F': ' '{print $2}')
       echo "$selected_interface"
       return
   fi
   
   # 如果只有一个合适的接口，直接使用它
   if [ "$interface_count" -eq 1 ]; then
       echo "Using single available interface:" >&2
       echo "$interfaces" >&2
       echo "$interfaces"
       return
   fi
   
   # 如果有多个合适的接口，让用户选择
   echo "Multiple suitable interfaces found:" >&2
   echo "------------------------" >&2
   local i=1
   while read -r interface; do
       echo "$i) $interface" >&2
       i=$((i+1))
   done <<< "$interfaces"
   echo "------------------------" >&2
   read -p "Please select interface number [1-$interface_count]: " selection >&2
   selected_interface=$(echo "$interfaces" | sed -n "${selection}p")
   echo "$selected_interface"
}

# Check if all arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <auth_secret> <url> <name>"
  echo "Example: $0 your_secret wss://api.123.321 HK-Akile"
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
