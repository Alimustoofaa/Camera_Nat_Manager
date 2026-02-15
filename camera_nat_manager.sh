#!/bin/bash

# ==========================================
# Camera NAT Manager
# ==========================================

if [ "$#" -lt 4 ]; then
    echo "Usage:"
    echo "  Add:    $0 add <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>"
    echo "  Delete: $0 delete <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>"
    exit 1
fi

ACTION=$1
CAMERA_IP=$2
EXT_PORT=$3
CAMERA_PORT=$4

enable_forwarding() {
    if [ "$(cat /proc/sys/net/ipv4/ip_forward)" -eq 0 ]; then
        echo "Enabling IP Forwarding..."
        sysctl -w net.ipv4.ip_forward=1 > /dev/null
        grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || \
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
}

save_rules() {
    netfilter-persistent save > /dev/null 2>&1
}

rule_exists() {
    iptables -t nat -C PREROUTING -p tcp --dport $EXT_PORT \
    -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT 2>/dev/null
    return $?
}

add_rule() {

    enable_forwarding

    if rule_exists; then
        echo "⚠ Rule already exists on port $EXT_PORT"
        read -p "Replace? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Cancelled."
            exit 0
        fi
        delete_rule
    fi

    echo "Adding DNAT..."
    iptables -t nat -A PREROUTING -p tcp --dport $EXT_PORT \
    -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT

    echo "Allowing NEW + ESTABLISHED forward..."
    iptables -A FORWARD -p tcp -d $CAMERA_IP --dport $CAMERA_PORT \
    -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

    iptables -A FORWARD -p tcp -s $CAMERA_IP --sport $CAMERA_PORT \
    -m state --state ESTABLISHED,RELATED -j ACCEPT

    echo "Done."
    echo "Access: http://$(hostname -I | awk '{print $1}'):$EXT_PORT"

    save_rules
}

delete_rule() {

    echo "Deleting rules..."

    iptables -t nat -D PREROUTING -p tcp --dport $EXT_PORT \
    -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT 2>/dev/null

    iptables -D FORWARD -p tcp -d $CAMERA_IP --dport $CAMERA_PORT \
    -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 2>/dev/null

    iptables -D FORWARD -p tcp -s $CAMERA_IP --sport $CAMERA_PORT \
    -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null

    save_rules

    echo "Deleted."
}

case $ACTION in
    add)
        add_rule
        ;;
    delete)
        delete_rule
        ;;
    *)
        echo "Invalid action. Use add or delete."
        exit 1
        ;;
esac
