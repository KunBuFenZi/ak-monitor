##主控后端

```
wget -O setup-monitor.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-monitor.sh" && chmod +x setup-monitor.sh && sudo ./setup-monitor.sh
```

##被控端

```
wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh" && chmod +x setup-client.sh && sudo ./setup-client.sh <your_secret> <url> <net_name> <name>
```
如
```
wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh" && chmod +x setup-client.sh && sudo ./setup-client.sh 123321 wss://123.321.123.321/monitor eth0 HKLite-One-Akile
```
