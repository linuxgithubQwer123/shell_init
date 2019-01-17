#!/bin/bash
# System optimization
# Author: Hjh
# QQ: 924215461
# Development time: 2018/8/23
#INITENV
USERNAME=$(id -u)

#YUMENV
YUMBACK="/root/yum"
YUMPATH="/etc/yum.repos.d/"
SYS6RELEASE=$(cat /etc/centos-release  | grep -o "6.")
SYS7RELEASE=$(cat /etc/centos-release  | grep -o "7.")
YUM6URL="/etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo"
EPEL6URL="/etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo"
YUM7URL="/etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
EPEL7URL="/etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo"


#STREAMLINEENV
CENTOS6PROCE=(
crond
network
rsyslog
sshd
)
CENTOS7PROCE=(
network
crond
sshd
rsyslog
rc-local
NetworkManager
)


#FIREWALL SELINUXENV
SELINUXPATH="/etc/selinux/config"

#REMOTEENV
SSHCONFIGPATH="/etc/ssh/sshd_config"
SSHPORT="$RANDOM"
SSHIP=$(ifconfig | awk 'NR==2{print }' | awk '{print $2}' | cut -d: -f2)

#DATETIMEENV
TIMEZONESRC="/usr/share/zoneinfo/Asia/Shanghai"
TIMEZONEDST="/etc/localtime "
SYNCTIMEU="root"
TIMESERVER="1.centos.pool.ntp.org"


#COMPILEENV

#LIMITENV
LIMITFILE="65536"
LIMITPROC="65536"
LIMITPATH="/etc/security/limits.conf"

#KERNELENV
INITFILE="/etc/sysctl.conf"

#LOCKFILEENV
LOCKFILE="init.lock"
LOCKFILEPATH="/var/lock/subsys"

#LOGFILEENV
LOGFILE="init.log"
LOGFILEPATH="/tmp"
LOGDATE="date +%Y-%m-%d"
LOGTIME="date +%H:%M:%S"


#function lockfle  {
#	touch $LOCKFILEPATH/$LOCKFILE
#}

#function unlockfile {
#	rm -f $LOCKFILEPATH/$LOCKFILE
#}

#function traplock {
#	trap 'rm -f $LOCKFILEPATH/$LOCKFILE' INT
#}


function first {
yum install wget vim &>/dev/null -y
}
first

function usage {
	echo "Usage $0 {1|2|3|4|5|6|7}"
cat << FOE 
1) Yum config 
2) Startup optimization 
3) Stop selinux and firewall  
4) Ssh optimization 
5) Datetime sync 
6) Install Development tools 
7) Limit optimization 
8) Kernel optimiztion
9) Hostname config
10) A key all optimization
FOE
}

function ntpusage {
	echo "Usage $0 5 ntphost"
}

function hostnameusage {
	echo "Usage $0   hostname"
}



function logfile {
LOGINFO=$*
	echo "`${LOGDATE}` `${LOGTIME}`:${LOGINFO}" >> $LOGFILEPATH/$LOGFILE
}


function init {

if [  "$USERNAME" -gt 0 ]; then
        echo "Please sitwch to root user" && logfile "[init]This is not root user"
        exit 1
fi
	logfile "[init]Is root user success"
}


function repo {
if ! ping -c 2 www.baidu.com &>/dev/null ; then
        echo "Please connection internet" && logfile "[init]connection internet error"
        exit 1
fi

	mkdir $YUMBACK &>/dev/null
	mv $YUMPATH/* $YUMBACK

if [[ "$SYS6RELEASE" == "6." ]]; then
	wget -O $YUM6URL &>/dev/null  && logfile "[yum]download yum6 success" || logfile "[yum]download yum6 error" 

	wget -O $EPEL6URL &>/dev/null && logfile "[yum]download epel6 success" || logfile "[yum]download epel6 error" 

elif [[ "$SYS7RELEASE" == "7." ]]; then
	wget -O $YUM7URL &>/dev/null  && logfile "[yum]download yum7 success"  || logfile "[yum]download yum7 error" 

	wget -O $EPEL7URL &>/dev/null && logfile "[yum]download epel7 success"  || logfile "[yum]download epel7 error" 


fi
}


function streamline {
if [[ "$SYS6RELEASE" == "6." ]]; then
	for i in $(chkconfig --list | egrep "3:on|5:on" | awk '{print $1}'); do
		chkconfig --level 3 $i off
	done
	for j in ${CENTOS6PROCE[*]}; do
		chkconfig --level 3 $j on
	done

elif [[ "$SYS7RELEASE" == "7." ]]; then
	for i in $(systemctl list-unit-files --type=service | awk '{print $1}'); do
		systemctl disable $i &>/dev/null
	done
	for j in ${CENTOS7PROCE[*]}; do
		systemctl enable $j &>/dev/null
	done

else
	logfile "[streamline]The system is not centos or rhel" 
	exit 3		
fi
	logfile "[streamline]streamline system success"
}


function fs {
	setenforce 0 &>/dev/null
	sed -i 's/SELINUX=\(permissive\|enforcing\)/SELINUX=disabled/' $SELINUXPATH && \
	logfile "[fs-selinux]selinux stop success"

if [[ "$SYS6RELEASE" == "6." ]]; then
	service iptables stop &>/dev/null 

elif [[ "$SYS7RELEASE" == "7." ]]; then
	systemctl stop firewall &>/dev/null 
	iptables -F 
	
else
	logfile "[fs-firewall]The system is not centos or rhel"
	exit 4
fi
	logfile "[fs-firewall]firewall stop success"	
}


function remote {
	yum install openssh-clients openssh-server -y &>/dev/null
	sed -i "s/#\?ListenAddress.*/ListenAddress ${SSHIP}/" $SSHCONFIGPATH
	sed -i "s/#\?Port.*/Port ${SSHPORT}/" $SSHCONFIGPATH
	sed -i "s/#\?UseDNS.*/UseDNS no/" $SSHCONFIGPATH 
	sed -i "s/GSSAPIAuthentication.*/GSSAPIAuthentication no/" $SSHCONFIGPATH
	sed -i "s/#\?MaxAuthTries.*/MaxAuthTries 3/" $SSHCONFIGPATH
	logfile "[remote-ssh]init success"
}




