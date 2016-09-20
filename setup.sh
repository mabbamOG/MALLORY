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
    time='30m' # can be 30s 30m 30h 30w ...
}
function menu # PERMETTE ALL'UTENTE DI SCEGLIERE UN COMANDO
{
    echo $1
    PS3="--------->choice? " # "PS3" contiene il valore della domanda effettuata ad ogni scelta
    select choice in ${@:2}
    do
    # can also use $REPLY to get exact user input...
    # and use it with for case in {1..5}
        [[ -z $choice ]] && continue # verifico che il valore scelto non sia invalido
        #[[ $choice == 'Abort' ]] && break
        echo "$choice" | sed -r 's/^([^ ]+).*/\l\1/g' && return
        #$(echo $choice | sed 's/ /_/g;s/./\L&/g') # eseguo il comando, dopo aver tolto spazi e maiuscole
    done
}
function install # for installing the backdoor
{
echo 'installing...'
# Check for systemd
pidof systemd &>/dev/null || echo 'This system is not running systemd!' && exit
# Apply OS changes for ssh service
OS=$(menu 'Choose distro' 'Ubuntu' 'Arch Linux')
[[ $OS == 'ubuntu' ]] && sshservice='ssh.service' || sshservice='sshd.service'
sed -i -r "s/^Wants=ssh.*/Wants=$sshservice/" backdoor.timer
sed -i -r "s/^Wants=ssh.*/Wants=$sshservice/" backdoor.service
sed -i -r "s/^sshservice=[^# ]*/sshservice='$sshservice'/" backdoor.sh
# Choose user
USER=$(menu 'Choose user to run the backdoor' 'root (default)' 'other')
[[ $USER == 'other' ]] && read -p 'username: ' USER
[[ id $USER &>/dev/null ]] || echo 'user nonexistent!' && exit
sed -i -r "s/^User=.*/User=$USER/" backdoor.service
# email address
read -p 'Email address for updates: ' EMAIL
echo "$EMAIL" | grep -E '^[a-zA-Z0-9.]+@[a-zA-Z0-9.]+[.][a-zA-Z0-9]+$' &>/dev/null || echo 'email address invalid!' && exit
sed -i -r "s/^emailaddress=[^# ]*/emailaddress='$EMAIL'/" backdoor.sh
# time of timer
TIME=$(menu 'Choose timer loop time, to run the script' '30m (default)' 'other')
[[ $TIME == 'other' ]] && read -p 'time (ex. 5s 5m 5h 5w): ' TIME
echo "$TIME" | grep -E '^[0-9]+[smhw]$' &>/dev/null || echo 'time invalid!' && exit
sed -i -r "s/^OnUnitActiveSec=.*/OnUnitActiveSec=$TIME/" backdoor.timer
# install services and programs needed
# Copy Files
cp backdoor.sh /usr/local/bin/
chmod +x /usr/local/bin/backdoor.sh
cp backdoor.service backdoor.timer /etc/systemd/system/ 
# Enable services
systemctl enable --now backdoor.timer
# Check
systemctl status $sshservice postfix backdoor.timer
systemctl list-timers
clear
echo 'done installing!'
}
function uninstall # for removing the backdoor
{
echo 'uninstalling...'
# Disable services
systemctl disable --now backdoor.timer
# Remove files
rm /home/$(sed -r -n 's/^User=//p' /etc/systemd/system/backdoor.service)/.backdoor
rm /etc/systemd/system/backdoor* $backdoor /usr/local/bin/backdoor.sh
# Check
systemctl status $sshservice postfix backdoor.timer
systemctl list-timers
clear
echo 'done uninstalling! remember to check everything!'
}

[[ $# -ne 1 ]] && echo -e "NO ACTION SELECTED! usage: $0 [install|uninstall]" && exit
[[ $EUID -ne 0 ]] && echo 'please run this script as root to install/uninstall.' && exit
[[ $1 == 'install' || $1 == 'uninstall' ]] && $1
exit
