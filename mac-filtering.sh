#!/bin/bash
secs=600   # Set interval (duration) in seconds.
SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0

get_mac_address () {
	all_mac=$(grep -B 1 "PXE" /var/lib/dhcp/dhcpd.leases | sort -u | grep hardware | awk '{print $3}' |  awk -F';' '{print $1}')
	list_all_mac=( $( echo $all_mac ) )
	new_list_all_mac=( $(echo ${list_all_mac[@]} ${old_list_all_mac[@]} | tr ' ' '\n' | sort | uniq -u) )
	old_list_all_mac+=(${new_list_all_mac[@]})
	end=$(expr ${#new_list_all_mac[@]} - 1)
}
find_last_line () {
	last_line=$(tail -n 1 /etc/dhcp/dhcpd.class)
	check_line=$(tail -n 1 /etc/dhcp/dhcpd.class | grep hardware )
	if [[ -z $check_line ]]; then
        	while [[ "$last_line" != "}" ]]
        	do
                	echo -e "\033[0;31mNO last line \033[0m"
                	sed -i '$d' /etc/dhcp/dhcpd.class
                	last_line=$(tail -n 1 /etc/dhcp/dhcpd.class)
        	done
		sed -i '$d' /etc/dhcp/dhcpd.class
	fi
}

if [[ -f /etc/dhcp/dhcpd.class ]]; then
	old_list_all_mac=$( cat /etc/dhcp/dhcpd.class | grep hardware | awk -F ')' '{print $2}' | awk '{print $2}' )
	sed -i '1,2!d' /etc/dhcp/dhcpd.class
	echo -e "}" >>  /etc/dhcp/dhcpd.class
else
	declare -A old_list_all_mac=()
fi
first_line=$(cat /etc/dhcp/dhcpd.class | grep match )
while [ $SECONDS -le $secs ]
do 
	get_mac_address
	for i in "${!new_list_all_mac[@]}"; do
		find_last_line
		sed -i 's/);/) or/g' /etc/dhcp/dhcpd.class
		if [[ -z $first_line  ]]; then
			echo $first_line
			echo ${new_list_all_mac[$i]}
			sed -i 's/);/) or/g' /etc/dhcp/dhcpd.class
			echo -e "        match if (substring(hardware,1,6) = ${new_list_all_mac[$i]} ); " >> /etc/dhcp/dhcpd.class
			echo -e "}" >>  /etc/dhcp/dhcpd.class
			sudo systemctl restart isc-dhcp-server
			first_line=$(cat /etc/dhcp/dhcpd.class | grep match )
		elif [[ $i == $end ]]; then
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]} );" >> /etc/dhcp/dhcpd.class
			echo -e "}" >>  /etc/dhcp/dhcpd.class
			sudo systemctl restart isc-dhcp-server
		else
			sed -i 's/);/) or/g' /etc/dhcp/dhcpd.class
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]} ) or" >> /etc/dhcp/dhcpd.class
			echo -e "}" >>  /etc/dhcp/dhcpd.class
		fi
	done
done