function datetime {
DATETIMEARG1="$1"
	if ! rpm -q ntp &>/dev/null; then	
		yum install ntp -y &>/dev/null
	fi

	if [[ "$DATETIMEARG1" == "" ]]; then
		ntpusage 
		logfile "[datetime]Ntphost error"

	else
			
		install $TIMEZONESRC $TIMEZONEDST
		ntpdate $DATETIMEARG1 &>/dev/null
		if [ "$?" -eq 0 ]; then
			logfile "[datetime]Datetime sync success"
			echo "*/5 * * * * /usr/bin/ntpdate $DATETIMEARG1 >/dev/null 2>&1" > /var/spool/cron/"$SYNCTIMEU"
		else
			logfile "[datetime]Sync datetime error"
		fi	
	fi
}

function autodatetime {
	yum install ntp -y &>/dev/null
	echo "*/5 * * * * /usr/bin/ntpdate $TIMESERVER >/dev/null 2>&1" > /var/spool/cron/"$SYNCTIMEU"
	ntpdate $TIMESERVER
	[ $? -eq 0 ] && logfile "[datetime]Datetime sync success"
}

function complie {
	yum install gcc-c++ gcc make -y &>/dev/null && \
	[ $? -eq 0 ] && \
	logfile "[compile]gcc tools install success" || logfile "[compile]gcc tools install error"
}

function limit {
	echo -e "* - nofile ${LIMITFILE}\n* - nproc ${LIMITPROC}" >>  $LIMITPATH && \
	logfile "[limit]limit success" || logfile "[limit]limit error"
}

function kernel {
FLAG="net.ipv4.tcp_max_syn_backlog"
KERNELFILE="/etc/sysctl.conf"
if ! grep "$FLAG" $KERNELFILE &>/dev/null; then
cat >> $INITFILE << EOF
####################################################
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65535
####################################################
EOF
sysctl -p
logfile "[kernel]kernel success"
fi
}


function hostn {
HOSTNARG1="$1"
if [[ "$SYS6RELEASE" == "6." ]]; then
	if [[ "$HOSTNARG1" != "" ]]; then
		hostname $HOSTNARG1
		sed -i "s/HOSTNAME.*/HOSTNAME=${HOSTNARG1}/" /etc/sysconfig/network
		logfile "[hostn]hostname config success"
	else
		hostnameusage
		logfile "[hostn]hostname  is null"
		exit 5
	fi

elif [[ "$SYS7RELEASE" == "7." ]]; then

	if [[ "$HOSTNARG1" != "" ]]; then
		hostnamectl set-hostname --static $HOSTNARG1
		sed -i "s@.*@${HOSTNARG1}@" /etc/hostname
		logfile "[hostn]hostname config success"
	else
		hostnameusage
		logfile "[hostn]hostname  is null"
		exit 5
	fi


else
	logfile "[fs-firewall]The system is not centos or rhel"
	exit 4
fi

}



function main {
MAINARG1="$1"
MAINARG2="$2"
	init
	case $MAINARG1  in
	1)
		repo
		;;
	2)		
		streamline
		;;
	3)
		fs	
		;;
	4)
		remote			
		;;
	5)
		datetime $MAINARG2
		;;
	6)
		complie
		;;
	7)
		limit
		;;
	8)
		kernel
		;;
	9)	
		hostn $MAINARG2
		;;
	10)
		if [[ $2 != "" ]];then
			autodatetime
			repo
			streamline
			fs
			remote
			hostn $MAINARG2
			complie
			limit
			kernel
		else
			echo "Usage $0 10 hostname"	
		fi
		
		;;
	*)	
		usage
		;;
	esac

}

main $1 $2
