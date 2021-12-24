#!/bin/bash
secs=600   # Set interval (duration) in seconds.
SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0

get_mac_address () {
	all_mac=$(grep -B 1 "PXE" /var/lib/dhcp/dhcpd.lease | sort -u | grep hardware | awk '{print $2}')
	list_all_mac=( $( echo $all_mac ) )
	new_list_all_mac=( $(echo ${list_all_mac[@]} ${old_list_all_mac[@]} | tr ' ' '\n' | sort | uniq -u) )
	old_list_all_mac+=(${list_all_mac[@]})
	end=$(expr ${#new_list_all_mac[@]} - 1)
}
find_last_line () {
	last_line=$(tail -n 1 /etc/dhcp/dhcpd.class)
	check_line=$(tail -n 1 /etc/dhcp/dhcpd.class | grep hardware )
        while [[ "$end" != "}" ]]
        do
		if [[ -z $check_line ]]; then
			break
		fi
                echo -e "\033[0;31mNO last line \033[0m"
                sed -i '$d' /etc/dhcp/dhcpd.class
                end=$(tail -n 1 /etc/dhcp/dhcpd.class)
        done
}

if [[ -f /etc/dhcp/dhcpd.class ]]; then
	old_list_all_mac=$( cat /etc/dhcp/dhcpd.class | grep hardware | awk -F ')' '{print $2}' | awk '{print $2}' )
else
	declare -A old_list_all_mac=()
fi

while [ $SECONDS -le $secs ]
do 
	get_mac_address
	for i in "${!new_list_all_mac[@]}"; do
		if [[ $i = "0" && ! -f  /etc/dhcp/dhcpd.class ]]; then
			cat > etc/dhcp/dhcpd.class <<\EOT
##mac address class
class "pxe-mac-address" {
        match if (substring(hardware,1,6) = ${new_list_all_mac[$i]});
}
EOT		
		elif [[ $i == "$end" ]]; then
			sed -i 's/);/) or/g' dhcpd.class
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]});" >> /etc/dhcp/dhcpd.class
			echo -e "}" >>  /etc/dhcp/dhcpd.class
			systemctl restart isc-dhcp-server
		else
			find_last_line
			sed -i 's/);/) or/g' dhcpd.class
			echo -e "                 (substring(hardware,1,6) = ${new_list_all_mac[$i]}) or" >> /etc/dhcp/dhcpd.class
		fi
	done
done
