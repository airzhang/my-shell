#!/bin/bash

confpath=/etc/samba/new-smb.conf


sed -i '/config file/d' /etc/samba/smb.conf
sed -i '/\[global\]/a\\tconfig file = /etc/samba/new-smb.conf' /etc/samba/smb.conf

if [ ! -e ${confpath} ];then
	touch ${confpath}

	echo \[global\] >> ${confpath}
	echo -e "\tworkgroup = MSHOME" >> ${confpath}
	echo -e "\tserver string = Samba for ancun" >> ${confpath}
	echo -e "\tlog file = /var/log/samba/log.%m" >> ${confpath}
	echo -e "\tmax log size = 50" >> ${confpath}
	echo -e "\tsecurity = user" >> ${confpath}
	echo -e "\tpassdb backend = tdbsam" >> ${confpath}
	echo -e "\tsmb passwd file = /etc/samba/smbpasswd" >> ${confpath}
fi
	
#until [ $# -eq 0 ]
#do
#	shift
#done

#mode=`echo "$1"|awk '{print $1}'`
#for mode in $1;do
#	case $1 in
#		modify-path)
#			;;
#		add-user)
#			;;
#		modify-auth)
#			;;
#		*)
#			;;
#	esac
#done

path=`echo "$1"|awk '{print $1}'`
user=`echo "$1"|awk '{print $2}'`
authority=`echo "$1"|awk '{print $3}'`

#mkdir ${path}
#chmod 750 ${path}

if grep -w "path = ${path}" ${confpath};then 
#	if grep -w " ${user}" ${confpath};then 
	isuser=`sed -n "\#${path}#{n;/${user}/{s/.*/yes/p;q}}" ${confpath}`
	if [ "${isuser}"x = "yes"x ];then
		if [ "${authority}"x = "n"x ];then
			sed -n "\#${path}#{n;/${user}/{s/${user}//p;q}}" ${confpath}
			sed -n "\#${path}#{n;/${user}/{s/\(.*\)${user}\(.*\)/\1\2/p}}" ${confpath} 
#		else
		fi
#	else
	fi

#else
fi

