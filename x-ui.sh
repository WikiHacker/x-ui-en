#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#Add some basic function here
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}
# check root
[[ $EUID -ne 0 ]] && LOGE "Error: This script must be run using root! \n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    LOGE "The system version is not detected, please contact the script author! \n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        LOGE "Please use CentOS 7 or higher! \n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        LOGE "Please use Ubuntu 16 or higher! \n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        LOGE "Please use Debian 8 or higher system! \n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [default$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Whether to restart the panel? Restarting the panel will also restart xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/wikihacker/x-ui-en/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will force the latest version to be reinstalled, and data will not be lost. Do you want to continue?" "n"
    if [[ $? != 0 ]]; then
        LOGE "Canceled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/wikihacker/x-ui-en/master/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Update completed, the panel has been restarted automatically "
        exit 0
    fi
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel, and xray will also uninstall?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Uninstall succeeded. If you want to delete this script, exit the script and run it ${green}rm /usr/bin/x-ui -f${plain} Delete"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Are you sure you want to reset the user name and password to admin" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "User name and password have been reset to ${green}admin${plain}, Please restart the panel now"
    confirm_restart
}

reset_config() {
    confirm "Are you sure to reset all panel settings? The account data will not be lost, and the user name and password will not be changed" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "All panel settings have been reset to the default values. Now restart the panel and use the default ${green}54321${plain} Port Access Panel"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "get current settings error,please check logs"
        show_menu
    fi
    LOGI "${info}"
}

set_port() {
    echo && echo -n -e "Enter the port number[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Canceled"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "After setting the port, please restart the panel and use the newly set port ${green}${port}${plain} Access Panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "The panel is already running and does not need to be restarted. Please select restart if necessary"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "x-ui Successfully started"
        else
            LOGE "The panel failed to start, possibly because the starting time exceeded two seconds. Please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "The panel has stopped, no need to stop again"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "x-ui and xray stop successfully"
        else
            LOGE "The panel failed to stop, possibly because the stop time exceeded two seconds. Please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "x-ui and xray restart successfully"
    else
        LOGE "The panel failed to restart, possibly because the startup time exceeded two seconds. Please check the log information later"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui setting boot auto start succeeded"
    else
        LOGE "x-ui failed to set the boot auto start"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui cancellation of startup and automatic startup succeeded"
    else
        LOGE "x-ui failed to cancel power on and auto start"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/wikihacker/x-ui-en/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Failed to download the script. Please check whether the local machine can be connected Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Upgrade script succeeded, please re run the script" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "The panel has been installed, please do not install it again"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Please install the panel first"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "Panel Status: ${green}Running${plain}"
        show_enable_status
        ;;
    1)
        echo -e "Panel Status: ${yellow}Not running${plain}"
        show_enable_status
        ;;
    2)
        echo -e "Panel Status: ${red}Not installed${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Whether the machine starts automatically: ${green}yes${plain}"
    else
        echo -e "Whether the machine starts automatically: ${red}no${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray state: ${green}running${plain}"
    else
        echo -e "xray state: ${red}not running${plain}"
    fi
}

ssl_cert_issue() {
    echo -E ""
    LOGD "******instructions******"
    LOGI "This script will use Acme script to apply for a certificate, and you need to ensure that:"
    LOGI "1.Know Cloudflare registration email"
    LOGI "2.know Cloudflare Global API Key"
    LOGI "3.The domain name has been resolved to the current server through Cloudflare"
    LOGI "4.The default installation path of the script request certificate is/root/cert directory"
    confirm "I have confirmed the above[y/n]" "y"
    if [ $? -eq 0 ]; then
        cd ~
        LOGI "Install Acme Script"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            LOGE "Failed to install acme script"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        LOGD "Please set the domain name:"
        read -p "Input your domain here:" CF_Domain
        LOGD "Your domain name is set to:${CF_Domain}"
        LOGD "Please set the API key:"
        read -p "Input your key here:" CF_GlobalKey
        LOGD "Your API key is:${CF_GlobalKey}"
        LOGD "Please set the registration email:"
        read -p "Input your email here:" CF_AccountEmail
        LOGD "Your registered email address is:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "Failed to modify the default CA to Lets'Encrypt. The script exits"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "Failed to sign the certificate. The script exits"
            exit 1
        else
            LOGI "Certificate issued successfully, installing..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
        --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "The certificate installation failed, and the script exited"
            exit 1
        else
            LOGI "The certificate installation is successful, and automatic update is enabled..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "Failed to update settings automatically. The script exits"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            LOGI "The certificate has been installed and automatic update has been enabled. The details are as follows"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}

show_usage() {
    echo "x-ui How to use management scripts: "
    echo "------------------------------------------"
    echo "x-ui              - Display the management menu (more functions)"
    echo "x-ui start        - Launch x-ui panel"
    echo "x-ui stop         - Stop the x-ui panel"
    echo "x-ui restart      - Restart the x-ui panel"
    echo "x-ui status       - View x-ui status"
    echo "x-ui enable       - Set x-ui to start automatically"
    echo "x-ui disable      - Cancel x-ui startup"
    echo "x-ui log          - View x-ui logs"
    echo "x-ui v2-ui        - Migrate v2 ui account data of this machine to x-ui"
    echo "x-ui update       - Update x-ui panel"
    echo "x-ui install      - Installing the x-ui panel"
    echo "x-ui uninstall    - Uninstall x-ui panel"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}x-ui Panel Management Script${plain}
  ${green}0.${plain} Exit Script
————————————————
  ${green}1.${plain} Install x-ui
  ${green}2.${plain} To update x-ui
  ${green}3.${plain} Uninstall x-ui
————————————————
  ${green}4.${plain} Reset Username Password
  ${green}5.${plain} Reset Panel Settings
  ${green}6.${plain} Set Panel Port
  ${green}7.${plain} View current panel settings
————————————————
  ${green}8.${plain} Start-up x-ui
  ${green}9.${plain} Stop it x-ui
  ${green}10.${plain} Restart x-ui
  ${green}11.${plain} See x-ui state
  ${green}12.${plain} See x-ui Logs
————————————————
  ${green}13.${plain} Set x-ui to start automatically
  ${green}14.${plain} Cancel x-ui startup
————————————————
  ${green}15.${plain} One click installation of bbr (latest kernel)
  ${green}16.${plain} One click application for SSL certificate (acme application)
 "
    show_status
    echo && read -p "Please enter a selection [0-16]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && uninstall
        ;;
    4)
        check_install && reset_user
        ;;
    5)
        check_install && reset_config
        ;;
    6)
        check_install && set_port
        ;;
    7)
        check_install && check_config
        ;;
    8)
        check_install && start
        ;;
    9)
        check_install && stop
        ;;
    10)
        check_install && restart
        ;;
    11)
        check_install && status
        ;;
    12)
        check_install && show_log
        ;;
    13)
        check_install && enable
        ;;
    14)
        check_install && disable
        ;;
    15)
        install_bbr
        ;;
    16)
        ssl_cert_issue
        ;;
    *)
        LOGE "Please enter the correct number [0-16]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start 0
        ;;
    "stop")
        check_install 0 && stop 0
        ;;
    "restart")
        check_install 0 && restart 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "enable")
        check_install 0 && enable 0
        ;;
    "disable")
        check_install 0 && disable 0
        ;;
    "log")
        check_install 0 && show_log 0
        ;;
    "v2-ui")
        check_install 0 && migrate_v2_ui 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi
