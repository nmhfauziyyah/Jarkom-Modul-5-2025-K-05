#!/bin/bash

# ==========================================================
# KONFIGURASI RIVENDELL (ROUTER ONLY) - MODUL 5
# DHCP Relay DIHAPUS karena Vilya (DHCP Server) berada di Subnet A13
# ==========================================================

echo "Mulai konfigurasi Rivendell..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Osgiliath (A12: 10.66.0.28/30). Rivendell IP: 10.66.0.30
auto eth0
iface eth0 inet static
    address 10.66.0.30
    netmask 255.255.255.252

# eth1: ke Switch 1 / A13 (10.66.0.40/29). Rivendell IP: 10.66.0.41
auto eth1
iface eth1 inet static
    address 10.66.0.41
    netmask 255.255.255.248

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

# Default Gateway via Osgiliath (10.66.0.29)
route add default gw 10.66.0.29

# Rute via Osgiliath (Gateway 10.66.0.29 - eth0)
# Tujuan: Semua jaringan di "luar" Rivendell (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11)
echo "Menambahkan rute via Osgiliath (10.66.0.29)"
route add -net 10.66.0.0 netmask 255.255.255.252 gw 10.66.0.29 # A1
route add -net 10.66.0.4 netmask 255.255.255.252 gw 10.66.0.29 # A2
route add -net 10.66.0.8 netmask 255.255.255.252 gw 10.66.0.29 # A3
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.29 # A4
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.29 # A5
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.29 # A6
route add -net 10.66.0.16 netmask 255.255.255.252 gw 10.66.0.29 # A7
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.29 # A8
route add -net 10.66.0.24 netmask 255.255.255.252 gw 10.66.0.29 # A9
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.29 # A10
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.29 # A11
# A12 dan A13 Connected

echo "Static Routing selesai."
echo "========================================"


# ----------------------------------------------------------------
# C. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 3. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth[0-1]'

echo -e "\n=== KONFIRMASI IP FORWARDING ==="
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n=== KONFIRMASI ROUTING TABLE ==="
route -n

echo -e "\n=== UJI KONEKTIVITAS KE OSGILIATH (Gateway) ==="
ping -c 3 10.66.0.29

echo -e "\n=== UJI KONEKTIVITAS KE VILYA (DHCP Server) ==="
ping -c 3 10.66.0.43

echo -e "\n=== UJI PING KE INTERNET (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI RIVENDELL SELESAI !!!"