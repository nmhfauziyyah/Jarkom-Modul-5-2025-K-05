#!/bin/bash

# ==========================================================
# KONFIGURASI MINASTIR (ROUTER & DHCP RELAY) - MODUL 5
# Disusun berdasarkan Topologi dan VLSM 10.66.x.x
# ==========================================================

echo "Mulai konfigurasi Minastir..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: A1 (ke Osgiliath - Gateway) - 10.66.0.0/30
auto eth0
iface eth0 inet static
    address 10.66.0.2
    netmask 255.255.255.252

# eth1: A6 (ke Swicth4/Elendil) - 10.66.1.0/24
auto eth1
iface eth1 inet static
    address 10.66.1.1
    netmask 255.255.255.0

# eth2: A2 (ke Pelargir) - 10.66.0.4/30
auto eth2
iface eth2 inet static
    address 10.66.0.5
    netmask 255.255.255.252

EOF
# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 2 # Beri jeda agar network aktif

echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Aktifkan IP Forwarding (live dan persistent)
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
echo "IP Static, DNS, dan Forwarding selesai."

# ----------------------------------------------------------------
# B. Misi 1 No. 3: Konfigurasi Static Routing
# ----------------------------------------------------------------
echo "--- 2. Konfigurasi Static Routing ---"

# Hapus rute lama untuk menghindari duplikasi
ip route flush table main

# Default Gateway (ke Osgiliath/NAT)
route add default gw 10.66.0.1

# Rute via Osgiliath (Gateway 10.66.0.1 - eth0)
echo "Menambahkan rute via Osgiliath (10.66.0.1)"
route add -net 10.66.0.16 netmask 255.255.255.252 gw 10.66.0.1  # A8 (Moria/Switch2)
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.1  # A9 (Westerland/Switch3)
route add -net 10.66.0.24 netmask 255.255.255.252 gw 10.66.0.1  # A12 (Rivendell/Switch1)
route add -net 10.66.0.28 netmask 255.255.255.252 gw 10.66.0.1  # Moria/Westerland
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.1  # A11 (Khamul)
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.1  # A13 (Vilya/Narya)
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.1  # A10 (Durin)

# Rute via Pelargir (Gateway 10.66.0.6 - eth2)
echo "Menambahkan rute via Pelargir (10.66.0.6)"
route add -net 10.66.0.8 netmask 255.255.255.252 gw 10.66.0.6   # A3 (Pelargir/AnduinBanks)
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.6   # A4 (Pelargir/Rajkatir)
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.6 # A5 (Gilgalad & Cirdan)

# Rute via Switch4 (Gateway 10.66.1.2 - eth1) - ke subnet A6 Elendil
echo "Menambahkan rute via Switch4 (10.66.1.2)"
route add -net 10.66.0.0 netmask 255.255.255.0 gw 10.66.1.2     # Subnet Elendil 10.66.0.0/24
echo "Static Routing selesai."

# ----------------------------------------------------------------
# C. Misi 1 No. 4: Konfigurasi DHCP Relay
# ----------------------------------------------------------------
# Note: Ini dikerjakan setelah Misi 2 No. 1 (NAT) selesai, 
# tapi di sini digabungkan agar scriptnya 1.

echo "--- 3. Instalasi dan Konfigurasi DHCP Relay ---"
apt update
apt install isc-dhcp-relay -y

# Konfigurasi /etc/default/isc-dhcp-relay
# INTERFACES: eth1 (dari Switch4) dan eth2 (dari Pelargir) yang mendengarkan permintaan DHCP
cat << EOF > /etc/default/isc-dhcp-relay
SERVERS="10.66.0.43"
INTERFACES="eth1 eth2" 
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

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP SERVER) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI KONEKTIVITAS KE INTERNET (via Osgiliath) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! SELESAI !!!"
echo "Silakan uji fungsi DHCP Relay dari klien di subnet A5 atau A6."