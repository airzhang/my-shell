#!/bin/bash

confpath=/etc/samba/new-smb.conf

mode=`echo "$1"|awk '{print $1}'`
name=`echo "$1"|awk '{print $2}'`
password=`echo "$1"|awk '{print $3}'`

if [ "$mode"x = "new"x ];then
	#new linux user and add passwd
	useradd -s /bin/false -M -N ${name}
	echo ${password} | passwd --stdin ${name}
	#new samba user
	echo -e "${password}\n${password}" | smbpasswd -a ${name} -s
elif [ "$mode"x = "modify"x ];then
	echo ${password} | passwd --stdin ${name}
	echo -e "${password}\n${password}" | smbpasswd ${name} -s
elif [ "$mode"x = "delete"x ];then
	#delete user in samba
	smbpasswd -x ${name}
	#delete user in linux
	/usr/sbin/userdel -rf ${name}
	emptygroup=`cat /etc/group | sed -n '/-ro.*:$/{N;/:$/p}' | awk -F- '{print $1}' | uniq -d`
	if [[ ${emptygroup} ]];then 
		for i in ${emptygroup}
		do
			groupdel ${i}-ro
			groupdel ${i}-rw
			sed -r -i "/\[${i}\]/{N;N;N;N;N;N;N;N;d}" ${confpath}
		done
	fi
else
	echo "wrong mode !!"
fi
service smb restart
