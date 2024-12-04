# 本脚本已并入官方

视频教程：
<video src="https://pan.kbfz.top/d/Local/AK-monitor.mp4"></video>


# 非官方demo：

https://uptime.cpu.red

## 前后端集合一键脚本

```
wget -O ak-setup.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/ak-setup.sh" && chmod +x ak-setup.sh && sudo ./ak-setup.sh
```

![image](https://github.com/user-attachments/assets/40b80106-9c07-4def-a8b5-35a48d6401ae)



## 主控后端

```
wget -O setup-monitor.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-monitor.sh" && chmod +x setup-monitor.sh && sudo ./setup-monitor.sh
```

## 被控端

```
wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh" && chmod +x setup-client.sh && sudo ./setup-client.sh <your_secret> <url> <name>
```
如
```
wget -O setup-client.sh "https://raw.githubusercontent.com/KunBuFenZi/ak-monitor/refs/heads/main/setup-client.sh" && chmod +x setup-client.sh && sudo ./setup-client.sh 123321 wss://123.321.123.321/monitor HKLite-One-Akile
```

## 主控前端部署教程(cf pages)

### 1.下载
···
https://github.com/akile-network/akile_monitor_fe/releases/download/v0.0.1/akile_monitor_fe.zip
···

### 2.修改config.json为自己的api地址（公网地址）（如果前端要加ssl 后端也要加ssl 且此处记得改为https和wss）

```
{
  "socket": "ws(s)://192.168.31.64:3000/ws",
  "apiURL": "http(s)://192.168.31.64:3000"
}
```

### 3.直接上传文件夹至cf pages

![image](https://github.com/user-attachments/assets/c9e5a950-045a-4a7f-8b30-00899994c8cf)
![image](https://github.com/user-attachments/assets/c4096133-694d-4c2a-8d90-f92e48de6e9b)

### 4.设置域名（可选）

![image](https://github.com/user-attachments/assets/14adc0cf-2292-4148-a913-7a466e441d71)
