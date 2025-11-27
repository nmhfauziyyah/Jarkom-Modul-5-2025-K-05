#!/bin/bash

# ==========================================================
# KONFIGURASI ANDUINBANKS (DHCP RELAY) - MODUL 5
# Didasarkan pada VLSM K-05: eth0=Pelargir(A3), eth1=Switch5(A5)
# ==========================================================

echo "Mulai konfigurasi AnduinBanks..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Pelargir (A3: 10.66.0.8/30). AnduinBanks IP: 10.66.0.10
auto eth0
iface eth0 inet static
    address 10.66.0.10
    netmask 255.255.255.252

# eth1: ke Switch 5 (A5: 10.66.0.128/25). AnduinBanks IP: 10.66.0.129
auto eth1
iface eth1 inet static
    address 10.66.0.129
    netmask 255.255.255.128

EOF
/etc/init.d/networking restart
sleep 2

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

# Default Gateway via Pelargir (10.66.0.9)
route add default gw 10.66.0.9

# Rute via Pelargir (Gateway 10.66.0.9 - eth0)
# Tujuan: Semua jaringan di "kiri" Pelargir (A1, A2, A4, A6, A7, A8, A9, A10, A11, A12, A13)
echo "Menambahkan rute via Pelargir (10.66.0.9)"
route add -net 10.66.0.0 netmask 255.255.255.252 gw 10.66.0.9 # A1
route add -net 10.66.0.4 netmask 255.255.255.252 gw 10.66.0.9 # A2
# A3 (Connected)
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.9 # A4
# A5 (Connected)
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.9 # A6
route add -net 10.66.0.16 netmask 255.255.255.252 gw 10.66.0.9 # A7
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.9 # A8
route add -net 10.66.0.24 netmask 255.255.255.252 gw 10.66.0.9 # A9
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.9 # A10
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.9 # A11
route add -net 10.66.0.28 netmask 255.255.255.252 gw 10.66.0.9 # A12
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.9 # A13

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
# INTERFACES: HANYA eth1 (terhubung ke A5/Gilgalad & Cirdan)
cat << EOF > /etc/default/isc-dhcp-relay
SERVERS="10.66.0.43"
INTERFACES="eth1" 
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
ip a | grep 'eth[0-1]'

echo -e "\n=== KONFIRMASI IP FORWARDING ==="
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n=== KONFIRMASI ROUTING TABLE ==="
route -n

echo -e "\n=== KONFIRMASI STATUS DHCP RELAY ==="
service isc-dhcp-relay status | grep 'Active'

echo -e "\n=== UJI KONEKTIVITAS KE PELARGIR (Gateway) ==="
ping -c 3 10.66.0.9

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server) ==="
ping -c 3 10.66.0.43

echo -e "\n!!! KONFIGURASI ANDUINBANKS SELESAI !!!"
echo "Lanjut ke router berikutnya? (Moria atau Rivendell)"