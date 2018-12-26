# Basex install script for Ubuntu 16.04
VERSION="1.0.0"
NODEPORT='43210'
RPCPORT='43211'

# Useful variables
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPT_LOGFILE="/tmp/basex_node_${DATE_STAMP}_out.log"
declare -r SCRIPTPATH=$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )

function print_greeting() {
  echo -e "\e[33m                                        "
  echo -e "\e[33m██████╗  █████╗ ███████╗███████╗██╗  ██╗"
  echo -e "\e[33m██╔══██╗██╔══██╗██╔════╝██╔════╝╚██╗██╔╝"
  echo -e "\e[33m██████╔╝███████║███████╗█████╗   ╚███╔╝ "
  echo -e "\e[33m██╔══██╗██╔══██║╚════██║██╔══╝   ██╔██╗ "
  echo -e "\e[33m██████╔╝██║  ██║███████║███████╗██╔╝ ██╗"
  echo -e "\e[33m╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝"
  echo -e "\e[33m                                        "
  echo -e "\e[0m"
}
function print_info() {
	echo -e "	Install scrypt version: ${VERSION}"
	echo -e "	Date: ${DATE_STAMP}"
	echo -e "	Logfile: ${SCRIPT_LOGFILE}\n\n"
}

function install_packages() {
	echo "Install packages..."
	apt-get -y update &>> ${SCRIPT_LOGFILE}
	apt-get install -y software-properties-common dnsutils &>> ${SCRIPT_LOGFILE}
	add-apt-repository -yu ppa:bitcoin/bitcoin  &>> ${SCRIPT_LOGFILE}
	apt-get -y update &>> ${SCRIPT_LOGFILE}
	apt-get -y install wget make automake autoconf build-essential libtool autotools-dev \
	git nano python-virtualenv pwgen virtualenv \
	pkg-config libssl-dev libevent-dev bsdmainutils software-properties-common \
	libboost-all-dev libminiupnpc-dev libdb4.8-dev libdb4.8++-dev &>> ${SCRIPT_LOGFILE}
	echo "Install done..."
}

function download_wallet() {
	echo "Downloading wallet..."
	mkdir /root/basex
	mkdir /root/.basex
	wget https://github.com/basexcoin/basex/releases/download/2.0.0.1/basex_ubuntu_16.04.tar.gz
	tar -zxvf basex_ubuntu_16.04.tar.gz
	rm basex_ubuntu_16.04.tar.gz
	echo "Done..."
}

function configure_masternode() {
	echo "Configuring masternode..."
	conffile=/root/.basex/basex.conf
	PASSWORD=`pwgen -1 20 -n` &>> ${SCRIPT_LOGFILE}
	WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
	if [ "x$PASSWORD" = "x" ]; then
	    PASSWORD=${WANIP}-`date +%s`
	fi
	echo "Loading and syncing wallet..."
	echo "    if you see *error: Could not locate RPC credentials* message, do not worry"
	/root/basex/basex-cli stop
	echo "It's okay :D"
	sleep 10
	echo -e "rpcuser=basexuser\nrpcpassword=${PASSWORD}\nrpcport=${RPCPORT}\nport=${NODEPORT}\nexternalip=${WANIP}\nlisten=1\nmaxconnections=250" >> ${conffile}
	echo ""
	echo -e "\e[31m=================================================================="
	echo -e "         PLEASE WAIT 1 MINUTE AND DON'T CLOSE THIS WINDOW"
	echo -e "==================================================================\e[0m"
	echo ""
	/root/basex/basexd -daemon
	echo "60 seconds left"
	sleep 10
	echo "50 seconds left"
	sleep 10
	echo "40 seconds left"
	sleep 10
	echo "30 seconds left"
	sleep 10
	echo "20 seconds left"
	sleep 10
	echo "10 seconds left"
	sleep 10
	masternodekey=$(/root/basex/basex-cli masternode genkey)
	/root/basex/basex-cli stop
	sleep 5
	echo "Creating masternode config..."
	echo -e "daemon=1\nmasternode=1\nmasternodeprivkey=$masternodekey" >> ${conffile}
	echo "Done...Starting daemon..."
	/root/basex/basexd -daemon
}

function addnodes() {
	echo "Adding nodes..."
	conffile=/root/.basex/basex.conf
	echo -e "\naddnode=95.213.200.76:43210" >> ${conffile}
	echo -e "addnode=82.202.221.172:43210" >> ${conffile}
	echo -e "addnode=92.53.77.167:43210" >> ${conffile}
	echo -e "addnode=31.184.255.237:43210" >> ${conffile}
	echo -e "addnode=78.155.218.157:43210" >> ${conffile}
	echo -e "addnode=5.189.224.97:43210" >> ${conffile}
	echo -e "addnode=37.228.119.205:43210" >> ${conffile}
	echo -e "addnode=95.213.252.22:43210\n"  >> ${conffile}
	echo "Done..."
}

function show_result() {
   echo ""
   echo -e "\e[33m==================================================================\e[0m"
   echo "DATE: ${DATE_STAMP}"
   echo "LOG: ${SCRIPT_LOGFILE}"
   echo ""
   echo -e "\e[31mMASTERNODE IP: ${WANIP}:${NODEPORT} \e[0m"
   echo -e "\e[31mMASTERNODE PRIVATE GENKEY: ${masternodekey} \e[0m"
   echo ""
   echo -e "You can check your masternode status on VPS with \e[31m/root/basex/basex-cli masternode status\e[0m command"
   echo -e "If you get \"Masternode not in masternode list\" status, don't worry,\nyou just have to start your MN from your local wallet and the status will change."
   echo -e "Now you need to add alias in your local wallet"
   echo -e "\e[33m==================================================================\e[0m"
}

function cronjob() {
	crontab -l > tempcron
	echo "@reboot /root/basex/basexd -daemon -reindex" > tempcron
	crontab tempcron
	rm tempcron
}

function cleanup() {
	echo "Cleanup..."
	apt-get -y autoremove 	&>> ${SCRIPT_LOGFILE}
	apt-get -y autoclean 		&>> ${SCRIPT_LOGFILE}
	echo "Done..."
}


# Main routine
print_greeting
print_info
install_packages
download_wallet
addnodes
configure_masternode
cronjob
show_result
cleanup
echo "All done!"