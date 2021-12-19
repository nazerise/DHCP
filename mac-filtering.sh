#!/bin/bash
all_mac=$(grep -B 1 "PXE" /var/lib/dhcp/dhcpd.lease | grep hardware | awk '{print $2}')
list_all_mac=( $( echo $all_mac ) )
end=$(expr ${#list_all_mac[@]} - 1)
for i in "${!list_all_mac[@]}"; do
	if [[ $i = "0" ]]; then
		sed -i '1,2!d' dhcpd.class
		echo -e "        match if (substring(hardware,1,6) = ${list_all_mac[$i]}) or" >> /etc/dhcp/dhcpd.class
	elif [[ $i == "$end" ]]; then
		echo -e "                 (substring(hardware,1,6) = ${list_all_mac[$i]});" >> /etc/dhcp/dhcpd.class
		echo -e "}" >> dhcpd.class
		systemctl restart isc-dhcp-server
	else
		echo -e "                 (substring(hardware,1,6) = ${list_all_mac[$i]}) or" >> /etc/dhcp/dhcpd.class
	fi

done
