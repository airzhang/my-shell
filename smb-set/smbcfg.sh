#!/bin/bash

confpath=/etc/samba/new-smb.conf

pathtmp=`echo "$1"|awk '{print $1}'`
user=`echo "$1"|awk '{print $2}'`
auth=`echo "$1"|awk '{print $3}'`

path="/gmnt`echo ${pathtmp} | sed -r 's/^([^\/])/\/&/'`"
dirname=`echo ${path}|sed 's/\//_/g;s/^.gmnt_//'`

if [ "${pathtmp}"x = "/gmnt"x ];then
	path=${pathtmp}
	dirname="myroot"
fi

useradmin(){
	if [ "${auth}"x = "ro"x ];then
		gpasswd -d ${user} ${dirname}-rw
		gpasswd -a ${user} ${dirname}-ro
	elif [ "${auth}"x = "rw"x ];then
		gpasswd -d ${user} ${dirname}-ro
		gpasswd -a ${user} ${dirname}-rw
	elif [ "${auth}"x = "n"x ];then
		gpasswd -d ${user} ${dirname}-ro
		gpasswd -d ${user} ${dirname}-rw
		if [[ `cat /etc/group | sed -n '/-ro.*:$/{N;/:$/p}'` ]];then
			groupdel ${dirname}-ro
			groupdel ${dirname}-rw
			sed -r -i "/\[${dirname}\]/{N;N;N;N;N;N;N;N;d}" ${confpath}
		fi
	fi
}

if [ `gemcli --cp=ok v info | grep -oP '(?<=Status:).*'`x != "Started"x ];then
	echo "No volumes available !!"
	exit 1
fi

if [ ! -e /gmnt ];then
	echo "No mount directory !!"
	exit 2
else
	chmod 777 /gmnt
fi

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
#passdb backend = smbpasswd:/etc/samba/smbpasswd
unix password sync = yes
passwd program = /usr/bin/passwd %u

EOF
fi

sed -i '/config file/d' /etc/samba/smb.conf
sed -i '/\[global\]/a\\tconfig file = '"${confpath}"'' /etc/samba/smb.conf

if grep -w "path = ${path}$" ${confpath};then
	useradmin
	chmod 777 ${path}
else
	if [ ! -e ${path} ];then
		mkdir -p "${path}"
		chmod 777 ${path}
	fi
	groupadd ${dirname}-ro
	groupadd ${dirname}-rw

	useradmin

cat<<EOF >> ${confpath}
[${dirname}]
path = ${path}
valid users = @${dirname}-ro,@${dirname}-rw
writeable = no
browseable = yes
create mode = 777
directory mode = 777
write list = @${dirname}-rw

EOF
fi

service smb restart

