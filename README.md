# Camera NAT Manager

Camera NAT Manager is a production-ready bash script to automate NAT
(port forwarding) configuration for IP cameras on Ubuntu using iptables.

Designed for multi-camera environments such as CCTV monitoring systems,
AI-based computer vision pipelines, and gateway servers.

------------------------------------------------------------------------

## Features

-   Add NAT rule (port forwarding)
-   Delete NAT rule
-   Check if rule already exists
-   Confirm replacement if rule exists
-   Auto enable IP forwarding
-   Auto install `iptables-persistent`
-   Auto save rules after changes
-   Prevent duplicate rules
-   Persistent after reboot

------------------------------------------------------------------------

## Example Network Topology

PC (192.168.100.x) ↓ Ubuntu Server eth0 → 192.168.100.28 eth1 →
192.168.200.x ↓ Camera 1 → 192.168.200.30 Camera 2 → 192.168.200.31

Example Port Mapping:

192.168.100.28:8081 → 192.168.200.30:80\
192.168.100.28:8082 → 192.168.200.31:80

------------------------------------------------------------------------

## Installation

Make the script executable:

``` bash
chmod +x camera_nat_manager.sh
```

------------------------------------------------------------------------

## Add NAT Rule

Format:

``` bash
sudo ./camera_nat_manager.sh add <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>
```

Example:

``` bash
sudo ./camera_nat_manager.sh add 192.168.200.30 8081 80
```

If rule already exists, you will be prompted:

Replace existing rule? (y/n)

------------------------------------------------------------------------

## Delete NAT Rule

Format:

``` bash
sudo ./camera_nat_manager.sh delete <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>
```

Example:

``` bash
sudo ./camera_nat_manager.sh delete 192.168.200.30 8081 80
```

------------------------------------------------------------------------

## Check Active Rules

``` bash
sudo iptables -t nat -L -n -v
sudo iptables -L -n -v
```

------------------------------------------------------------------------

## Persistence

The script automatically:

-   Installs iptables-persistent (if not installed)
-   Saves rules using netfilter-persistent

All rules remain active after reboot.

------------------------------------------------------------------------

## Troubleshooting

### Check IP Forwarding

``` bash
cat /proc/sys/net/ipv4/ip_forward
```

Value must be:

1

------------------------------------------------------------------------

### Verify Ubuntu Can Reach Camera

``` bash
ping 192.168.200.30
```

If unreachable, verify:

-   LAN interface configuration
-   Subnet mask
-   Network cabling

------------------------------------------------------------------------

### If Browser Timeout Occurs

Check:

-   Firewall rules
-   FORWARD chain policy
-   UFW status
-   Camera accessibility from Ubuntu

------------------------------------------------------------------------

## Use Cases

-   CCTV web monitoring
-   AI video processing backend
-   OCR & computer vision systems
-   Multi-camera gateway routing
-   Secure internal camera exposure

------------------------------------------------------------------------

## Requirements

-   Ubuntu 18.04+
-   iptables
-   netfilter-persistent

------------------------------------------------------------------------

## Notes

This script uses iptables (legacy).\
If your system uses nftables, adaptation may be required.

------------------------------------------------------------------------

## Future Improvements

-   Restrict by specific subnet
-   Auto detect network interfaces
-   List all active NAT mappings
-   Security hardening mode
-   Public internet exposure mode
