
#!/bin/bash


# MIT License

# Copyright (c) 2025 Julien Simbola

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.



### INIT ###
cmd_ip="/usr/sbin/ip"
cmd_iptables="/usr/sbin/iptables"
ARRAY_ADD=""
ARRAY_DEL=""
FLUSH=false

# Force ip forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

function display_usage() {
	echo "Add or removes IP NAT 1:1 mappings. You can add or remove multiples couples."
	echo
	echo "long syntax:"
	echo " $0 --add=IPSRC:IPDST --add=IPSRC:IPDST --del=IPSRC:IPDST --del=IPSRC:IPDST ..."
	echo "short syntax:"
	echo " $0 +IPSRC:IPDST +IPSRC:IPDST -IPSRC:IPDST -IPSRC:IPDST ..."
	echo
	echo "Other options are :"
	echo " -h or --help: display this help"
	echo " -f or --flush: Flushes all the mappings"
	echo
	echo "Example"
	echo " $0 -f +192.168.170.10:192.168.173.10 +192.168.170.120:192.168.173.120"
	echo " $0 -192.168.170.10:192.168.173.10"
}


for i in "$@"
do
case $i in
    --add=*)
    ARRAY_ADD="${ARRAY_ADD} ${i#*=}"
    ;;
    --del=*)
    ARRAY_DEL="${ARRAY_DEL} ${i#*=}"
	;;
    -h|--help)
    display_usage
	exit 0
    ;;
    -f|--flush)
    FLUSH=true
    ;;
    +*)
    ARRAY_ADD="${ARRAY_ADD} ${i/+/}"
	;;
    -*)
    ARRAY_DEL="${ARRAY_DEL} ${i/-/}"
	;;
    *)
    	# unknown option
		echo "unkown parameter: $i"
		display_usage
		exit 1
    ;;
esac
done

### FLUSH ###
$FLUSH && echo "Flushing NAT table" && iptables -t nat  -F 

### ADD ###
filter=""
for A in $ARRAY_ADD; do
	echo "Adding mapping $A"
	t=(${A/:/ })
	src=${t[0]}
	dst=${t[1]}
	$cmd_ip address add ${src}/32 dev ens18
	$cmd_iptables -t nat -A PREROUTING -d ${src} -j DNAT --to-destination ${dst}
	$cmd_iptables -t nat -A POSTROUTING -d ${dst} -j SNAT --to-source ${src}
	filter="${filter} or dst ${src}"
done
filter=${filter/or /}

### REMOVE ###
for A in $ARRAY_DEL; do
	echo "Removing mapping $A"
	t=(${A/:/ })
	src=${t[0]}
	dst=${t[1]}
	while $cmd_iptables -t nat -D POSTROUTING -d ${dst} -j SNAT --to-source ${src}; do echo -n '.'; done &>/dev/null
	while $cmd_iptables -t nat -D PREROUTING -d ${src} -j DNAT --to-destination ${dst}; do echo -n '.'; done  &>/dev/null
	while $cmd_ip address delete ${src}/32  dev ens18; do echo -n '.'; done  &>/dev/null
done

echo "Here are the NAT mappings:"
$cmd_iptables -L PREROUTING -n -t nat -v

if [[ "x${filter}x" != "xx" ]]; then
	echo
	echo "To monitor redicted traffic:"
	echo "tcpdump -ni ens18 ${filter} "
fi


