# Zabbix Agent for Windows - Auto Installer

This PowerShell script automates the installation or upgrade of the Zabbix Agent on Windows systems.

## Features

- Detects and removes existing agent (ZIP or MSI)
- Downloads the latest Zabbix Agent
- Updates configuration file with your Zabbix server and hostname
- Installs and starts the agent as a Windows service

## Instructions

1. Open PowerShell as Administrator
2. Edit the script before running:
   - Update the `$serverIP` variable with your Zabbix server IP:
     ```powershell
     $serverIP = "your.zabbix.server.ip"
     ```
   - Also update the `$zipUrl` variable if a newer Zabbix Agent version is released:
     ```powershell
     $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.4/latest/zabbix_agent-7.4-latest-windows-amd64-openssl.zip"
     ```

