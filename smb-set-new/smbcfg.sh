#!/bin/bash

confpath=/etc/samba/new-smb.conf

confmodify(){
cat<<EOF >> ${confpath}
[${sharename}]
	path = ${dirpath}
	valid users = ${rwauth},${roauth}
	writeable = no
	browseable = yes
	create mode = 777
	directory mode = 777
	write list = ${rwauth}

EOF
}

chmod 777 /gmnt

if [ ! -e /etc/samba/smbpasswd ];then
	touch /etc/samba/smbpasswd
fi

if [ ! -e ${confpath} ];then
	touch ${confpath}
cat<<EOF >> ${confpath}
[global]
	workgroup = MSHOME
	server string = Samba for ancun
	log file = /var/log/samba/log.%m
	max log size = 50
	security = user
	passdb backend = tdbsam
	unix password sync = yes
	passwd program = /usr/bin/passwd %u

EOF
fi

sed -i '/config file/d' /etc/samba/smb.conf
sed -i '/\[global\]/a\\tconfig file = '"${confpath}"'' /etc/samba/smb.conf

#mode=`echo "$1"|awk '{print $1}'`
mode=$1

case ${mode} in
	group_add)
		groupname=$2
		groupadd ${groupname}
		;;

	group_del)
		groupname=$2
		for((i=3;i<=$#;i++)) 
		do
			eval testuser=\$$i
			sed -i -r "s/\<${testuser},|,${testuser}\>|\<${testuser}\>//g" ${confpath}
            smbpasswd -x ${testuser}
			/usr/sbin/userdel -rf ${testuser}
		done
		sed -i -r "s/\<@${groupname},|,@${groupname}\>|@${groupname}\>//g" ${confpath}
		groupdel ${groupname}
		;;

	user_add)
		username=$2
		userkey=$3
		usergroup=$4
		useradd -s /bin/false -M -N ${username}
		echo ${userkey} | passwd --stdin ${username}
		echo -e "${userkey}\n${userkey}" | smbpasswd -a ${username} -s
		gpasswd -a ${username} ${usergroup}
		;;

	user_del)
		username=$2
		sed -i -r "s/\<${username},|,${username}\>|\<${username}\>//g" ${confpath}
		smbpasswd -x ${username}
		/usr/sbin/userdel -rf ${username}
		;;

	user_modify)
		username=$2
		userkey=$3
		usergroup=$4
		echo ${userkey} | passwd --stdin ${username}
		echo -e "${userkey}\n${userkey}" | smbpasswd ${username} -s
		#gpasswd -a ${username} ${usergroup}
		usermod -G ${usergroup} ${username}
		;;

	connect_status)
		username=$2
		if [[ `smbstatus | grep ${username}` ]];then
			echo "connected"
		else
			echo "unconnected"
		fi
		exit 0
		;;

	dir_modify)
		sharename=$2
		dirpath=$3
		rwauth=$4
		roauth=$5
		if [ ! -e ${dirpath} ];then
			mkdir -p "${dirpath}"
			chmod 777 ${dirpath}
		fi
		sed -r -i "/\[${sharename}\]/{N;N;N;N;N;N;N;N;d}" ${confpath}
		confmodify
		;;

	dir_del)
		sharename=$2
		sed -r -i "/\[${sharename}\]/{N;N;N;N;N;N;N;N;d}" ${confpath}
		;;

	*)
		echo "wrong type !!"
		;;
esac

service smb restart
