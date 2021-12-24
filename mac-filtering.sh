#!/bin/bash
secs=600   # Set interval (duration) in seconds.
SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0
old_list_all_mac=$( cat /etc/dhcp/dhcpd.class | grep hardware | awk -F ')' '{print $2}' | awk '{print $2}' )
while [ $SECONDS -le $secs ]
do 
	all_mac=$(grep -B 1 "PXE" /var/lib/dhcp/dhcpd.lease | sort -u | grep hardware | awk '{print $2}')
	list_all_mac=( $( echo $all_mac ) )
	new_list_all_mac=( $(echo ${list_all_mac[@]} ${old_list_all_mac[@]} | tr ' ' '\n' | sort | uniq -u) )
	old_list_all_mac+=(${list_all_mac[@]})
	end=$(expr ${#new_list_all_mac[@]} - 1)
	for i in "${!new_list_all_mac[@]}"; do
		if [[ $i = "0" ]]; then
			sed -i '1,2!d' dhcpd.class
			echo -e "        match if (substring(hardware,1,6) = ${new_list_all_mac[$i]}) or" >> /etc/dhcp/dhcpd.class
		elif [[ $i == "$end" ]]; then
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]});" >> /etc/dhcp/dhcpd.class
			echo -e "}" >> dhcpd.class
			systemctl restart isc-dhcp-server
		else
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]}) or" >> /etc/dhcp/dhcpd.class
		fi
done
