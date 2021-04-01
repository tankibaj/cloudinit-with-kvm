#!/usr/bin/env bash

IP=192.168.0.0/24
OVPN_PROFILE_PATH=/home/naim/profile.ovpn
OVPN_AUTH_PATH=/home/naim/.ovpnauth
# OVPN_AUTH_USERNAME=test
# OVPN_AUTH_PASSWORD=test

config_firewall() {
  # Forward
  grep -qxF 'net.ipv4.ip_forward = 1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward = 1' >>/etc/sysctl.conf
  sysctl -p >/dev/null

  # Flush
  iptables -t nat -F
  iptables -t mangle -F
  iptables -F
  iptables -X

  # Block All
  iptables -P OUTPUT DROP
  iptables -P INPUT DROP
  iptables -P FORWARD DROP

  # Allow Localhost
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT

  # Make sure you can communicate with any DHCP server
  iptables -A OUTPUT -d 255.255.255.255 -j ACCEPT
  iptables -A INPUT -s 255.255.255.255 -j ACCEPT

  # Make sure that you can communicate within your own network
  iptables -A INPUT -s $IP -d $IP -j ACCEPT
  iptables -A OUTPUT -s $IP -d $IP -j ACCEPT

  # Allow established sessions to receive traffic:
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # Allow TUN
  iptables -A INPUT -i tun+ -j ACCEPT
  iptables -A FORWARD -i tun+ -j ACCEPT
  iptables -A FORWARD -o tun+ -j ACCEPT
  iptables -t nat -A POSTROUTING -o tun+ -j MASQUERADE
  iptables -A OUTPUT -o tun+ -j ACCEPT

  # Allow DNS connection
  iptables -I OUTPUT 1 -p udp --dport 53 -m comment --comment "Allow DNS UDP" -j ACCEPT
  iptables -I OUTPUT 2 -p tcp --dport 53 -m comment --comment "Allow DNS TCP" -j ACCEPT

  # Allow NTP connection
  iptables -I OUTPUT 3 -p udp --dport 123 -m comment --comment "Allow NTP" -j ACCEPT

  # Allow VPN connection
  iptables -I OUTPUT 4 -p udp --dport 1194 -m comment --comment "Allow VPN UDP" -j ACCEPT
  iptables -I OUTPUT 5 -p tcp --dport 1194 -m comment --comment "Allow VPN TCP" -j ACCEPT

  # Block All
  iptables -A OUTPUT -j DROP
  iptables -A INPUT -j DROP
  iptables -A FORWARD -j DROP

  # Log all dropped packages, debug only.
  iptables -N logging
  iptables -A INPUT -j logging
  iptables -A OUTPUT -j logging
  iptables -A logging -m limit --limit 2/min -j LOG --log-prefix "IPTables general: " --log-level 7
  iptables -A logging -j DROP

  # Iptable persistent
  netfilter-persistent save
  systemctl enable netfilter-persistent
}

config_openvpn() {
  cp $OVPN_PROFILE_PATH /etc/openvpn/default.conf
#   echo "$OVPN_AUTH_USERNAME
# $OVPN_AUTH_PASSWORD" >/etc/openvpn/auth
  touch $OVPN_AUTH_PATH
  chmod 600 $OVPN_AUTH_PATH
  # Append auth file to openvpn profile
  sed -i 's|auth-user-pass.*|auth-user-pass '$OVPN_AUTH_PATH'|g' /etc/openvpn/default.conf
  # Append log file to openvpn profile
  sed -i -e '$alog /var/log/openvpn.log' /etc/openvpn/default.conf
  # Connect openvpn
  openvpn --client --config /etc/openvpn/default.conf --daemon
}

install_openvpn() {
  apt-get update -y
  apt-get -y install ntp
  apt-get -y install openvpn
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
  apt-get -y install iptables-persistent
  config_firewall
  config_openvpn
}

install_dnsmasq() {
  systemctl disable systemd-resolved
  systemctl stop systemd-resolved

  echo "nameserver 8.8.8.8" >/etc/resolv.conf

  apt-get install -y dnsmasq

  cp /etc/dnsmasq.conf /etc/dnsmasq.conf.original
  rm -f /etc/dnsmasq.conf
  echo "port=53
domain-needed
bogus-priv
strict-order" >/etc/dnsmasq.conf

  echo "nameserver 127.0.0.1
nameserver 1.1.1.1
nameserver 1.0.0.1" >/etc/resolv.conf
  systemctl restart dnsmasq
}

if [[ ! -d /etc/openvpn ]]; then
  install_dnsmasq
  install_openvpn
fi
