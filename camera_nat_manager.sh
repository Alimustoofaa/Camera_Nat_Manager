#!/bin/bash

# ==========================================
# Camera NAT Manager (Add / Delete / Replace)
# ==========================================

if [ "$#" -lt 4 ]; then
    echo "Usage:"
    echo "  Add:    $0 add <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>"
    echo "  Delete: $0 delete <CAMERA_IP> <EXTERNAL_PORT> <CAMERA_PORT>"
    echo ""
    echo "Example:"
    echo "  $0 add 192.168.200.30 8081 80"
    echo "  $0 delete 192.168.200.30 8081 80"
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
        grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
}

install_persistent() {
    if ! dpkg -l | grep -q iptables-persistent; then
        echo "Installing iptables-persistent..."
        DEBIAN_FRONTEND=noninteractive apt update -qq
        DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
    fi
}

save_rules() {
    echo "Saving rules..."
    netfilter-persistent save > /dev/null
}

rule_exists() {
    iptables -t nat -C PREROUTING -p tcp --dport $EXT_PORT -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT 2>/dev/null
    return $?
}

add_rule() {

    enable_forwarding

    if rule_exists; then
        echo "⚠ Rule already exists for port $EXT_PORT"
        read -p "Replace existing rule? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Cancelled."
            exit 0
        fi
        delete_rule
    fi

    iptables -t nat -A PREROUTING -p tcp --dport $EXT_PORT -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT
    iptables -A FORWARD -p tcp -d $CAMERA_IP --dport $CAMERA_PORT -j ACCEPT
    iptables -A FORWARD -p tcp -s $CAMERA_IP --sport $CAMERA_PORT -j ACCEPT
    iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -j MASQUERADE

    install_persistent
    save_rules

    echo "✅ NAT Added:"
    echo "   http://$(hostname -I | awk '{print $1}'):$EXT_PORT"
}

delete_rule() {

    iptables -t nat -D PREROUTING -p tcp --dport $EXT_PORT -j DNAT --to-destination $CAMERA_IP:$CAMERA_PORT 2>/dev/null
    iptables -D FORWARD -p tcp -d $CAMERA_IP --dport $CAMERA_PORT -j ACCEPT 2>/dev/null
    iptables -D FORWARD -p tcp -s $CAMERA_IP --sport $CAMERA_PORT -j ACCEPT 2>/dev/null

    save_rules

    echo "🗑 NAT Rule Deleted for port $EXT_PORT"
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
