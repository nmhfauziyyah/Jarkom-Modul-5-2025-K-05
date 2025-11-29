#!/bin/bash

# ==========================================================
# KONFIGURASI OSGILIATH (ROUTER & NAT GATEWAY) - FINAL REVISI
# Didasarkan pada VLSM yang Disediakan dan Urutan Interface: 
# eth0=NAT, eth1=Rivendell(A12), eth2=Moria(A7), eth3=Minastir(A1)
# ==========================================================

echo "Mulai konfigurasi Osgiliath (Revisi Final)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static/DHCP dan IP Forwarding
# ----------------------------------------------------------------
echo "--- 1. Misi 1: Konfigurasi IP Static/DHCP dan Forwarding ---"

# Konfigurasi /etc/network/interfaces (IP Static/DHCP)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke NAT1 (Internet)
auto eth0
iface eth0 inet dhcp

# eth1: ke Rivendell (A12: 10.66.0.28/30)
auto eth1
iface eth1 inet static
    address 10.66.0.29
    netmask 255.255.255.252

# eth2: ke Moria (A7: 10.66.0.16/30)
auto eth2
iface eth2 inet static
    address 10.66.0.17
    netmask 255.255.255.252

# eth3: ke Minastir (A1: 10.66.0.0/30)
auto eth3
iface eth3 inet static
    address 10.66.0.1
    netmask 255.255.255.252

EOF

# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

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

# Rute via Minastir (Gateway 10.66.0.2 - eth3)
# Subnet: A2, A3, A4, A5, A6
echo "Menambahkan rute via Minastir (10.66.0.2)"
route add -net 10.66.0.4 netmask 255.255.255.252 gw 10.66.0.2 # A2 (Minastir/Pelargir)
route add -net 10.66.0.8 netmask 255.255.255.252 gw 10.66.0.2 # A3 (Pelargir/AnduinBanks)
route add -net 10.66.0.12 netmask 255.255.255.252 gw 10.66.0.2 # A4 (Pelargir/Rajkatir)
route add -net 10.66.0.128 netmask 255.255.255.128 gw 10.66.0.2 # A5 (Gilgalad & Cirdan)
route add -net 10.66.1.0 netmask 255.255.255.0 gw 10.66.0.2 # A6 (Switch4/Elendil)

# Rute via Moria (Gateway 10.66.0.18 - eth2)
# Subnet: A8, A9, A10, A11
echo "Menambahkan rute via Moria (10.66.0.18)"
route add -net 10.66.0.20 netmask 255.255.255.252 gw 10.66.0.18 # A8 (Moria/Switch2)
route add -net 10.66.0.24 netmask 255.255.255.252 gw 10.66.0.18 # A9 (Moria/Westerland)
route add -net 10.66.0.64 netmask 255.255.255.192 gw 10.66.0.18 # A10 (Durin)
route add -net 10.66.0.32 netmask 255.255.255.248 gw 10.66.0.18 # A11 (Khamul)

# Rute via Rivendell (Gateway 10.66.0.30 - eth1)
# Subnet: A13
echo "Menambahkan rute via Rivendell (10.66.0.30)"
route add -net 10.66.0.40 netmask 255.255.255.248 gw 10.66.0.30 # A13 (Vilya/Narya)
echo "Static Routing selesai."
echo "========================================"


# ----------------------------------------------------------------
# C. Misi 2 No. 1: NAT (SNAT) untuk Akses Keluar Jaringan
# ----------------------------------------------------------------
echo "--- 3. Misi 2: Konfigurasi SNAT ---"

# Ambil IP publik eth0 secara dinamis
export PUBLIC_IP=$(ip a show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

# Hapus aturan POSTROUTING NAT yang mungkin ada
iptables -t nat -F POSTROUTING

# Tambahkan aturan SNAT (TIDAK MENGGUNAKAN MASQUERADE)
# Jaringan internal 10.66.0.0/23 (Total subnet) di-SNAT ke IP eth0 Osgiliath
iptables -t nat -A POSTROUTING -s 10.66.0.0/23 -o eth0 -j SNAT --to-source $PUBLIC_IP
echo "SNAT ke IP $PUBLIC_IP (eth0) untuk jaringan 10.66.0.0/23 selesai dikonfigurasi."
echo "========================================"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth[0-3]'

echo -e "\n=== KONFIRMASI IP FORWARDING ==="
cat /proc/sys/net/ipv4/ip_forward

echo -e "\n=== KONFIRMASI ROUTING TABLE ==="
route -n

echo -e "\n=== KONFIRMASI ATURAN NAT (SNAT) ==="
iptables -t nat -L POSTROUTING -v -n | grep "SNAT"

echo -e "\n=== UJI KONEKTIVITAS KE INTERNET ==="
ping -c 3 8.8.8.8
