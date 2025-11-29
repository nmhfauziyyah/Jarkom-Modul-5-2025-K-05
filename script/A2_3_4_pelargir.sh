#!/bin/bash

# ==========================================================
# KONFIGURASI PELARGIR (ROUTER ONLY)
# DHCP Relay DIHAPUS karena klien DHCP (Isildur) berada di A6.
# ==========================================================

echo "Mulai konfigurasi Pelargir (Hanya Router)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Minastir (A2: 10.66.0.4/30). Pelargir IP: 10.66.0.6
auto eth0
iface eth0 inet static
    address 10.66.0.6
    netmask 255.255.255.252

# eth1: ke AnduinBanks (A3: 10.66.0.8/30). Pelargir IP: 10.66.0.9
auto eth1
iface eth1 inet static
    address 10.66.0.9
    netmask 255.255.255.252 

# eth2: ke A4 (Palantir/Web Server 2). Pelargir IP: 10.66.0.13
auto eth2
iface eth2 inet static
    address 10.66.0.13
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
echo "IP Configuration dan Forwarding selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 1 No. 3: Konfigurasi Static Routing
# ----------------------------------------------------------------
echo "--- 2. Misi 1: Konfigurasi Static Routing ---"

# Hapus rute lama untuk menghindari duplikasi
ip route flush table main

# Default Gateway via Minastir (10.66.0.5)
route add default gw 10.66.0.5

# Rute via Minastir (Gateway 10.66.0.5 - eth0)
# Tujuan: Semua jaringan di "kiri" Pelargir (A1, A6, A7, A8, A9, A10, A11, A12, A13)
echo "Menambahkan rute via Minastir (10.66.0.5)"
route add -net 10.66.0.0 netmask 255.255.255.252 gw 10.66.0.5   # A1
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.5     # A6
route add -net 10.66.0.16 netmask 255.255.255.252 gw 10.66.0.5   # A7
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.5   # A8
route add -net 10.66.0.24 netmask 255.255.255.252 gw 10.66.0.5   # A9
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.5   # A10
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.5   # A11
route add -net 10.66.0.28 netmask 255.255.255.252 gw 10.66.0.5   # A12
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.5   # A13

# Rute via AnduinBanks (Gateway 10.66.0.10 - eth1)
# Tujuan: A5 (Gilgalad & Cirdan)
echo "Menambahkan rute via AnduinBanks (10.66.0.10)"
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.10 # A5

echo "Static Routing selesai."
echo "========================================"


# ----------------------------------------------------------------
# C. Konfirmasi (DHCP Relay tidak ada, jadi ini hanya memastikan routing)
# ----------------------------------------------------------------
echo "--- 3. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth[0-2]'

echo -e "\n=== KONFIRMASI IP FORWARDING ==="
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n=== KONFIRMASI ROUTING TABLE ==="
route -n

echo -e "\n=== UJI KONEKTIVITAS KE MINASTIR (Gateway) ==="
ping -c 3 10.66.0.5

echo -e "\n=== UJI KONEKTIVITAS KE ANDUINBANKS ==="
ping -c 3 10.66.0.10

echo -e "\n!!! KONFIGURASI PELARGIR SELESAI !!!"