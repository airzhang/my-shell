#!/bin/bash

mode=`echo "$1"|awk '{print $1}'`
zone=`echo "$1"|awk '{print $2}'`
newdate=`echo "$1"|awk '{print $3}'`
newtime=`echo "$1"|awk '{print $4}'`

myip=`ifconfig -a | sed -n "/eth/{N;p}" | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}'`

driftpath=/var/lib/ntp/drift
cftpath=/etc/ntp.conf

servercfg(){
cat<<EOF > /etc/ntp.conf
driftfile ${driftpath}

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

restrict 127.0.0.1
restrict -6 ::1

server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys

restrict 0.0.0.0 mask 0.0.0.0 nomodify notrap
server 127.127.1.0
fudge 127.127.1.0 stratum 10
EOF
}

clientcfg(){
cat<<EOF > /etc/ntp.conf
driftfile ${driftpath} 

restrict 127.0.0.1
restrict -6 ::1

server ${ip} prefer
restrict ${ip} nomodify notrap noquery

server 127.127.1.0
fudge 127.127.1.0 stratum 10

includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF
}

if [ ! -e ${driftpath} ];then
	touch ${driftpath}
fi

if [ "${mode}"x = "timeset"x  ];then
	\cp /usr/share/zoneinfo/${zone} /etc/localtime
	date -s "${newdate} ${newtime}"
	hwclock -w
elif [ "${mode}"x = "ntpset"x ];then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	ip=`echo "$1"|awk '{print $2}'`
	if [[ ${myip} =~ "${ip}" ]];then
		rm -rf ${cfgpath}
		servercfg	
	else
		rm -rf ${cfgpath}
		clientcfg
	fi
	chkconfig ntpd on
	service ntpd restart
fi
