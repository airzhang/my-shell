#!/bin/bash

num=$(ifconfig -a | grep eth | wc -l)

##if ifcfg-ethx exist but have wrong name,save the mask and gateway
if [[ `ls | grep "aa"` ]];then
	oldfile=$(ls | grep "aa" | sed -n '1p') 
	\cp -fa ./${oldfile} ./aa_tmp
	mask=$(cat ./aa_tmp | grep "NETMASK" | awk -F= '{printf $2}')
	gateway=$(cat ./aa_tmp | grep "GATEWAY" | awk -F= '{printf $2}')
fi

##if ifcfg-ethx doesn't exist, set a default one
mask=255.255.255.0
gateway=192.168.1.1

##amend the /etc/udev/rules.d/70-persistent-net.rules
rm -rf ./rules
for((n=0;n<${num};n++))
do
	attr=$(ifconfig -a | grep "eth" | sed -n "$[ ${n} + 1 ]p" | awk '{print $5}')
	touch ./rules
	echo SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR\{address\}==\"${attr}\", ATTR\{type\}==\"1\", KERNEL==\"eth\", NAME=\"eth${n}\" >> ./rules
done


for((n=0;n<${num};n++))
do
	if [ -e ./aa${n} ];then
		sed -i '/HWADDR/d' ./aa${n}
		ifconfig -a | grep "eth${n}" | awk '{print "HWADDR=\""$5"\""}' >> ./aa${n}
	else
		touch ./aa${n}
		echo DEVICE="\"eth${n}\"" >> ./aa${n}
		echo HWADDR=\"$attr\" >> ./aa${n}
		echo TYPE="\"Ethernet\"" >> ./aa${n}
		echo ONBOOT="\"yes\"" >> ./aa${n}
		echo NM_CONTROLLED="\"yes\"" >> ./aa${n}
		echo BOOTPROTO="\"static\"" >> ./aa${n}
		echo NETMASK=\"${mask}\" >> ./aa${n}
		echo GATEWAY=\"${gateway}\" >> ./aa${n}
		echo nameserver=\"${gateway}\" >> ./aa${n}
	fi
done

