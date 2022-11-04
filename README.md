# x-ui_single_port_mod
A dirty mod that adds email-based multi-user single-port support to the original project. (多用户单端口)

# Description
I made this mod in a quickie-triky way to add the following features I needed. There are probably tons of bugs to fix in the future. Use at your own risk. I may or may not keep maintaining this mod in the near future.

Also, please __*DO NOT*__ PM the original author for any kind of support.

*Hint:* You can use [DB Browser for SQLite](https://sqlitebrowser.org/) to change default web root path in the database(located in /etc/x-ui/x-ui.db).

# Features
- Add multiple users sharing same port under same protocol and stream settings.
- Change bandwidth counting from tag-based to email-based.
- Lower cron job time intervals to have a more precise bandwidth monitoring.

# Usage
Please refer to the [Docker Hub Page](https://hub.docker.com/r/net2cn/x-ui_single_port_mod) for more information about how to use my modded Docker image. It also contains a tiny migration guide if you want to migrate to the modded version.

### Please be awared that this project is licensed under GPLv3 License. I have my rights to make such a mod, and so do you.

---
Modded by net2cn, 2022.

## Below is the original README.
---

# x-ui

Xray panel supporting multiple protocols and users

# Function introduction

- System status monitoring
- Support multi-user and multi protocol, web page visualization operation
- Supported protocols: vmess, vless, trojan, shadowlocks, dokodemo-door, socks, http
- Support configuration of more transport configurations
- Traffic statistics, limit traffic, limit expiration time
- Customizable xray configuration template
- Support https access panel (self provided domain name+ssl certificate)
- Support one click SSL certificate application and automatic renewal
- For more advanced configuration items, see the panel

# Install&Upgrade

```
bash <(curl -Ls https://raw.githubusercontent.com/wikihacker/x-ui-en/master/install.sh)
```

## Manual Installation&Upgrade

1. First from https://github.com/wikihacker/x-ui-en/releases Download the latest compressed package, generally `amd64`framework
2. Then upload the compressed package to the `/root/`Directory, and use `root`User Login Server

> If your server CPU architecture is not `amd64`，the `amd64`Replace with another schema

```
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

## Install with Docker

> N/A


## SSL certificate request

> This feature and tutorial are provided by[FranzKafkaYu](https://github.com/FranzKafkaYu)provide

The script has built-in SSL certificate request function. The following conditions must be met when using this script to request a certificate:

- Know Cloudflare registration email
- Know Cloudflare Global API Key
- The domain name has been resolved to the current server through cloudflare

Method to obtain Cloudflare Global API Key:
    ![](media/bda84fbc2ede834deaba1c173a932223.png)
    ![](media/d13ffd6a73f938d1037d0708e31433bf.png)

Only input when using `Domain Name`, `mailbox`, `API KEY`OK, the schematic diagram is as follows：
        ![](media/2022-04-04_141259.png)

matters needing attention:

- This script uses the DNS API to request a certificate
- Let's sEncrypt is used as the CA party by default
- The certificate installation directory is/root/cert directory
- The script application certificates are universal domain name certificates

## Suggested system

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# common problem

## Migrating from v2 ui

First, install the latest version of x-ui on the server where v2 ui is installed, and then use the following command to migrate `All inbound Account Data`to x-ui，`Panel settings and user names and passwords will not be migrated`

> After the migration is successful, please `close v2-ui`also `restart x-ui`，otherwise v2-ui of inbound Meeting with x-ui of inbound Will produce `Port conflict`

```
x-ui v2-ui
```

