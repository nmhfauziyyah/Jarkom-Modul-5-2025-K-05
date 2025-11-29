#!/bin/bash

# ==========================================================
# KONFIGURASI Wilderland (DHCP RELAY) - MODUL 5
# Didasarkan pada VLSM K-05
# eth0=Moria(A9), eth1=Durin(A10), eth2=Khamul(A11)
# ==========================================================

echo "Mulai konfigurasi Wilderland (Winderland)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Moria (A9: 10.66.0.24/30). Wilderland IP: 10.66.0.26
auto eth0
iface eth0 inet static
    address 10.66.0.26
    netmask 255.255.255.252

# eth1: ke Switch 3 / Durin (A10: 10.66.0.64/26). Wilderland IP: 10.66.0.65
auto eth1
iface eth1 inet static
    address 10.66.0.65
    netmask 255.255.255.192

# eth2: ke Switch 3 / Khamul (A11: 10.66.0.32/29). Wilderland IP: 10.66.0.33
auto eth2
iface eth2 inet static
    address 10.66.0.33
    netmask 255.255.255.248

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

# Default Gateway via Moria (10.66.0.25)
route add default gw 10.66.0.25

# Rute via Moria (Gateway 10.66.0.25 - eth0)
# Tujuan: Semua jaringan di "luar" Wilderland (A1, A2, A3, A4, A5, A6, A7, A8, A12, A13)
echo "Menambahkan rute via Moria (10.66.0.25)"
route add -net 10.66.0.0 netmask 255.255.255.252 gw 10.66.0.25 # A1
route add -net 10.66.0.4 netmask 255.255.255.252 gw 10.66.0.25 # A2
route add -net 10.66.0.8 netmask 255.255.255.252 gw 10.66.0.25 # A3
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.25 # A4
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.25 # A5
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.25 # A6
route add -net 10.66.0.16 netmask 255.255.255.252 gw 10.66.0.25 # A7
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.25 # A8
route add -net 10.66.0.28 netmask 255.255.255.252 gw 10.66.0.25 # A12
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.25 # A13

# Rute A10 dan A11 tidak diperlukan karena connected.

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
# INTERFACES: HANYA eth1 (ke Durin/A10) dan eth2 (ke Khamul/A11)
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

echo -e "\n=== UJI KONEKTIVITAS KE MORIA (Gateway) ==="
ping -c 3 10.66.0.25

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI PING KE INTERNET (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI Wilderland SELESAI !!!"