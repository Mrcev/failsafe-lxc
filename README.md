# 🚀 Failsafe: Dynamic Multi-WAN Failover for Linux/LXC

Failsafe is a lightweight, scalable, and color-coded network monitoring tool designed to manage multiple internet gateways on Linux systems (optimized for Proxmox LXC).

## ✨ Features
* **Zero Configuration:** Automatically detects interfaces and gateways from `/etc/network/interfaces`.
* **Zero-Downtime:** Monitors secondary links in the background without interrupting the active connection.
* **Intelligent Failback:** Automatically returns to the primary high-priority link when it becomes available.
* **Color-Coded Logs:** Visual status updates for easy monitoring via `journalctl`.
* **Scalable:** Supports as many interfaces as your system can handle.

## 🛠 Installation

You can install Failsafe with a single command:

```bash
wget -qO- https://raw.githubusercontent.com/Mrcev/failsafe-lxc/main/install.sh | sudo bash
 ```
```bash
curl -sSL https://raw.githubusercontent.com/Mrcev/failsafe-lxc/main/install.sh | sudo bash
 ```
