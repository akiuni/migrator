# migrator

This script allows you to NAT and redirect all traffic from an IP address to another.

It is usefull when you want to migrate something to a new IP address: 
* prepare a box or a container (LXC, docker) to run migrator.
* move your target to the new ip address.
* start migrator to redirect the old ip address to the new one.
* On migrator, monitor traffic to see which clients are still contacting the old ip address (and need to be updated)

## Prequisites

This script is intended to run on Linux debian, it is based on iptables. So you can create a dedicated vm, lxc or docker container.

Install iptables
```
apt update
apt install -y ipset iptables netfilter-persistent ipset-persistent iptables-persistent
```

Activate routing
```
echo 1 >  /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
```

## Usage

Help
```
./migrator.sh --help
```

Flush all redirections
```
./migrator.sh -f
```

Bind addresses old addresses 192.168.0.1 and 192.168.0.2 and redirect them to the new ip address 192.168.0.10:
```
./migrator.sh +192.168.0.1:192.168.0.10 +192.168.0.2:192.168.0.10
```

Monitor redirections (replace ens18 with your nic)
```
watch iptables -L -n -t nat -v
tcpdump -ni ens18  dst 192.168.170.90 
```

When done, remove the redirections
```
./migrator.sh -192.168.0.1:192.168.0.10 -192.168.0.2:192.168.0.10
```

