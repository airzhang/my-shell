#!/bin/bash

CLI="gemcli --cp=ok"

opt=`echo "$1"|awk '{print $1}'`

case ${opt} in

	auth)
		volname=`echo "$1"|awk '{print $2}'`
		volauth=`echo "$1"|awk '{print $3}'`
		auth_allow=`echo ${volauth} |grep -oP '(\d{1,3}\.){3}\d{1,3}' |sort -u | sed ':t;N;s/\n/,/;b t'`

		if [ `${CLI} v info |grep -oP '(?<=Status:).*'`x != "Started"x ];then
			echo "No volumes available !!"
		fi

		service nfs stop
		${CLI} v set ${volname} nfs.disable off
		${CLI} v set ${volname} nfs.export-volumes off
		${CLI} v set ${volname} nfs.export-dirs off
		${CLI} v set ${volname} server.root-squash off
		${CLI} v set ${volname} nfs.rpc-auth-allow ${auth_allow}
		${CLI} v set ${volname} nfs.export-dir "${volauth}"

		${CLI} v start ${volname} force
	;;

    creatdir)
		volname=`echo "$1"|awk '{print $2}'`
		pathdir=`echo "$1"|awk '{print $3}'`
		pathvol=/gmnt/${volname}

		if [ ! -e ${pathdir} ];then
			echo "No volumes available !!"
		fi

		if [ ! -e ${pathdir} ];then
			mkdir -p "${pathdir}"
			chmod 777 "${pathdir}"
		fi
	;;

	checkip)
		pathip=`echo "$1"|awk '{print $2}'`
		showmount -a |grep ${pathip} |awk -F: '{print $1}' |sort -u
	;;

	*)
		echo "you print wrong type !!"
	;;
esac
