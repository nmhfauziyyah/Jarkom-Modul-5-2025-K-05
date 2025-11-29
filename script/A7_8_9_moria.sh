#!/bin/bash

# ==========================================================
# KONFIGURASI MORIA (ROUTER & DHCP RELAY) - MODUL 5
# Didasarkan pada VLSM K-05
# eth0=Osgiliath(A7), eth1=IronHills(A8), eth2=Wilderland(A9)
# ==========================================================

echo "Mulai konfigurasi Moria..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Osgiliath (A7: 10.66.0.16/30). Moria IP: 10.66.0.18
auto eth0
iface eth0 inet static
    address 10.66.0.18
    netmask 255.255.255.252

# eth1: ke Switch 2 / IronHills (A8: 10.66.0.20/30). Moria IP: 10.66.0.21
auto eth1
iface eth1 inet static
    address 10.66.0.21
    netmask 255.255.255.252

# eth2: ke Wilderland (A9: 10.66.0.24/30). Moria IP: 10.66.0.25
auto eth2
iface eth2 inet static
    address 10.66.0.25
    netmask 255.255.255.252

EOF

# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Aktifkan IP Forwarding (live dan persistent)
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
echo "IP Configuration, DNS, dan Forwarding selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 1 No. 3: Konfigurasi Static Routing
# ----------------------------------------------------------------
echo "--- 2. Misi 1: Konfigurasi Static Routing ---"

# Hapus rute lama untuk menghindari duplikasi
ip route flush table main

# Default Gateway via Osgiliath (10.66.0.17)
route add default gw 10.66.0.17

# Rute via Osgiliath (Gateway 10.66.0.17 - eth0)
# Tujuan: Semua jaringan di "luar" Moria (A1, A2, A3, A4, A5, A6, A12, A13)
echo "Menambahkan rute via Osgiliath (10.66.0.17)"
route add -net 10.66.0.0 netmask 255.255.255.252 gw 10.66.0.17 # A1
route add -net 10.66.0.4 netmask 255.255.255.252 gw 10.66.0.17 # A2
route add -net 10.66.0.8 netmask 255.255.255.252 gw 10.66.0.17 # A3
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.17 # A4
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.17 # A5
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.17 # A6
route add -net 10.66.0.28 netmask 255.255.255.252 gw 10.66.0.17 # A12
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.17 # A13

# Rute via Wilderland (Gateway 10.66.0.26 - eth2)
# Tujuan: A10 (Durin) dan A11 (Khamul)
echo "Menambahkan rute via Wilderland (10.66.0.26)"
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.26 # A10
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.26 # A11

echo "Static Routing selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# C. Misi 1 No. 4: Konfigurasi DHCP Relay
# ----------------------------------------------------------------
echo "--- 3. Misi 1: Instalasi dan Konfigurasi DHCP Relay ---"
apt update
apt install isc-dhcp-relay -y

# Konfigurasi /etc/default/isc-dhcp-relay
# SERVERS: IP Address Vilya (DHCP Server) adalah 10.66.0.43
# INTERFACES: HANYA eth2 (terhubung ke Wilderland, yang menuju Durin/Khamul)
cat << EOF > /etc/default/isc-dhcp-relay
SERVERS="10.66.0.43"
INTERFACES="eth2" 
OPTIONS=""
EOF

service isc-dhcp-relay restart
echo "Instalasi dan Konfigurasi DHCP Relay selesai."
echo "========================================"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth[0-2]'

echo -e "\n=== KONFIRMASI IP FORWARDING ==="
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n=== KONFIRMASI ROUTING TABLE ==="
route -n

echo -e "\n=== KONFIRMASI STATUS DHCP RELAY ==="
service isc-dhcp-relay status | grep 'Active'

echo -e "\n=== UJI KONEKTIVITAS KE OSGILIATH (Gateway) ==="
ping -c 3 10.66.0.17

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI PING KE INTERNET (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI MORIA SELESAI !!!"