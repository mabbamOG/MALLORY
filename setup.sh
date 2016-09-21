#----------------CONFIGURATION---------------------------------------------------------------------------------------
function config
{
    # EMAIL ADDRESS
    email='mallory@example.com' # please change this!

    # DISTRO
    sshservice='sshd.service' # archlinux
    #sshservice='ssh.service' # ubuntu

    # USER
    user='root' # (affects ~ directory)

    # TIMER TIME
    time='30m' # can be 30s 30m 30h 30w 5m30s ...
}

#---------------------------MAIN FUNCTIONS--------------------------------------------------------------------------------
function install
{
echo 'installing...'
# CHECK SYSTEMD and other services?
    pidof systemd &>/dev/null || echo 'This system is not running systemd!' && exit
# CHECK CONFIG
    read -p 'have you configured the settings (yes/no)? '
    [[ $REPLY == 'yes' ]] && config || (echo 'please configure settings! look for "configure" function in setup.sh' && exit)
    systemctl list-unit-files | grep -F $sshservice &>/dev/null || (echo "service $sshservice not found!" && exit)
    echo "$email" | grep -E '^[A-Za-z0-9.]+@[A-za-z0-9.]+[.][A-Za-z0-9]+$' &>/dev/null || (echo "email address $email is not valid!" && exit)
    id $user &>/dev/null || (echo "user $user nonexistent!" && exit)
    echo "$time" | grep -E '^[0-9]+[smhw]$' &>/dev/null || (echo "time $time is invalid!" && exit)
# APPLY CONFIG
    sed -i -r "s/^Wants=ssh.*/Wants=$sshservice/" backdoor.timer backdoor.service # sshservice
    sed -i -r "s/^emailaddress=[^# ]*/emailaddress='$email'/" backdoor.sh # email
    sed -i -r "s/^User=.*/User=$user/" backdoor.service # user
    sed -i -r "s/^OnUnitActiveSec=.*/OnUnitActiveSec=$time/" backdoor.timer # time
# COPY FILES
    cp backdoor.sh /usr/local/bin/
    chmod +x /usr/local/bin/backdoor.sh
    cp backdoor.service backdoor.timer /etc/systemd/system/ 
# ENABLE SERVICES
    systemctl enable --now backdoor.timer
# VERIFY
    systemctl status $sshservice postfix backdoor.timer
    systemctl list-timers
clear
echo 'done installing!'
}

function uninstall
{
echo 'uninstalling...'
# DISABLE SERVICES
    systemctl disable --now backdoor.timer
# REMOVE FILES
    user=$(sed -r -n 's/^User=//p' /etc/systemd/system/backdoor.service)
    sshservice=$(sed -r -n 's/^Wants=//p' /etc/systemd/system/backdoor.service)
    [[ $user == 'root' || $user == '' ]] && rm ~/.backdoor || rm /home/$user/.backdoor
    rm /etc/systemd/system/backdoor* /usr/local/bin/backdoor.sh
# VERIFY
    systemctl status $sshservice postfix backdoor.timer
    systemctl list-timers
clear
echo 'done uninstalling! remember to check everything!'
}

#-------------------------------MAIN SCRIPT--------------------------------------------------------
[[ $# -ne 1 ]] && echo -e "NO ACTION SELECTED! usage: $0 [install|uninstall]" && exit
[[ $EUID -ne 0 ]] && echo 'please run this script as root to install/uninstall.' && exit
[[ $1 == 'install' || $1 == 'uninstall' ]] && $1
exit
